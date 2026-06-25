import 'dart:math';

import 'package:intl/intl.dart';

/// Fun, upbeat messages shown to a user when it's THEIR turn to pick (receive
/// the payout) this cycle.
const List<String> njangiHypeMessages = [
  'Money dey road 🥳',
  'Your turn to chop! 🤑',
  'Cash incoming, get ready! 💸',
  "It's your payday, enjoy! 🎉",
  'The pot is yours this round! 🏆',
  'Soakings loading… 💰',
];

final Random _random = Random();

/// Returns a hype message. Pass [seed] for deterministic output (testability).
String njangiHypeMessage([int? seed]) {
  if (njangiHypeMessages.isEmpty) return '';
  final index = seed != null
      ? seed.abs() % njangiHypeMessages.length
      : _random.nextInt(njangiHypeMessages.length);
  return njangiHypeMessages[index];
}

final DateFormat _dueDateFormat = DateFormat('EEE, d MMM');
final DateFormat _dueTimeFormat = DateFormat('h:mm a');

/// Formats a due datetime as a friendly string, e.g. "Sun, 5 Jul · 6:00 PM".
String formatDueDateTime(DateTime dt) {
  return '${_dueDateFormat.format(dt)} · ${_dueTimeFormat.format(dt)}';
}

/// Returns a relative label for a due datetime, e.g. "in 3 days", "Today",
/// "Tomorrow", "Overdue".
String relativeDueLabel(DateTime dt) {
  final now = DateTime.now();
  if (dt.isBefore(now)) return 'Overdue';

  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(dt.year, dt.month, dt.day);
  final dayDiff = dueDay.difference(today).inDays;

  if (dayDiff == 0) return 'Today';
  if (dayDiff == 1) return 'Tomorrow';
  if (dayDiff < 7) return 'in $dayDiff days';
  if (dayDiff < 14) return 'in 1 week';
  if (dayDiff < 30) return 'in ${(dayDiff / 7).floor()} weeks';
  final months = (dayDiff / 30).floor();
  return months <= 1 ? 'in 1 month' : 'in $months months';
}
