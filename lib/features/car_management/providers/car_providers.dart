import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/notification_service.dart';
import '../../expenses/data/expense_local_model.dart';
import '../../expenses/data/expenses_repository.dart';
import '../../expenses/providers/expenses_providers.dart';
import '../data/car_model.dart';
import '../data/car_repository.dart';
import '../data/oil_change_model.dart';
import '../data/car_document_model.dart';
import '../../../core/providers/common_providers.dart';

// Repository provider
final carRepositoryProvider = Provider<CarRepository>((ref) {
  return CarRepository();
});

// ========================================
// CARS
// ========================================

final carsProvider = FutureProvider.autoDispose<List<Car>>((ref) async {
  final repository = ref.watch(carRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return await repository.getAllCars(userId);
});

final selectedCarIdProvider = StateProvider<int?>((ref) => null);

final selectedCarProvider = FutureProvider.autoDispose<Car?>((ref) async {
  final carId = ref.watch(selectedCarIdProvider);
  if (carId == null) return null;
  
  final repository = ref.watch(carRepositoryProvider);
  return await repository.getCarById(carId);
});

// ========================================
// OIL CHANGES
// ========================================

final oilChangeHistoryProvider =
    FutureProvider.autoDispose.family<List<OilChange>, int>((ref, carId) async {
  final repository = ref.watch(carRepositoryProvider);
  return await repository.getOilChangeHistory(carId);
});

final latestOilChangeProvider =
    FutureProvider.autoDispose.family<OilChange?, int>((ref, carId) async {
  final repository = ref.watch(carRepositoryProvider);
  return await repository.getLatestOilChange(carId);
});

// ========================================
// CAR DOCUMENTS
// ========================================

final carDocumentsProvider =
    FutureProvider.autoDispose.family<List<CarDocument>, int>((ref, carId) async {
  final repository = ref.watch(carRepositoryProvider);
  return await repository.getCarDocuments(carId);
});

final expiringSoonDocumentsProvider =
    FutureProvider.autoDispose<List<CarDocument>>((ref) async {
  final repository = ref.watch(carRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return await repository.getExpiringSoonDocuments(userId);
});

// ========================================
// CAR MANAGEMENT NOTIFIER
// ========================================

class CarManagementNotifier extends StateNotifier<AsyncValue<void>> {
  final CarRepository _carRepository;
  final ExpensesRepository _expensesRepository;
  final NotificationService _notificationService;
  final int _userId;
  final Ref _ref;

  CarManagementNotifier(
    this._carRepository,
    this._expensesRepository,
    this._notificationService,
    this._userId,
    this._ref,
  ) : super(const AsyncValue.data(null));

  // ========================================
  // CAR OPERATIONS
  // ========================================

  Future<int> addCar(Car car) async {
    state = const AsyncValue.loading();
    try {
      final carId = await _carRepository.addCar(car);
      state = const AsyncValue.data(null);
      return carId;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateCar(Car car) async {
    state = const AsyncValue.loading();
    try {
      await _carRepository.updateCar(car);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteCar(int carId) async {
    state = const AsyncValue.loading();
    try {
      await _carRepository.deleteCar(carId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  // ========================================
  // OIL CHANGE OPERATIONS
  // ========================================

  Future<void> addOilChange({
    required OilChange oilChange,
    required String expenseCategoryId,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Add oil change record
      await _carRepository.addOilChange(oilChange);

      // Create linked expense
      final expense = ExpenseLocalModel(
        userId: _userId,
        categoryId: expenseCategoryId,
        amount: oilChange.cost,
        currency: oilChange.currency,
        paymentMethod: oilChange.paymentMethod,
        expenseDate: oilChange.changeDate,
        notes: 'تغيير زيت - ${oilChange.oilType ?? ''} ${oilChange.oilViscosity ?? ''}',
        linkedTo: 'oil_change',
        linkedId: oilChange.id,
      );
      await _expensesRepository.addExpense(expense);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateOilChange(OilChange oilChange) async {
    state = const AsyncValue.loading();
    try {
      await _carRepository.updateOilChange(oilChange);

      // Sync linked expense
      final existingExpense = await _expensesRepository.getExpenseByLinkedItem('oil_change', oilChange.id!);
      if (existingExpense != null) {
        await _expensesRepository.updateExpense(existingExpense.copyWith(
          amount: oilChange.cost,
          currency: oilChange.currency,
          paymentMethod: oilChange.paymentMethod,
          expenseDate: oilChange.changeDate,
          notes: 'تغيير زيت - ${oilChange.oilType ?? ''} ${oilChange.oilViscosity ?? ''}',
        ));
        _ref.invalidate(expensesProvider);
        _ref.invalidate(totalExpensesProvider);
        _ref.invalidate(expensesByCategoryProvider);
      }

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteOilChange(int id) async {
    state = const AsyncValue.loading();
    try {
      await _carRepository.deleteOilChange(id);
      
      // Delete linked expense
      final existingExpense = await _expensesRepository.getExpenseByLinkedItem('oil_change', id);
      if (existingExpense != null) {
        await _expensesRepository.deleteExpense(existingExpense.id!);
        _ref.invalidate(expensesProvider);
        _ref.invalidate(totalExpensesProvider);
        _ref.invalidate(expensesByCategoryProvider);
      }

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  // ========================================
  // DOCUMENT OPERATIONS
  // ========================================

  Future<void> addCarDocument({
    required CarDocument document,
    required String expenseCategoryId,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Cancel previous notification for the same document type
      final existingDocs = await _carRepository.getDocumentsByType(document.carId, document.documentType);
      if (existingDocs.isNotEmpty) {
        final latestOldDoc = existingDocs.first;
        if (latestOldDoc.notificationId != null) {
          await _notificationService.cancelNotification(latestOldDoc.notificationId!);
          // Optional: Clear notificationId in DB for the old document
          await _carRepository.updateCarDocument(latestOldDoc.copyWith(notificationId: null));
        }
      }

      // Add document record
      final docId = await _carRepository.addCarDocument(document);

      // Create linked expense
      final expense = ExpenseLocalModel(
        userId: _userId,
        categoryId: expenseCategoryId,
        amount: document.cost,
        currency: document.currency,
        paymentMethod: document.paymentMethod,
        expenseDate: document.renewalDate,
        notes: '${document.documentType.nameAr} - ${document.placeName ?? ''}',
        linkedTo: 'car_document',
        linkedId: docId,
      );
      await _expensesRepository.addExpense(expense);
      _ref.invalidate(expensesProvider);
      _ref.invalidate(totalExpensesProvider);
      _ref.invalidate(expensesByCategoryProvider);

      // Schedule notification 15 days before expiry
      await _scheduleExpiryNotification(document.copyWith(id: docId));

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateCarDocument(CarDocument document) async {
    state = const AsyncValue.loading();
    try {
      await _carRepository.updateCarDocument(document);
      
      // Sync linked expense
      final existingExpense = await _expensesRepository.getExpenseByLinkedItem('car_document', document.id!);
      if (existingExpense != null) {
        await _expensesRepository.updateExpense(existingExpense.copyWith(
          amount: document.cost,
          currency: document.currency,
          paymentMethod: document.paymentMethod,
          expenseDate: document.renewalDate,
          notes: '${document.documentType.nameAr} - ${document.placeName ?? ''}',
        ));
        _ref.invalidate(expensesProvider);
        _ref.invalidate(totalExpensesProvider);
        _ref.invalidate(expensesByCategoryProvider);
      }

      // Cancel old notification and schedule new one
      if (document.notificationId != null) {
        await _notificationService.cancelNotification(document.notificationId!);
      }
      await _scheduleExpiryNotification(document);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> deleteCarDocument(int id) async {
    state = const AsyncValue.loading();
    try {
      await _carRepository.deleteCarDocument(id);

      // Delete linked expense
      final existingExpense = await _expensesRepository.getExpenseByLinkedItem('car_document', id);
      if (existingExpense != null) {
        await _expensesRepository.deleteExpense(existingExpense.id!);
        _ref.invalidate(expensesProvider);
        _ref.invalidate(totalExpensesProvider);
        _ref.invalidate(expensesByCategoryProvider);
      }

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  // ========================================
  // NOTIFICATION HELPERS
  // ========================================

  Future<void> _scheduleExpiryNotification(CarDocument document) async {
    try {
      // Calculate notification date (15 days before expiry)
      final notificationDate = document.expiryDate.subtract(const Duration(days: 15));
      
      // Only schedule if notification date is in the future
      if (notificationDate.isAfter(DateTime.now())) {
        final car = await _carRepository.getCarById(document.carId);
        final carName = car?.name ?? 'السيارة';
        final notificationId = document.id;
        final expiryStr = DateFormat('yyyy-MM-dd').format(document.expiryDate);
        
        await _notificationService.scheduleNotification(
          id: notificationId,
          title: 'تذكير: ${document.documentType.nameAr} - $carName',
          body: 'ينتهي ${document.documentType.nameAr} لسيارة $carName في $expiryStr',
          scheduledDate: notificationDate,
          payload: 'car_document:${document.id}',
        );

        // Update document with notification ID
        await _carRepository.updateCarDocument(
          document.copyWith(notificationId: notificationId),
        );
      }
    } catch (e) {
      // Log error but don't fail the whole operation
      print('Failed to schedule notification: $e');
    }
  }
}

// Car Management Notifier Provider
final carManagementNotifierProvider =
    StateNotifierProvider<CarManagementNotifier, AsyncValue<void>>((ref) {
  final carRepository = ref.watch(carRepositoryProvider);
  final expensesRepository = ExpensesRepository();
  final notificationService = NotificationService.instance;
  final userId = ref.watch(currentUserIdProvider);

  return CarManagementNotifier(
    carRepository,
    expensesRepository,
    notificationService,
    userId,
    ref,
  );
});
