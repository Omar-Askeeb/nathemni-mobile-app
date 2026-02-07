import 'package:equatable/equatable.dart';

/// Base API Response matching Laravel backend structure:
/// {
///   "success": true/false,
///   "message": "...",
///   "data": {...},
///   "errors": {...} // for validation errors
/// }
class ApiResponse<T> extends Equatable {
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? errors;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T)? toJsonT) {
    return {
      'success': success,
      if (message != null) 'message': message,
      if (data != null && toJsonT != null) 'data': toJsonT(data as T),
      if (errors != null) 'errors': errors,
    };
  }

  @override
  List<Object?> get props => [success, message, data, errors];
}

/// Paginated response for list endpoints
class PaginatedResponse<T> extends Equatable {
  final bool success;
  final String? message;
  final List<T> data;
  final PaginationMeta meta;

  const PaginatedResponse({
    required this.success,
    this.message,
    required this.data,
    required this.meta,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => fromJsonT(e as Map<String, dynamic>))
              .toList() ??
          [],
      meta: PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [success, message, data, meta];
}

class PaginationMeta extends Equatable {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['current_page'] as int,
      lastPage: json['last_page'] as int,
      perPage: json['per_page'] as int,
      total: json['total'] as int,
    );
  }

  @override
  List<Object?> get props => [currentPage, lastPage, perPage, total];
}
