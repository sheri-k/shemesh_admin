class StringUtils {
  // Converts a string of the format : 2026-01-01T14:18:39.009 to 01/26 (mm/yy)
  static String getMonthYearStr(String inputDate) {
    final parts = inputDate.split('-');
    final month = parts[1];
    final year = parts[0].substring(2); // last 2 digits

    return '$month/$year';
  }

  // Converts a 'YYYY-MM-DD' key to 'DD/MM'.
  static String getDayMonthStr(String key) {
    final parts = key.split('-');
    return '${parts[2]}/${parts[1]}';
  }

  // Single Hebrew weekday letter for the given date.
  // DateTime.weekday: Mon=1 ... Sun=7.
  static String getHebrewDayLetter(DateTime d) {
    const letters = {
      DateTime.sunday: 'א',
      DateTime.monday: 'ב',
      DateTime.tuesday: 'ג',
      DateTime.wednesday: 'ד',
      DateTime.thursday: 'ה',
      DateTime.friday: 'ו',
      DateTime.saturday: 'ש',
    };
    return letters[d.weekday] ?? '';
  }
}
