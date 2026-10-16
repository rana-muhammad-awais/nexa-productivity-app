import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/animations.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../widgets/glass.dart';
import '../../widgets/store_guard.dart';
import '../../widgets/tiles.dart';
import 'add_task_sheet.dart';
import 'focus_timer_page.dart';
import 'habits_page.dart';
import 'task_detail_sheet.dart';

enum _View { list, kanban, calendar, focus, habits }
enum _Filter { all, today, upcoming, overdue, completed }

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  static Future<void> openAdder(BuildContext context) =>
      AddTaskSheet.show(context);

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  _View _view = _View.list;
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    return StoreGuard(
      child: (data) {
        final today = todayIsoDate();
        var tasks = [...data.tasks]..sort((a, b) => a.order.compareTo(b.order));

        // Filter tasks
        tasks = switch (_filter) {
          _Filter.today => tasks.where((t) => t.dueDate == today).toList(),
          _Filter.upcoming => tasks
              .where((t) =>
                  !t.isCompleted &&
                  t.dueDate != null &&
                  t.dueDate!.compareTo(today) > 0)
              .toList(),
          _Filter.overdue =>
            tasks.where((t) => isOverdue(t.dueDate, t.isCompleted)).toList(),
          _Filter.completed => tasks.where((t) => t.isCompleted).toList(),
          _Filter.all => tasks,
        };

        return Column(
          children: [
            _headerControls,
            Expanded(
              child: switch (_view) {
                _View.list => tasks.isEmpty
                    ? _empty()
                    : _ListView(allTasks: data.tasks, filteredTasks: tasks),
                _View.kanban => tasks.isEmpty
                    ? _empty()
                    : _KanbanView(tasks: tasks),
                _View.calendar => _CalendarView(tasks: data.tasks),
                _View.focus => const FocusTimerPage(),
                _View.habits => const HabitsPage(),
              },
            ),
          ],
        );
      },
    );
  }

  Widget _empty() => EmptyState(
        icon: LucideIcons.checkSquare,
        title: _filter == _Filter.all ? 'No tasks yet' : 'No matching tasks',
        text:
            'Try adding a task with smart natural language like "Buy groceries tomorrow #shopping".',
        buttonLabel: 'Add Task',
        onButton: () => AddTaskSheet.show(context),
      );

  Widget get _headerControls => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Column(
          children: [
            // View toggle (List, Board, Calendar, Focus, Habits)
            GlassCard(
              blur: 20,
              radius: 16,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _seg('List', _View.list, LucideIcons.list),
                    _seg('Board', _View.kanban, LucideIcons.columns),
                    _seg('Calendar', _View.calendar, LucideIcons.calendar),
                    _seg('Focus', _View.focus, LucideIcons.timer),
                    _seg('Habits', _View.habits, LucideIcons.sparkles),
                  ],
                ),
              ),
            ),

            // Filter chips horizontal scroll (only in list view)
            if (_view == _View.list)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _Filter.values.map((f) {
                    final active = _filter == f;
                    final label = capitalize(f.name);
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: active,
                        onSelected: (_) {
                          NexaHaptics.tick();
                          setState(() => _filter = f);
                        },
                        selectedColor: primaryColor(context),
                        labelStyle: TextStyle(
                          color:
                              active ? Colors.white : textSecondaryColor(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      );

  Widget _seg(String label, _View v, IconData icon) {
    final active = _view == v;
    return GestureDetector(
      onTap: () {
        NexaHaptics.tick();
        setState(() => _view = v);
      },
      child: AnimatedContainer(
        duration: NexaAnim.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(colors: NexaColors.gradPrimary)
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: active ? Colors.white : textSecondaryColor(context)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : textSecondaryColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── List view with productivity stats & multi-select mode ────────────────
class _ListView extends ConsumerStatefulWidget {
  final List<Task> allTasks;
  final List<Task> filteredTasks;

  const _ListView({required this.allTasks, required this.filteredTasks});

  @override
  ConsumerState<_ListView> createState() => _ListViewState();
}

class _ListViewState extends ConsumerState<_ListView> {
  final Set<String> _selectedIds = {};
  bool _isMultiSelect = false;

  void _toggleSelection(String id) {
    NexaHaptics.tick();
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isMultiSelect = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _completeSelected() {
    NexaHaptics.success();
    final store = ref.read(appStoreProvider.notifier);
    for (final id in _selectedIds) {
      final task = widget.allTasks.where((t) => t.id == id).firstOrNull;
      if (task != null && !task.isCompleted) {
        store.toggleTask(id);
      }
    }
    setState(() {
      _selectedIds.clear();
      _isMultiSelect = false;
    });
  }

  void _deleteSelected() {
    NexaHaptics.medium();
    final store = ref.read(appStoreProvider.notifier);
    for (final id in _selectedIds) {
      store.deleteTask(id);
    }
    setState(() {
      _selectedIds.clear();
      _isMultiSelect = false;
    });
  }

  void _showTaskMenu(BuildContext context, Task task) {
    NexaHaptics.medium();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(LucideIcons.fileText, size: 20),
              title: const Text('View / Edit Details'),
              onTap: () {
                Navigator.pop(ctx);
                TaskDetailSheet.show(context, task.id);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.copy,
                  size: 20, color: NexaColors.lightPrimary),
              title: const Text('Duplicate Task'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(appStoreProvider.notifier).duplicateTask(task.id);
                NexaHaptics.success();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task cloned successfully')),
                );
              },
            ),
            ListTile(
              leading: Icon(
                task.isCompleted ? LucideIcons.rotateCcw : LucideIcons.checkCheck,
                size: 20,
                color: NexaColors.success,
              ),
              title: Text(task.isCompleted ? 'Mark as Incomplete' : 'Complete Task'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(appStoreProvider.notifier).toggleTask(task.id);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2,
                  size: 20, color: NexaColors.danger),
              title: const Text('Delete Task',
                  style: TextStyle(color: NexaColors.danger)),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(appStoreProvider.notifier).deleteTask(task.id);
                NexaHaptics.medium();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.filteredTasks.where((t) => !t.isCompleted).toList();
    final done = widget.filteredTasks.where((t) => t.isCompleted).toList();
    final store = ref.read(appStoreProvider.notifier);

    // Productivity Statistics
    final totalTasks = widget.allTasks.length;
    final totalDone = widget.allTasks.where((t) => t.isCompleted).length;
    final completionPct =
        totalTasks > 0 ? ((totalDone / totalTasks) * 100).round() : 0;
    final userStreak = ref.watch(appStoreProvider).valueOrNull?.user.streak ?? 0;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
          children: [
            // Productivity Summary Banner
            if (!_isMultiSelect) ...[
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Productivity Score',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textSecondaryColor(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$completionPct% Completed',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$totalDone of $totalTasks total tasks done',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondaryColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: NexaColors.warning.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.flame,
                              size: 16, color: NexaColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            '$userStreak day streak',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: NexaColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],

            if (active.isNotEmpty) ...[
              SectionHeader('Active · ${active.length}'),
              ...active.asMap().entries.map((entry) {
                final i = entry.key;
                final task = entry.value;
                final isSelected = _selectedIds.contains(task.id);

                return StaggeredFadeIn(
                  index: i,
                  child: Dismissible(
                    key: ValueKey(task.id),
                    background: _swipeBg(
                        alignLeft: true,
                        color: NexaColors.success,
                        icon: LucideIcons.check),
                    secondaryBackground: _swipeBg(
                        alignLeft: false,
                        color: NexaColors.danger,
                        icon: LucideIcons.trash2),
                    onDismissed: (dir) {
                      NexaHaptics.swipeAction();
                      if (dir == DismissDirection.startToEnd) {
                        store.toggleTask(task.id);
                      } else {
                        store.deleteTask(task.id);
                      }
                    },
                    child: GestureDetector(
                      onLongPress: () {
                        if (!_isMultiSelect) {
                          _showTaskMenu(context, task);
                        } else {
                          _toggleSelection(task.id);
                        }
                      },
                      child: Row(
                        children: [
                          if (_isMultiSelect)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleSelection(task.id),
                              ),
                            ),
                          Expanded(
                            child: TaskTile(
                              task: task,
                              onToggle: () {
                                if (_isMultiSelect) {
                                  _toggleSelection(task.id);
                                } else {
                                  NexaHaptics.success();
                                  store.toggleTask(task.id);
                                  if (!task.isCompleted &&
                                      task.recurrence != null &&
                                      task.recurrence != 'none') {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Task completed! Next ${task.recurrence} occurrence scheduled.'),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              },
                              onTap: () {
                                if (_isMultiSelect) {
                                  _toggleSelection(task.id);
                                } else {
                                  TaskDetailSheet.show(context, task.id);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],

            if (done.isNotEmpty) ...[
              SectionHeader('Completed · ${done.length}'),
              ...done.asMap().entries.map((entry) {
                final i = entry.key;
                final task = entry.value;
                final isSelected = _selectedIds.contains(task.id);

                return StaggeredFadeIn(
                  index: i,
                  child: Dismissible(
                    key: ValueKey(task.id),
                    secondaryBackground: _swipeBg(
                        alignLeft: false,
                        color: NexaColors.danger,
                        icon: LucideIcons.trash2),
                    onDismissed: (_) {
                      NexaHaptics.swipeAction();
                      store.deleteTask(task.id);
                    },
                    child: Row(
                      children: [
                        if (_isMultiSelect)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggleSelection(task.id),
                            ),
                          ),
                        Expanded(
                          child: TaskTile(
                            task: task,
                            onToggle: () => store.toggleTask(task.id),
                            onTap: () => TaskDetailSheet.show(context, task.id),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),

        // Multi-select Bottom Floating Bar
        if (_isMultiSelect)
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    '${_selectedIds.length} selected',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _completeSelected,
                    icon: const Icon(LucideIcons.checkCheck, size: 16),
                    label: const Text('Complete'),
                  ),
                  TextButton.icon(
                    onPressed: _deleteSelected,
                    icon: const Icon(LucideIcons.trash2,
                        size: 16, color: NexaColors.danger),
                    label: const Text('Delete',
                        style: TextStyle(color: NexaColors.danger)),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 18),
                    onPressed: () => setState(() {
                      _selectedIds.clear();
                      _isMultiSelect = false;
                    }),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _swipeBg({
    required bool alignLeft,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color),
    );
  }
}

// ─── Kanban board view ───────────────────────────────────────────────────
class _KanbanView extends ConsumerWidget {
  final List<Task> tasks;
  const _KanbanView({required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = [
      ('Urgent', tasks.where((t) => t.priority == 'urgent').toList(), 'urgent'),
      ('High', tasks.where((t) => t.priority == 'high').toList(), 'high'),
      ('Medium', tasks.where((t) => t.priority == 'medium').toList(), 'medium'),
      ('Low', tasks.where((t) => t.priority == 'low').toList(), 'low'),
    ];

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: columns.map((col) {
        final (title, colTasks, priority) = col;
        return _KanbanColumn(
          title: title,
          tasks: colTasks,
          priority: priority,
        );
      }).toList(),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String title;
  final List<Task> tasks;
  final String priority;

  const _KanbanColumn({
    required this.title,
    required this.tasks,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    final col = NexaColors.priorityColor(priority);

    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(width: 6),
                Text('${tasks.length}',
                    style: TextStyle(
                        color: textSecondaryColor(context), fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (ctx, i) {
                  final t = tasks[i];
                  return StaggeredFadeIn(
                    index: i,
                    child: GestureDetector(
                      onTap: () => TaskDetailSheet.show(context, t.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: col.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: col.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.title,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600)),
                            if (t.dueDate != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.calendar,
                                        size: 11,
                                        color: textSecondaryColor(context)),
                                    const SizedBox(width: 4),
                                    Text(formatDate(t.dueDate),
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: textSecondaryColor(context))),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Interactive Calendar view with month navigation & day task viewer ───
class _CalendarView extends ConsumerStatefulWidget {
  final List<Task> tasks;
  const _CalendarView({required this.tasks});

  @override
  ConsumerState<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<_CalendarView> {
  late DateTime _focusedMonth;
  late String _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDate = todayIsoDate();
  }

  void _prevMonth() {
    NexaHaptics.tick();
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    NexaHaptics.tick();
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final firstWeekday = DateTime(year, month, 1).weekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final todayStr = todayIsoDate();

    final taskDates = widget.tasks
        .where((t) => t.dueDate != null)
        .map((t) => t.dueDate!)
        .toSet();

    final dayTasks = widget.tasks
        .where((t) => t.dueDate == _selectedDate)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
      children: [
        GlassCard(
          margin: const EdgeInsets.only(top: 6),
          blur: 16,
          radius: 20,
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // Month navigation header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.chevronLeft, size: 20),
                    onPressed: _prevMonth,
                  ),
                  Text(_monthLabel(_focusedMonth),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  IconButton(
                    icon: const Icon(LucideIcons.chevronRight, size: 20),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Weekday Letters
              Row(
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                    .map((d) => Expanded(
                          child: Center(
                            child: Text(d,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: textSecondaryColor(context),
                                    fontWeight: FontWeight.w600)),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),

              // Calendar Days Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: firstWeekday + daysInMonth,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7, mainAxisSpacing: 6, crossAxisSpacing: 6),
                itemBuilder: (ctx, i) {
                  if (i < firstWeekday) return const SizedBox();
                  final day = i - firstWeekday + 1;
                  final dateStr =
                      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                  final isToday = dateStr == todayStr;
                  final isSelected = dateStr == _selectedDate;
                  final hasTask = taskDates.contains(dateStr);

                  return GestureDetector(
                    onTap: () {
                      NexaHaptics.tick();
                      setState(() => _selectedDate = dateStr);
                    },
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: NexaColors.gradPrimary)
                              : null,
                          color: !isSelected && isToday
                              ? primaryColor(context).withOpacity(0.18)
                              : (!isSelected && hasTask
                                  ? primaryColor(context).withOpacity(0.08)
                                  : null),
                          shape: BoxShape.circle,
                          border: isToday && !isSelected
                              ? Border.all(
                                  color: primaryColor(context), width: 1.5)
                              : null,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected || isToday || hasTask
                                    ? FontWeight.w800
                                    : FontWeight.w400,
                                color: isSelected
                                    ? Colors.white
                                    : (isToday
                                        ? primaryColor(context)
                                        : null),
                              ),
                            ),
                            if (hasTask && !isSelected)
                              Positioned(
                                bottom: 4,
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: primaryColor(context),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Tasks scheduled on selected date
        const SizedBox(height: 10),
        SectionHeader('Scheduled on $_selectedDate · ${dayTasks.length}'),

        if (dayTasks.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'No tasks scheduled for this day',
                style: TextStyle(
                  color: textSecondaryColor(context),
                  fontSize: 13,
                ),
              ),
            ),
          )
        else
          ...dayTasks.map((t) => TaskTile(
                task: t,
                onToggle: () =>
                    ref.read(appStoreProvider.notifier).toggleTask(t.id),
                onTap: () => TaskDetailSheet.show(context, t.id),
              )),
      ],
    );
  }

  String _monthLabel(DateTime d) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${names[d.month]} ${d.year}';
  }
}
