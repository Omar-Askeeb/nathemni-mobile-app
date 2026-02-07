import 'dart:convert';

/// Model for checklist items within a task
class ChecklistItem {
  final String id;
  final String title;
  final bool isCompleted;
  final double? price; // For shopping category

  ChecklistItem({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.price,
  });

  // Create from JSON
  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      price: json['price'] as double?,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      if (price != null) 'price': price,
    };
  }

  // Copy with
  ChecklistItem copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    double? price,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      price: price ?? this.price,
    );
  }
}

/// Helper methods for checklist
class ChecklistHelper {
  /// Convert list of items to JSON string for storage
  static String encodeChecklist(List<ChecklistItem> items) {
    return jsonEncode(items.map((item) => item.toJson()).toList());
  }

  /// Parse JSON string to list of items
  static List<ChecklistItem> decodeChecklist(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) => ChecklistItem.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Calculate completion percentage
  static double getCompletionPercentage(List<ChecklistItem> items) {
    if (items.isEmpty) return 0.0;
    final completed = items.where((item) => item.isCompleted).length;
    return (completed / items.length) * 100;
  }

  /// Check if all items are completed
  static bool areAllCompleted(List<ChecklistItem> items) {
    if (items.isEmpty) return false;
    return items.every((item) => item.isCompleted);
  }

  /// Calculate total price of checked items
  static double getTotalPrice(List<ChecklistItem> items) {
    return items
        .where((item) => item.isCompleted && item.price != null)
        .fold(0.0, (sum, item) => sum + item.price!);
  }
}
