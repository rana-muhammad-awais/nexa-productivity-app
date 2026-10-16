import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../core/utils.dart';
import '../services/notifications.dart';
import 'models.dart';

/// Single source of truth — the Riverpod equivalent of `js/store.js`.
///
/// Every mutation builds a BRAND-NEW [AppData] with new list instances and
/// assigns it to [state]. This is mandatory: Riverpod compares state by
/// reference; mutating lists in place meant listeners never rebuilt.
const _kStorageKey = 'nexa-data-v1';
const _uuid = Uuid();

class AppStore extends AsyncNotifier<AppData> {
  SharedPreferences? _prefs;
  Timer? _debounce;

  @override
  Future<AppData> build() async {
    _prefs = await SharedPreferences.getInstance();
    final d = _load() ?? const AppData();
    unawaited(NotificationService.instance.rescheduleAll(d));
    return d;
  }

  AppData? _load() {
    final raw = _prefs?.getString(_kStorageKey);
    if (raw == null) return null;
    try {
      return AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null; // corrupt data → keep defaults
    }
  }

  /// Debounced persist — coalesce rapid writes into one disk hit.
  void _persist(AppData data) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _prefs?.setString(_kStorageKey, jsonEncode(data.toJson()));
    });
  }

  /// Apply a transform and persist.
  void _commit(AppData Function(AppData current) transform) {
    final next = transform(state.requireValue);
    state = AsyncData(next);
    _persist(next);
  }

  AppData get data => state.requireValue;

  // Helper for deep-copy commits
  AppData _copy(AppData d, {
    UserPrefs? user,
    List<Task>? tasks,
    List<Note>? notes,
    List<NoteFolder>? noteFolders,
    List<Expense>? expenses,
    List<Account>? accounts,
    List<Budget>? budgets,
    List<Resource>? resources,
    List<FocusSession>? focusSessions,
    List<KhataPerson>? khataPersons,
    List<KhataEntry>? khataEntries,
    List<Habit>? habits,
    List<HabitCompletion>? habitCompletions,
  }) => AppData(
    user: user ?? d.user,
    tasks: tasks ?? d.tasks,
    notes: notes ?? d.notes,
    noteFolders: noteFolders ?? d.noteFolders,
    expenses: expenses ?? d.expenses,
    accounts: accounts ?? d.accounts,
    budgets: budgets ?? d.budgets,
    resources: resources ?? d.resources,
    focusSessions: focusSessions ?? d.focusSessions,
    khataPersons: khataPersons ?? d.khataPersons,
    khataEntries: khataEntries ?? d.khataEntries,
    habits: habits ?? d.habits,
    habitCompletions: habitCompletions ?? d.habitCompletions,
  );

  // ─── User prefs ───────────────────────────────────────────────────────
  void updateUser(UserPrefs Function(UserPrefs) fn) =>
      _commit((d) => _copy(d, user: fn(d.user)));

  // ─── Tasks ────────────────────────────────────────────────────────────
  Task addTask({
    required String title,
    String description = '',
    String? dueDate,
    String? dueTime,
    String priority = 'medium',
    List<String>? tags,
    String? listId,
    List<SubTask> subtasks = const [],
    String? recurrence,
    String? linkedNoteId,
  }) {
    final task = Task(
      id: _uuid.v4(),
      title: title,
      description: description,
      dueDate: dueDate,
      dueTime: dueTime,
      priority: priority,
      tags: tags ?? const [],
      listId: listId ?? 'inbox',
      subtasks: subtasks,
      recurrence: recurrence,
      linkedNoteId: linkedNoteId,
      order: state.requireValue.tasks.length,
      createdAt: DateTime.now().toIso8601String(),
    );
    _commit((d) => _copy(d, tasks: [task, ...d.tasks]));
    if (task.dueDate != null) {
      NotificationService.instance.scheduleTaskReminder(
        taskId: task.id,
        title: task.title,
        dueDate: task.dueDate,
        dueTime: task.dueTime,
      );
    }
    return task;
  }

  void updateTask(String id, Task Function(Task) fn) {
    _commit((d) => _copy(d,
        tasks: d.tasks.map((t) => t.id == id ? fn(t) : t).toList()));
    final updated = state.requireValue.tasks.firstWhere((t) => t.id == id);
    if (updated.isCompleted || updated.dueDate == null) {
      NotificationService.instance.cancelTaskReminder(id);
    } else {
      NotificationService.instance.scheduleTaskReminder(
        taskId: updated.id,
        title: updated.title,
        dueDate: updated.dueDate,
        dueTime: updated.dueTime,
      );
    }
  }

  void toggleTask(String id) {
    final t = state.requireValue.tasks.firstWhere((x) => x.id == id);
    final nowCompleted = !t.isCompleted;
    updateTask(id, (x) => x.copyWith(
      isCompleted: nowCompleted,
      completedAt: nowCompleted ? DateTime.now().toIso8601String() : null,
    ));
    if (nowCompleted) {
      _bumpStreak();
      NotificationService.instance.cancelTaskReminder(id);

      // Auto-generate next recurring instance if repeat rule is active
      if (t.recurrence != null && t.recurrence != 'none') {
        _spawnNextRecurringTask(t);
      }
    }
  }

  void _spawnNextRecurringTask(Task t) {
    final nextDate = _calculateNextRecurrenceDate(t.dueDate, t.recurrence!);
    final nextTask = Task(
      id: _uuid.v4(),
      title: t.title,
      description: t.description,
      dueDate: nextDate,
      dueTime: t.dueTime,
      priority: t.priority,
      tags: List.from(t.tags),
      listId: t.listId,
      subtasks: t.subtasks
          .map((s) => SubTask(id: _uuid.v4(), title: s.title, done: false))
          .toList(),
      recurrence: t.recurrence,
      linkedNoteId: t.linkedNoteId,
      order: state.requireValue.tasks.length,
      createdAt: DateTime.now().toIso8601String(),
    );
    _commit((d) => _copy(d, tasks: [nextTask, ...d.tasks]));
    if (nextTask.dueDate != null) {
      NotificationService.instance.scheduleTaskReminder(
        taskId: nextTask.id,
        title: nextTask.title,
        dueDate: nextTask.dueDate,
        dueTime: nextTask.dueTime,
      );
    }
  }

  String _calculateNextRecurrenceDate(String? baseDateStr, String recurrence) {
    DateTime base;
    if (baseDateStr != null) {
      base = DateTime.tryParse(baseDateStr) ?? DateTime.now();
    } else {
      base = DateTime.now();
    }

    final today = DateTime.now();
    final todayClean = DateTime(today.year, today.month, today.day);
    DateTime candidate = DateTime(base.year, base.month, base.day);

    switch (recurrence) {
      case 'daily':
        candidate = candidate.add(const Duration(days: 1));
        while (candidate.isBefore(todayClean)) {
          candidate = candidate.add(const Duration(days: 1));
        }
        break;
      case 'weekly':
        candidate = candidate.add(const Duration(days: 7));
        while (candidate.isBefore(todayClean)) {
          candidate = candidate.add(const Duration(days: 7));
        }
        break;
      case 'monthly':
        int nextMonth = candidate.month + 1;
        int nextYear = candidate.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }
        final daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        final targetDay = candidate.day > daysInNextMonth ? daysInNextMonth : candidate.day;
        candidate = DateTime(nextYear, nextMonth, targetDay);
        while (candidate.isBefore(todayClean)) {
          nextMonth = candidate.month + 1;
          nextYear = candidate.year;
          if (nextMonth > 12) {
            nextMonth = 1;
            nextYear++;
          }
          final daysInMonth = DateTime(nextYear, nextMonth + 1, 0).day;
          final day = candidate.day > daysInMonth ? daysInMonth : candidate.day;
          candidate = DateTime(nextYear, nextMonth, day);
        }
        break;
      case 'yearly':
        candidate = DateTime(candidate.year + 1, candidate.month, candidate.day);
        while (candidate.isBefore(todayClean)) {
          candidate = DateTime(candidate.year + 1, candidate.month, candidate.day);
        }
        break;
      default:
        candidate = candidate.add(const Duration(days: 1));
    }

    return candidate.toIso8601String().substring(0, 10);
  }

  void deleteTask(String id) {
    NotificationService.instance.cancelTaskReminder(id);
    _commit((d) => _copy(d, tasks: d.tasks.where((t) => t.id != id).toList()));
  }

  Task duplicateTask(String id) {
    final original = state.requireValue.tasks.firstWhere((t) => t.id == id);
    final copy = Task(
      id: _uuid.v4(),
      title: '${original.title} (Copy)',
      description: original.description,
      dueDate: original.dueDate,
      dueTime: original.dueTime,
      priority: original.priority,
      tags: List.from(original.tags),
      listId: original.listId,
      subtasks: original.subtasks
          .map((s) => SubTask(id: _uuid.v4(), title: s.title, done: false))
          .toList(),
      recurrence: original.recurrence,
      linkedNoteId: original.linkedNoteId,
      order: state.requireValue.tasks.length,
      createdAt: DateTime.now().toIso8601String(),
    );
    _commit((d) => _copy(d, tasks: [copy, ...d.tasks]));
    return copy;
  }

  void reorderTasks(List<String> orderedIds) => _commit((d) {
        final byId = {for (final t in d.tasks) t.id: t};
        final reordered = orderedIds
            .where((id) => byId.containsKey(id))
            .toList()
            .asMap()
            .entries
            .map((e) => byId[e.value]!.copyWith(order: e.key))
            .toList();
        return _copy(d, tasks: reordered);
      });

  void toggleSubtask(String taskId, String subtaskId) => updateTask(
      taskId,
      (t) => t.copyWith(
          subtasks: t.subtasks
              .map((s) => s.id == subtaskId ? s.copyWith(done: !s.done) : s)
              .toList()));

  void _bumpStreak() {
    final today = todayIsoDate();
    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
    final u = state.requireValue.user;
    if (u.lastCompletionDate == today) return;
    final newStreak = u.lastCompletionDate == yesterday ? u.streak + 1 : 1;
    updateUser((p) => p.copyWith(streak: newStreak, lastCompletionDate: today));
  }

  // ─── Notes ────────────────────────────────────────────────────────────
  Note addNote({
    String title = 'Untitled',
    String body = '',
    String folderId = 'inbox',
    List<String>? tags,
    bool pinned = false,
    String? color,
  }) {
    final now = DateTime.now().toIso8601String();
    final note = Note(
      id: _uuid.v4(),
      title: title,
      body: body,
      folderId: folderId,
      tags: tags ?? const [],
      pinned: pinned,
      color: color,
      createdAt: now,
      updatedAt: now,
    );
    _commit((d) => _copy(d, notes: [note, ...d.notes]));
    return note;
  }

  void updateNote(String id, Note Function(Note) fn) =>
      _commit((d) => _copy(d,
          notes: d.notes.map((n) => n.id == id ? fn(n) : n).toList()));

  void deleteNote(String id) =>
      _commit((d) => _copy(d, notes: d.notes.where((n) => n.id != id).toList()));

  void togglePinNote(String id) => updateNote(
      id, (n) => n.copyWith(pinned: !n.pinned));

  // ─── Note Folders ─────────────────────────────────────────────────────
  void addNoteFolder(String name) {
    final folder = NoteFolder(_uuid.v4(), name);
    _commit((d) => _copy(d, noteFolders: [...d.noteFolders, folder]));
  }

  void deleteNoteFolder(String id) => _commit((d) {
    // Move notes from deleted folder to inbox
    final updatedNotes = d.notes.map((n) {
      if (n.folderId == id) return n.copyWith(folderId: 'inbox');
      return n;
    }).toList();
    return _copy(d,
        noteFolders: d.noteFolders.where((f) => f.id != id).toList(),
        notes: updatedNotes);
  });

  void renameNoteFolder(String id, String name) => _commit((d) => _copy(d,
      noteFolders: d.noteFolders
          .map((f) => f.id == id ? NoteFolder(f.id, name) : f)
          .toList()));

  Note duplicateNote(String id) {
    final original = state.requireValue.notes.firstWhere((n) => n.id == id);
    final now = DateTime.now().toIso8601String();
    final copy = Note(
      id: _uuid.v4(),
      title: '${original.title} (Copy)',
      body: original.body,
      folderId: original.folderId,
      tags: List.from(original.tags),
      pinned: false,
      color: original.color,
      createdAt: now,
      updatedAt: now,
    );
    _commit((d) => _copy(d, notes: [copy, ...d.notes]));
    return copy;
  }

  // ─── Expenses ─────────────────────────────────────────────────────────
  Expense addExpense({
    required double amount,
    String type = 'expense',
    String category = 'other',
    String accountId = 'cash',
    String note = '',
    String? date,
    bool isRecurring = false,
    String? linkedTaskId,
  }) {
    final exp = Expense(
      id: _uuid.v4(),
      amount: amount,
      type: type,
      category: category,
      accountId: accountId,
      note: note,
      date: date ?? todayIsoDate(),
      isRecurring: isRecurring,
      linkedTaskId: linkedTaskId,
      createdAt: DateTime.now().toIso8601String(),
    );
    _commit((d) => _copy(d, expenses: [exp, ...d.expenses]));
    return exp;
  }

  void deleteExpense(String id) =>
      _commit((d) => _copy(d,
          expenses: d.expenses.where((e) => e.id != id).toList()));

  void updateExpense(String id, Expense Function(Expense) fn) =>
      _commit((d) => _copy(d,
          expenses: d.expenses.map((e) => e.id == id ? fn(e) : e).toList()));

  void setBudget(String category, double limit, String monthYear) =>
      _commit((d) {
        final idx = d.budgets.indexWhere(
            (b) => b.category == category && b.monthYear == monthYear);
        final budget = Budget(
          id: idx >= 0 ? d.budgets[idx].id : _uuid.v4(),
          category: category,
          monthlyLimit: limit,
          monthYear: monthYear,
        );
        final budgets = [...d.budgets];
        if (idx >= 0) {
          budgets[idx] = budget;
        } else {
          budgets.add(budget);
        }
        return _copy(d, budgets: budgets);
      });

  // ─── Resources ────────────────────────────────────────────────────────
  Resource addResource(Resource r) {
    final created = Resource(
      id: _uuid.v4(),
      type: r.type,
      name: r.name,
      details: r.details,
      fileUrl: r.fileUrl,
      renewalDate: r.renewalDate,
      tags: r.tags,
      quantity: r.quantity,
      lowStockThreshold: r.lowStockThreshold,
      createdAt: DateTime.now().toIso8601String(),
    );
    _commit((d) => _copy(d, resources: [created, ...d.resources]));
    if (created.renewalDate != null && created.renewalDate!.isNotEmpty) {
      NotificationService.instance.scheduleRenewalReminder(
        resourceId: created.id,
        name: created.name,
        renewalDate: created.renewalDate,
        isExpiry: created.type == ResourceType.document,
      );
    }
    return created;
  }

  void updateResource(String id, Resource Function(Resource) fn) =>
      _commit((d) {
        final updatedList = d.resources.map((r) {
          if (r.id == id) {
            final updated = fn(r);
            if (updated.renewalDate != null && updated.renewalDate!.isNotEmpty) {
              NotificationService.instance.scheduleRenewalReminder(
                resourceId: updated.id,
                name: updated.name,
                renewalDate: updated.renewalDate,
                isExpiry: updated.type == ResourceType.document,
              );
            } else {
              NotificationService.instance.cancelRenewalReminder(updated.id);
            }
            return updated;
          }
          return r;
        }).toList();
        return _copy(d, resources: updatedList);
      });

  void deleteResource(String id) {
    NotificationService.instance.cancelRenewalReminder(id);
    _commit((d) => _copy(d,
        resources: d.resources.where((r) => r.id != id).toList()));
  }

  // ─── Khata (Hisaab-Kitaab) ────────────────────────────────────────────
  KhataPerson addKhataPerson({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) {
    final person = KhataPerson(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
      createdAt: DateTime.now().toIso8601String(),
    );
    _commit((d) => _copy(d, khataPersons: [person, ...d.khataPersons]));
    return person;
  }

  void updateKhataPerson(String id, KhataPerson Function(KhataPerson) fn) =>
      _commit((d) => _copy(d,
          khataPersons:
              d.khataPersons.map((p) => p.id == id ? fn(p) : p).toList()));

  void deleteKhataPerson(String id) => _commit((d) => _copy(d,
      khataPersons: d.khataPersons.where((p) => p.id != id).toList(),
      khataEntries: d.khataEntries.where((e) => e.personId != id).toList()));

  KhataEntry addKhataEntry({
    required String personId,
    required double amount,
    String type = 'given',
    String description = '',
    String? date,
  }) {
    final entry = KhataEntry(
      id: _uuid.v4(),
      personId: personId,
      amount: amount,
      type: type,
      description: description,
      date: date ?? todayIsoDate(),
      createdAt: DateTime.now().toIso8601String(),
    );
    _commit((d) => _copy(d, khataEntries: [entry, ...d.khataEntries]));
    return entry;
  }

  void deleteKhataEntry(String id) =>
      _commit((d) => _copy(d,
          khataEntries: d.khataEntries.where((e) => e.id != id).toList()));

  void updateKhataEntry(String id, KhataEntry Function(KhataEntry) fn) =>
      _commit((d) => _copy(d,
          khataEntries:
              d.khataEntries.map((e) => e.id == id ? fn(e) : e).toList()));

  /// Net balance for a person: positive = they owe you, negative = you owe them.
  double khataBalance(String personId) {
    return state.requireValue.khataEntries
        .where((e) => e.personId == personId)
        .fold(0.0, (sum, e) => e.type == 'given' ? sum + e.amount : sum - e.amount);
  }

  /// Total receivable across all persons (positive balances).
  double totalReceivable() {
    final d = state.requireValue;
    double total = 0;
    for (final p in d.khataPersons) {
      final bal = khataBalance(p.id);
      if (bal > 0) total += bal;
    }
    return total;
  }

  /// Total payable across all persons (negative balances, returned as positive).
  double totalPayable() {
    final d = state.requireValue;
    double total = 0;
    for (final p in d.khataPersons) {
      final bal = khataBalance(p.id);
      if (bal < 0) total += bal.abs();
    }
    return total;
  }

  // ─── Focus Sessions (legacy — kept for data compat) ────────────────────
  FocusSession startFocusSession({
    String type = 'focus',
    int durationMinutes = 25,
    String? linkedTaskId,
  }) {
    final session = FocusSession(
      id: _uuid.v4(),
      type: type,
      durationMinutes: durationMinutes,
      linkedTaskId: linkedTaskId,
      startedAt: DateTime.now().toIso8601String(),
    );
    _commit((d) => _copy(d, focusSessions: [session, ...d.focusSessions]));
    return session;
  }

  void completeFocusSession(String id) =>
      _commit((d) => _copy(d,
          focusSessions: d.focusSessions
              .map((s) => s.id == id
                  ? s.copyWith(
                      completed: true,
                      completedAt: DateTime.now().toIso8601String())
                  : s)
              .toList()));

  void deleteFocusSession(String id) =>
      _commit((d) => _copy(d,
          focusSessions:
              d.focusSessions.where((s) => s.id != id).toList()));

  int todayFocusMinutes() {
    final today = todayIsoDate();
    return state.requireValue.focusSessions
        .where((s) =>
            s.completed &&
            s.type == 'focus' &&
            s.startedAt.startsWith(today))
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  int weekFocusSessions() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final ws = weekStart.toIso8601String().substring(0, 10);
    return state.requireValue.focusSessions
        .where((s) =>
            s.completed &&
            s.type == 'focus' &&
            s.startedAt.substring(0, 10).compareTo(ws) >= 0)
        .length;
  }

  // ─── Habits ────────────────────────────────────────────────────────────
  Habit addHabit({
    required String name,
    String frequency = 'daily',
    List<int> customDays = const [],
    int targetCount = 1,
    String? reminderTime,
    String color = 'purple',
    String icon = 'check',
  }) {
    final habit = Habit(
      id: _uuid.v4(),
      name: name,
      frequency: frequency,
      customDays: customDays,
      targetCount: targetCount,
      reminderTime: reminderTime,
      color: color,
      icon: icon,
      createdAt: DateTime.now().toIso8601String(),
    );
    _commit((d) => _copy(d, habits: [habit, ...d.habits]));
    if (habit.reminderTime != null && habit.reminderTime!.isNotEmpty) {
      NotificationService.instance.scheduleHabitReminder(
        habitId: habit.id,
        habitName: habit.name,
        time: habit.reminderTime!,
      );
    }
    return habit;
  }

  void updateHabit(String id, Habit Function(Habit) fn) =>
      _commit((d) {
        final updated = d.habits.map((h) {
          if (h.id == id) {
            final next = fn(h);
            if (next.reminderTime != null && next.reminderTime!.isNotEmpty) {
              NotificationService.instance.scheduleHabitReminder(
                habitId: next.id,
                habitName: next.name,
                time: next.reminderTime!,
              );
            } else {
              NotificationService.instance.cancelHabitReminder(next.id);
            }
            return next;
          }
          return h;
        }).toList();
        return _copy(d, habits: updated);
      });

  void deleteHabit(String id) {
    NotificationService.instance.cancelHabitReminder(id);
    _commit((d) => _copy(d,
        habits: d.habits.where((h) => h.id != id).toList(),
        habitCompletions:
            d.habitCompletions.where((c) => c.habitId != id).toList()));
  }

  void toggleHabitCompletion(String habitId, String date) {
    final d = state.requireValue;
    final existing = d.habitCompletions
        .where((c) => c.habitId == habitId && c.date == date)
        .firstOrNull;
    if (existing != null) {
      // Remove completion (uncomplete)
      _commit((d) => _copy(d,
          habitCompletions:
              d.habitCompletions.where((c) => c.id != existing.id).toList()));
    } else {
      // Add completion
      final completion = HabitCompletion(
        id: _uuid.v4(),
        habitId: habitId,
        date: date,
        count: 1,
      );
      _commit((d) => _copy(d,
          habitCompletions: [completion, ...d.habitCompletions]));
    }
  }

  void skipHabitDay(String habitId, String date) {
    final d = state.requireValue;
    final existing = d.habitCompletions
        .where((c) => c.habitId == habitId && c.date == date)
        .firstOrNull;
    if (existing != null) {
      // Update to skipped
      _commit((d) => _copy(d,
          habitCompletions: d.habitCompletions
              .map((c) => c.id == existing.id
                  ? HabitCompletion(
                      id: c.id,
                      habitId: c.habitId,
                      date: c.date,
                      count: 0,
                      skipped: true)
                  : c)
              .toList()));
    } else {
      final skip = HabitCompletion(
        id: _uuid.v4(),
        habitId: habitId,
        date: date,
        count: 0,
        skipped: true,
      );
      _commit((d) => _copy(d,
          habitCompletions: [skip, ...d.habitCompletions]));
    }
  }

  int habitCurrentStreak(String habitId) {
    final completions = state.requireValue.habitCompletions
        .where((c) => c.habitId == habitId && (c.count > 0 || c.skipped))
        .map((c) => c.date)
        .toSet();
    int streak = 0;
    var day = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final dateStr =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      if (completions.contains(dateStr)) {
        streak++;
      } else if (i > 0) {
        break; // Allow today to not be completed yet
      }
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int habitBestStreak(String habitId) {
    final completions = state.requireValue.habitCompletions
        .where((c) => c.habitId == habitId && (c.count > 0 || c.skipped))
        .map((c) => c.date)
        .toList()
      ..sort();
    if (completions.isEmpty) return 0;
    int best = 1, current = 1;
    for (int i = 1; i < completions.length; i++) {
      final prev = DateTime.parse(completions[i - 1]);
      final curr = DateTime.parse(completions[i]);
      if (curr.difference(prev).inDays == 1) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }
    return best;
  }

  // ─── Search ───────────────────────────────────────────────────────────
  SearchResult globalSearch(String query) {
    final q = query.toLowerCase().trim();
    final d = state.requireValue;
    if (q.isEmpty) return const SearchResult();
    return SearchResult(
      tasks: d.tasks
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              t.description.toLowerCase().contains(q) ||
              t.tags.any((tag) => tag.toLowerCase().contains(q)))
          .toList(),
      notes: d.notes
          .where((n) =>
              n.title.toLowerCase().contains(q) ||
              n.body.toLowerCase().contains(q) ||
              n.tags.any((tag) => tag.toLowerCase().contains(q)))
          .toList(),
      expenses: d.expenses
          .where((e) =>
              e.note.toLowerCase().contains(q) ||
              e.category.toLowerCase().contains(q))
          .toList(),
      resources: d.resources
          .where((r) =>
              r.name.toLowerCase().contains(q) ||
              r.tags.any((tag) => tag.toLowerCase().contains(q)))
          .toList(),
      khataPersons: d.khataPersons
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              (p.phone ?? '').contains(q) ||
              (p.notes ?? '').toLowerCase().contains(q))
          .toList(),
    );
  }

  // ─── Computed stats ───────────────────────────────────────────────────
  int totalTasksCompleted() =>
      state.requireValue.tasks.where((t) => t.isCompleted).length;

  double totalMoneyTracked() =>
      state.requireValue.expenses.fold(0.0, (s, e) => s + e.amount);

  double completionRate() {
    final tasks = state.requireValue.tasks;
    if (tasks.isEmpty) return 0;
    return tasks.where((t) => t.isCompleted).length / tasks.length * 100;
  }

  // ─── Sample data / reset / export / import ────────────────────────────
  void loadSampleData() => _commit((d) => _sampleData(d.user));

  void clearAllData() {
    const next = AppData();
    state = const AsyncData(next);
    _persist(next);
  }

  String exportJson() =>
      const JsonEncoder.withIndent('  ').convert(state.requireValue.toJson());

  bool importJson(String json) {
    try {
      final data = AppData.fromJson(jsonDecode(json) as Map<String, dynamic>);
      state = AsyncData(data);
      _persist(data);
      return true;
    } catch (_) {
      return false;
    }
  }

  AppData _sampleData(UserPrefs user) {
    final now = DateTime.now();
    String iso(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final today = iso(now);
    final tomorrow = iso(now.add(const Duration(days: 1)));
    final nextWeek = iso(now.add(const Duration(days: 7)));
    final firstOfMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    final fifth = '${now.year}-${now.month.toString().padLeft(2, '0')}-05';

    // Khata sample persons
    final personAli = _uuid.v4();
    final personSara = _uuid.v4();
    final personAhmad = _uuid.v4();

    return AppData(
      user: user.copyWith(streak: 3),
      tasks: [
        Task(id: _uuid.v4(), title: 'Team standup meeting', description: 'Daily sync with the team', dueDate: today, dueTime: '10:00', priority: 'high', tags: const ['work'], listId: 'work', order: 0, createdAt: now.toIso8601String()),
        Task(id: _uuid.v4(), title: 'Pay electricity bill', dueDate: tomorrow, dueTime: '18:00', priority: 'urgent', tags: const ['bills'], recurrence: 'monthly', order: 1, createdAt: now.toIso8601String()),
        Task(id: _uuid.v4(), title: 'Buy groceries', description: 'Milk, eggs, bread, vegetables', dueDate: today, priority: 'medium', tags: const ['shopping'], subtasks: [SubTask(id: _uuid.v4(), title: 'Milk'), SubTask(id: _uuid.v4(), title: 'Eggs', done: true)], order: 2, createdAt: now.toIso8601String()),
        Task(id: _uuid.v4(), title: 'Review project proposal', dueDate: nextWeek, priority: 'low', tags: const ['work'], listId: 'work', isCompleted: true, completedAt: now.toIso8601String(), order: 3, createdAt: now.toIso8601String()),
      ],
      notes: [
        Note(id: _uuid.v4(), title: 'Meeting Notes — Q3 Planning', body: '# Q3 Planning\n\n## Goals\n- Launch MVP by August\n- Hire 2 engineers\n\n## Action Items\n- [ ] Draft roadmap\n- [x] Schedule interviews', folderId: 'work', tags: const ['meetings'], pinned: true, color: 'blue', createdAt: now.toIso8601String(), updatedAt: now.toIso8601String()),
        Note(id: _uuid.v4(), title: 'Recipe: Pasta Carbonara', body: '## Ingredients\n- 400g spaghetti\n- 200g guanciale\n- 4 egg yolks\n\n## Steps\n1. Boil pasta\n2. Crisp guanciale', folderId: 'personal', tags: const ['recipe'], color: 'orange', createdAt: now.toIso8601String(), updatedAt: now.toIso8601String()),
        Note(id: _uuid.v4(), title: 'Journal — Today', body: 'Feeling productive today. Finished the project review.', folderId: 'personal', tags: const ['journal'], color: 'green', createdAt: now.toIso8601String(), updatedAt: now.toIso8601String()),
      ],
      expenses: [
        Expense(id: _uuid.v4(), amount: 45.50, category: 'food', accountId: 'credit', note: 'Lunch at cafe', date: today, createdAt: now.toIso8601String()),
        Expense(id: _uuid.v4(), amount: 12.00, category: 'transport', accountId: 'cash', note: 'Uber ride', date: today, createdAt: now.toIso8601String()),
        Expense(id: _uuid.v4(), amount: 3500, type: 'income', category: 'other', accountId: 'bank', note: 'Freelance payment', date: firstOfMonth, createdAt: now.toIso8601String()),
        Expense(id: _uuid.v4(), amount: 15.99, category: 'bills', accountId: 'credit', note: 'Netflix subscription', date: fifth, isRecurring: true, createdAt: now.toIso8601String()),
        Expense(id: _uuid.v4(), amount: 89.00, category: 'shopping', accountId: 'credit', note: 'Amazon order', date: fifth, createdAt: now.toIso8601String()),
      ],
      budgets: [
        Budget(id: _uuid.v4(), category: 'food', monthlyLimit: 500, monthYear: monthYearKey()),
        Budget(id: _uuid.v4(), category: 'transport', monthlyLimit: 200, monthYear: monthYearKey()),
        Budget(id: _uuid.v4(), category: 'shopping', monthlyLimit: 300, monthYear: monthYearKey()),
      ],
      resources: [
        Resource(id: _uuid.v4(), type: ResourceType.subscription, name: 'Netflix', details: const {'plan': 'Standard', 'cost': 15.99}, renewalDate: iso(DateTime(now.year, now.month + 1, 5)), tags: const ['entertainment'], createdAt: now.toIso8601String()),
        Resource(id: _uuid.v4(), type: ResourceType.subscription, name: 'Spotify', details: const {'plan': 'Premium', 'cost': 9.99}, renewalDate: iso(DateTime(now.year, now.month + 1, 15)), tags: const ['entertainment'], createdAt: now.toIso8601String()),
        Resource(id: _uuid.v4(), type: ResourceType.document, name: 'Passport', details: const {'number': '****1234', 'expiry': '2028-06-15'}, renewalDate: '2028-06-15', tags: const ['id'], createdAt: now.toIso8601String()),
        Resource(id: _uuid.v4(), type: ResourceType.inventory, name: 'Office Paper (A4)', details: const {'location': 'Storage closet', 'unitCost': 12.50}, tags: const ['office'], quantity: 3, lowStockThreshold: 5, createdAt: now.toIso8601String()),
        Resource(id: _uuid.v4(), type: ResourceType.contact, name: 'Dr. Sarah Chen', details: const {'phone': '+1 555-0123', 'email': 'sarah.chen@clinic.com', 'role': 'Primary care'}, tags: const ['medical'], createdAt: now.toIso8601String()),
        Resource(id: _uuid.v4(), type: ResourceType.password, name: 'GitHub Account', details: const {'username': 'nexora_dev', 'password': '••••••••••••', 'url': 'https://github.com'}, tags: const ['tech', 'work'], createdAt: now.toIso8601String()),
        Resource(id: _uuid.v4(), type: ResourceType.wifiPassword, name: 'Studio_5G_Guest', details: const {'ssid': 'Studio_5G_Guest', 'password': 'NexoraSecurePassword2026', 'security': 'WPA3'}, tags: const ['office', 'wifi'], createdAt: now.toIso8601String()),
        Resource(id: _uuid.v4(), type: ResourceType.bankCard, name: 'Primary Platinum Card', details: const {'cardholder': 'NEXORA USER', 'cardNumber': '•••• •••• •••• 8842', 'expiry': '08/28', 'bank': 'Chase'}, tags: const ['finance'], createdAt: now.toIso8601String()),
      ],
      habits: [
        Habit(id: _uuid.v4(), name: 'Morning Workout', frequency: 'daily', color: 'orange', icon: 'flame', reminderTime: '07:00', createdAt: now.toIso8601String()),
        Habit(id: _uuid.v4(), name: 'Read 20 Pages', frequency: 'daily', color: 'blue', icon: 'bookOpen', reminderTime: '21:30', createdAt: now.toIso8601String()),
        Habit(id: _uuid.v4(), name: 'Drink 2L Water', frequency: 'daily', color: 'teal', icon: 'check', createdAt: now.toIso8601String()),
      ],
      habitCompletions: const [],
      focusSessions: const [],
      khataPersons: [
        KhataPerson(id: personAli, name: 'Ali Khan', phone: '+92 300 1234567', notes: 'Shop supplier', createdAt: now.toIso8601String()),
        KhataPerson(id: personSara, name: 'Sara Ahmed', phone: '+92 321 9876543', createdAt: now.toIso8601String()),
        KhataPerson(id: personAhmad, name: 'Ahmad Raza', notes: 'Construction materials', createdAt: now.toIso8601String()),
      ],
      khataEntries: [
        KhataEntry(id: _uuid.v4(), personId: personAli, amount: 5000, type: 'given', description: 'Goods delivered', date: iso(now.subtract(const Duration(days: 5))), createdAt: now.toIso8601String()),
        KhataEntry(id: _uuid.v4(), personId: personAli, amount: 2000, type: 'received', description: 'Partial payment', date: iso(now.subtract(const Duration(days: 2))), createdAt: now.toIso8601String()),
        KhataEntry(id: _uuid.v4(), personId: personSara, amount: 1500, type: 'received', description: 'Borrowed for event', date: iso(now.subtract(const Duration(days: 3))), createdAt: now.toIso8601String()),
        KhataEntry(id: _uuid.v4(), personId: personAhmad, amount: 12000, type: 'given', description: 'Cement and bricks', date: iso(now.subtract(const Duration(days: 10))), createdAt: now.toIso8601String()),
        KhataEntry(id: _uuid.v4(), personId: personAhmad, amount: 8000, type: 'received', description: 'Payment received', date: iso(now.subtract(const Duration(days: 1))), createdAt: now.toIso8601String()),
      ],
      noteFolders: const [...kDefaultFolders],
      accounts: const [...kDefaultAccounts],
    );
  }
}

class SearchResult {
  final List<Task> tasks;
  final List<Note> notes;
  final List<Expense> expenses;
  final List<Resource> resources;
  final List<KhataPerson> khataPersons;
  const SearchResult({
    this.tasks = const [],
    this.notes = const [],
    this.expenses = const [],
    this.resources = const [],
    this.khataPersons = const [],
  });
  bool get isEmpty =>
      tasks.isEmpty && notes.isEmpty && expenses.isEmpty && resources.isEmpty && khataPersons.isEmpty;
}

final appStoreProvider =
    AsyncNotifierProvider<AppStore, AppData>(AppStore.new);
