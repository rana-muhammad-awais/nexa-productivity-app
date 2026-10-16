import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../widgets/glass.dart';
import '../../widgets/sheet.dart';

class TaskDetailSheet extends ConsumerStatefulWidget {
  final String taskId;
  const TaskDetailSheet({super.key, required this.taskId});

  static Future<void> show(BuildContext context, String taskId) => showNexaSheet(
        context,
        title: 'Task Details',
        initialSize: 0.88,
        builder: (_) => TaskDetailSheet(taskId: taskId),
      );

  @override
  ConsumerState<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends ConsumerState<TaskDetailSheet> {
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late final TextEditingController _date;
  late final TextEditingController _time;
  late final TextEditingController _tagInput;
  late String _priority;
  late String _recurrence;
  late List<SubTask> _subs;
  late List<String> _tags;
  final _subInput = TextEditingController();

  @override
  void initState() {
    super.initState();
    final t = _task;
    _title = TextEditingController(text: t.title);
    _desc = TextEditingController(text: t.description);
    _date = TextEditingController(text: t.dueDate ?? '');
    _time = TextEditingController(text: t.dueTime ?? '');
    _priority = t.priority;
    _recurrence = t.recurrence ?? 'none';
    _subs = t.subtasks.map((s) => SubTask(id: s.id, title: s.title, done: s.done)).toList();
    _tags = List.from(t.tags);
    _tagInput = TextEditingController();
  }

  Task get _task =>
      ref.read(appStoreProvider).requireValue.tasks.firstWhere((t) => t.id == widget.taskId);

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _date.dispose();
    _time.dispose();
    _subInput.dispose();
    _tagInput.dispose();
    super.dispose();
  }

  void _save() {
    NexaHaptics.success();
    ref.read(appStoreProvider.notifier).updateTask(
          widget.taskId,
          (t) => t.copyWith(
            title: _title.text.trim().isEmpty ? t.title : _title.text.trim(),
            description: _desc.text.trim(),
            dueDate: _date.text.isEmpty ? null : _date.text,
            dueTime: _time.text.isEmpty ? null : _time.text,
            priority: _priority,
            recurrence: _recurrence == 'none' ? null : _recurrence,
            subtasks: _subs,
            tags: _tags,
          ),
        );
    Navigator.of(context).maybePop();
  }

  void _addTag(String tag) {
    final cleaned = tag.trim().toLowerCase().replaceAll('#', '');
    if (cleaned.isNotEmpty && !_tags.contains(cleaned)) {
      NexaHaptics.light();
      setState(() => _tags.add(cleaned));
      _tagInput.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _task;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _desc,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description / Notes'),
          ),
          const SizedBox(height: 12),

          // Date & Time Row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _date,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Due date',
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
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _time,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    prefixIcon: Icon(LucideIcons.clock, size: 18),
                  ),
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (t != null) {
                      _time.text =
                          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Priority Selector
          Text(
            'Priority',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: kPriorities.map((p) {
              final active = p == _priority;
              return GestureDetector(
                onTap: () {
                  NexaHaptics.tick();
                  setState(() => _priority = p);
                },
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
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: NexaColors.priorityColor(p),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        kPriorityLabels[p] ?? p,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: active ? null : textSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Recurrence Dropdown
          DropdownButtonFormField<String>(
            value: _recurrence,
            decoration: const InputDecoration(
              labelText: 'Repeat / Recurrence',
              prefixIcon: Icon(LucideIcons.repeat, size: 18),
            ),
            items: const [
              DropdownMenuItem(value: 'none', child: Text('Does not repeat')),
              DropdownMenuItem(value: 'daily', child: Text('Repeats daily')),
              DropdownMenuItem(value: 'weekly', child: Text('Repeats weekly')),
              DropdownMenuItem(value: 'monthly', child: Text('Repeats monthly')),
              DropdownMenuItem(value: 'yearly', child: Text('Repeats yearly')),
            ],
            onChanged: (v) => setState(() => _recurrence = v ?? 'none'),
          ),
          const SizedBox(height: 14),

          // Tags Manager
          Text(
            'Tags',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ..._tags.map((tag) => Chip(
                    label: Text('#$tag'),
                    deleteIcon: const Icon(LucideIcons.x, size: 14),
                    onDeleted: () => setState(() => _tags.remove(tag)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  )),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagInput,
                  decoration: const InputDecoration(
                    hintText: 'Add tag (e.g. work, personal)...',
                    isDense: true,
                  ),
                  onSubmitted: _addTag,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.plus, size: 20),
                onPressed: () => _addTag(_tagInput.text),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Subtasks Manager
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtasks (${_subs.where((s) => s.done).length}/${_subs.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textSecondaryColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ..._subs.map((s) => Row(
                children: [
                  Checkbox(
                    value: s.done,
                    onChanged: (v) => setState(() {
                      final i = _subs.indexOf(s);
                      _subs[i] = s.copyWith(done: v ?? false);
                    }),
                    shape: const CircleBorder(),
                  ),
                  Expanded(
                    child: Text(
                      s.title,
                      style: TextStyle(
                        decoration: s.done ? TextDecoration.lineThrough : null,
                        color: s.done ? textSecondaryColor(context) : null,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 16),
                    onPressed: () =>
                        setState(() => _subs.removeWhere((x) => x.id == s.id)),
                  ),
                ],
              )),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _subInput,
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Add a subtask...',
                  ),
                  onSubmitted: (v) {
                    if (v.trim().isNotEmpty) {
                      setState(() => _subs.add(
                          SubTask(id: const Uuid().v4(), title: v.trim())));
                      _subInput.clear();
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.plus, size: 20),
                onPressed: () {
                  if (_subInput.text.trim().isNotEmpty) {
                    setState(() => _subs.add(SubTask(
                        id: const Uuid().v4(), title: _subInput.text.trim())));
                    _subInput.clear();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Metadata Footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surfaceColor(context).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Created: ${formatDate(t.createdAt.substring(0, 10))}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: textSecondaryColor(context),
                  ),
                ),
                if (t.completedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Completed: ${formatDate(t.completedAt!.substring(0, 10))}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: NexaColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (t.linkedNoteId != null) ...[
                  const SizedBox(height: 2),
                  const Text(
                    '📝 Linked to a note in your vault',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: NexaColors.lightPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  'Save Task',
                  onPressed: _save,
                  icon: LucideIcons.check,
                ),
              ),
              const SizedBox(width: 10),
              GhostButton(
                'Delete',
                danger: true,
                icon: LucideIcons.trash2,
                onPressed: () {
                  ref.read(appStoreProvider.notifier).deleteTask(widget.taskId);
                  Navigator.of(context).maybePop();
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}
