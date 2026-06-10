class AppDateUtils {
  AppDateUtils._();

  static DateTime addFrequency(DateTime start, String frequency, int cycles) {
    switch (frequency.toLowerCase()) {
      case 'weekly':
        return start.add(Duration(days: 7 * cycles));
      case 'bi-weekly':
        return start.add(Duration(days: 14 * cycles));
      case 'monthly':
        return DateTime(start.year, start.month + cycles, start.day);
      default:
        return start.add(Duration(days: 30 * cycles));
    }
  }

  static bool isOverdue(DateTime dueDate) {
    return DateTime.now().isAfter(dueDate);
  }

  static int daysUntil(DateTime date) {
    return date.difference(DateTime.now()).inDays;
  }

  static String relativeDue(DateTime dueDate) {
    final days = daysUntil(dueDate);
    if (days < 0) return 'Overdue by ${-days} days';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in $days days';
  }
}
