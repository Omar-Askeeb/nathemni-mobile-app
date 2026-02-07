# Offline Tasks - Testing Guide

## ✅ Completed Features

### Phase 3: Offline Functionality - Tasks Module

#### Data Layer
- ✅ **TaskLocalModel** - SQLite model with serialization
- ✅ **TasksLocalDao** - Complete CRUD operations
- ✅ **TasksRepository** - Unified offline/online interface
- ✅ **Riverpod Providers** - State management

#### UI Layer
- ✅ **TasksScreen** - Main tasks list view
- ✅ **AddTaskScreen** - Create new tasks form
- ✅ **Empty State** - User-friendly empty state
- ✅ **Task Cards** - Display tasks with status, priority, due dates
- ✅ **Statistics** - Real-time task counts

## 📱 Testing Instructions

### 1. Launch the App
```bash
flutter run -d emulator-5554  # Android
# or
flutter run -d <device-id>    # iOS
```

### 2. Initial State
**Expected:**
- App shows "المهام" (Tasks) in the app bar
- Cloud offline icon in top right
- Empty state with:
  - Task icon
  - "لا توجد مهام" (No tasks)
  - "اضغط على + لإضافة مهمة جديدة" (Press + to add a new task)
- Floating action button (+) at bottom right

### 3. Create a Task
1. Tap the floating action button (+)
2. Fill in the form:
   - **Title:** (Required) e.g., "شراء المواد الغذائية"
   - **Description:** (Optional) e.g., "حليب، خبز، بيض"
   - **Priority:** Select from dropdown (منخفضة/متوسطة/عالية)
   - **Due Date:** Tap to select (optional)
   - **Due Time:** Tap to select (optional)
3. Tap "حفظ المهمة" (Save Task)

**Expected:**
- Success message: "تم إضافة المهمة بنجاح"
- Returns to tasks list
- Task appears in the list
- Shows "بانتظار المزامنة" (Awaiting sync) indicator

### 4. View Task List
**Expected:**
- Statistics cards at top:
  - الكل (All)
  - قيد التنفيذ (In Progress)
  - مكتملة (Completed)
- Tasks grouped by status:
  - قيد الانتظار (Pending)
  - قيد التنفيذ (In Progress)
  - مكتملة (Completed)
- Each task card shows:
  - Checkbox for completion
  - Title
  - Description (if set)
  - Due date (if set) with calendar icon
  - "متأخر" badge if overdue
  - Priority badge (color-coded)
  - Sync status indicator

### 5. Complete a Task
1. Tap the checkbox next to a task

**Expected:**
- Task moves to "Completed" section
- Title has strikethrough
- Text color changes to grey
- Statistics update immediately
- Sync status changes to "pending"

### 6. Task Actions Menu
1. Long press on any task

**Expected:**
- Bottom sheet opens with options:
  - تعيين كمكتملة (Mark as completed)
  - تعديل (Edit) - TODO
  - حذف (Delete) - red color

### 7. Delete a Task
1. Long press on a task
2. Tap "حذف" (Delete)
3. Confirm deletion in dialog

**Expected:**
- Confirmation dialog appears
- After confirming:
  - Task is removed from list (soft delete)
  - Statistics update
  - Sync status set to pending for sync

### 8. Offline Persistence Test
1. Create several tasks
2. Close the app completely
3. Reopen the app

**Expected:**
- All tasks persist and appear correctly
- No data loss
- SQLite database maintains state

## 🔍 Database Inspection

To verify data is stored correctly:

```bash
# Find the database file
adb shell run-as com.skepteck.nathemni ls databases/
# Expected: nathemni.db

# Pull the database
adb exec-out run-as com.skepteck.nathemni cat databases/nathemni.db > nathemni.db

# Inspect with SQLite browser
sqlite3 nathemni.db
.tables
SELECT * FROM tasks;
```

## 📊 Current Features

### ✅ Implemented
- [x] Create tasks offline
- [x] View all tasks
- [x] Complete tasks
- [x] Delete tasks (soft delete)
- [x] Task statistics
- [x] Priority levels (low/medium/high)
- [x] Due dates and times
- [x] Offline-first architecture
- [x] Sync status tracking
- [x] Search capability (backend ready)
- [x] Empty state UI
- [x] Arabic localization
- [x] Material Design 3 theme

### 🔜 Coming Next
- [ ] Edit existing tasks
- [ ] Task categories
- [ ] Recurring tasks
- [ ] Task sharing
- [ ] Backend sync (Phase 4)
- [ ] Conflict resolution
- [ ] Attachments
- [ ] Reminders/notifications

## 🐛 Known Limitations

1. **No Authentication Yet** - Using hardcoded userId=1
2. **No Edit Screen** - Can only create and delete
3. **No Sync** - Backend sync not implemented yet
4. **No Categories** - Category assignment not available
5. **No Search UI** - Backend ready but UI not built

## 📁 File Structure

```
lib/
├── features/
│   └── tasks/
│       ├── data/
│       │   ├── task_local_model.dart     # SQLite model
│       │   ├── tasks_local_dao.dart      # Database operations
│       │   └── tasks_repository.dart     # Offline/online abstraction
│       ├── providers/
│       │   └── tasks_providers.dart      # Riverpod state management
│       └── presentation/
│           ├── tasks_screen.dart         # Main list view
│           └── add_task_screen.dart      # Create task form
├── data/
│   └── local/
│       └── database_helper.dart          # SQLite initialization
└── main.dart
```

## 🎯 Next Steps

1. **Phase 3 Continuation:**
   - [ ] Add edit task functionality
   - [ ] Implement categories UI
   - [ ] Add search interface
   - [ ] Build task details screen
   - [ ] Add filters (today, overdue, by priority)

2. **Phase 4: Authentication**
   - [ ] Login/register screens
   - [ ] JWT token management
   - [ ] Secure storage
   - [ ] User profile

3. **Phase 5: Sync Implementation**
   - [ ] Upload pending tasks to backend
   - [ ] Download server tasks
   - [ ] Conflict resolution UI
   - [ ] Sync status indicators

## 🏆 Success Criteria

Phase 3 (Offline Tasks) is considered **COMPLETE** when:
- ✅ Users can create tasks without internet
- ✅ Tasks persist across app restarts
- ✅ Users can view, complete, and delete tasks
- ✅ UI is responsive and follows Material Design
- ✅ Arabic localization is properly implemented
- ✅ Sync status is tracked for future sync
- 🔜 Users can edit existing tasks (next priority)
