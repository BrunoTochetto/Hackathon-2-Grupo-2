const express = require('express');
const http = require('http');
const path = require('path');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// ==========================================
// 1. BANCO DE DADOS EM MEMÓRIA (VOLÁTIL)
// ==========================================

const DEFAULT_DIAS_SEMANA = {
  segunda: { abertura: '11:00', fechamento: '23:00', pico: [{ inicio: '11:30', fim: '14:00' }, { inicio: '19:00', fim: '21:30' }], baixa: [{ inicio: '14:30', fim: '17:00' }, { inicio: '22:00', fim: '23:00' }] },
  terca:   { abertura: '11:00', fechamento: '23:00', pico: [{ inicio: '11:30', fim: '14:00' }, { inicio: '19:00', fim: '21:30' }], baixa: [{ inicio: '14:30', fim: '17:00' }, { inicio: '22:00', fim: '23:00' }] },
  quarta:  { abertura: '11:00', fechamento: '23:00', pico: [{ inicio: '11:30', fim: '14:00' }, { inicio: '19:00', fim: '21:30' }], baixa: [{ inicio: '14:30', fim: '17:00' }, { inicio: '22:00', fim: '23:00' }] },
  quinta:  { abertura: '11:00', fechamento: '23:00', pico: [{ inicio: '11:30', fim: '14:00' }, { inicio: '19:00', fim: '21:30' }], baixa: [{ inicio: '14:30', fim: '17:00' }, { inicio: '22:00', fim: '23:00' }] },
  sexta:   { abertura: '11:00', fechamento: '23:30', pico: [{ inicio: '11:30', fim: '14:30' }, { inicio: '19:00', fim: '22:00' }], baixa: [{ inicio: '15:00', fim: '17:30' }, { inicio: '22:30', fim: '23:30' }] },
  sabado:  { abertura: '11:30', fechamento: '23:30', pico: [{ inicio: '12:00', fim: '15:00' }, { inicio: '19:30', fim: '22:30' }], baixa: [{ inicio: '15:30', fim: '18:00' }, { inicio: '22:30', fim: '23:30' }] },
  domingo: { abertura: '11:30', fechamento: '22:00', pico: [{ inicio: '12:00', fim: '15:30' }], baixa: [{ inicio: '16:00', fim: '18:00' }, { inicio: '21:00', fim: '22:00' }] }
};

const memoryStore = {
  restaurantes: {
    rest_01: {
      id: 'rest_01',
      nome: 'V.E.R Matriz',
      senha: 'admin',
      simulatedTime: null, // "HH:mm" para simulação se desejado
      dias_semana: JSON.parse(JSON.stringify(DEFAULT_DIAS_SEMANA)),
      historico_movimentos: []
    }
  }
};

function cadastrarRestaurante({ id, nome, senha }) {
  if (!id || typeof id !== 'string' || !id.trim()) {
    return { sucesso: false, mensagem: 'ID do restaurante é obrigatório.' };
  }
  if (!nome || typeof nome !== 'string' || !nome.trim()) {
    return { sucesso: false, mensagem: 'Nome do restaurante é obrigatório.' };
  }
  if (!senha || typeof senha !== 'string' || !senha.trim()) {
    return { sucesso: false, mensagem: 'Senha de acesso é obrigatória.' };
  }

  // Normalizar ID: minúsculo, substitui caracteres não-alfanuméricos por _
  const cleanId = id.trim().toLowerCase().replace(/[^a-z0-9_-]/g, '_');
  if (!cleanId) {
    return { sucesso: false, mensagem: 'ID do restaurante contém apenas caracteres inválidos.' };
  }

  if (memoryStore.restaurantes[cleanId]) {
    return { sucesso: false, mensagem: `O ID "${cleanId}" já está em uso por outro restaurante.` };
  }

  const novoRest = {
    id: cleanId,
    nome: nome.trim(),
    senha: senha.trim(),
    simulatedTime: null,
    dias_semana: JSON.parse(JSON.stringify(DEFAULT_DIAS_SEMANA)),
    historico_movimentos: []
  };

  memoryStore.restaurantes[cleanId] = novoRest;
  console.log(`[Cadastro] Novo restaurante registrado com sucesso: ${cleanId} - "${novoRest.nome}"`);

  return {
    sucesso: true,
    mensagem: 'Restaurante cadastrado com sucesso!',
    restaurante: {
      id: novoRest.id,
      nome: novoRest.nome
    }
  };
}

// Dias da semana indexados por getDay() (0 = domingo)
const DIAS_SEMANA_MAP = ['domingo', 'segunda', 'terca', 'quarta', 'quinta', 'sexta', 'sabado'];

// ==========================================
// 2. MOTOR DE DECISÃO E CÁLCULO DE FLUXO
// ==========================================

function parseTimeToMinutes(timeStr) {
  if (!timeStr || typeof timeStr !== 'string') return 0;
  const [h, m] = timeStr.split(':').map(Number);
  return (h || 0) * 60 + (m || 0);
}

function getCurrentTimeInfo(restaurante) {
  const now = new Date();
  const diaSemana = DIAS_SEMANA_MAP[now.getDay()];

  let horaMinutosStr;
  if (restaurante && restaurante.simulatedTime) {
    horaMinutosStr = restaurante.simulatedTime;
  } else {
    const hh = String(now.getHours()).padStart(2, '0');
    const mm = String(now.getMinutes()).padStart(2, '0');
    horaMinutosStr = `${hh}:${mm}`;
  }

  return { now, diaSemana, horaMinutosStr };
}

function getTipoHorario(restaurante, diaSemana, horaMinutosStr) {
  const configDia = restaurante && restaurante.dias_semana && restaurante.dias_semana[diaSemana];
  if (!configDia) return 'NORMAL';

  const minutosAtual = parseTimeToMinutes(horaMinutosStr);

  // 1. Verificar Horário de Abertura e Fechamento
  if (configDia.abertura && configDia.fechamento) {
    const aberturaMin = parseTimeToMinutes(configDia.abertura);
    const fechamentoMin = parseTimeToMinutes(configDia.fechamento);

    // Se estiver fora do horário de funcionamento
    if (minutosAtual < aberturaMin || minutosAtual > fechamentoMin) {
      return 'FECHADO';
    }

    // Se estiver nos últimos 30 minutos antes de fechar -> ENCERRAMENTO (baixa de produção obrigatória)
    if (minutosAtual >= (fechamentoMin - 30) && fechamentoMin > aberturaMin) {
      return 'ENCERRAMENTO';
    }
  }

  // 2. Verificar Múltiplos Horários de Pico
  if (Array.isArray(configDia.pico)) {
    for (const faixa of configDia.pico) {
      if (!faixa || !faixa.inicio || !faixa.fim) continue;
      const inicioMin = parseTimeToMinutes(faixa.inicio);
      const fimMin = parseTimeToMinutes(faixa.fim);
      if (minutosAtual >= inicioMin && minutosAtual <= fimMin) {
        return 'PICO';
      }
    }
  }

  // 3. Verificar Múltiplos Horários de Baixa
  if (Array.isArray(configDia.baixa)) {
    for (const faixa of configDia.baixa) {
      if (!faixa || !faixa.inicio || !faixa.fim) continue;
      const inicioMin = parseTimeToMinutes(faixa.inicio);
      const fimMin = parseTimeToMinutes(faixa.fim);
      if (minutosAtual >= inicioMin && minutosAtual <= fimMin) {
        return 'BAIXA';
      }
    }
  }

  return 'NORMAL';
}

function calculateProductionDecision(tipoHorario, saldoFluxo) {
  // Regras de Negócio:
  // - Restaurante Fechado:
  //   * FECHADO / FORA DO HORÁRIO
  // - Encerramento (Últimos 30 min):
  //   * BAIXA DE PRODUÇÃO
  // - Horário de Pico:
  //   * Saldo >= 0 -> AUMENTAR PRODUÇÃO
  //   * Saldo < 0 -> ESTAGNAÇÃO (MANTER)
  // - Horário Normal:
  //   * Saldo > 5 -> AUMENTAR PRODUÇÃO
  //   * -5 <= Saldo <= 5 -> ESTAGNAÇÃO (MANTER)
  //   * Saldo < -5 -> BAIXA DE PRODUÇÃO
  // - Horário de Baixa:
  //   * BAIXA DE PRODUÇÃO

  if (tipoHorario === 'FECHADO') {
    return 'FECHADO / FORA DO HORÁRIO';
  }

  if (tipoHorario === 'ENCERRAMENTO') {
    return 'BAIXA DE PRODUÇÃO';
  }

  if (tipoHorario === 'PICO') {
    if (saldoFluxo >= 0) {
      return 'AUMENTAR PRODUÇÃO';
    } else {
      return 'ESTAGNAÇÃO (MANTER)';
    }
  }

  if (tipoHorario === 'NORMAL') {
    if (saldoFluxo > 5) {
      return 'AUMENTAR PRODUÇÃO';
    } else if (saldoFluxo >= -5 && saldoFluxo <= 5) {
      return 'ESTAGNAÇÃO (MANTER)';
    } else {
      return 'BAIXA DE PRODUÇÃO';
    }
  }

  if (tipoHorario === 'BAIXA') {
    return 'BAIXA DE PRODUÇÃO';
  }

  return 'ESTAGNAÇÃO (MANTER)';
}

function calculate15MinRollingStats(restaurante) {
  const agoraMs = Date.now();
  const limite15Min = agoraMs - (15 * 60 * 1000);

  let entradas_15min = 0;
  let saidas_15min = 0;

  for (const mov of restaurante.historico_movimentos) {
    if (mov.timestamp >= limite15Min) {
      if (mov.tipo === 'ENTRADA') {
        entradas_15min += mov.quantidade;
      } else if (mov.tipo === 'SAIDA') {
        saidas_15min += mov.quantidade;
      }
    }
  }

  const saldo_fluxo_15min = entradas_15min - saidas_15min;

  return {
    entradas_15min,
    saidas_15min,
    saldo_fluxo_15min
  };
}

function getEstadoCompleto(restauranteId) {
  const restaurante = memoryStore.restaurantes[restauranteId];
  if (!restaurante) return null;

  const { diaSemana, horaMinutosStr } = getCurrentTimeInfo(restaurante);
  const tipoHorario = getTipoHorario(restaurante, diaSemana, horaMinutosStr);
  const stats = calculate15MinRollingStats(restaurante);
  const estadoProducao = calculateProductionDecision(tipoHorario, stats.saldo_fluxo_15min);

  return {
    restaurante_id: restaurante.id,
    restaurante_nome: restaurante.nome,
    estado_producao: estadoProducao,
    saldo_fluxo_15min: stats.saldo_fluxo_15min,
    entradas_15min: stats.entradas_15min,
    saidas_15min: stats.saidas_15min,
    tipo_horario_atual: tipoHorario,
    dia_semana: diaSemana,
    hora_atual: horaMinutosStr,
    hora_simulada_ativa: Boolean(restaurante.simulatedTime),
    ultimos_movimentos: restaurante.historico_movimentos.slice(-10).reverse()
  };
}

// ==========================================
// 3. ROTAS REST DA API
// ==========================================

app.post('/api/auth/login', (req, res) => {
  const { restaurante_id, senha, papel } = req.body;
  const rest = memoryStore.restaurantes[restaurante_id];
  if (!rest || rest.senha !== senha) {
    return res.status(401).json({ sucesso: false, mensagem: 'Credenciais inválidas.' });
  }
  if (papel !== 'RECEPCAO' && papel !== 'COZINHA') {
    return res.status(400).json({ sucesso: false, mensagem: 'Papel inválido. Selecione RECEPCAO ou COZINHA.' });
  }

  return res.json({
    sucesso: true,
    restaurante_id: rest.id,
    restaurante_nome: rest.nome,
    papel,
    estado_atual: getEstadoCompleto(restaurante_id),
    dias_semana: rest.dias_semana
  });
});

app.post('/api/auth/register', (req, res) => {
  const { id, restaurante_id, nome, senha } = req.body;
  const targetId = id || restaurante_id;
  const resultado = cadastrarRestaurante({ id: targetId, nome, senha });
  if (!resultado.sucesso) {
    return res.status(400).json(resultado);
  }
  return res.status(201).json(resultado);
});

app.get('/api/restaurantes', (req, res) => {
  const lista = Object.values(memoryStore.restaurantes).map((r) => ({
    id: r.id,
    nome: r.nome
  }));
  return res.json(lista);
});

app.get('/api/estado/:id', (req, res) => {
  const estado = getEstadoCompleto(req.params.id);
  if (!estado) return res.status(404).json({ erro: 'Restaurante não encontrado' });
  return res.json(estado);
});

app.get('/api/horarios/:id', (req, res) => {
  const rest = memoryStore.restaurantes[req.params.id];
  if (!rest) return res.status(404).json({ erro: 'Restaurante não encontrado' });
  return res.json({ restaurante_id: rest.id, dias_semana: rest.dias_semana });
});

// ==========================================
// 4. STREAM CONTÍNUO WEBSOCKET (SOCKET.IO)
// ==========================================

function broadcastEstado(restauranteId) {
  const estado = getEstadoCompleto(restauranteId);
  if (estado) {
    io.to(`rest_${restauranteId}`).emit('stream_estado', estado);
  }
}

io.on('connection', (socket) => {
  console.log(`[Socket] Conexão estabelecida: ${socket.id}`);

  socket.on('cadastrar_restaurante', ({ id, nome, senha }, callback) => {
    const resultado = cadastrarRestaurante({ id, nome, senha });
    if (typeof callback === 'function') {
      callback(resultado);
    }
  });

  socket.on('entrar_restaurante', ({ restaurante_id, senha, papel }, callback) => {
    const rest = memoryStore.restaurantes[restaurante_id];
    if (!rest || rest.senha !== senha) {
      if (typeof callback === 'function') {
        callback({ sucesso: false, mensagem: 'ID do restaurante ou senha incorretos.' });
      }
      return;
    }

    const roomName = `rest_${restaurante_id}`;
    socket.join(roomName);
    socket.restaurante_id = restaurante_id;
    socket.papel = papel;

    console.log(`[Socket ${socket.id}] Conectado ao ${restaurante_id} como ${papel}`);

    const estadoInicial = getEstadoCompleto(restaurante_id);
    if (typeof callback === 'function') {
      callback({
        sucesso: true,
        restaurante_nome: rest.nome,
        dias_semana: rest.dias_semana,
        estado_inicial: estadoInicial
      });
    }

    socket.emit('stream_estado', estadoInicial);
  });

  socket.on('registrar_fluxo', ({ restaurante_id, tipo, quantidade }) => {
    const rest = memoryStore.restaurantes[restaurante_id];
    if (!rest) return;
    if (tipo !== 'ENTRADA' && tipo !== 'SAIDA') return;
    const qtd = Number(quantidade) || 1;

    const agora = new Date();
    const registro = {
      id: Date.now() + Math.random().toString(36).substring(2, 5),
      tipo,
      quantidade: qtd,
      timestamp: Date.now(),
      horaFormatada: agora.toLocaleTimeString('pt-BR')
    };

    rest.historico_movimentos.push(registro);
    console.log(`[Fluxo] ${restaurante_id}: ${tipo} +${qtd} (Total movs: ${rest.historico_movimentos.length})`);

    broadcastEstado(restaurante_id);
  });

  socket.on('atualizar_horarios', ({ restaurante_id, dias_semana }, callback) => {
    const rest = memoryStore.restaurantes[restaurante_id];
    if (!rest || !dias_semana) return;

    rest.dias_semana = dias_semana;
    console.log(`[Config] Horários atualizados para ${restaurante_id}`);

    io.to(`rest_${restaurante_id}`).emit('horarios_atualizados', { dias_semana: rest.dias_semana });
    broadcastEstado(restaurante_id);

    if (typeof callback === 'function') {
      callback({ sucesso: true, dias_semana: rest.dias_semana });
    }
  });

  socket.on('definir_hora_simulada', ({ restaurante_id, hora_simulada }) => {
    const rest = memoryStore.restaurantes[restaurante_id];
    if (!rest) return;

    rest.simulatedTime = hora_simulada || null;
    console.log(`[Simulação] Hora para ${restaurante_id} definida como: ${rest.simulatedTime || 'Tempo Real (Sistema)'}`);
    broadcastEstado(restaurante_id);
  });

  socket.on('limpar_historico', ({ restaurante_id }) => {
    const rest = memoryStore.restaurantes[restaurante_id];
    if (!rest) return;

    rest.historico_movimentos = [];
    console.log(`[Historico] Limpo para ${restaurante_id}`);
    broadcastEstado(restaurante_id);
  });

  socket.on('disconnect', () => {
    console.log(`[Socket] Desconectado: ${socket.id}`);
  });
});

// Heartbeat / Tick a cada 5 segundos para reavaliação contínua da janela móvel e transição de horários
let heartbeatInterval = null;
function startHeartbeat() {
  if (heartbeatInterval) clearInterval(heartbeatInterval);
  heartbeatInterval = setInterval(() => {
    for (const restId of Object.keys(memoryStore.restaurantes)) {
      broadcastEstado(restId);
    }
  }, 5000);
}

// Inicializar Servidor quando executado diretamente
if (require.main === module) {
  startHeartbeat();
  server.listen(PORT, () => {
    console.log('====================================================');
    console.log(` V.E.R (Visão Estratégica de Recursos) - Servidor Ativo`);
    console.log(` URL Local: http://localhost:${PORT}`);
    console.log(` Credenciais Padrão: rest_01 / admin`);
    console.log('====================================================');
  });
}

module.exports = {
  app,
  server,
  memoryStore,
  DEFAULT_DIAS_SEMANA,
  cadastrarRestaurante,
  calculateProductionDecision,
  getTipoHorario,
  calculate15MinRollingStats,
  getEstadoCompleto
};
