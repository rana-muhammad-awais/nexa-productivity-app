import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../widgets/glass.dart';
import '../../widgets/sheet.dart';

/// Set per-category monthly budget limits.
class SetBudgetSheet extends ConsumerStatefulWidget {
  const SetBudgetSheet({super.key});

  static Future<void> show(BuildContext context) => showNexaSheet(
        context,
        title: 'Set Monthly Budgets',
        initialSize: 0.7,
        builder: (_) => const SetBudgetSheet(),
      );

  @override
  ConsumerState<SetBudgetSheet> createState() => _SetBudgetSheetState();
}

class _SetBudgetSheetState extends ConsumerState<SetBudgetSheet> {
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    final data = ref.read(appStoreProvider).valueOrNull;
    final my = monthYearKey();
    final budgets = data?.budgets ?? [];
    _controllers = {
      for (final key in kCategories.keys)
        key: TextEditingController(
          text: budgets
              .firstWhere(
                (b) => b.category == key && b.monthYear == my,
                orElse: () => Budget(
                    id: '', category: key, monthlyLimit: 0, monthYear: my),
              )
              .monthlyLimit
              .toStringAsFixed(0),
        ),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final store = ref.read(appStoreProvider.notifier);
    final my = monthYearKey();
    for (final entry in _controllers.entries) {
      final v = double.tryParse(entry.value.text);
      if (v != null && v > 0) {
        store.setBudget(entry.key, v, my);
      }
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(appStoreProvider).valueOrNull?.user.currency ?? 'USD';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...kCategories.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: _controllers[e.key],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: e.value,
                  prefixText: '  ${kCurrencySymbols[currency] ?? '\$'} ',
                ),
              ),
            )),
        const SizedBox(height: 8),
        GradientButton('Save Budgets', onPressed: _save),
      ],
    );
  }
}
