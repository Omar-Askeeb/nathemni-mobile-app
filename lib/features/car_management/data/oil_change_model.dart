import 'package:equatable/equatable.dart';

class OilChange extends Equatable {
  final int id;
  final int carId;
  final int userId;
  final DateTime changeDate;
  final double odometer;
  final double cost;
  final String currency;
  final String? oilType;
  final String? oilViscosity;
  final bool filterChanged;
  final double? expectedDistance;
  final double? nextChangeOdometer;
  final String paymentMethod;
  final String? notes;
  final bool isSynced;
  final String? syncId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const OilChange({
    required this.id,
    required this.carId,
    required this.userId,
    required this.changeDate,
    required this.odometer,
    required this.cost,
    this.currency = 'LYD',
    this.oilType,
    this.oilViscosity,
    this.filterChanged = false,
    this.expectedDistance,
    this.nextChangeOdometer,
    this.paymentMethod = 'cash',
    this.notes,
    this.isSynced = false,
    this.syncId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory OilChange.fromJson(Map<String, dynamic> json) {
    return OilChange(
      id: json['id'] as int,
      carId: json['car_id'] as int,
      userId: json['user_id'] as int,
      changeDate: DateTime.parse(json['change_date'] as String),
      odometer: (json['odometer'] as num).toDouble(),
      cost: (json['cost'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'LYD',
      oilType: json['oil_type'] as String?,
      oilViscosity: json['oil_viscosity'] as String?,
      filterChanged: (json['filter_changed'] as int? ?? 0) == 1,
      expectedDistance: json['expected_distance'] != null
          ? (json['expected_distance'] as num).toDouble()
          : null,
      nextChangeOdometer: json['next_change_odometer'] != null
          ? (json['next_change_odometer'] as num).toDouble()
          : null,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      notes: json['notes'] as String?,
      isSynced: json['is_synced'] == 1 || json['is_synced'] == true,
      syncId: json['sync_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'car_id': carId,
      'user_id': userId,
      'change_date': changeDate.toIso8601String().split('T')[0],
      'odometer': odometer,
      'cost': cost,
      'currency': currency,
      if (oilType != null) 'oil_type': oilType,
      if (oilViscosity != null) 'oil_viscosity': oilViscosity,
      'filter_changed': filterChanged ? 1 : 0,
      if (expectedDistance != null) 'expected_distance': expectedDistance,
      if (nextChangeOdometer != null) 'next_change_odometer': nextChangeOdometer,
      'payment_method': paymentMethod,
      if (notes != null) 'notes': notes,
      'is_synced': isSynced ? 1 : 0,
      if (syncId != null) 'sync_id': syncId,
    };
  }

  OilChange copyWith({
    int? id,
    int? carId,
    int? userId,
    DateTime? changeDate,
    double? odometer,
    double? cost,
    String? currency,
    String? oilType,
    String? oilViscosity,
    bool? filterChanged,
    double? expectedDistance,
    double? nextChangeOdometer,
    String? paymentMethod,
    String? notes,
    bool? isSynced,
    String? syncId,
  }) {
    return OilChange(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      userId: userId ?? this.userId,
      changeDate: changeDate ?? this.changeDate,
      odometer: odometer ?? this.odometer,
      cost: cost ?? this.cost,
      currency: currency ?? this.currency,
      oilType: oilType ?? this.oilType,
      oilViscosity: oilViscosity ?? this.oilViscosity,
      filterChanged: filterChanged ?? this.filterChanged,
      expectedDistance: expectedDistance ?? this.expectedDistance,
      nextChangeOdometer: nextChangeOdometer ?? this.nextChangeOdometer,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      syncId: syncId ?? this.syncId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        carId,
        userId,
        changeDate,
        odometer,
        cost,
        currency,
        oilType,
        oilViscosity,
        filterChanged,
        expectedDistance,
        nextChangeOdometer,
        paymentMethod,
        notes,
        isSynced,
        syncId,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
