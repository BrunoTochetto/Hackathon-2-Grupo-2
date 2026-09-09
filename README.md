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

### 2. Instalação e Inicialização
No terminal, dentro da pasta do projeto (`C:\Users\maria\.gemini\antigravity\scratch\smartbuffet-stream`):

```bash
npm install
npm start
```

O servidor iniciará em:
👉 **`http://localhost:3000`**

### 3. Credenciais Padrão para Demonstração
- **ID do Restaurante:** `rest_01`
- **Senha:** `admin`

---

## 💻 Cenário de Teste Prático (Duas Abas)

Para experimentar o stream contínuo via WebSocket:

1. Abra uma aba no navegador em `http://localhost:3000`, selecione o perfil **Recepção** e faça login.
2. Abra uma segunda aba (ou janela anônima) em `http://localhost:3000`, selecione o perfil **Cozinha** e faça login.
3. Na **Recepção**, clique nos botões de fluxo (`+1 Cliente`, `+5 Clientes`, `-1 Cliente`, `-5 Clientes`).
4. Observe na tela da **Cozinha** a atualização imediata das cores, comando e estatísticas sem recarregar a página.

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
