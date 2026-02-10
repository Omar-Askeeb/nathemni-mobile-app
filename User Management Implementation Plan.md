# User Management Implementation Plan
## Overview
Add complete user management with registration, login, profile management, and persistent sessions to the Nathemni app.
## Current State
* `AuthService` exists with basic login/register API methods
* `User` model exists but lacks: `name_ar`, `name_en`, `username`, `profile_image`
* SQLite `users` table has basic schema, needs additional fields
* Auth/Profile feature folders exist but screens are empty/placeholder
* `ApiClient` handles token storage via `flutter_secure_storage`
## Requirements Summary
* **Registration fields**: name_ar, name_en, username (nickname), phone, email, password
* **Login**: via phone OR email + password
* **Profile**: view/edit data, upload profile image
* **Flow**: first launch → registration → login → home; stay logged in until logout
## Implementation Plan
### Phase 1: Data Layer Updates
**1.1 Update User Model** (`lib/data/models/user.dart`)
* Add fields: `nameAr`, `nameEn`, `username`, `profileImage`
* Update `fromJson`, `toJson`, `copyWith`, `props`
**1.2 Update Database Schema** (`lib/data/local/database_helper.dart`)
* Add columns to `users` table: `name_ar`, `name_en`, `username`, `profile_image`
* Bump DB version to 16 with migration
**1.3 Create Local User Repository** (`lib/data/repositories/user_repository.dart`)
* CRUD operations for local user storage
* Methods: `saveUser`, `getUser`, `updateUser`, `deleteUser`, `hasUser`
### Phase 2: Auth Service Updates
**2.1 Update AuthService** (`lib/features/auth/data/auth_service.dart`)
* Update `register()` to include all new fields
* Update `updateProfile()` to handle all fields
* Add `uploadProfileImage()` method
* Add `isLoggedIn()` check method
### Phase 3: State Management (Riverpod)
**3.1 Create Auth Providers** (`lib/features/auth/providers/auth_provider.dart`)
* `authStateProvider`: AsyncNotifier for auth state (authenticated/unauthenticated/loading)
* `currentUserProvider`: holds current user data
* `authServiceProvider`: provides AuthService instance
**3.2 Create Auth State** (`lib/features/auth/providers/auth_state.dart`)
* Define auth states: initial, authenticated, unauthenticated, loading, error
### Phase 4: Auth UI Screens
**4.1 Registration Screen** (`lib/features/auth/presentation/pages/register_screen.dart`)
* Form fields: name_ar, name_en, username, phone, email, password, confirm_password
* Validation for all fields
* Navigate to login on success
**4.2 Login Screen** (`lib/features/auth/presentation/pages/login_screen.dart`)
* Form fields: identifier (phone or email), password
* "Forgot password" link
* Navigate to home on success
**4.3 Shared Widgets** (`lib/features/auth/presentation/widgets/`)
* `auth_text_field.dart`: styled input field
* `auth_button.dart`: styled primary button
* `phone_input_field.dart`: phone with country code
### Phase 5: Profile Management
**5.1 Profile Screen** (`lib/features/profile/presentation/pages/profile_screen.dart`)
* Display user info with profile image
* Edit button → navigate to edit screen
* Logout button
**5.2 Edit Profile Screen** (`lib/features/profile/presentation/pages/edit_profile_screen.dart`)
* Edit all user fields (name_ar, name_en, username, phone, email)
* Profile image picker (camera/gallery)
**5.3 Profile Provider** (`lib/features/profile/providers/profile_provider.dart`)
* Handle profile updates
* Handle image upload
### Phase 6: Navigation & App Flow
**6.1 Update App Routes** (`lib/core/navigation/app_routes.dart`)
* Add routes: `/register`, `/login`
* Replace profile placeholder with actual screen
**6.2 Create Auth Wrapper** (`lib/core/widgets/auth_wrapper.dart`)
* Check auth state on app start
* Redirect to register/login if not authenticated
* Show loading while checking
**6.3 Update main.dart**
* Wrap app with auth state check
* Initial route based on auth status
### Phase 7: Testing & Polish
* Test registration flow
* Test login flow (phone & email)
* Test persistent session
* Test profile update & image upload
* Test logout
* Handle edge cases and errors
## File Structure After Implementation
```warp-runnable-command
lib/features/auth/
├── data/
│   └── auth_service.dart (updated)
├── presentation/
│   ├── pages/
│   │   ├── register_screen.dart (new)
│   │   └── login_screen.dart (new)
│   └── widgets/
│       ├── auth_text_field.dart (new)
│       ├── auth_button.dart (new)
│       └── phone_input_field.dart (new)
└── providers/
    ├── auth_provider.dart (new)
    └── auth_state.dart (new)
lib/features/profile/
├── presentation/
│   ├── pages/
│   │   ├── profile_screen.dart (new)
│   │   └── edit_profile_screen.dart (new)
│   └── widgets/
│       └── profile_image_picker.dart (new)
└── providers/
    └── profile_provider.dart (new)
lib/data/
├── models/
│   └── user.dart (updated)
└── repositories/
    └── user_repository.dart (new)
```
