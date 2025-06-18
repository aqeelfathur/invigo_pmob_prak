// models/models_export.dart

// Export all models for easy importing
export 'user_model.dart';
export 'product_model.dart';
export 'pengadaan_model.dart';
export 'pendapatan_model.dart';
export 'laporan_mingguan_model.dart';
export 'laporan_bulanan_model.dart';

// You can also add any model-related constants or utilities here
class ModelConstants {
  // Date format constants
  static const String dateFormat = 'yyyy-MM-dd';
  static const String displayDateFormat = 'dd MMMM yyyy';
  static const String shortDateFormat = 'dd/MM/yyyy';
  
  // Currency format constants
  static const String currencyLocale = 'id';
  static const String currencySymbol = 'Rp';
  static const int currencyDecimalDigits = 0;
  
  // Stock constants
  static const int defaultMinimalStock = 0;
  static const int defaultInitialStock = 0;
  
  // Validation constants
  static const int maxDescriptionLength = 500;
  static const int maxProductNameLength = 100;
  static const int maxSupplierNameLength = 100;
  static const int maxNoteLength = 300;
}

// Helper class for common model operations
class ModelHelpers {
  // Format currency
  static String formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
  
  // Parse currency string to int
  static int parseCurrency(String currencyString) {
    return int.tryParse(
      currencyString.replaceAll(RegExp(r'[^\d]'), '')
    ) ?? 0;
  }
  
  // Validate positive integer
  static bool isValidPositiveInt(String value) {
    final parsed = int.tryParse(value);
    return parsed != null && parsed > 0;
  }
  
  // Validate non-negative integer
  static bool isValidNonNegativeInt(String value) {
    final parsed = int.tryParse(value);
    return parsed != null && parsed >= 0;
  }
  
  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }
  
  // Check if date is this week
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));
    
    return date.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
           date.isBefore(endOfWeek.add(Duration(days: 1)));
  }
  
  // Check if date is this month
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }
  
  // Get start of day
  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  // Get end of day
  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }
  
  // Get first day of month
  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
  
  // Get last day of month
  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }
  
  // Generate ID (simple UUID-like string)
  static String generateId() {
    final now = DateTime.now();
    return '${now.millisecondsSinceEpoch}-${(1000 + (9999 - 1000) * (now.microsecond / 1000000)).round()}';
  }
}