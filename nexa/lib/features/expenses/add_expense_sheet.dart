import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/app_store.dart';
import '../../services/notifications.dart';
import '../../widgets/glass.dart';
import '../../widgets/sheet.dart';
import 'currency_converter_sheet.dart';

/// Add income/expense with visual category grid, quick-amount chips,
/// split-bill calculator, live auto-categorization pill, and recurring frequency.
class AddExpenseSheet extends ConsumerStatefulWidget {
  const AddExpenseSheet({super.key});

  static Future<void> show(BuildContext context) => showNexaSheet(
        context,
        title: 'Add Transaction',
        initialSize: 0.88,
        builder: (_) => const AddExpenseSheet(),
      );

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _date = TextEditingController(text: todayIsoDate());
  String _type = 'expense';
  String _category = 'food';
  String _accountId = 'cash';
  bool _recurring = false;
  String _recurringFrequency = 'monthly';
  bool _splitBill = false;
  int _splitCount = 2;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _date.dispose();
    super.dispose();
  }

  void _addAmount(double add) {
    NexaHaptics.light();
    final current = double.tryParse(_amount.text) ?? 0;
    final updated = current + add;
    setState(() {
      _amount.text = updated % 1 == 0
          ? updated.toInt().toString()
          : updated.toStringAsFixed(2);
    });
  }

  void _clearAmount() {
    NexaHaptics.light();
    setState(() {
      _amount.clear();
    });
  }

  Future<void> _submit() async {
    final amt = double.tryParse(_amount.text);
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    var category = _category;
    if (category == 'other' && _note.text.isNotEmpty) {
      final auto = autoCategorizeExpense(_note.text);
      if (auto != 'other') category = auto;
    }

    var finalNote = _note.text.trim();
    if (_splitBill && _splitCount > 1) {
      final perPerson = (amt / _splitCount).toStringAsFixed(1);
      final splitTag = ' [Split $_splitCount ways: $perPerson/person]';
      if (!finalNote.contains('Split')) {
        finalNote = finalNote.isEmpty ? splitTag.trim() : '$finalNote$splitTag';
      }
    }

    if (_recurring) {
      final recurTag = ' [Repeats $_recurringFrequency]';
      if (!finalNote.contains('Repeats')) {
        finalNote = finalNote.isEmpty ? recurTag.trim() : '$finalNote$recurTag';
      }
    }

    final store = ref.read(appStoreProvider.notifier);
    final data = ref.read(appStoreProvider).valueOrNull;

    store.addExpense(
      amount: amt,
      type: _type,
      category: category,
      accountId: _accountId,
      note: finalNote,
      date: _date.text,
      isRecurring: _recurring,
    );

    // Check budget alert
    if (_type == 'expense' && data != null) {
      final currency = data.user.currency;
      final currentMonth = _date.text.length >= 7
          ? _date.text.substring(0, 7)
          : todayIsoDate().substring(0, 7);
      final budget = data.budgets.where((b) =>
          b.category == category && b.monthYear == currentMonth).firstOrNull;

      if (budget != null && budget.monthlyLimit > 0) {
        final currentSpend = data.expenses
            .where((e) =>
                e.type == 'expense' &&
                e.category == category &&
                e.date.startsWith(currentMonth))
            .fold<double>(0, (sum, e) => sum + e.amount) + amt;

        final pct = (currentSpend / budget.monthlyLimit * 100).round();
        if (pct >= 80) {
          NotificationService.instance.showBudgetAlert(
            category: kCategories[category] ?? category,
            spent: currentSpend,
            limit: budget.monthlyLimit,
            currency: currency,
            percent: pct,
          );
        }
      }
    }

    NexaHaptics.success();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final asyncData = ref.watch(appStoreProvider);
    final accounts = asyncData.valueOrNull?.accounts ?? kDefaultAccounts;
    final currency = asyncData.valueOrNull?.user.currency ?? 'USD';
    final currencySymbol = kCurrencySymbols[currency] ?? '\$';

    final categories = _type == 'income' ? kIncomeCategories : kCategories;
    if (!categories.containsKey(_category)) {
      _category = categories.keys.first;
    }

    final suggestedCategory = _type == 'expense' && _note.text.length >= 3
        ? autoCategorizeExpense(_note.text)
        : null;
    final showSuggestion = suggestedCategory != null &&
        suggestedCategory != 'other' &&
        suggestedCategory != _category;

    final currentAmt = double.tryParse(_amount.text) ?? 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Type Switcher ──
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: dark ? NexaColors.darkSurface2 : NexaColors.lightSurface2,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TypeTab(
                    label: 'Expense',
                    icon: LucideIcons.arrowUpRight,
                    active: _type == 'expense',
                    activeColor: NexaColors.danger,
                    onTap: () {
                      NexaHaptics.selection();
                      setState(() {
                        _type = 'expense';
                        _category = 'food';
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _TypeTab(
                    label: 'Income',
                    icon: LucideIcons.arrowDownLeft,
                    active: _type == 'income',
                    activeColor: NexaColors.success,
                    onTap: () {
                      NexaHaptics.selection();
                      setState(() {
                        _type = 'income';
                        _category = 'salary';
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Amount Input ──
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true, signed: false),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: ' $currencySymbol ',
              prefixStyle: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: _type == 'expense' ? NexaColors.danger : NexaColors.success,
              ),
              suffixIcon: _amount.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: _clearAmount,
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),

          // ── Quick Amount Preset Chips ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _QuickChip(label: '+100', onTap: () => _addAmount(100)),
                _QuickChip(label: '+500', onTap: () => _addAmount(500)),
                _QuickChip(label: '+1,000', onTap: () => _addAmount(1000)),
                _QuickChip(label: '+5,000', onTap: () => _addAmount(5000)),
                _QuickChip(
                  label: '💱 Convert',
                  onTap: () {
                    NexaHaptics.tick();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => CurrencyConverterSheet(
                        initialToCurrency: currency,
                        initialAmount: double.tryParse(_amount.text) ?? 100,
                        onApplyAmount: (converted) {
                          _amount.text = converted.toStringAsFixed(2);
                          setState(() {});
                        },
                      ),
                    );
                  },
                ),
                if (_amount.text.isNotEmpty)
                  _QuickChip(
                    label: 'Clear',
                    isDestructive: true,
                    onTap: _clearAmount,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Note Field with Auto-Categorization Pill ──
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'Note / Description',
              hintText: 'e.g. Starbucks coffee, Uber ride, Team lunch',
              prefixIcon: Icon(LucideIcons.fileText, size: 18),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (showSuggestion) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                NexaHaptics.light();
                setState(() => _category = suggestedCategory);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: NexaColors.lightPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: NexaColors.lightPrimary.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.sparkles,
                        size: 16, color: NexaColors.lightPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Auto-detected: ${kCategories[suggestedCategory] ?? suggestedCategory} (Tap to apply)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: NexaColors.lightPrimary,
                        ),
                      ),
                    ),
                    const Icon(LucideIcons.check,
                        size: 14, color: NexaColors.lightPrimary),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),

          // ── Visual Category Grid ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: dark ? NexaColors.darkTextSec : NexaColors.lightTextSec,
                ),
              ),
              Text(
                categories[_category] ?? _category,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: NexaColors.categoryColors[_category] ??
                      (dark ? NexaColors.darkPrimary : NexaColors.lightPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final entry = categories.entries.elementAt(index);
                final catKey = entry.key;
                final catName = entry.value;
                final isSelected = _category == catKey;
                final catColor = NexaColors.categoryColors[catKey] ??
                    NexaColors.lightPrimary;
                final iconData = kCategoryIcons[catKey] as IconData? ??
                    LucideIcons.tag;

                return GestureDetector(
                  onTap: () {
                    NexaHaptics.selection();
                    setState(() => _category = catKey);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 76,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? catColor.withOpacity(dark ? 0.25 : 0.15)
                          : (dark
                              ? NexaColors.darkSurface2
                              : NexaColors.lightSurface2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? catColor
                            : (dark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.black.withOpacity(0.06)),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(isSelected ? 0.9 : 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            iconData,
                            size: 16,
                            color: isSelected ? Colors.white : catColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          catName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? (dark ? Colors.white : Colors.black87)
                                : (dark
                                    ? NexaColors.darkTextSec
                                    : NexaColors.lightTextSec),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          // ── Account Selector & Date Row ──
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _accountId,
                  decoration: const InputDecoration(
                    labelText: 'Account',
                    prefixIcon: Icon(LucideIcons.wallet, size: 18),
                  ),
                  items: accounts
                      .map((a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(
                              a.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _accountId = v ?? 'cash'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _date,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(LucideIcons.calendar, size: 18),
                  ),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(_date.text) ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) {
                      _date.text =
                          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Split Expense Accordion ──
          if (_type == 'expense') ...[
            Container(
              decoration: BoxDecoration(
                color: dark ? NexaColors.darkSurface2 : NexaColors.lightSurface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: dark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.06),
                ),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                    title: const Row(
                      children: [
                        Icon(LucideIcons.users, size: 18),
                        SizedBox(width: 10),
                        Text(
                          'Split with friends / group',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    value: _splitBill,
                    onChanged: (v) {
                      NexaHaptics.selection();
                      setState(() => _splitBill = v);
                    },
                  ),
                  if (_splitBill) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                      child: Row(
                        children: [
                          const Text('Split between: '),
                          IconButton(
                            icon: const Icon(LucideIcons.minusCircle, size: 20),
                            onPressed: _splitCount > 2
                                ? () => setState(() => _splitCount--)
                                : null,
                          ),
                          Text(
                            '$_splitCount people',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.plusCircle, size: 20),
                            onPressed: _splitCount < 10
                                ? () => setState(() => _splitCount++)
                                : null,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: NexaColors.info.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              currentAmt > 0
                                  ? '$currencySymbol${(currentAmt / _splitCount).toStringAsFixed(1)} / ea'
                                  : '$currencySymbol 0 / ea',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: NexaColors.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // ── Recurring Toggle & Frequency ──
          Container(
            decoration: BoxDecoration(
              color: dark ? NexaColors.darkSurface2 : NexaColors.lightSurface2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: dark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.06),
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  title: const Row(
                    children: [
                      Icon(LucideIcons.repeat, size: 18),
                      SizedBox(width: 10),
                      Text(
                        'Recurring transaction',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  value: _recurring,
                  onChanged: (v) {
                    NexaHaptics.selection();
                    setState(() => _recurring = v);
                  },
                ),
                if (_recurring) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Row(
                      children: [
                        const Text('Frequency: '),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                  value: 'daily',
                                  label: Text('Day', style: TextStyle(fontSize: 11))),
                              ButtonSegment(
                                  value: 'weekly',
                                  label: Text('Wk', style: TextStyle(fontSize: 11))),
                              ButtonSegment(
                                  value: 'monthly',
                                  label: Text('Mo', style: TextStyle(fontSize: 11))),
                              ButtonSegment(
                                  value: 'yearly',
                                  label: Text('Yr', style: TextStyle(fontSize: 11))),
                            ],
                            selected: {_recurringFrequency},
                            onSelectionChanged: (s) =>
                                setState(() => _recurringFrequency = s.first),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Submit Button ──
          GradientButton(
            _type == 'expense' ? 'Add Expense' : 'Add Income',
            icon: _type == 'expense'
                ? LucideIcons.arrowUpRight
                : LucideIcons.arrowDownLeft,
            onPressed: _submit,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _TypeTab({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? (dark ? activeColor.withOpacity(0.2) : activeColor.withOpacity(0.12))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: active
              ? Border.all(color: activeColor.withOpacity(0.4), width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: active
                  ? activeColor
                  : (dark ? NexaColors.darkTextSec : NexaColors.lightTextSec),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active
                    ? (dark ? Colors.white : activeColor)
                    : (dark ? NexaColors.darkTextSec : NexaColors.lightTextSec),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _QuickChip({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDestructive
                ? NexaColors.danger
                : (dark ? NexaColors.darkPrimary : NexaColors.lightPrimary),
          ),
        ),
        backgroundColor: isDestructive
            ? NexaColors.danger.withOpacity(0.1)
            : (dark ? NexaColors.darkSurface2 : NexaColors.lightSurface2),
        side: BorderSide(
          color: isDestructive
              ? NexaColors.danger.withOpacity(0.3)
              : (dark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.08)),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onPressed: onTap,
      ),
    );
  }
}
