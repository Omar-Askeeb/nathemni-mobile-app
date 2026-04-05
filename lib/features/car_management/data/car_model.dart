import 'package:equatable/equatable.dart';

class Car extends Equatable {
  final int id;
  final int userId;
  final String name;
  final String? model;
  final int? year;
  final String? plateNumber;
  final double? currentOdometer;
  final String? notes;
  final bool isSynced;
  final String? syncId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const Car({
    required this.id,
    required this.userId,
    required this.name,
    this.model,
    this.year,
    this.plateNumber,
    this.currentOdometer,
    this.notes,
    this.isSynced = false,
    this.syncId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      model: json['model'] as String?,
      year: json['year'] as int?,
      plateNumber: json['plate_number'] as String?,
      currentOdometer: json['current_odometer'] != null
          ? (json['current_odometer'] as num).toDouble()
          : null,
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
      'user_id': userId,
      'name': name,
      if (model != null) 'model': model,
      if (year != null) 'year': year,
      if (plateNumber != null) 'plate_number': plateNumber,
      if (currentOdometer != null) 'current_odometer': currentOdometer,
      if (notes != null) 'notes': notes,
      'is_synced': isSynced ? 1 : 0,
      if (syncId != null) 'sync_id': syncId,
    };
  }

  Car copyWith({
    int? id,
    int? userId,
    String? name,
    String? model,
    int? year,
    String? plateNumber,
    double? currentOdometer,
    String? notes,
    bool? isSynced,
    String? syncId,
  }) {
    return Car(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      model: model ?? this.model,
      year: year ?? this.year,
      plateNumber: plateNumber ?? this.plateNumber,
      currentOdometer: currentOdometer ?? this.currentOdometer,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      syncId: syncId ?? this.syncId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        model,
        year,
        plateNumber,
        currentOdometer,
        notes,
        isSynced,
        syncId,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}
