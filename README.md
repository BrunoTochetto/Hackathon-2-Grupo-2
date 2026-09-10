# V.E.R (Visão Estratégica de Recursos) 🍽️⚡

Sistema em tempo real com arquitetura orientada a eventos para gerenciamento contínuo da taxa de produção em serviços de refeição e buffets.

O sistema opera **sem necessidade de cadastrar alimentos individuais**, orientando a equipe por meio de comandos visuais e sonoros de alto impacto:
- **AUMENTAR PRODUÇÃO** (🟢 Fundo Verde)
- **ESTAGNAÇÃO / MANTER** (🟡 Fundo Âmbar)
- **BAIXA DE PRODUÇÃO** (🔴 Fundo Vermelho)

---

## 🚀 Como Executar

### 1. Pré-requisitos
- Node.js instalado (v18+ ou v20 LTS).

```bash
npm install
npm start
```

O servidor iniciará em:
👉 **`http://localhost:3000`**

### 3. Credenciais Padrão & Cadastro de Novas Contas
- **Conta Matriz Inicial:** ID `rest_01` / Senha `admin`
- **Cadastro de Novas Contas:** Na tela inicial, clique na aba **"➕ Criar Conta"**, informe um ID único (ex: `filial_centro`), o Nome do Estabelecimento e a Senha.
- As contas criadas recebem automaticamente a grade de horários padrão e operam com canais WebSocket e históricos 100% isolados.

---

## 💻 Cenário de Teste Prático (Múltiplas Contas & Abas)

Para experimentar o stream contínuo e o isolamento entre múltiplos restaurantes:

1. **Conta 1 (Matriz):**
   - Em uma aba em `http://localhost:3000`, faça login no `rest_01` como **Recepção**.
   - Em outra aba, faça login no `rest_01` como **Cozinha**.
2. **Conta 2 (Nova Filial):**
   - Clique em **"➕ Criar Conta"** e cadastre um novo restaurante (ex: ID `filial_sul`, Nome `V.E.R Filial Sul`, Senha `123`).
   - Abra duas novas abas para a `filial_sul` (uma como **Recepção** e outra como **Cozinha**).
3. **Validação de Isolamento em Tempo Real:**
   - Lance clientes na **Recepção** da `filial_sul`.
   - Observe que **apenas a tela da Cozinha da `filial_sul` reage**, enquanto a Matriz (`rest_01`) permanece inalterada.

---

## 🧠 Regras de Negócio e Matriz de Decisão

O motor de decisão do backend processa a cada evento de fluxo e a cada tick de relógio:
1. **Identifica o Dia da Semana e Hora Atual** (ou hora simulada).
2. **Determina a Faixa**: `PICO`, `BAIXA` ou `NORMAL` de acordo com a tabela do restaurante.
3. **Calcula a Janela Móvel dos Últimos 15 Minutos**:
   - `Entradas_15min`
   - `Saidas_15min`
   - `Saldo_Fluxo = Entradas_15min - Saidas_15min`
4. **Aplica a Matriz de Decisão**:

| Tipo de Horário | Condição do Saldo (15 min) | Estado de Produção Resultante | Cor de Exibição |
| :--- | :--- | :--- | :--- |
| **PICO** | `Saldo_Fluxo >= 0` | **AUMENTAR PRODUÇÃO** | 🟢 Fundo Verde |
| **PICO** | `Saldo_Fluxo < 0` | **ESTAGNAÇÃO (MANTER)** | 🟡 Fundo Amarelo |
| **NORMAL** | `Saldo_Fluxo > 5` | **AUMENTAR PRODUÇÃO** | 🟢 Fundo Verde |
| **NORMAL** | `-5 <= Saldo_Fluxo <= 5` | **ESTAGNAÇÃO (MANTER)** | 🟡 Fundo Amarelo |
| **NORMAL** | `Saldo_Fluxo < -5` | **BAIXA DE PRODUÇÃO** | 🔴 Fundo Vermelho |
| **BAIXA** | Qualquer saldo | **BAIXA DE PRODUÇÃO** | 🔴 Fundo Vermelho |

---

## 📦 Estrutura do Projeto

```
smartbuffet-stream/
├── package.json              # Metadados e dependências (express, socket.io)
├── server.js                 # Backend Node.js, Express, Socket.io, In-Memory Store e Motor de Decisão
├── public/
│   ├── index.html            # Interface Web (Login, Painel Recepção e Display Cozinha)
│   ├── styles.css            # Estilização responsiva com sinalização visual de alto contraste
│   └── app.js                # Lógica WebSocket reativa, manipulador de DOM e sintetizador sonoro
├── test/
│   └── test_engine.js        # Testes automatizados da matriz de decisão e janela móvel
└── README.md                 # Documentação e instruções de execução
```

---

## 🧪 Testes Automatizados

Para executar os testes unitários do motor de regras:

```bash
npm test
```
