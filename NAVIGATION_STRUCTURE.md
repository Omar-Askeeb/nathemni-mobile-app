# Navigation Structure - Nathemni App

## 📱 Overview

The Nathemni app now has a complete navigation structure with:
- **Home Dashboard** - Central hub with quick access
- **Drawer Menu** - Comprehensive navigation to all modules
- **Placeholder Screens** - For modules under development
- **Named Routes** - Clean navigation architecture

---

## 🏠 Home Screen

**Route:** `/` (AppRoutes.home)

**Features:**
- Welcome header with app logo
- Quick access grid (6 main modules)
- Features showcase section
- Drawer menu access
- Notifications button

**Quick Access Cards:**
1. المهام (Tasks) - Blue
2. المصاريف (Expenses) - Green
3. الوجبات (Meals) - Orange
4. المعدات (Equipment) - Purple
5. الأشخاص (People) - Teal
6. المشاريع (Projects) - Indigo

---

## 🗂️ Drawer Menu Structure

### Core Modules

#### 1. المهام والتنظيم اليومي (Tasks & Daily Organization)
- **Route:** `/tasks`
- **Status:** ✅ **Implemented**
- **Icon:** task_alt
- **Features:**
  - Create, view, complete, delete tasks
  - Priority levels (low, medium, high)
  - Due dates and times
  - Task statistics
  - Offline-first with sync tracking

---

### Meal Management

#### 2. إدارة الوجبات (Meals Management)
- **Route:** `/meals`
- **Status:** 🔜 **Coming Soon**
- **Icon:** restaurant_menu
- **Color:** Orange

---

### Financial Management Section

#### 3. تتبع المصاريف (Expense Tracking)
- **Route:** `/expenses`
- **Status:** 🔜 **Coming Soon**
- **Icon:** payments
- **Color:** Green

#### 4. الالتزامات والديون (Commitments & Debts)
- **Route:** `/commitments`
- **Status:** 🔜 **Coming Soon**
- **Icon:** account_balance_wallet
- **Color:** Red

#### 5. إدارة الحسابات المصرفية (Bank Accounts)
- **Route:** `/bank-accounts`
- **Status:** 🔜 **Coming Soon**
- **Icon:** account_balance
- **Color:** Blue

---

### Projects

#### 6. إدارة المشاريع (Projects Management)
- **Route:** `/projects`
- **Status:** 🔜 **Coming Soon**
- **Icon:** business_center
- **Color:** Indigo

---

### Other Management Modules

#### 7. إدارة بطاقات الهاتف (Phone Cards)
- **Route:** `/phone-cards`
- **Status:** 🔜 **Coming Soon**
- **Icon:** phone_android
- **Color:** Teal

#### 8. إدارة السيارات (Vehicles)
- **Route:** `/vehicles`
- **Status:** 🔜 **Coming Soon**
- **Icon:** directions_car
- **Color:** Deep Orange

#### 9. إدارة المعدات والأدوات (Equipment & Tools)
- **Route:** `/equipment`
- **Status:** 🔜 **Coming Soon**
- **Icon:** build
- **Color:** Purple

#### 10. إدارة الأشخاص (People Management)
- **Route:** `/people`
- **Status:** 🔜 **Coming Soon**
- **Icon:** people
- **Color:** Cyan

---

### Tools Section

#### 11. البيانات الشخصية (Personal Data)
- **Route:** `/profile`
- **Status:** 🔜 **Coming Soon**
- **Icon:** person
- **Color:** Blue Grey

#### 12. الباركود و QR Code (Barcode & QR Code)
- **Route:** `/barcode`
- **Status:** 🔜 **Coming Soon**
- **Icon:** qr_code_scanner
- **Color:** Deep Purple

#### 13. الإشعارات والسجلات (Notifications & Logs)
- **Route:** `/notifications`
- **Status:** 🔜 **Coming Soon**
- **Icon:** notifications
- **Color:** Amber

---

### Settings Section

#### 14. الأوضاع (Offline / Online Modes)
- **Route:** `/sync-mode`
- **Status:** 🔜 **Coming Soon**
- **Icon:** cloud_sync
- **Color:** Light Blue

#### 15. الدعم الفني (Technical Support)
- **Route:** `/support`
- **Status:** 🔜 **Coming Soon**
- **Icon:** support_agent
- **Color:** Green

#### 16. إدارة حساب المستخدم (User Account)
- **Route:** `/account`
- **Status:** 🔜 **Coming Soon**
- **Icon:** account_circle
- **Color:** Blue

#### 17. عن التطبيق (About)
- **Route:** `/about`
- **Status:** 🔜 **Coming Soon**
- **Icon:** info
- **Color:** Grey
- **Description:** App version and credits

---

## 📂 File Structure

```
lib/
├── core/
│   ├── navigation/
│   │   ├── app_drawer.dart          # Main drawer menu
│   │   └── app_routes.dart          # Routes configuration
│   ├── widgets/
│   │   └── placeholder_screen.dart  # Reusable placeholder
│   └── theme/
│       └── app_theme.dart
├── features/
│   ├── home/
│   │   └── home_screen.dart         # Dashboard
│   └── tasks/
│       ├── data/
│       ├── providers/
│       └── presentation/
└── main.dart
```

---

## 🎨 Design System

### Drawer Header
- **Background:** Gradient (primary color)
- **Content:** 
  - App logo in circular avatar
  - App name "نظمني"
  - Tagline "تطبيقك الشخصي للتنظيم"

### Menu Items
- **Leading:** Colored icon (module-specific)
- **Title:** Module name in Arabic
- **Trailing:** Chevron right arrow
- **Dividers:** Between major sections
- **Section Headers:** Small, uppercase, primary color

### Quick Access Cards
- **Layout:** 2-column grid
- **Design:** Circular icon with background, title
- **Interaction:** Tap to navigate
- **Colors:** Module-specific

---

## 🔄 Navigation Flow

### From Home
```
Home → Drawer → Select Module → Module Screen
Home → Quick Access Card → Module Screen
```

### From Any Module
```
Module → Drawer → Select Another Module
Module → Back Button → Previous Screen
```

### Navigation Methods
1. **Drawer Menu** - Available on all screens
2. **Quick Access Cards** - Home screen only
3. **Named Routes** - Navigator.pushNamed()
4. **Back Button** - Navigator.pop()

---

## 🚀 Implementation Status

### ✅ Completed
- [x] Home dashboard screen
- [x] Drawer menu (all 17 modules)
- [x] Routes configuration
- [x] Placeholder screen template
- [x] Tasks module (fully functional)
- [x] Navigation integration
- [x] Arabic localization

### 🔜 Next Priorities
1. **Expenses Module** - Similar to tasks
2. **Equipment Module** - Inventory management
3. **People Module** - Contacts and commitments
4. **Authentication** - Login/register
5. **Sync System** - Backend integration

---

## 💡 Usage Examples

### Navigate to a Module
```dart
Navigator.pushNamed(context, AppRoutes.tasks);
Navigator.pushNamed(context, '/expenses');
```

### Add New Route
1. Add constant in `app_routes.dart`
2. Add route in `getRoutes()` method
3. Create screen or use `PlaceholderScreen`
4. Add to drawer menu if needed

### Create New Module
```dart
// Use placeholder temporarily
'/new-module': (context) => const PlaceholderScreen(
  title: 'Module Name',
  icon: Icons.icon_name,
  color: Colors.color,
),
```

---

## 📱 Testing Checklist

- [x] Home screen displays correctly
- [x] Drawer opens from home
- [x] All menu items navigate correctly
- [x] Quick access cards work
- [x] Back navigation works
- [x] Drawer available on all screens
- [x] Placeholder screens show proper content
- [x] Tasks module accessible and functional
- [x] Arabic text displays correctly
- [x] Icons and colors match design

---

## 🎯 Development Workflow

### Working on a New Module:
1. Module starts as `PlaceholderScreen`
2. Users can navigate and see "Coming Soon"
3. Develop module features incrementally
4. Replace placeholder with actual screen when ready
5. Update status in documentation

### Benefits:
- ✅ Complete navigation structure from day one
- ✅ Users can explore the app
- ✅ Clear development roadmap
- ✅ Easy to work on modules independently
- ✅ Professional appearance

---

## 📊 Module Priority Order

Based on backend database and features:

1. ✅ **Tasks** - Completed
2. **Expenses** - High priority (financial tracking)
3. **Equipment** - High priority (lending/borrowing)
4. **People** - Medium priority (contacts/commitments)
5. **Commitments** - Medium priority (debts tracking)
6. **Projects** - Medium priority
7. **Meals** - Medium priority
8. **Others** - Lower priority

---

**Note:** All modules are accessible via navigation, but only Tasks is fully implemented. Others show a professional "Coming Soon" screen.
