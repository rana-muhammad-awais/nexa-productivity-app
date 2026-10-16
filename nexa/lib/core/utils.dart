import 'package:intl/intl.dart';

/// Faithful Dart port of `js/utils.js`.

/// "Today" / "Tomorrow" / "Yesterday" / weekday / "MMM d" — mirrors formatDate().
String formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  final d = _parseDate(dateStr);
  if (d == null) return dateStr;
  final today = DateTime.now();
  final t = DateTime(today.year, today.month, today.day);
  final diff = d.difference(t).inDays;

  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff == -1) return 'Yesterday';
  if (diff > 1 && diff <= 7) {
    return DateFormat('EEEE').format(d); // e.g. "Friday"
  }
  return DateFormat('MMM d').format(d); // e.g. "Jul 26"
}

DateTime? _parseDate(String s) {
  try {
    return DateTime.parse(s.length == 10 ? s : s.substring(0, 10));
  } catch (_) {
    return null;
  }
}

String todayIsoDate() => _isoDate(DateTime.now());

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String monthYearKey([DateTime? base]) {
  final d = base ?? DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}';
}

/// Mirror of formatCurrency(amount, currency). Uses the symbol table so output
/// is stable regardless of device locale.
String formatCurrency(num amount, String currency) {
  final symbol = const {
        'USD': '\$',
        'EUR': '€',
        'GBP': '£',
        'INR': '₹',
        'PKR': '₨',
        'JPY': '¥',
        'CAD': 'C\$',
        'AUD': 'A\$',
      }[currency] ??
      '\$';
  final isInt = amount.roundToDouble() == amount.toDouble();
  final formatted = isInt
      ? NumberFormat('#,##0').format(amount)
      : NumberFormat('#,##0.00').format(amount);
  final negative = amount < 0;
  return negative ? '-$symbol${formatted.replaceFirst('-', '')}' : '$symbol$formatted';
}

String getGreeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

bool isOverdue(String? dueDate, bool isCompleted) {
  if (dueDate == null || dueDate.isEmpty || isCompleted) return false;
  return dueDate.compareTo(todayIsoDate()) < 0;
}

/// Whole days from today to [dateStr] (can be negative). Null if unparseable.
int? daysUntil(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return null;
  final target = _parseDate(dateStr);
  if (target == null) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return target.difference(today).inDays;
}

class ParsedTask {
  final String title;
  final String? dueDate;
  final String? dueTime;
  final List<String> tags;
  final String priority;
  const ParsedTask({
    required this.title,
    this.dueDate,
    this.dueTime,
    this.tags = const [],
    this.priority = 'medium',
  });
}

/// Natural-language quick-add parser — direct port of parseNaturalLanguage().
/// Handles: `#tags`, priority words, `3pm`/`3:30pm`, today/tomorrow/weekday.
ParsedTask parseNaturalLanguage(String input) {
  String title = input;
  final tags = <String>[];

  final tagMatches = RegExp(r'#(\w+)').allMatches(title);
  for (final m in tagMatches) {
    tags.add(m.group(1)!.toLowerCase());
  }
  title = title.replaceAll(RegExp(r'#\w+'), '').trim();

  const priorityWords = {
    'urgent': 'urgent',
    'asap': 'urgent',
    'important': 'high',
    'high': 'high',
  };
  String priority = 'medium';
  for (final entry in priorityWords.entries) {
    final re = RegExp('\\b${entry.key}\\b', caseSensitive: false);
    if (re.hasMatch(title)) {
      priority = entry.value;
      title = title.replaceAll(re, '').trim();
    }
  }

  String? dueTime;
  final timeMatch = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)', caseSensitive: false)
      .firstMatch(title);
  if (timeMatch != null) {
    var h = int.parse(timeMatch.group(1)!);
    final m = timeMatch.group(2) ?? '00';
    final period = timeMatch.group(3)!.toLowerCase();
    if (period == 'pm' && h < 12) h += 12;
    if (period == 'am' && h == 12) h = 0;
    dueTime = '${h.toString().padLeft(2, '0')}:$m';
    title = title.replaceFirst(timeMatch.group(0)!, '').trim();
  }

  String? dueDate;
  const dateOffsets = {'today': 0, 'tonight': 0, 'tomorrow': 1};
  for (final entry in dateOffsets.entries) {
    final re = RegExp('\\b${entry.key}\\b', caseSensitive: false);
    if (re.hasMatch(title)) {
      final d = DateTime.now().add(Duration(days: entry.value));
      dueDate = _isoDate(d);
      title = title.replaceFirst(re, '').trim();
      break;
    }
  }
  if (dueDate == null) {
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    final lower = title.toLowerCase();
    for (final wd in days) {
      if (RegExp('\\b$wd\\b').hasMatch(lower)) {
        final d = DateTime.now();
        final target = days.indexOf(wd);
        var diff = target - d.weekday; // DateTime.weekday: Mon=1..Sun=7
        if (diff <= 0) diff += 7;
        dueDate = _isoDate(d.add(Duration(days: diff)));
        title =
            title.replaceAll(RegExp('\\b$wd\\b', caseSensitive: false), '').trim();
        break;
      }
    }
  }

  title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
  return ParsedTask(
    title: title,
    dueDate: dueDate,
    dueTime: dueTime,
    tags: tags,
    priority: priority,
  );
}

/// Keyword-based auto-categorization — port of autoCategorizeExpense().
String autoCategorizeExpense(String? note) {
  final text = (note ?? '').toLowerCase();
  const rules = {
    'food': [
      'food', 'restaurant', 'cafe', 'coffee', 'lunch', 'dinner', 'grocery',
      'uber eats', 'doordash', 'pizza', 'starbucks', 'breakfast', 'snack',
      'bakery', 'meal', 'takeout',
    ],
    'transport': [
      'uber', 'lyft', 'taxi', 'gas', 'fuel', 'parking', 'transit', 'metro',
      'bus', 'train', 'flight', 'airline', 'car', 'ride',
    ],
    'bills': [
      'rent', 'electric', 'electricity', 'water', 'internet', 'phone',
      'insurance', 'netflix', 'spotify', 'subscription', 'utilities', 'bill',
      'mortgage',
    ],
    'shopping': [
      'amazon', 'target', 'walmart', 'shop', 'clothes', 'shoes', 'order',
      'purchase', 'store', 'mall',
    ],
  };
  for (final entry in rules.entries) {
    if (entry.value.any((kw) => text.contains(kw))) return entry.key;
  }
  return 'other';
}

/// Strip markdown to a single-line preview — port of stripMarkdown().
String stripMarkdown(String text) {
  return text
      .replaceAll(RegExp(r'^#+\s+', multiLine: true), '')
      .replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m.group(1)!)
      .replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m.group(1)!)
      .replaceAll(RegExp(r'- \[.\]\s'), '')
      .replaceAll(RegExp(r'^-\s', multiLine: true), '')
      .replaceAll(RegExp(r'\n+'), ' ')
      .trim();
}

String notePreview(String body) {
  final stripped = stripMarkdown(body);
  return stripped.length > 100 ? stripped.substring(0, 100) : stripped;
}

String capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
