import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants.dart';
import '../core/utils.dart';
import '../data/models.dart';

/// Export utilities — JSON backup (whole app), CSV export of expenses,
/// Markdown note export, and Khata statement sharing.
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  Future<void> shareJson(String json, {String fileName = 'nexa-backup.json'}) async {
    final file = await _write(fileName, json);
    await Share.shareXFiles([XFile(file.path)], subject: fileName);
  }

  Future<void> shareExpensesCsv(List<Expense> expenses, String currency) async {
    final header = ['Date', 'Type', 'Amount ($currency)', 'Category', 'Account', 'Note'];
    final rows = expenses.map((e) {
      final cat = kCategories[e.category] ?? e.category;
      final acct = e.accountId;
      return [e.date, e.type, e.amount.toStringAsFixed(2), cat, acct, _csvEscape(e.note)];
    });
    final csv = [header, ...rows].map((r) => r.join(',')).join('\n');
    final file = await _write('nexa-expenses.csv', csv);
    await Share.shareXFiles([XFile(file.path)], subject: 'Nexora expenses');
  }

  Future<void> shareNoteAsMarkdown(Note note) async {
    final safeTitle = note.title.trim().isEmpty
        ? 'Untitled'
        : note.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final content = StringBuffer();
    content.writeln('# ${note.title}');
    content.writeln('Date: ${note.createdAt.substring(0, 10)}');
    if (note.tags.isNotEmpty) {
      content.writeln('Tags: ${note.tags.map((t) => '#$t').join(' ')}');
    }
    content.writeln();
    content.writeln(note.body);

    final file = await _write('$safeTitle.md', content.toString());
    await Share.shareXFiles([XFile(file.path)], subject: note.title);
  }

  Future<void> shareKhataStatementText({
    required KhataPerson person,
    required List<KhataEntry> entries,
    required double netBalance,
    required String currency,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('════════════════════════════════');
    buffer.writeln('📜 NEXORA KHATA STATEMENT');
    buffer.writeln('════════════════════════════════');
    buffer.writeln('Account: ${person.name}');
    if (person.phone != null && person.phone!.isNotEmpty) {
      buffer.writeln('Phone: ${person.phone}');
    }
    buffer.writeln('Date: ${todayIsoDate()}');
    buffer.writeln('────────────────────────────────');
    buffer.writeln(
      netBalance > 0
          ? 'STATUS: You will get ${formatCurrency(netBalance, currency)}'
          : (netBalance < 0
              ? 'STATUS: You owe ${formatCurrency(netBalance.abs(), currency)}'
              : 'STATUS: Fully Settled'),
    );
    buffer.writeln('────────────────────────────────');
    buffer.writeln('TRANSACTIONS HISTORY:');

    if (entries.isEmpty) {
      buffer.writeln('No entries recorded yet.');
    } else {
      for (final e in entries) {
        final sign = e.type == 'given' ? 'GAVE' : 'GOT';
        buffer.writeln(
            '${e.date} | $sign: ${formatCurrency(e.amount, currency)} ${e.description.isNotEmpty ? '(${e.description})' : ''}');
      }
    }
    buffer.writeln('════════════════════════════════');
    buffer.writeln('Generated with Nexora Personal OS');

    await Share.share(buffer.toString(), subject: 'Khata Statement: ${person.name}');
  }

  String _csvEscape(String s) {
    final needsQuote = s.contains(',') || s.contains('"') || s.contains('\n');
    var out = s.replaceAll('"', '""');
    return needsQuote ? '"$out"' : out;
  }

  Future<File> _write(String name, String content) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsString(content);
    return file;
  }
}
