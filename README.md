# نظمني - Nathemni Mobile App

Personal Organization & Productivity App built with Flutter.

## 📱 App Information

- **App Name:** نظمني (Nathemni)
- **Package ID:** com.skepteck.nathemni
- **Platforms:** Android & iOS
- **Backend:** Laravel API at https://nathemni.ly

## 🎨 Design System

### Colors

```dart
Primary Dark: #146084    // Main brand color
Primary Light: #6D99A0   // Secondary buttons, highlights
Accent: #F4B860          // CTA buttons, important actions
Success: #3FA796         // Completed states
Warning: #F2A65A         // Alerts, due-soon
Error: #D64545           // Errors, delete actions
```

### Typography

- **Font Family:** Cairo (via Google Fonts)
- **Weights:** 400 (Regular), 500 (Medium), 600 (SemiBold), 700 (Bold)
- **Default Language:** Arabic

## 📂 Project Structure

```
lib/
├── core/
│   ├── config/           # Environment & app configuration
│   │   └── env_config.dart
│   ├── constants/        # App constants
│   ├── theme/            # Theme configuration
│   │   └── app_theme.dart
│   ├── utils/            # Utility functions
│   └── widgets/          # Shared widgets
├── data/
│   ├── models/           # Data models
│   │   ├── api_response.dart
│   │   └── user.dart
│   ├── repositories/     # Data repositories
│   └── services/         # API services
│       └── api_client.dart
├── features/
│   ├── auth/             # Authentication feature
│   │   ├── data/
│   │   │   └── auth_service.dart
│   │   ├── presentation/
│   │   │   ├── pages/    # Auth screens
│   │   │   └── widgets/  # Auth widgets
│   │   └── providers/    # Auth state management
│   ├── tasks/            # Tasks module
│   ├── expenses/         # Expenses module
│   └── profile/          # Profile & Settings
└── l10n/                 # Internationalization
```

## ✅ What's Been Set Up

### 1. **Project Foundation**
- ✅ Flutter project initialized with org ID: `com.skepteck`
- ✅ Dependencies installed (Dio, Riverpod, GoRouter, etc.)
- ✅ Logo assets copied from parent directory
- ✅ Cairo font configured (via Google Fonts)

### 2. **Core Infrastructure**
- ✅ **Environment Config** (`lib/core/config/env_config.dart`)
  - Supports dev/staging/prod environments
  - Configurable API base URLs
- ✅ **Theme System** (`lib/core/theme/app_theme.dart`)
  - Complete light/dark theme
  - Your brand colors implemented
  - Cairo font integration
  - Material 3 components styled

### 3. **API Layer**
- ✅ **API Client** (`lib/data/services/api_client.dart`)
  - Dio-based HTTP client
  - Bearer token authentication
  - Secure token storage with flutter_secure_storage
  - Request/response logging (dev mode only)
  - Auto token injection in headers
  
- ✅ **Base Response Models** (`lib/data/models/api_response.dart`)
  - Matches Laravel backend structure
  - Supports paginated responses
  - Generic type support

- ✅ **User Model** (`lib/data/models/user.dart`)
  - Complete user model matching backend

### 4. **Authentication Service**
- ✅ **Auth Service** (`lib/features/auth/data/auth_service.dart`)
  - Register (with OTP)
  - Login (password)
  - Request Login OTP
  - Login with OTP
  - Verify OTP
  - Get current user
  - Update profile
  - Logout
  - Change password

## 🚧 What Needs to be Built (Remaining Tasks)

### Phase 1: Authentication UI
- [ ] Auth Providers (Riverpod state management)
- [ ] Login Screen
- [ ] Register Screen
- [ ] OTP Verification Screen
- [ ] Password/OTP toggle logic

### Phase 2: Navigation & App Shell
- [ ] GoRouter setup with auth guard
- [ ] Main scaffold with bottom navigation
- [ ] Drawer/menu (if needed)
- [ ] App-level error handling

### Phase 3: Tasks Module
- [ ] Task model
- [ ] Tasks service (API calls)
- [ ] Tasks list screen
- [ ] Add/Edit task screen
- [ ] Task completion logic
- [ ] Task providers

### Phase 4: Expenses Module
- [ ] Expense model
- [ ] Expenses service
- [ ] Expenses list screen
- [ ] Add expense screen
- [ ] Category selector
- [ ] Basic expense summary
- [ ] Expense providers

### Phase 5: Profile & Settings
- [ ] Profile screen
- [ ] Language switcher (AR/EN)
- [ ] App settings
- [ ] Logout functionality
- [ ] Change password screen

### Phase 6: Localization (i18n)
- [ ] ARB files for Arabic/English
- [ ] Translation keys
- [ ] Language persistence
- [ ] RTL/LTR layout switching

### Phase 7: Polish & Launch
- [ ] App icons (use flutter_launcher_icons)
- [ ] Splash screen
- [ ] Error handling & loading states
- [ ] Form validation
- [ ] Toast messages
- [ ] Pull-to-refresh
- [ ] Empty states
- [ ] Android/iOS specific configurations

## 🔧 Development Setup

### Prerequisites
- Flutter SDK 3.32.8 or higher
- Dart 3.8.1 or higher
- Android Studio / VS Code with Flutter extensions
- Physical device or emulator

### Installation

1. **Clone/Navigate to the project:**
   ```bash
   cd "C:\Users\omara\Documents\Workbench\Projects\nathemni\Mobile App"
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

### Build Configurations

**Development (default):**
```bash
flutter run
# Uses https://nathemni.ly/api/v1
```

**Production:**
```bash
flutter run --dart-define=ENV=prod
```

**Staging:**
```bash
flutter run --dart-define=ENV=staging
```

### Local Development API

To test with local backend on a physical device, update `env_config.dart`:

```dart
case 'dev':
  return 'http://YOUR_LOCAL_IP:8000/api/v1';  // e.g., 192.168.1.100
```

## 📡 API Integration

### Backend Structure
The Laravel backend at `https://nathemni.ly` uses:
- **Authentication:** Laravel Sanctum (Bearer tokens)
- **API Version:** v1
- **Response Format:**
  ```json
  {
    "success": true/false,
    "message": "...",
    "data": {...},
    "errors": {...}  // for validation errors
  }
  ```

### Available Endpoints

**Public:**
- `POST /v1/register` - Register new user
- `POST /v1/login` - Login with password
- `POST /v1/verify-otp` - Verify OTP
- `POST /v1/request-login-otp` - Request OTP for login
- `POST /v1/login-with-otp` - Login with OTP

**Protected (requires Bearer token):**
- `GET /v1/user` - Get current user
- `PUT /v1/profile` - Update profile
- `POST /v1/change-password` - Change password
- `POST /v1/logout` - Logout
- `GET /v1/tasks` - List tasks
- `POST /v1/tasks` - Create task
- `PUT /v1/tasks/{id}` - Update task
- `POST /v1/tasks/{id}/complete` - Complete task
- `GET /v1/expenses` - List expenses
- `POST /v1/expenses` - Create expense
- `GET /v1/categories` - List categories

## 🧪 Testing

```bash
flutter test
```

## 🏗️ Build for Release

### Android APK
```bash
flutter build apk --release --dart-define=ENV=prod
```

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release --dart-define=ENV=prod
```

### iOS (requires Mac)
```bash
flutter build ios --release --dart-define=ENV=prod
```

## 📦 Dependencies

- **State Management:** flutter_riverpod
- **Navigation:** go_router
- **HTTP Client:** dio + pretty_dio_logger
- **Secure Storage:** flutter_secure_storage
- **Local Storage:** shared_preferences
- **UI:** google_fonts, flutter_svg, cached_network_image, flutter_spinkit
- **Utils:** intl, equatable, fluttertoast

## 🔐 Security Notes

- Tokens stored securely using flutter_secure_storage
- No hardcoded secrets in code
- HTTPS enforced for production API
- Token auto-injected in requests via interceptor

## 📝 Notes

1. **Cairo Font:** Using Google Fonts package for automatic font loading. No manual font files needed.
2. **RTL Support:** Arabic is the default language, app layout supports RTL automatically.
3. **API Logging:** Enabled in dev mode only via pretty_dio_logger.
4. **Token Management:** Handled automatically by ApiClient interceptor.

## 🤝 Backend Repository

Backend Laravel API is located at: `../backend`

## 👨‍💻 Developer

- **Organization:** Skepteck (skepteck.com)
- **Package:** com.skepteck.nathemni
- **Backend:** Laravel API at nathemni.ly

---

**Status:** 🏗️ Foundation Complete - Ready for UI Development

**Next Steps:** Build authentication screens and wire up the auth flow with Riverpod providers.
