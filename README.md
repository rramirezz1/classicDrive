# 🚗 Classic Drive

**Marketplace de Aluguer de Carros Clássicos**

Uma aplicação Flutter completa para aluguer de carros clássicos entre particulares.

---

## 🚀 Quick Start

### Pré-requisitos

- Flutter SDK (>= 3.0.0)
- Dart SDK (>= 3.0.0)
- Conta Supabase (para backend)
- Editor: VS Code ou Android Studio

### Instalação

```bash
# 1. Clonar ou navegar para o projeto
cd classic_drive

# 2. Instalar dependências
flutter pub get

# 3. Configurar variáveis de ambiente
# Editar o ficheiro .env com as credenciais Supabase

# 4. Executar a aplicação
flutter run
```

---

## 📱 Comandos de Terminal

### Desenvolvimento

```bash
# Executar em modo debug
flutter run

# Executar num dispositivo específico
flutter run -d chrome          # Web
flutter run -d windows         # Windows
flutter run -d <device_id>     # Dispositivo específico

# Hot reload (enquanto a app corre)
r                              # Reload
R                              # Restart
q                              # Sair
```

### Análise e Testes

```bash
# Analisar código
flutter analyze

# Executar testes
flutter test

# Verificar formatação
dart format lib/
```

### Build e Produção

```bash
# Build APK (Android)
flutter build apk --release

# Build App Bundle (Android - Play Store)
flutter build appbundle --release

# Build iOS
flutter build ios --release

# Build Web
flutter build web --release

# Build Windows
flutter build windows --release
```

### Limpeza

```bash
# Limpar cache e builds
flutter clean

# Atualizar dependências
flutter pub upgrade

# Corrigir problemas de dependências
flutter pub cache repair
```

---

## 📂 Estrutura do Projeto

```
lib/
├── main.dart              # Entry point
├── l10n/                  # Internacionalização
├── models/                # Modelos de dados
│   ├── vehicle_model.dart
│   ├── booking_model.dart
│   ├── user_model.dart
│   └── ...
├── providers/             # State management
├── screens/               # Ecrãs da aplicação
│   ├── auth/              # Login, registo
│   ├── home/              # Home screen
│   ├── vehicles/          # Listagem, detalhes
│   ├── booking/           # Reservas
│   ├── chat/              # Chat
│   ├── profile/           # Perfil
│   ├── owner/             # Dashboard proprietário
│   └── admin/             # Painel admin
├── services/              # Lógica de negócio
│   ├── auth_service.dart
│   ├── database_service.dart
│   ├── chat_service.dart
│   └── ...
├── theme/                 # Tema e estilos
│   ├── app_colors.dart
│   ├── app_shadows.dart
│   └── app_theme.dart
├── utils/                 # Utilitários
└── widgets/               # Componentes reutilizáveis
    ├── widgets.dart       # Export central
    └── ...                # 40+ widgets
```

---

## ✨ Features

### Core
- 🔐 Autenticação (email, social)
- 🚗 Listagem de veículos clássicos
- 🔍 Pesquisa avançada com filtros
- 📅 Sistema de reservas
- 💳 Pagamentos (Stripe)
- 🛡️ Seguros

### Social
- 💬 Chat em tempo real
- ⭐ Sistema de avaliações
- 📤 Partilha de veículos

### Engagement
- 🏆 Programa de fidelidade
- 🎫 Códigos promocionais
- 📊 Analytics para proprietários

### Trust & Safety
- ✅ Verificação de utilizadores
- 📋 Verificação KYC
- 🔒 Badges de confiança

---

## 🗄️ Base de Dados (Supabase)

### Tabelas Principais

| Tabela | Descrição |
|--------|-----------|
| `users` | Utilizadores |
| `vehicles` | Veículos |
| `bookings` | Reservas |
| `conversations` | Conversas |
| `messages` | Mensagens |
| `reviews` | Avaliações |
| `user_loyalty` | Fidelidade |
| `promo_codes` | Códigos promo |
| `verifications` | KYC |

---

## 🎨 Design System

- **Cores**: Midnight Blue (#1a237e) + Gold (#d4af37)
- **Tipografia**: Poppins
- **Modo escuro**: Suportado
- **Widgets**: 130+ componentes personalizados

---

## 📋 Variáveis de Ambiente

Criar ficheiro `.env` na raiz:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
STRIPE_PUBLISHABLE_KEY=pk_test_...
```

---

## 🧪 Testes

```bash
# Executar todos os testes
flutter test

# Executar com coverage
flutter test --coverage

# Testes de integração
flutter test integration_test/
```

---

## 📦 Dependências Principais

| Package | Uso |
|---------|-----|
| `supabase_flutter` | Backend |
| `provider` | State management |
| `go_router` | Navegação |
| `flutter_stripe` | Pagamentos |
| `cached_network_image` | Cache de imagens |
| `intl` | Formatação |

---

## 👥 Contribuição

1. Fork o projeto
2. Cria uma branch (`git checkout -b feature/nova-feature`)
3. Commit as mudanças (`git commit -m 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abre um Pull Request

---

## 📝 Licença

Este projeto é privado e destinado a uso académico/pessoal.

---

## 📞 Suporte

Para questões ou suporte, contactar o desenvolvedor.
