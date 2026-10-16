import 'package:flutter_test/flutter_test.dart';
import 'package:nexa/core/utils.dart';

void main() {
  group('parseNaturalLanguage', () {
    test('parses tags', () {
      final r = parseNaturalLanguage('Buy milk #shopping #groceries');
      expect(r.tags, containsAll(['shopping', 'groceries']));
      expect(r.title, 'Buy milk');
    });

    test('parses priority words', () {
      final r = parseNaturalLanguage('Finish report urgent');
      expect(r.priority, 'urgent');
      expect(r.title, 'Finish report');
    });

    test('parses time', () {
      final r = parseNaturalLanguage('Meeting 3pm');
      expect(r.dueTime, '15:00');
      expect(r.title, 'Meeting');
    });

    test('parses 12-hour midnight correctly', () {
      final r = parseNaturalLanguage('Late snack 12am');
      expect(r.dueTime, '00:00');
    });

    test('parses "tomorrow" offset', () {
      final r = parseNaturalLanguage('Pay rent tomorrow');
      final expected = DateTime.now()
          .add(const Duration(days: 1))
          .toIso8601String()
          .substring(0, 10);
      expect(r.dueDate, expected);
    });

    test('parses full NL string', () {
      final r = parseNaturalLanguage('Pay rent tomorrow 6pm #bills urgent');
      expect(r.tags, ['bills']);
      expect(r.priority, 'urgent');
      expect(r.dueTime, '18:00');
      expect(r.title, 'Pay rent');
    });
  });

  group('autoCategorizeExpense', () {
    test('food keywords', () {
      expect(autoCategorizeExpense('Lunch at cafe'), 'food');
      expect(autoCategorizeExpense('starbucks coffee'), 'food');
    });

    test('transport keywords', () {
      expect(autoCategorizeExpense('Uber ride home'), 'transport');
      expect(autoCategorizeExpense('Gas for car'), 'transport');
    });

    test('bills keywords', () {
      expect(autoCategorizeExpense('Netflix subscription'), 'bills');
      expect(autoCategorizeExpense('Electricity bill'), 'bills');
    });

    test('shopping keywords', () {
      expect(autoCategorizeExpense('Amazon order'), 'shopping');
    });

    test('defaults to other', () {
      expect(autoCategorizeExpense('Random thing'), 'other');
      expect(autoCategorizeExpense(''), 'other');
    });
  });

  group('formatDate', () {
    test('today', () {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      expect(formatDate(today), 'Today');
    });

    test('tomorrow', () {
      final tomorrow = DateTime.now()
          .add(const Duration(days: 1))
          .toIso8601String()
          .substring(0, 10);
      expect(formatDate(tomorrow), 'Tomorrow');
    });

    test('null/empty returns empty', () {
      expect(formatDate(null), '');
      expect(formatDate(''), '');
    });
  });

  group('isOverdue', () {
    test('past date not completed is overdue', () {
      expect(isOverdue('2020-01-01', false), isTrue);
    });

    test('completed tasks are never overdue', () {
      expect(isOverdue('2020-01-01', true), isFalse);
    });

    test('null due date is not overdue', () {
      expect(isOverdue(null, false), isFalse);
    });

    test('future date is not overdue', () {
      final future = DateTime.now()
          .add(const Duration(days: 5))
          .toIso8601String()
          .substring(0, 10);
      expect(isOverdue(future, false), isFalse);
    });
  });

  group('formatCurrency', () {
    test('formats integer amounts without decimals', () {
      expect(formatCurrency(100, 'USD'), '\$100');
    });

    test('formats decimal amounts with 2 places', () {
      expect(formatCurrency(12.5, 'USD'), '\$12.50');
    });

    test('respects currency symbol', () {
      expect(formatCurrency(1000, 'EUR'), '€1,000');
    });

    test('thousands separator', () {
      expect(formatCurrency(3500, 'USD'), '\$3,500');
    });
  });

  group('stripMarkdown', () {
    test('removes headings', () {
      expect(stripMarkdown('# Title'), 'Title');
      expect(stripMarkdown('## Sub'), 'Sub');
    });

    test('removes bold/italic markers', () {
      expect(stripMarkdown('**bold** text'), 'bold text');
      expect(stripMarkdown('*italic*'), 'italic');
    });
  });
}
