import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../services/notifications.dart';
import '../../widgets/glass.dart';
import '../../widgets/sheet.dart';

/// Edit or delete an existing transaction with full category grid,
/// quick-amount adjustments, date/account editing, and budget re-check.
class EditExpenseSheet extends ConsumerStatefulWidget {
  final Expense expense;

  const EditExpenseSheet({super.key, required this.expense});

  static Future<void> show(BuildContext context, Expense expense) =>
      showNexaSheet(
        context,
        title: 'Edit Transaction',
        initialSize: 0.88,
        builder: (_) => EditExpenseSheet(expense: expense),
      );

  @override
  ConsumerState<EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends ConsumerState<EditExpenseSheet> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late final TextEditingController _date;
  late String _type;
  late String _category;
  late String _accountId;
  late bool _recurring;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.expense.amount % 1 == 0
          ? widget.expense.amount.toInt().toString()
          : widget.expense.amount.toStringAsFixed(2),
    );
    _note = TextEditingController(text: widget.expense.note);
    _date = TextEditingController(text: widget.expense.date);
    _type = widget.expense.type;
    _category = widget.expense.category;
    _accountId = widget.expense.accountId;
    _recurring = widget.expense.isRecurring;
  }

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

  Future<void> _submit() async {
    final amt = double.tryParse(_amount.text);
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final store = ref.read(appStoreProvider.notifier);
    store.updateExpense(
      widget.expense.id,
      (e) => e.copyWith(
        amount: amt,
        type: _type,
        category: _category,
        accountId: _accountId,
        note: _note.text.trim(),
        date: _date.text,
        isRecurring: _recurring,
      ),
    );

    // Budget overspend alert check if expense was edited
    final data = ref.read(appStoreProvider).valueOrNull;
    if (_type == 'expense' && data != null) {
      final currency = data.user.currency;
      final currentMonth = _date.text.length >= 7
          ? _date.text.substring(0, 7)
          : todayIsoDate().substring(0, 7);
      final budget = data.budgets.where((b) =>
          b.category == _category && b.monthYear == currentMonth).firstOrNull;

      if (budget != null && budget.monthlyLimit > 0) {
        final currentSpend = data.expenses
            .where((e) =>
                e.type == 'expense' &&
                e.category == _category &&
                e.date.startsWith(currentMonth))
            .fold<double>(0, (sum, e) => sum + e.amount);

        final pct = (currentSpend / budget.monthlyLimit * 100).round();
        if (pct >= 80) {
          NotificationService.instance.showBudgetAlert(
            category: kCategories[_category] ?? _category,
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

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text(
          'Are you sure you want to remove this record? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: NexaColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ref.read(appStoreProvider.notifier).deleteExpense(widget.expense.id);
      NexaHaptics.medium();
      Navigator.of(context).maybePop();
    }
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
              suffixIcon: IconButton(
                icon: const Icon(LucideIcons.x, size: 18),
                onPressed: () {
                  NexaHaptics.light();
                  setState(() => _amount.clear());
                },
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Quick Adjust Chips ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _QuickChip(label: '+100', onTap: () => _addAmount(100)),
                _QuickChip(label: '+500', onTap: () => _addAmount(500)),
                _QuickChip(label: '+1,000', onTap: () => _addAmount(1000)),
                _QuickChip(label: '+5,000', onTap: () => _addAmount(5000)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Note Field ──
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'Note / Description',
              hintText: 'What was this transaction for?',
              prefixIcon: Icon(LucideIcons.fileText, size: 18),
            ),
          ),
          const SizedBox(height: 18),

          // ── Category Selector ──
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

          // ── Account & Date Row ──
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

          // ── Recurring Toggle ──
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Row(
              children: [
                Icon(LucideIcons.repeat, size: 18),
                SizedBox(width: 10),
                Text('Recurring transaction'),
              ],
            ),
            value: _recurring,
            onChanged: (v) => setState(() => _recurring = v),
          ),
          const SizedBox(height: 20),

          // ── Actions ──
          GradientButton(
            'Save Changes',
            icon: LucideIcons.check,
            onPressed: _submit,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _confirmDelete,
            icon: const Icon(LucideIcons.trash2, size: 18, color: NexaColors.danger),
            label: const Text(
              'Delete Transaction',
              style: TextStyle(color: NexaColors.danger, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: NexaColors.danger.withOpacity(0.4)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 16),
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

  const _QuickChip({required this.label, required this.onTap});

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
            color: dark ? NexaColors.darkPrimary : NexaColors.lightPrimary,
          ),
        ),
        backgroundColor: dark ? NexaColors.darkSurface2 : NexaColors.lightSurface2,
        side: BorderSide(
          color: dark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.08),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onPressed: onTap,
      ),
    );
  }
}
