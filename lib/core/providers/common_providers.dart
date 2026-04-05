import 'package:flutter_riverpod/flutter_riverpod.dart';

// ========== COMMON PROVIDERS ==========

/// Current user ID provider (temporary for testing)
/// TODO: Replace with actual auth user ID from auth provider in Phase 4
final currentUserIdProvider = Provider<int>((ref) => 1);
