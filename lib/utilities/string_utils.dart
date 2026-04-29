class StringUtils {
  // Converts a string of the format : 2026-01-01T14:18:39.009 to 01/26 (mm/yy)
  static String getMonthYearStr(String inputDate) {
    final parts = inputDate.split('-');
    final month = parts[1];
    final year = parts[0].substring(2); // last 2 digits

    return '$month/$year';
  }
}
