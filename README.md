# SmartBuffet — Equipe V.E.R. (Visão Estratégica de Recursos)

> **"Produza o necessário. Desperdice menos."**

O **SmartBuffet** é uma solução inteligente desenvolvida para **restaurantes** e **escolas**, criada com o objetivo de sincronizar a produção de alimentos com o movimento real de clientes e alunos, eliminando a superprodução e o desperdício de alimentos.

---

## 👥 Identidade do Projeto

* **Equipe:** V.E.R. — Visão Estratégica de Recursos
* **Produto:** SmartBuffet
* **Público-alvo:** Restaurantes (buffet self-service, à la carte) e Escolas (refeitórios escolares, merenda)
* **Objetivo:** Prevenir a perda de alimentos através do monitoramento preditivo e do cálculo determinístico de fornadas e lotes em tempo real.

---

## 🛠️ Tecnologias Utilizadas

* **Linguagem & Framework:** Flutter 3.x + Dart (Null Safety habilitado)
* **Gerenciamento de Estado:** Provider (Reativo em tempo real via Streams)
* **Autenticação:** Firebase Authentication
* **Banco de Dados:** Cloud Firestore (Arquitetura multi-tenant por estabelecimento)
* **Backend Server-Side:** Cloud Functions for Firebase (Node.js)
* **Gráficos & Visualizações:** CustomPainter otimizado para web, mobile e tablet
* **Testes:** Flutter Test (Cobertura completa de cenários de recomendação)

---

## 📁 Estrutura do Projeto

```text
ver/
├── lib/
│   ├── main.dart                      # Ponto de entrada do aplicativo
│   ├── app/
│   │   ├── app.dart                   # Configuração de tema e Providers
│   │   ├── routes.dart                # Rotas nomeadas e Guards de autenticação
│   │   └── theme.dart                 # Design System V.E.R. (Verde floresta, Bege suave, Tipografia)
│   ├── models/
│   │   ├── user_model.dart            # Modelo de usuário
│   │   ├── establishment_model.dart   # Estabelecimento (Restaurante ou Escola)
│   │   ├── food_model.dart            # Ficha técnica, custo, lote e gramatura por pessoa
│   │   ├── movement_model.dart        # Registros de contagem de fluxo com timestamp
│   │   ├── production_model.dart      # Registros de fornadas produzidas
│   │   ├── recommendation_model.dart  # Ações calculadas (Normal, Reduzir, Aumentar, etc.)
│   │   ├── history_model.dart         # Histórico consolidado por data
│   │   └── waste_model.dart           # Registro de descartes e motivos
│   ├── services/
│   │   ├── auth_service.dart          # Camada de autenticação com persistência de sessão
│   │   ├── firestore_service.dart     # Persistência com Streams reativos e fallback offline
│   │   └── recommendation_service.dart # Motor determinístico de regras de produção
│   ├── state/
│   │   ├── auth_provider.dart         # Estado reativo da sessão
│   │   └── buffet_provider.dart       # Estado global, movimentação, cálculo e modo demo
│   ├── screens/
│   │   ├── landing/landing_screen.dart           # Página institucional do SmartBuffet
│   │   ├── auth/                                 # Login, Cadastro (Restaurante/Escola) e Recuperação
│   │   ├── dashboard/                            # Dashboards adaptativos (Restaurante vs Escola)
│   │   ├── movement/movement_screen.dart         # Registro rápido (+1, +5, +10, -1) e gráfico
│   │   ├── production/production_screen.dart     # Gestão de estoque e registro de lotes
│   │   ├── menu/menu_screen.dart                 # CRUD completo de alimentos
│   │   ├── kitchen/kitchen_screen.dart           # Visão de alto contraste para Cozinha/Tablets
│   │   ├── history/history_screen.dart           # Histórico com filtros (Hoje, 7 dias, 30 dias)
│   │   ├── waste/waste_screen.dart               # Métricas de desperdício evitado e economia
│   │   ├── demo/demo_screen.dart                 # Modo Demonstração interativo do pitch
│   │   ├── settings/settings_screen.dart         # Configuração de horários, tipo e metas
│   │   └── about/about_screen.dart               # Sobre a equipe V.E.R.
│   └── widgets/                                  # Componentes modulares e reutilizáveis
├── test/
│   ├── recommendation_service_test.dart          # 10 cenários de testes do motor de decisão
│   └── widget_test.dart                          # Testes de inicialização da interface
├── firestore.rules                               # Regras de segurança multi-tenant
├── functions/                                    # Cloud Functions (triggers e cron jobs)
│   ├── package.json
│   └── index.js
└── README.md
```

---

## ⚡ Como Instalar e Executar

### 1. Pré-requisitos
* Ter o Flutter SDK instalado (versão 3.10 ou superior).
* Caso o executável `flutter` não esteja adicionado ao seu `PATH`, você pode referenciá-lo diretamente pelo caminho (exemplo no Windows: `C:\Users\kauan\Downloads\flutter\bin\flutter.bat`).

### 2. Instalar Dependências
No terminal, dentro da pasta `ver`:
```bash
flutter pub get
```

### 3. Executar em Flutter Web
```bash
flutter run -d chrome
```

### 4. Executar em Android
Conecte um dispositivo com depuração USB ou inicie um emulador:
```bash
flutter run -d android
```

### 5. Executar em Desktop (Windows / macOS / Linux)
```bash
flutter run -d windows
```

---

## 🧪 Como Executar os Testes Automatizados

O sistema conta com testes unitários cobrindo rigorosamente todos os 10 cenários requeridos pelo motor de recomendação:
1. Movimento abaixo da previsão $\rightarrow$ Reduzir produção.
2. Movimento próximo da previsão $\rightarrow$ Produção normal.
3. Movimento acima da previsão $\rightarrow$ Aumentar produção.
4. Pouco tempo restante $\rightarrow$ Produção mínima.
5. Estoque suficiente $\rightarrow$ Não iniciar novo lote.
6. Estoque crítico com consumo ativo $\rightarrow$ Prioridade alta de reposição.
7. Movimento alto + estoque baixo $\rightarrow$ Aumento emergencial de produção.
8. Movimento baixo + estoque suficiente $\rightarrow$ Trava de lote para evitar sobras.
9. Identificação de déficit para novos lotes.
10. Pouco tempo restante com estoque suficiente $\rightarrow$ Bloqueio de desperdício.

Para executar todos os testes:
```bash
flutter test
```

---

## 🔥 Configuração do Firebase

O aplicativo possui uma camada de serviço desacoplada (`FirestoreService` e `AuthService`), já operando de forma 100% autônoma com persistência em tempo real e modo offline/demonstração.

Para conectar ao seu próprio projeto no Firebase Console:

### 1. Criar o Projeto no Firebase Console
1. Acesse [Firebase Console](https://console.firebase.google.com/) e clique em **Adicionar projeto**.
2. Nomeie o projeto (ex: `smartbuffet-ver`).

### 2. Configurar Firebase Authentication
1. No menu lateral, acesse **Authentication** > **Métodos de login**.
2. Ative o provedor **E-mail/senha**.

### 3. Configurar Cloud Firestore
1. No menu lateral, acesse **Firestore Database** > **Criar banco de dados**.
2. Selecione o modo de produção.
3. Aplique as regras de segurança contidas no arquivo `ver/firestore.rules`:
```bash
firebase deploy --only firestore:rules
```

### 4. Configurar Cloud Functions
1. Na pasta `ver/functions`:
```bash
cd functions
npm install
firebase deploy --only functions
```

### 5. Configurar o FlutterFire CLI (Android e Web)
Instale o CLI do FlutterFire e configure os arquivos `google-services.json` (Android) ou `firebase_options.dart` (Web):
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

---

## 🎯 Modo Demonstração (Pitch do Hackathon)

O SmartBuffet inclui um painel de **Modo Demonstração** acessível diretamente pelo menu lateral ou pela tela de início:
* **Cenário 1:** Previsão 400 pessoas, Movimento 350 $\rightarrow$ Situação "Normal".
* **Cenário 2:** Movimento 250 $\rightarrow$ "Movimento abaixo do previsto" / Recomendação: "Reduzir produção".
* **Cenário 3:** Movimento 150 + 15 minutos restantes $\rightarrow$ "Pouco movimento e pouco tempo restante" / Recomendação: "Não iniciar novo lote".
* **Cenário 4:** Movimento 380 $\rightarrow$ "Movimento acima do previsto" / Recomendação: "Aumentar produção".

*Obs:* O Modo Demonstração opera em camada isolada na memória, garantindo que os jurados possam interagir livremente sem alterar o banco de dados de produção do estabelecimento!

---

## 📦 Gerar Build de Produção

### Para Web:
```bash
flutter build web --release
```
Os arquivos prontos para hospedagem serão gerados em `build/web`.

### Para Android (APK):
```bash
flutter build apk --release
```
O arquivo `.apk` será gerado em `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🌿 Sobre a Equipe V.E.R.

A **V.E.R. — Visão Estratégica de Recursos** é uma equipe focada no desenvolvimento de soluções tecnológicas para a administração eficiente, inteligente e sustentável de recursos escassos.
