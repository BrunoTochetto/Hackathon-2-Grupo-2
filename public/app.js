// =========================================================
// V.E.R (VISÃO ESTRATÉGICA DE RECURSOS) - FRONT-END
// =========================================================

const socket = io();

// Estado Local da Aplicação
const appState = {
  restauranteId: null,
  restauranteNome: null,
  papel: null, // "RECEPCAO" ou "COZINHA"
  diasSemana: {},
  diaSelecionado: 'segunda',
  ultimoEstadoProducao: null,
  somAtivado: true,
  cozinhaFullscreen: false,
  // Cache temporário para edição de slots do dia ativo
  slotsEdicao: {
    abertura: '11:00',
    fechamento: '23:00',
    pico: [],
    baixa: []
  }
};

// Sintetizador de Som com Web Audio API
let audioCtx = null;
function playStateChangeSound(estado) {
  if (!appState.somAtivado) return;
  try {
    if (!audioCtx) {
      audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    }
    if (audioCtx.state === 'suspended') {
      audioCtx.resume();
    }

    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    osc.connect(gain);
    gain.connect(audioCtx.destination);

    if (estado.includes('AUMENTAR')) {
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(523.25, audioCtx.currentTime); // C5
      osc.frequency.exponentialRampToValueAtTime(783.99, audioCtx.currentTime + 0.25); // G5
      gain.gain.setValueAtTime(0.2, audioCtx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.4);
      osc.start(audioCtx.currentTime);
      osc.stop(audioCtx.currentTime + 0.4);
    } else if (estado.includes('BAIXA')) {
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(440, audioCtx.currentTime); // A4
      osc.frequency.exponentialRampToValueAtTime(220, audioCtx.currentTime + 0.3); // A3
      gain.gain.setValueAtTime(0.2, audioCtx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.45);
      osc.start(audioCtx.currentTime);
      osc.stop(audioCtx.currentTime + 0.45);
    } else {
      osc.type = 'sine';
      osc.frequency.setValueAtTime(440, audioCtx.currentTime);
      gain.gain.setValueAtTime(0.15, audioCtx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.3);
      osc.start(audioCtx.currentTime);
      osc.stop(audioCtx.currentTime + 0.3);
    }
  } catch (err) {
    console.warn('AudioContext não pôde ser iniciado sem interação prévia:', err);
  }
}

// =========================================================
// ELEMENTOS DO DOM
// =========================================================

const screens = {
  login: document.getElementById('view-login'),
  recepcao: document.getElementById('view-recepcao'),
  cozinha: document.getElementById('view-cozinha')
};

// Layout, Topbar e Sidebar
const btnToggleMenu = document.getElementById('btn-toggle-menu');
const appSidebar = document.getElementById('app-sidebar');
const sidebarBackdrop = document.getElementById('sidebar-backdrop');
const sidebarNavItems = document.querySelectorAll('.sidebar-nav-item');
const navLoginIcon = document.getElementById('nav-login-icon');
const navLoginText = document.getElementById('nav-login-text');

const mainContentArea = document.getElementById('main-content-area');

// Login & Cadastro
const tabBtnLogin = document.getElementById('tab-btn-login');
const tabBtnRegister = document.getElementById('tab-btn-register');
const authPanelLogin = document.getElementById('auth-panel-login');
const authPanelRegister = document.getElementById('auth-panel-register');

const loginForm = document.getElementById('login-form');
const inputRestId = document.getElementById('input-rest-id');
const inputSenha = document.getElementById('input-senha');
const loginError = document.getElementById('login-error');

const registerForm = document.getElementById('register-form');
const inputRegId = document.getElementById('input-reg-id');
const inputRegName = document.getElementById('input-reg-name');
const inputRegSenha = document.getElementById('input-reg-senha');
const inputRegSenhaConfirm = document.getElementById('input-reg-senha-confirm');
const registerError = document.getElementById('register-error');
const registerSuccess = document.getElementById('register-success');

const accountsBadgesList = document.getElementById('accounts-badges-list');
const btnRefreshAccounts = document.getElementById('btn-refresh-accounts');

// Recepção
const recRestName = document.getElementById('rec-rest-name');
const recClock = document.getElementById('rec-clock');
const recTipoHorario = document.getElementById('rec-tipo-horario');
const recEntradas = document.getElementById('rec-entradas');
const recSaidas = document.getElementById('rec-saidas');
const recSaldo = document.getElementById('rec-saldo');
const recEstadoProd = document.getElementById('rec-estado-prod');
const recMovimentosTbody = document.getElementById('rec-movimentos-tbody');

// Fluxo Customizado
const inputCustomFlowQtd = document.getElementById('input-custom-flow-qtd');
const btnCustomIn = document.getElementById('btn-custom-in');
const btnCustomOut = document.getElementById('btn-custom-out');

// Cozinha
const cozRestName = document.getElementById('coz-rest-name');
const cozCommandBox = document.getElementById('coz-command-box');
const cozMainDisplay = document.querySelector('.cozinha-main-display');
const cozEstadoTexto = document.getElementById('coz-estado-texto');
const cozDiaSemana = document.getElementById('coz-dia-semana');
const cozTipoHorario = document.getElementById('coz-tipo-horario');
const cozSaldoFluxo = document.getElementById('coz-saldo-fluxo');
const cozHoraAtual = document.getElementById('coz-hora-atual');
const btnToggleSound = document.getElementById('btn-toggle-sound');
const btnToggleFullscreen = document.getElementById('btn-toggle-fullscreen');

// Configuração de Horários Dinâmicos
const dayTabs = document.querySelectorAll('.day-tab');
const currentDayLabel = document.getElementById('current-day-label');
const inputAbertura = document.getElementById('input-abertura');
const inputFechamento = document.getElementById('input-fechamento');
const picoSlotsContainer = document.getElementById('pico-slots-container');
const baixaSlotsContainer = document.getElementById('baixa-slots-container');
const btnAddPicoSlot = document.getElementById('btn-add-pico-slot');
const btnAddBaixaSlot = document.getElementById('btn-add-baixa-slot');
const btnSalvarHorarios = document.getElementById('btn-salvar-horarios');
const saveHorariosFeedback = document.getElementById('save-horarios-feedback');

// Nomes amigáveis para os dias da semana
const DIAS_NOMES = {
  segunda: 'Segunda-feira',
  terca: 'Terça-feira',
  quarta: 'Quarta-feira',
  quinta: 'Quinta-feira',
  sexta: 'Sexta-feira',
  sabado: 'Sábado',
  domingo: 'Domingo'
};

// =========================================================
// NAVEGAÇÃO DE TELAS & SIDEBAR
// =========================================================

function showScreen(screenKey) {
  Object.keys(screens).forEach((key) => {
    if (screens[key]) screens[key].classList.remove('active');
  });

  if (screens[screenKey]) {
    screens[screenKey].classList.add('active');
  }

  // Atualiza item ativo da sidebar
  sidebarNavItems.forEach((btn) => {
    if (btn.dataset.target === `view-${screenKey}`) {
      btn.classList.add('active');
    } else {
      btn.classList.remove('active');
    }
  });

  // Fecha menu mobile após seleção
  closeMobileMenu();

  // Rola para o topo do conteúdo
  if (mainContentArea) {
    mainContentArea.scrollTop = 0;
  }
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// Controle do Menu Hambúrguer (Mobile)
function toggleMobileMenu() {
  if (appSidebar) appSidebar.classList.toggle('open');
  if (sidebarBackdrop) sidebarBackdrop.classList.toggle('active');
}

function closeMobileMenu() {
  if (appSidebar) appSidebar.classList.remove('open');
  if (sidebarBackdrop) sidebarBackdrop.classList.remove('active');
}

if (btnToggleMenu) btnToggleMenu.addEventListener('click', toggleMobileMenu);
if (sidebarBackdrop) sidebarBackdrop.addEventListener('click', closeMobileMenu);

// Cliques nos itens da sidebar
sidebarNavItems.forEach((btn) => {
  btn.addEventListener('click', () => {
    const targetId = btn.dataset.target;
    if (targetId === 'view-login') {
      if (appState.restauranteId) {
        handleLogout();
      } else {
        showScreen('login');
      }
    } else if (targetId === 'view-recepcao') {
      showScreen('recepcao');
    } else if (targetId === 'view-cozinha') {
      showScreen('cozinha');
    }
  });
});

// Relógio Local no Painel da Recepção
setInterval(() => {
  if (recClock) {
    const agora = new Date();
    recClock.textContent = agora.toLocaleTimeString('pt-BR');
  }
}, 1000);

// =========================================================
// MODO TELA CHEIA NA COZINHA (FULLSCREEN)
// =========================================================

function toggleKitchenFullscreen() {
  appState.cozinhaFullscreen = !appState.cozinhaFullscreen;
  if (appState.cozinhaFullscreen) {
    document.body.classList.add('cozinha-fullscreen');
    if (btnToggleFullscreen) btnToggleFullscreen.textContent = '✖ Sair da Tela Cheia';
    
    // Tenta fullscreen nativo do navegador se suportado
    if (document.documentElement.requestFullscreen && !document.fullscreenElement) {
      document.documentElement.requestFullscreen().catch(() => {});
    }
  } else {
    document.body.classList.remove('cozinha-fullscreen');
    if (btnToggleFullscreen) btnToggleFullscreen.textContent = '⛶ Tela Cheia';

    if (document.exitFullscreen && document.fullscreenElement) {
      document.exitFullscreen().catch(() => {});
    }
  }
}

if (btnToggleFullscreen) {
  btnToggleFullscreen.addEventListener('click', toggleKitchenFullscreen);
}

// Tecla ESC para sair da tela cheia
window.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && appState.cozinhaFullscreen) {
    toggleKitchenFullscreen();
  }
});

// =========================================================
// 1. FLUXO DE AUTENTICAÇÃO E CADASTRO DE RESTAURANTES
// =========================================================

// Alternância entre Abas: Login e Cadastro
function switchAuthTab(tab) {
  if (tab === 'login') {
    if (tabBtnLogin) tabBtnLogin.classList.add('active');
    if (tabBtnRegister) tabBtnRegister.classList.remove('active');
    if (authPanelLogin) authPanelLogin.classList.add('active');
    if (authPanelRegister) authPanelRegister.classList.remove('active');
  } else {
    if (tabBtnLogin) tabBtnLogin.classList.remove('active');
    if (tabBtnRegister) tabBtnRegister.classList.add('active');
    if (authPanelLogin) authPanelLogin.classList.remove('active');
    if (authPanelRegister) authPanelRegister.classList.add('active');
  }

  if (loginError) loginError.classList.add('hidden');
  if (registerError) registerError.classList.add('hidden');
}

if (tabBtnLogin) {
  tabBtnLogin.addEventListener('click', () => switchAuthTab('login'));
}

if (tabBtnRegister) {
  tabBtnRegister.addEventListener('click', () => switchAuthTab('register'));
}

// Carregar e Exibir Contas Disponíveis no Sistema
async function carregarContasDisponiveis() {
  if (!accountsBadgesList) return;
  try {
    const res = await fetch('/api/restaurantes');
    if (!res.ok) return;
    const contas = await res.json();

    if (!Array.isArray(contas) || contas.length === 0) {
      accountsBadgesList.innerHTML = '<span class="section-hint">Nenhum restaurante cadastrado no momento.</span>';
      return;
    }

    accountsBadgesList.innerHTML = contas.map((c) => `
      <button type="button" class="account-badge-btn" data-id="${c.id}" title="Clique para selecionar este restaurante">
        <span class="account-badge-id">${c.id}</span>
        <span>${c.nome}</span>
      </button>
    `).join('');

    // Evento de clique para auto-preenchimento
    accountsBadgesList.querySelectorAll('.account-badge-btn').forEach((btn) => {
      btn.addEventListener('click', () => {
        const id = btn.dataset.id;
        if (inputRestId) {
          inputRestId.value = id;
        }
        switchAuthTab('login');
        if (inputSenha) {
          inputSenha.focus();
        }
      });
    });
  } catch (err) {
    console.warn('[Contas] Falha ao carregar lista de restaurantes:', err);
  }
}

if (btnRefreshAccounts) {
  btnRefreshAccounts.addEventListener('click', carregarContasDisponiveis);
}

// Submissão do Formulário de Cadastro
if (registerForm) {
  registerForm.addEventListener('submit', (e) => {
    e.preventDefault();
    if (registerError) registerError.classList.add('hidden');
    if (registerSuccess) registerSuccess.classList.add('hidden');

    const id = inputRegId.value.trim();
    const nome = inputRegName.value.trim();
    const senha = inputRegSenha.value.trim();
    const senhaConfirm = inputRegSenhaConfirm.value.trim();

    if (!id) {
      registerError.textContent = 'Informe o ID do restaurante.';
      registerError.classList.remove('hidden');
      return;
    }

    if (!nome) {
      registerError.textContent = 'Informe o nome do restaurante.';
      registerError.classList.remove('hidden');
      return;
    }

    if (!senha) {
      registerError.textContent = 'Informe uma senha de acesso.';
      registerError.classList.remove('hidden');
      return;
    }

    if (senha !== senhaConfirm) {
      registerError.textContent = 'As senhas digitadas não coincidem. Verifique e tente novamente.';
      registerError.classList.remove('hidden');
      return;
    }

    socket.emit('cadastrar_restaurante', { id, nome, senha }, (response) => {
      if (!response || !response.sucesso) {
        registerError.textContent = response ? response.mensagem : 'Erro ao cadastrar restaurante.';
        registerError.classList.remove('hidden');
        return;
      }

      // Sucesso no cadastro
      registerSuccess.textContent = `✔ ${response.mensagem} O ID "${response.restaurante.id}" está pronto para uso.`;
      registerSuccess.classList.remove('hidden');

      // Limpa os campos do formulário de cadastro
      registerForm.reset();

      // Atualiza listagem de contas
      carregarContasDisponiveis();

      // Preenche o ID no formulário de login e muda para a aba de login após breve intervalo
      if (inputRestId) {
        inputRestId.value = response.restaurante.id;
      }
      if (inputSenha) {
        inputSenha.value = '';
      }

      setTimeout(() => {
        switchAuthTab('login');
        if (inputSenha) {
          inputSenha.focus();
        }
      }, 1500);
    });
  });
}

// Submissão do Formulário de Login
loginForm.addEventListener('submit', (e) => {
  e.preventDefault();
  loginError.classList.add('hidden');

  const restaurante_id = inputRestId.value.trim();
  const senha = inputSenha.value.trim();
  const papelRadio = document.querySelector('input[name="role"]:checked');
  const papel = papelRadio ? papelRadio.value : 'RECEPCAO';

  socket.emit('entrar_restaurante', { restaurante_id, senha, papel }, (response) => {
    if (!response || !response.sucesso) {
      loginError.textContent = response ? response.mensagem : 'Erro ao conectar ao servidor.';
      loginError.classList.remove('hidden');
      return;
    }

    appState.restauranteId = restaurante_id;
    appState.restauranteNome = response.restaurante_nome;
    appState.papel = papel;
    appState.diasSemana = response.dias_semana || {};

    // Atualiza estado de login para exibir sidebar
    document.body.classList.remove('not-logged-in');
    document.body.classList.add('logged-in');

    // Atualiza cabeçalho com usuário ativo
    const papelNome = papel === 'RECEPCAO' ? 'Recepção' : 'Cozinha';


    // Atualiza botão da sidebar para 'Sair'
    if (navLoginText) navLoginText.textContent = 'Sair';
    if (navLoginIcon) navLoginIcon.textContent = '🚪';

    if (papel === 'RECEPCAO') {
      recRestName.textContent = appState.restauranteNome;
      loadDayScheduleToInputs(appState.diaSelecionado);
      showScreen('recepcao');
    } else {
      cozRestName.textContent = appState.restauranteNome;
      showScreen('cozinha');
    }

    if (response.estado_inicial) {
      updateUIWithStream(response.estado_inicial);
    }
  });
});

function handleLogout() {
  appState.restauranteId = null;
  appState.papel = null;
  appState.ultimoEstadoProducao = null;
  
  if (appState.cozinhaFullscreen) {
    toggleKitchenFullscreen();
  }

  document.body.classList.remove('logged-in');
  document.body.classList.add('not-logged-in');


  // Restaura botão da sidebar para 'Login'
  if (navLoginText) navLoginText.textContent = 'Login';
  if (navLoginIcon) navLoginIcon.textContent = '🔐';

  carregarContasDisponiveis();
  showScreen('login');
}

// Alternar Alerta Sonoro na Cozinha
btnToggleSound.addEventListener('click', () => {
  appState.somAtivado = !appState.somAtivado;
  if (appState.somAtivado) {
    btnToggleSound.textContent = '🔔 Som: Ativado';
    btnToggleSound.classList.remove('muted');
  } else {
    btnToggleSound.textContent = '🔕 Som: Mudo';
    btnToggleSound.classList.add('muted');
  }
});

// =========================================================
// 2. PAINEL DA RECEPÇÃO: REGISTRO DE FLUXO
// =========================================================

function registerFlow(tipo, quantidade) {
  if (!appState.restauranteId) return;
  const qtd = Math.max(1, Number(quantidade) || 1);
  socket.emit('registrar_fluxo', {
    restaurante_id: appState.restauranteId,
    tipo,
    quantidade: qtd
  });
}

// Botões rápidos
document.getElementById('btn-in-1').addEventListener('click', () => registerFlow('ENTRADA', 1));
document.getElementById('btn-in-5').addEventListener('click', () => registerFlow('ENTRADA', 5));
document.getElementById('btn-out-1').addEventListener('click', () => registerFlow('SAIDA', 1));
document.getElementById('btn-out-5').addEventListener('click', () => registerFlow('SAIDA', 5));

// Botões de quantidade customizada
if (btnCustomIn) {
  btnCustomIn.addEventListener('click', () => {
    const qtd = Number(inputCustomFlowQtd.value) || 1;
    registerFlow('ENTRADA', qtd);
  });
}

if (btnCustomOut) {
  btnCustomOut.addEventListener('click', () => {
    const qtd = Number(inputCustomFlowQtd.value) || 1;
    registerFlow('SAIDA', qtd);
  });
}

// =========================================================
// 3. ATUALIZAÇÃO REATIVA DO WEBSOCKET
// =========================================================

socket.on('stream_estado', (payload) => {
  if (!payload || payload.restaurante_id !== appState.restauranteId) return;
  updateUIWithStream(payload);
});

socket.on('horarios_atualizados', ({ dias_semana }) => {
  appState.diasSemana = dias_semana;
  if (appState.papel === 'RECEPCAO') {
    loadDayScheduleToInputs(appState.diaSelecionado);
  }
});

function updateUIWithStream(data) {
  const {
    estado_producao,
    saldo_fluxo_15min,
    entradas_15min,
    saidas_15min,
    tipo_horario_atual,
    dia_semana,
    hora_atual,
    ultimos_movimentos
  } = data;

  // Se o estado mudou na Cozinha, emitir aviso sonoro
  if (appState.ultimoEstadoProducao && appState.ultimoEstadoProducao !== estado_producao) {
    playStateChangeSound(estado_producao);
  }
  appState.ultimoEstadoProducao = estado_producao;

  // ----------------------------------------------------
  // Atualização da Visão da Cozinha
  // ----------------------------------------------------
  if (cozEstadoTexto) {
    cozEstadoTexto.textContent = estado_producao;
  }

  if (cozMainDisplay) {
    cozMainDisplay.classList.remove('bg-aumentar', 'bg-manter', 'bg-baixa', 'bg-fechado');
    if (estado_producao.includes('FECHADO')) {
      cozMainDisplay.classList.add('bg-fechado');
    } else if (estado_producao.includes('AUMENTAR')) {
      cozMainDisplay.classList.add('bg-aumentar');
    } else if (estado_producao.includes('BAIXA')) {
      cozMainDisplay.classList.add('bg-baixa');
    } else {
      cozMainDisplay.classList.add('bg-manter');
    }
  }

  const diaFormatado = DIAS_NOMES[dia_semana] || dia_semana;
  if (cozDiaSemana) cozDiaSemana.textContent = diaFormatado;
  
  let tipoHorarioFormatado = 'Normal';
  if (tipo_horario_atual === 'PICO') tipoHorarioFormatado = 'Pico';
  if (tipo_horario_atual === 'BAIXA') tipoHorarioFormatado = 'Baixa';
  if (tipo_horario_atual === 'ENCERRAMENTO') tipoHorarioFormatado = 'Encerramento';
  if (tipo_horario_atual === 'FECHADO') tipoHorarioFormatado = 'Fechado';
  if (cozTipoHorario) cozTipoHorario.textContent = tipoHorarioFormatado;

  const saldoFormatado = (saldo_fluxo_15min > 0 ? `+${saldo_fluxo_15min}` : `${saldo_fluxo_15min}`);
  if (cozSaldoFluxo) cozSaldoFluxo.textContent = `${saldoFormatado} (In: ${entradas_15min} | Out: ${saidas_15min})`;
  if (cozHoraAtual) cozHoraAtual.textContent = hora_atual;

  // ----------------------------------------------------
  // Atualização da Visão da Recepção
  // ----------------------------------------------------
  if (recTipoHorario) {
    recTipoHorario.textContent = tipo_horario_atual;
    recTipoHorario.className = 'status-pill';
    if (tipo_horario_atual === 'PICO') recTipoHorario.classList.add('pico');
    if (tipo_horario_atual === 'BAIXA') recTipoHorario.classList.add('baixa');
    if (tipo_horario_atual === 'FECHADO' || tipo_horario_atual === 'ENCERRAMENTO') recTipoHorario.classList.add('fechado');
  }

  if (recEntradas) recEntradas.textContent = entradas_15min;
  if (recSaidas) recSaidas.textContent = saidas_15min;

  if (recSaldo) {
    const prefixo = saldo_fluxo_15min > 0 ? '+' : '';
    recSaldo.textContent = `${prefixo}${saldo_fluxo_15min}`;
    if (saldo_fluxo_15min > 0) {
      recSaldo.className = 'metric-value text-success';
    } else if (saldo_fluxo_15min < 0) {
      recSaldo.className = 'metric-value text-danger';
    } else {
      recSaldo.className = 'metric-value';
    }
  }

  if (recEstadoProd) {
    recEstadoProd.textContent = estado_producao;
    recEstadoProd.className = 'summary-badge';
    if (estado_producao.includes('FECHADO')) {
      recEstadoProd.classList.add('state-fechado');
    } else if (estado_producao.includes('AUMENTAR')) {
      recEstadoProd.classList.add('state-aumentar');
    } else if (estado_producao.includes('BAIXA')) {
      recEstadoProd.classList.add('state-baixa');
    } else {
      recEstadoProd.classList.add('state-manter');
    }
  }

  renderMovementHistoryTable(ultimos_movimentos || []);
}

function renderMovementHistoryTable(movimentos) {
  if (!recMovimentosTbody) return;

  if (movimentos.length === 0) {
    recMovimentosTbody.innerHTML = '<tr><td colspan="3" class="text-center">Nenhum movimento recente</td></tr>';
    return;
  }

  recMovimentosTbody.innerHTML = movimentos.map((mov) => {
    const isEntrada = mov.tipo === 'ENTRADA';
    const tagClass = isEntrada ? 'text-success' : 'text-danger';
    const sinal = isEntrada ? '+' : '-';
    return `
      <tr>
        <td>${mov.horaFormatada || '--:--'}</td>
        <td class="${tagClass}"><strong>${mov.tipo}</strong></td>
        <td><strong>${sinal}${mov.quantidade}</strong></td>
      </tr>
    `;
  }).join('');
}

// =========================================================
// 4. EDITOR DE MÚLTIPLOS HORÁRIOS POR DIA DA SEMANA
// =========================================================

dayTabs.forEach((tab) => {
  tab.addEventListener('click', () => {
    dayTabs.forEach((t) => t.classList.remove('active'));
    tab.classList.add('active');
    appState.diaSelecionado = tab.dataset.day;
    loadDayScheduleToInputs(appState.diaSelecionado);
  });
});

function renderSlotsList(container, slots, type) {
  if (!container) return;
  container.innerHTML = '';

  if (!slots || slots.length === 0) {
    container.innerHTML = '<p class="section-hint" style="margin-bottom:0">Nenhuma faixa cadastrada.</p>';
    return;
  }

  slots.forEach((slot, index) => {
    const row = document.createElement('div');
    row.className = 'slot-row';
    row.innerHTML = `
      <label>Início: <input type="time" class="input-slot-inicio" data-type="${type}" data-index="${index}" value="${slot.inicio || '12:00'}"></label>
      <label>Fim: <input type="time" class="input-slot-fim" data-type="${type}" data-index="${index}" value="${slot.fim || '14:00'}"></label>
      <button type="button" class="btn-remove-slot" data-type="${type}" data-index="${index}" title="Remover faixa">✖</button>
    `;
    container.appendChild(row);
  });

  // Eventos de remoção
  container.querySelectorAll('.btn-remove-slot').forEach((btn) => {
    btn.addEventListener('click', (e) => {
      const idx = Number(btn.dataset.index);
      const slotType = btn.dataset.type;
      appState.slotsEdicao[slotType].splice(idx, 1);
      renderSlotsList(container, appState.slotsEdicao[slotType], slotType);
    });
  });

  // Eventos de alteração dos inputs de tempo
  container.querySelectorAll('.input-slot-inicio').forEach((inp) => {
    inp.addEventListener('change', (e) => {
      const idx = Number(inp.dataset.index);
      const slotType = inp.dataset.type;
      if (appState.slotsEdicao[slotType][idx]) {
        appState.slotsEdicao[slotType][idx].inicio = inp.value;
      }
    });
  });

  container.querySelectorAll('.input-slot-fim').forEach((inp) => {
    inp.addEventListener('change', (e) => {
      const idx = Number(inp.dataset.index);
      const slotType = inp.dataset.type;
      if (appState.slotsEdicao[slotType][idx]) {
        appState.slotsEdicao[slotType][idx].fim = inp.value;
      }
    });
  });
}

function loadDayScheduleToInputs(dia) {
  currentDayLabel.textContent = DIAS_NOMES[dia] || dia;
  saveHorariosFeedback.textContent = '';

  const configDia = appState.diasSemana[dia] || {
    abertura: '11:00',
    fechamento: '23:00',
    pico: [{ inicio: '11:30', fim: '14:00' }],
    baixa: [{ inicio: '14:30', fim: '17:00' }]
  };

  appState.slotsEdicao = {
    abertura: configDia.abertura || '11:00',
    fechamento: configDia.fechamento || '23:00',
    pico: JSON.parse(JSON.stringify(configDia.pico || [])),
    baixa: JSON.parse(JSON.stringify(configDia.baixa || []))
  };

  if (inputAbertura) inputAbertura.value = appState.slotsEdicao.abertura;
  if (inputFechamento) inputFechamento.value = appState.slotsEdicao.fechamento;

  renderSlotsList(picoSlotsContainer, appState.slotsEdicao.pico, 'pico');
  renderSlotsList(baixaSlotsContainer, appState.slotsEdicao.baixa, 'baixa');
}

if (btnAddPicoSlot) {
  btnAddPicoSlot.addEventListener('click', () => {
    appState.slotsEdicao.pico.push({ inicio: '19:00', fim: '21:30' });
    renderSlotsList(picoSlotsContainer, appState.slotsEdicao.pico, 'pico');
  });
}

if (btnAddBaixaSlot) {
  btnAddBaixaSlot.addEventListener('click', () => {
    appState.slotsEdicao.baixa.push({ inicio: '15:00', fim: '17:00' });
    renderSlotsList(baixaSlotsContainer, appState.slotsEdicao.baixa, 'baixa');
  });
}

if (btnSalvarHorarios) {
  btnSalvarHorarios.addEventListener('click', () => {
    const dia = appState.diaSelecionado;

    appState.diasSemana[dia] = {
      abertura: inputAbertura ? inputAbertura.value : '11:00',
      fechamento: inputFechamento ? inputFechamento.value : '23:00',
      pico: appState.slotsEdicao.pico,
      baixa: appState.slotsEdicao.baixa
    };

    socket.emit('atualizar_horarios', {
      restaurante_id: appState.restauranteId,
      dias_semana: appState.diasSemana
    }, (resp) => {
      if (resp && resp.sucesso) {
        saveHorariosFeedback.textContent = '✔ Salvo!';
        setTimeout(() => { saveHorariosFeedback.textContent = ''; }, 3000);
      }
    });
  });
}

// =========================================================
// 5. SIMULAÇÃO DE HORÁRIOS
// =========================================================

const simButtons = document.querySelectorAll('.btn-sim');
simButtons.forEach((btn) => {
  btn.addEventListener('click', () => {
    simButtons.forEach((b) => b.classList.remove('active'));
    btn.classList.add('active');

    const horaSimulada = btn.dataset.time || null;
    socket.emit('definir_hora_simulada', {
      restaurante_id: appState.restauranteId,
      hora_simulada: horaSimulada
    });
  });
});

document.getElementById('btn-limpar-fluxo').addEventListener('click', () => {
  if (confirm('Deseja zerar o histórico recente de fluxo deste restaurante?')) {
    socket.emit('limpar_historico', { restaurante_id: appState.restauranteId });
  }
});

// Inicialização: carregar contas cadastradas na inicialização
carregarContasDisponiveis();


