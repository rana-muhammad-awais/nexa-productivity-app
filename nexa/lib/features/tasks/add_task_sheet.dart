import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/app_store.dart';
import '../../widgets/glass.dart';
import '../../widgets/sheet.dart';

/// Add-task sheet: NL quick-add + manual form.
class AddTaskSheet extends ConsumerStatefulWidget {
  final String? prefill;
  const AddTaskSheet({super.key, this.prefill});

  static Future<void> show(BuildContext context, {String? prefill}) =>
      showNexaSheet(
        context,
        title: 'New Task',
        initialSize: 0.78,
        builder: (_) => AddTaskSheet(prefill: prefill),
      );

  @override
  ConsumerState<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<AddTaskSheet> {
  final _raw = TextEditingController();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _date = TextEditingController();
  final _time = TextEditingController();
  final _tags = TextEditingController();
  String _priority = 'medium';
  String _recurrence = 'none';

  @override
  void dispose() {
    _raw.dispose();
    _title.dispose();
    _desc.dispose();
    _date.dispose();
    _time.dispose();
    _tags.dispose();
    super.dispose();
  }

  void _submit() {
    final store = ref.read(appStoreProvider.notifier);
    if (_raw.text.trim().isNotEmpty) {
      final p = parseNaturalLanguage(_raw.text);
      store.addTask(
        title: p.title.isEmpty ? _raw.text.trim() : p.title,
        dueDate: p.dueDate,
        dueTime: p.dueTime,
        priority: p.priority,
        tags: p.tags,
      );
    } else if (_title.text.trim().isNotEmpty) {
      store.addTask(
        title: _title.text.trim(),
        description: _desc.text.trim(),
        dueDate: _date.text.isEmpty ? null : _date.text,
        dueTime: _time.text.isEmpty ? null : _time.text,
        priority: _priority,
        recurrence: _recurrence == 'none' ? null : _recurrence,
        tags: _parseTags(_tags.text),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a task title')));
      return;
    }
    Navigator.of(context).maybePop();
  }

  List<String> _parseTags(String s) => s
      .split(',')
      .map((t) => t.trim().toLowerCase())
      .where((t) => t.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // NL quick add — featured at top
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(colors: [
              primaryColor(context).withOpacity(0.12),
              NexaColors.gradPrimary[2].withOpacity(0.08),
            ]),
            border: Border.all(color: primaryColor(context).withOpacity(0.3)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(LucideIcons.sparkles, size: 15, color: primaryColor(context)),
                const SizedBox(width: 6),
                Text('Smart Add',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: primaryColor(context))),
              ]),
              TextField(
                controller: _raw,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Pay rent tomorrow 6pm #bills',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.only(top: 8),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        kFieldGap,
        Row(children: [
          Expanded(child: Container(height: 1, color: borderColor(context))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('OR FILL MANUALLY',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: textSecondaryColor(context),
                    letterSpacing: 1)),
          ),
          Expanded(child: Container(height: 1, color: borderColor(context))),
        ]),
        kFieldGap,
        TextField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        kFieldGap,
        TextField(
          controller: _desc,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
        kFieldGap,
        Row(
          children: [
            Expanded(child: _DateField(label: 'Due date', controller: _date)),
            const SizedBox(width: 10),
            Expanded(child: _TimeField(controller: _time)),
          ],
        ),
        kFieldGap,
        Wrap(
          spacing: 8,
          children: kPriorities.map((p) {
            final active = p == _priority;
            return GestureDetector(
              onTap: () => setState(() => _priority = p),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: active
                      ? NexaColors.priorityColor(p).withOpacity(0.18)
                      : borderColor(context).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: active
                          ? NexaColors.priorityColor(p)
                          : Colors.transparent),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: NexaColors.priorityColor(p),
                        shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(kPriorityLabels[p] ?? p,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: active ? null : textSecondaryColor(context))),
                ]),
              ),
            );
          }).toList(),
        ),
        kFieldGap,
        DropdownButtonFormField<String>(
          value: _recurrence,
          decoration: const InputDecoration(labelText: 'Repeat'),
          items: kRecurrenceOptions.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: (v) => setState(() => _recurrence = v ?? 'none'),
        ),
        kFieldGap,
        TextField(
          controller: _tags,
          decoration: const InputDecoration(
              labelText: 'Tags', hintText: 'work, important'),
        ),
        const SizedBox(height: 20),
        GradientButton('Add Task', onPressed: _submit, icon: LucideIcons.plus),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _DateField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(LucideIcons.calendar, size: 18),
      ),
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (d != null) {
          controller.text =
              '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        }
      },
    );
  }
}

class _TimeField extends StatelessWidget {
  final TextEditingController controller;
  const _TimeField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Time',
        suffixIcon: Icon(LucideIcons.clock, size: 18),
      ),
      onTap: () async {
        final t = await showTimePicker(
            context: context, initialTime: TimeOfDay.now());
        if (t != null) {
          controller.text =
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
        }
      },
    );
  }
}
