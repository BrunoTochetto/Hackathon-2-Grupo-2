const assert = require('assert');
const {
  calculateProductionDecision,
  getTipoHorario,
  calculate15MinRollingStats,
  cadastrarRestaurante,
  getEstadoCompleto,
  memoryStore
} = require('../server');

console.log("=== INICIANDO TESTES DO MOTOR V.E.R (VISÃO ESTRATÉGICA DE RECURSOS) ===");

// ----------------------------------------------------
// TESTE 1: MATRIZ DE DECISÃO DE PRODUÇÃO
// ----------------------------------------------------
console.log("\n[1] Testando Regras da Matriz de Decisão...");

// 1.1 Horário de Pico
valor = assert.strictEqual(calculateProductionDecision('PICO', 0), 'AUMENTAR PRODUÇÃO', 'PICO com saldo 0 deve AUMENTAR');
valor = assert.strictEqual(calculateProductionDecision('PICO', 12), 'AUMENTAR PRODUÇÃO', 'PICO com saldo positivo deve AUMENTAR');
valor = assert.strictEqual(calculateProductionDecision('PICO', -6), 'ESTAGNAÇÃO (MANTER)', 'PICO com saldo < -5 deve MANTER');
valor = assert.strictEqual(calculateProductionDecision('PICO', -3), 'ESTAGNAÇÃO (MANTER)', 'PICO com saldo entre -5 e 0 deve MANTER');
console.log("  ✔ Regras de Horário de Pico: PASSOU");

// 1.2 Horário Normal
valor = assert.strictEqual(calculateProductionDecision('NORMAL', 6), 'AUMENTAR PRODUÇÃO', 'NORMAL com saldo > 5 deve AUMENTAR');
valor = assert.strictEqual(calculateProductionDecision('NORMAL', 5), 'ESTAGNAÇÃO (MANTER)', 'NORMAL com saldo 5 deve MANTER');
valor = assert.strictEqual(calculateProductionDecision('NORMAL', 0), 'ESTAGNAÇÃO (MANTER)', 'NORMAL com saldo 0 deve MANTER');
valor = assert.strictEqual(calculateProductionDecision('NORMAL', -5), 'ESTAGNAÇÃO (MANTER)', 'NORMAL com saldo -5 deve MANTER');
valor = assert.strictEqual(calculateProductionDecision('NORMAL', -6), 'BAIXA DE PRODUÇÃO', 'NORMAL com saldo < -5 deve BAIXAR');
console.log("  ✔ Regras de Horário Normal: PASSOU");

// 1.3 Horário de Baixa
valor = assert.strictEqual(calculateProductionDecision('BAIXA', 10), 'BAIXA DE PRODUÇÃO', 'BAIXA com qualquer saldo deve BAIXAR');
valor = assert.strictEqual(calculateProductionDecision('BAIXA', -2), 'BAIXA DE PRODUÇÃO', 'BAIXA deve BAIXAR');
console.log("  ✔ Regras de Horário de Baixa: PASSOU");

// 1.4 Regras Especiais de Fechado e Encerramento
valor = assert.strictEqual(calculateProductionDecision('FECHADO', 10), 'FECHADO / FORA DO HORÁRIO', 'FECHADO deve retornar FECHADO');
valor = assert.strictEqual(calculateProductionDecision('ENCERRAMENTO', 10), 'BAIXA DE PRODUÇÃO', 'ENCERRAMENTO deve BAIXAR produção para evitar desperdício');
console.log("  ✔ Regras de Fechamento e Encerramento: PASSOU");

// ----------------------------------------------------
// TESTE 2: RECONHECIMENTO DE FAIXA DE HORÁRIO E ABERTURA/FECHAMENTO
// ----------------------------------------------------
console.log("\n[2] Testando Reconhecimento de Horário e Abertura/Fechamento...");

const restauranteMock = {
  dias_semana: {
    quarta: {
      abertura: '11:00',
      fechamento: '22:00',
      pico: [
        { inicio: '12:00', fim: '14:00' },
        { inicio: '19:00', fim: '21:00' }
      ],
      baixa: [
        { inicio: '14:00', fim: '16:00' },
        { inicio: '16:00', fim: '18:00' }
      ]
    }
  }
};

// Teste de Abertura / Fechamento
valor = assert.strictEqual(getTipoHorario(restauranteMock, 'quarta', '10:59'), 'FECHADO', 'Antes da abertura deve ser FECHADO');
valor = assert.strictEqual(getTipoHorario(restauranteMock, 'quarta', '22:01'), 'FECHADO', 'Após o fechamento deve ser FECHADO');
valor = assert.strictEqual(getTipoHorario(restauranteMock, 'quarta', '21:40'), 'ENCERRAMENTO', 'Últimos 30 min deve ser ENCERRAMENTO');

// Teste de múltiplos picos e baixas
valor = assert.strictEqual(getTipoHorario(restauranteMock, 'quarta', '11:30'), 'NORMAL', 'Dentro do horário normal de operação');
valor = assert.strictEqual(getTipoHorario(restauranteMock, 'quarta', '12:00'), 'PICO', 'Primeira faixa de pico');
valor = assert.strictEqual(getTipoHorario(restauranteMock, 'quarta', '13:30'), 'PICO', 'Dentro da primeira faixa de pico');
valor = assert.strictEqual(getTipoHorario(restauranteMock, 'quarta', '14:30'), 'BAIXA', 'Primeira faixa de baixa');
valor = assert.strictEqual(getTipoHorario(restauranteMock, 'quarta', '17:00'), 'BAIXA', 'Segunda faixa de baixa');
valor = assert.strictEqual(getTipoHorario(restauranteMock, 'quarta', '18:30'), 'NORMAL', 'Entre baixa e segundo pico');
valor = assert.strictEqual(getTipoHorario(restauranteMock, 'quarta', '19:30'), 'PICO', 'Segunda faixa de pico');
console.log("  ✔ Abertura, Fechamento, Múltiplos Picos e Baixas: PASSOU");

// ----------------------------------------------------
// TESTE 3: JANELA MÓVEL DE 15 MINUTOS
// ----------------------------------------------------
console.log("\n[3] Testando Janela Móvel dos Últimos 15 Minutos...");

const agora = Date.now();
const vinteMinAtras = agora - (20 * 60 * 1000);
const dezMinAtras = agora - (10 * 60 * 1000);
const doisMinAtras = agora - (2 * 60 * 1000);

const restHistoricoMock = {
  historico_movimentos: [
    { tipo: 'ENTRADA', quantidade: 10, timestamp: vinteMinAtras }, // Deve ser IGNORADO (fora dos 15m)
    { tipo: 'ENTRADA', quantidade: 5,  timestamp: dezMinAtras },   // Válido (+5)
    { tipo: 'ENTRADA', quantidade: 1,  timestamp: doisMinAtras },  // Válido (+1)
    { tipo: 'SAIDA',   quantidade: 2,  timestamp: doisMinAtras }   // Válido (-2)
  ]
};

const stats = calculate15MinRollingStats(restHistoricoMock);
valor = assert.strictEqual(stats.entradas_15min, 6, 'Total de entradas válidas deve ser 6');
valor = assert.strictEqual(stats.saidas_15min, 2, 'Total de saídas válidas deve ser 2');
valor = assert.strictEqual(stats.saldo_fluxo_15min, 4, 'Saldo deve ser 6 - 2 = 4');
console.log("  ✔ Cálculo da Janela Móvel de 15 Minutos: PASSOU");

// ----------------------------------------------------
// TESTE 4: CADASTRO DE CONTAS / RESTAURANTES
// ----------------------------------------------------
console.log("\n[4] Testando Cadastro de Novas Contas...");

// 4.1 Cadastro com sucesso
const resCad1 = cadastrarRestaurante({
  id: 'rest_filial_02',
  nome: 'V.E.R Filial Shopping',
  senha: 'senha_filial_123'
});
assert.strictEqual(resCad1.sucesso, true, 'Deve cadastrar restaurante com sucesso');
assert.strictEqual(resCad1.restaurante.id, 'rest_filial_02', 'ID retornado deve coincidir');
assert(memoryStore.restaurantes['rest_filial_02'] !== undefined, 'Restaurante deve constar no memoryStore');
assert(memoryStore.restaurantes['rest_filial_02'].dias_semana.segunda !== undefined, 'Grade semanal padrão deve estar preenchida');
console.log("  ✔ Cadastro de nova conta com grade padrão: PASSOU");

// 4.2 Rejeição de ID duplicado
const resCadDuplicado = cadastrarRestaurante({
  id: 'rest_filial_02',
  nome: 'Outra Filial com Mesmo ID',
  senha: '123'
});
assert.strictEqual(resCadDuplicado.sucesso, false, 'Deve rejeitar cadastro com ID já existente');
console.log("  ✔ Rejeição de ID duplicado: PASSOU");

// 4.3 Rejeição de campos obrigatórios vazios
const resCadSemNome = cadastrarRestaurante({ id: 'rest_novo', nome: '', senha: '123' });
assert.strictEqual(resCadSemNome.sucesso, false, 'Deve rejeitar cadastro sem nome');
const resCadSemSenha = cadastrarRestaurante({ id: 'rest_novo', nome: 'Novo', senha: '' });
assert.strictEqual(resCadSemSenha.sucesso, false, 'Deve rejeitar cadastro sem senha');
console.log("  ✔ Validações de campos obrigatórios: PASSOU");

// ----------------------------------------------------
// TESTE 5: ISOLAMENTO ENTRE RESTAURANTES CONECTADOS
// ----------------------------------------------------
console.log("\n[5] Testando Isolamento de Dados entre Restaurantes...");

// Inserir fluxo no rest_01
memoryStore.restaurantes['rest_01'].historico_movimentos = [
  { tipo: 'ENTRADA', quantidade: 15, timestamp: Date.now() }
];

// Inserir fluxo oposto no rest_filial_02
memoryStore.restaurantes['rest_filial_02'].historico_movimentos = [
  { tipo: 'SAIDA', quantidade: 10, timestamp: Date.now() }
];

const estadoRest01 = getEstadoCompleto('rest_01');
const estadoRest02 = getEstadoCompleto('rest_filial_02');

assert.strictEqual(estadoRest01.restaurante_id, 'rest_01');
assert.strictEqual(estadoRest01.saldo_fluxo_15min, 15, 'Saldo do rest_01 deve ser +15');
assert.strictEqual(estadoRest01.entradas_15min, 15, 'Entradas do rest_01 deve ser 15');
assert.strictEqual(estadoRest01.saidas_15min, 0, 'Saídas do rest_01 deve ser 0');

assert.strictEqual(estadoRest02.restaurante_id, 'rest_filial_02');
assert.strictEqual(estadoRest02.saldo_fluxo_15min, -10, 'Saldo do rest_filial_02 deve ser -10');
assert.strictEqual(estadoRest02.entradas_15min, 0, 'Entradas do rest_filial_02 deve ser 0');
assert.strictEqual(estadoRest02.saidas_15min, 10, 'Saídas do rest_filial_02 deve ser 10');

console.log("  ✔ Isolamento de métricas e histórico entre restaurantes: PASSOU");

console.log("\n====================================================");
console.log(" TODOS OS TESTES PASSARAM COM SUCESSO! (100% OK) ");
console.log("====================================================\n");
process.exit(0);
