import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../widgets/glass.dart';
import '../../widgets/sheet.dart';

/// Bottom sheet for adding or editing a Khata entry (transaction) for a specific person.
class AddKhataEntrySheet extends ConsumerStatefulWidget {
  final String personId;
  final KhataEntry? existingEntry;

  const AddKhataEntrySheet({
    super.key,
    required this.personId,
    this.existingEntry,
  });

  static Future<void> show(
    BuildContext context, {
    required String personId,
    KhataEntry? existingEntry,
  }) =>
      showNexaSheet(
        context,
        title: existingEntry != null ? 'Edit Transaction' : 'Record Transaction',
        initialSize: 0.72,
        builder: (_) => AddKhataEntrySheet(
          personId: personId,
          existingEntry: existingEntry,
        ),
      );

  @override
  ConsumerState<AddKhataEntrySheet> createState() => _AddKhataEntrySheetState();
}

class _AddKhataEntrySheetState extends ConsumerState<AddKhataEntrySheet> {
  late final TextEditingController _amount;
  late final TextEditingController _description;
  late final TextEditingController _date;
  late String _type;

  @override
  void initState() {
    super.initState();
    final ex = widget.existingEntry;
    if (ex != null) {
      _amount = TextEditingController(
        text: ex.amount % 1 == 0
            ? ex.amount.toInt().toString()
            : ex.amount.toStringAsFixed(2),
      );
      _description = TextEditingController(text: ex.description);
      _date = TextEditingController(text: ex.date);
      _type = ex.type;
    } else {
      final user = ref.read(appStoreProvider).valueOrNull?.user;
      _type = user?.defaultKhataEntryType ?? 'given';
      _amount = TextEditingController();
      _description = TextEditingController();
      _date = TextEditingController(text: todayIsoDate());
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
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

  void _submit() {
    final amt = double.tryParse(_amount.text);
    if (amt == null || amt <= 0) {
      NexaHaptics.error();
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final store = ref.read(appStoreProvider.notifier);
    if (widget.existingEntry != null) {
      store.updateKhataEntry(
        widget.existingEntry!.id,
        (e) => e.copyWith(
          amount: amt,
          type: _type,
          description: _description.text.trim(),
          date: _date.text,
        ),
      );
    } else {
      store.addKhataEntry(
        personId: widget.personId,
        amount: amt,
        type: _type,
        description: _description.text.trim(),
        date: _date.text,
      );
    }

    NexaHaptics.success();
    Navigator.of(context).maybePop();
  }

  Future<void> _deleteEntry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text(
          'Are you sure you want to remove this ledger entry? Ledger balance will adjust automatically.',
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

    if (confirmed == true && mounted && widget.existingEntry != null) {
      ref.read(appStoreProvider.notifier).deleteKhataEntry(widget.existingEntry!.id);
      NexaHaptics.medium();
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final currency =
        ref.watch(appStoreProvider).valueOrNull?.user.currency ?? 'USD';
    final currencySymbol = kCurrencySymbols[currency] ?? '\$';

    final isEdit = widget.existingEntry != null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Type Switcher (You Gave / You Got) ──
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
                    label: 'You Gave (They Owe)',
                    icon: LucideIcons.arrowUpRight,
                    active: _type == 'given',
                    activeColor: NexaColors.success,
                    onTap: () {
                      NexaHaptics.selection();
                      setState(() => _type = 'given');
                    },
                  ),
                ),
                Expanded(
                  child: _TypeTab(
                    label: 'You Got (You Owe)',
                    icon: LucideIcons.arrowDownLeft,
                    active: _type == 'received',
                    activeColor: NexaColors.danger,
                    onTap: () {
                      NexaHaptics.selection();
                      setState(() => _type = 'received');
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
            autofocus: !isEdit,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true, signed: false),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: ' $currencySymbol ',
              prefixStyle: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: _type == 'given' ? NexaColors.success : NexaColors.danger,
              ),
              suffixIcon: _amount.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: () {
                        NexaHaptics.light();
                        setState(() => _amount.clear());
                      },
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
                _QuickChip(label: '+500', onTap: () => _addAmount(500)),
                _QuickChip(label: '+1,000', onTap: () => _addAmount(1000)),
                _QuickChip(label: '+2,000', onTap: () => _addAmount(2000)),
                _QuickChip(label: '+5,000', onTap: () => _addAmount(5000)),
                _QuickChip(label: '+10,000', onTap: () => _addAmount(10000)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Description Input ──
          TextField(
            controller: _description,
            decoration: const InputDecoration(
              labelText: 'Description / Item Details (optional)',
              hintText: 'e.g. Loan repayment, stock purchase, cash given',
              prefixIcon: Icon(LucideIcons.fileText, size: 18),
            ),
          ),
          const SizedBox(height: 12),

          // ── Date Input ──
          TextFormField(
            controller: _date,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Transaction Date',
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
          const SizedBox(height: 20),

          // ── Submit / Delete Actions ──
          GradientButton(
            isEdit ? 'Update Entry' : 'Record Transaction',
            icon: isEdit ? LucideIcons.check : LucideIcons.plus,
            onPressed: _submit,
          ),
          if (isEdit) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _deleteEntry,
              icon: const Icon(LucideIcons.trash2, size: 18, color: NexaColors.danger),
              label: const Text(
                'Delete Entry',
                style: TextStyle(color: NexaColors.danger, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: NexaColors.danger.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
          const SizedBox(height: 14),
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
              size: 15,
              color: active
                  ? activeColor
                  : (dark ? NexaColors.darkTextSec : NexaColors.lightTextSec),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active
                      ? (dark ? Colors.white : activeColor)
                      : (dark ? NexaColors.darkTextSec : NexaColors.lightTextSec),
                ),
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
