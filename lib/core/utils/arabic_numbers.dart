/// Utility class for Arabic number formatting
class ArabicNumbers {
  /// Convert English/Hindi digits to Arabic digits (0-9)
  static String convert(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const hindi = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

    String result = input;

    // Convert Hindi numerals to English first (if any)
    for (int i = 0; i < hindi.length; i++) {
      result = result.replaceAll(hindi[i], english[i]);
    }

    // Keep English numerals as is (0-9)
    // If you want Arabic-Indic numerals (٠-٩), uncomment below:
    // for (int i = 0; i < english.length; i++) {
    //   result = result.replaceAll(english[i], arabic[i]);
    // }

    return result;
  }

  /// Format date string to use English numerals (0-9)
  static String formatDate(String dateString) {
    return convert(dateString);
  }

  /// Format DateTime to string with English numerals
  static String formatDateTime(DateTime date) {
    final formatted =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return convert(formatted);
  }
}
