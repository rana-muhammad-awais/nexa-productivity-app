import 'package:uuid/uuid.dart';

import '../core/constants.dart';

const _uuid = Uuid();

/// Immutable data models. Every mutation returns a NEW object via [copyWith],
/// which is required for Riverpod to detect changes and rebuild the UI.

class UserPrefs {
  final String name;
  final String theme; // 'auto' | 'light' | 'dark'
  final String currency;
  final bool onboarded;
  final int streak;
  final String? lastCompletionDate;
  final bool biometricLock;
  // Focus settings (legacy — kept for data compat)
  final int focusDurationMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  // New settings
  final String fontSize; // 'small' | 'default' | 'large'
  final String accentColor; // 'purple' | 'blue' | 'teal' | 'orange' | 'pink' | 'green'
  final String defaultExpenseCategory; // category key
  final String startOfWeek; // 'sunday' | 'monday'
  final String dateFormat; // 'yyyy-MM-dd' | 'dd/MM/yyyy' | 'MM/dd/yyyy'
  final bool notificationReminders;
  final String defaultKhataEntryType; // 'given' | 'received'
  final bool autoBackup;
  final String dailyBriefTime; // '08:00'
  final bool notifyTasks;
  final bool notifyBudgets;
  final bool notifyRenewals;
  final bool notifyKhata;
  final bool notifyHabits;
  final bool hapticsEnabled;
  final bool compactMode;

  const UserPrefs({
    this.name = 'User',
    this.theme = 'auto',
    this.currency = 'USD',
    this.onboarded = false,
    this.streak = 0,
    this.lastCompletionDate,
    this.biometricLock = false,
    this.focusDurationMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.fontSize = 'default',
    this.accentColor = 'purple',
    this.defaultExpenseCategory = 'other',
    this.startOfWeek = 'monday',
    this.dateFormat = 'yyyy-MM-dd',
    this.notificationReminders = true,
    this.defaultKhataEntryType = 'given',
    this.autoBackup = false,
    this.dailyBriefTime = '08:00',
    this.notifyTasks = true,
    this.notifyBudgets = true,
    this.notifyRenewals = true,
    this.notifyKhata = true,
    this.notifyHabits = true,
    this.hapticsEnabled = true,
    this.compactMode = false,
  });

  factory UserPrefs.fromJson(Map<String, dynamic> j) => UserPrefs(
        name: j['name'] as String? ?? 'User',
        theme: j['theme'] as String? ?? 'auto',
        currency: j['currency'] as String? ?? 'USD',
        onboarded: j['onboarded'] as bool? ?? false,
        streak: j['streak'] as int? ?? 0,
        lastCompletionDate: j['lastCompletionDate'] as String?,
        biometricLock: j['biometricLock'] as bool? ?? false,
        focusDurationMinutes: j['focusDurationMinutes'] as int? ?? 25,
        shortBreakMinutes: j['shortBreakMinutes'] as int? ?? 5,
        longBreakMinutes: j['longBreakMinutes'] as int? ?? 15,
        fontSize: j['fontSize'] as String? ?? 'default',
        accentColor: j['accentColor'] as String? ?? 'purple',
        defaultExpenseCategory: j['defaultExpenseCategory'] as String? ?? 'other',
        startOfWeek: j['startOfWeek'] as String? ?? 'monday',
        dateFormat: j['dateFormat'] as String? ?? 'yyyy-MM-dd',
        notificationReminders: j['notificationReminders'] as bool? ?? true,
        defaultKhataEntryType: j['defaultKhataEntryType'] as String? ?? 'given',
        autoBackup: j['autoBackup'] as bool? ?? false,
        dailyBriefTime: j['dailyBriefTime'] as String? ?? '08:00',
        notifyTasks: j['notifyTasks'] as bool? ?? true,
        notifyBudgets: j['notifyBudgets'] as bool? ?? true,
        notifyRenewals: j['notifyRenewals'] as bool? ?? true,
        notifyKhata: j['notifyKhata'] as bool? ?? true,
        notifyHabits: j['notifyHabits'] as bool? ?? true,
        hapticsEnabled: j['hapticsEnabled'] as bool? ?? true,
        compactMode: j['compactMode'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'theme': theme,
        'currency': currency,
        'onboarded': onboarded,
        'streak': streak,
        'lastCompletionDate': lastCompletionDate,
        'biometricLock': biometricLock,
        'focusDurationMinutes': focusDurationMinutes,
        'shortBreakMinutes': shortBreakMinutes,
        'longBreakMinutes': longBreakMinutes,
        'fontSize': fontSize,
        'accentColor': accentColor,
        'defaultExpenseCategory': defaultExpenseCategory,
        'startOfWeek': startOfWeek,
        'dateFormat': dateFormat,
        'notificationReminders': notificationReminders,
        'defaultKhataEntryType': defaultKhataEntryType,
        'autoBackup': autoBackup,
        'dailyBriefTime': dailyBriefTime,
        'notifyTasks': notifyTasks,
        'notifyBudgets': notifyBudgets,
        'notifyRenewals': notifyRenewals,
        'notifyKhata': notifyKhata,
        'notifyHabits': notifyHabits,
        'hapticsEnabled': hapticsEnabled,
        'compactMode': compactMode,
      };

  UserPrefs copyWith({
    String? name,
    String? theme,
    String? currency,
    bool? onboarded,
    int? streak,
    String? lastCompletionDate,
    bool? biometricLock,
    int? focusDurationMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    String? fontSize,
    String? accentColor,
    String? defaultExpenseCategory,
    String? startOfWeek,
    String? dateFormat,
    bool? notificationReminders,
    String? defaultKhataEntryType,
    bool? autoBackup,
    String? dailyBriefTime,
    bool? notifyTasks,
    bool? notifyBudgets,
    bool? notifyRenewals,
    bool? notifyKhata,
    bool? notifyHabits,
    bool? hapticsEnabled,
    bool? compactMode,
  }) =>
      UserPrefs(
        name: name ?? this.name,
        theme: theme ?? this.theme,
        currency: currency ?? this.currency,
        onboarded: onboarded ?? this.onboarded,
        streak: streak ?? this.streak,
        lastCompletionDate: lastCompletionDate ?? this.lastCompletionDate,
        biometricLock: biometricLock ?? this.biometricLock,
        focusDurationMinutes: focusDurationMinutes ?? this.focusDurationMinutes,
        shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
        longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
        fontSize: fontSize ?? this.fontSize,
        accentColor: accentColor ?? this.accentColor,
        defaultExpenseCategory: defaultExpenseCategory ?? this.defaultExpenseCategory,
        startOfWeek: startOfWeek ?? this.startOfWeek,
        dateFormat: dateFormat ?? this.dateFormat,
        notificationReminders: notificationReminders ?? this.notificationReminders,
        defaultKhataEntryType: defaultKhataEntryType ?? this.defaultKhataEntryType,
        autoBackup: autoBackup ?? this.autoBackup,
        dailyBriefTime: dailyBriefTime ?? this.dailyBriefTime,
        notifyTasks: notifyTasks ?? this.notifyTasks,
        notifyBudgets: notifyBudgets ?? this.notifyBudgets,
        notifyRenewals: notifyRenewals ?? this.notifyRenewals,
        notifyKhata: notifyKhata ?? this.notifyKhata,
        notifyHabits: notifyHabits ?? this.notifyHabits,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
        compactMode: compactMode ?? this.compactMode,
      );
}

class SubTask {
  final String id;
  final String title;
  final bool done;

  const SubTask({required this.id, required this.title, this.done = false});

  factory SubTask.fromJson(Map<String, dynamic> j) => SubTask(
        id: j['id'] as String? ?? _uuid.v4(),
        title: j['title'] as String? ?? '',
        done: j['done'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};

  SubTask copyWith({String? title, bool? done}) =>
      SubTask(id: id, title: title ?? this.title, done: done ?? this.done);
}

class Task {
  final String id;
  final String title;
  final String description;
  final String? dueDate;
  final String? dueTime;
  final String priority;
  final List<String> tags;
  final String listId;
  final bool isCompleted;
  final List<SubTask> subtasks;
  final String? recurrence;
  final String? linkedNoteId;
  final int order;
  final String createdAt;
  final String? completedAt;

  const Task({
    required this.id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.dueTime,
    this.priority = 'medium',
    this.tags = const [],
    this.listId = 'inbox',
    this.isCompleted = false,
    this.subtasks = const [],
    this.recurrence,
    this.linkedNoteId,
    this.order = 0,
    required this.createdAt,
    this.completedAt,
  });

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'] as String? ?? _uuid.v4(),
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        dueDate: j['dueDate'] as String?,
        dueTime: j['dueTime'] as String?,
        priority: j['priority'] as String? ?? 'medium',
        tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        listId: j['listId'] as String? ?? 'inbox',
        isCompleted: j['isCompleted'] as bool? ?? false,
        subtasks: (j['subtasks'] as List?)
                ?.map((e) => SubTask.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        recurrence: j['recurrence'] as String?,
        linkedNoteId: j['linkedNoteId'] as String?,
        order: j['order'] as int? ?? 0,
        createdAt: j['createdAt'] as String? ?? DateTime.now().toIso8601String(),
        completedAt: j['completedAt'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'dueDate': dueDate,
        'dueTime': dueTime,
        'priority': priority,
        'tags': tags,
        'listId': listId,
        'isCompleted': isCompleted,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'recurrence': recurrence,
        'linkedNoteId': linkedNoteId,
        'order': order,
        'createdAt': createdAt,
        'completedAt': completedAt,
      };

  Task copyWith({
    String? title,
    String? description,
    String? dueDate,
    String? dueTime,
    String? priority,
    List<String>? tags,
    String? listId,
    bool? isCompleted,
    List<SubTask>? subtasks,
    String? recurrence,
    String? linkedNoteId,
    int? order,
    String? completedAt,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        dueDate: dueDate ?? this.dueDate,
        dueTime: dueTime ?? this.dueTime,
        priority: priority ?? this.priority,
        tags: tags ?? this.tags,
        listId: listId ?? this.listId,
        isCompleted: isCompleted ?? this.isCompleted,
        subtasks: subtasks ?? this.subtasks,
        recurrence: recurrence ?? this.recurrence,
        linkedNoteId: linkedNoteId ?? this.linkedNoteId,
        order: order ?? this.order,
        createdAt: createdAt,
        completedAt: completedAt ?? this.completedAt,
      );
}

class Note {
  final String id;
  final String title;
  final String body;
  final String folderId;
  final List<String> tags;
  final bool pinned;
  final List<String> attachments;
  final String createdAt;
  final String updatedAt;
  final String? color; // null | 'blue' | 'purple' | 'green' | 'orange' | 'pink' | 'yellow'

  const Note({
    required this.id,
    this.title = 'Untitled',
    this.body = '',
    this.folderId = 'inbox',
    this.tags = const [],
    this.pinned = false,
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
    this.color,
  });

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        id: j['id'] as String? ?? _uuid.v4(),
        title: j['title'] as String? ?? 'Untitled',
        body: j['body'] as String? ?? '',
        folderId: j['folderId'] as String? ?? 'inbox',
        tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        pinned: j['pinned'] as bool? ?? false,
        attachments: (j['attachments'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        createdAt: j['createdAt'] as String? ?? DateTime.now().toIso8601String(),
        updatedAt: j['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
        color: j['color'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'folderId': folderId,
        'tags': tags,
        'pinned': pinned,
        'attachments': attachments,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'color': color,
      };

  Note copyWith({
    String? title,
    String? body,
    String? folderId,
    List<String>? tags,
    bool? pinned,
    List<String>? attachments,
    String? updatedAt,
    String? color,
  }) =>
      Note(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
        folderId: folderId ?? this.folderId,
        tags: tags ?? this.tags,
        pinned: pinned ?? this.pinned,
        attachments: attachments ?? this.attachments,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
        color: color ?? this.color,
      );
}

class Expense {
  final String id;
  final double amount;
  final String type; // 'income' | 'expense'
  final String category;
  final String accountId;
  final String note;
  final String date;
  final String? receiptImage;
  final bool isRecurring;
  final String? linkedTaskId;
  final String createdAt;

  const Expense({
    required this.id,
    required this.amount,
    this.type = 'expense',
    this.category = 'other',
    this.accountId = 'cash',
    this.note = '',
    required this.date,
    this.receiptImage,
    this.isRecurring = false,
    this.linkedTaskId,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'] as String? ?? _uuid.v4(),
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        type: j['type'] as String? ?? 'expense',
        category: j['category'] as String? ?? 'other',
        accountId: j['accountId'] as String? ?? 'cash',
        note: j['note'] as String? ?? '',
        date: j['date'] as String? ??
            DateTime.now().toIso8601String().substring(0, 10),
        receiptImage: j['receiptImage'] as String?,
        isRecurring: j['isRecurring'] as bool? ?? false,
        linkedTaskId: j['linkedTaskId'] as String?,
        createdAt: j['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type,
        'category': category,
        'accountId': accountId,
        'note': note,
        'date': date,
        'receiptImage': receiptImage,
        'isRecurring': isRecurring,
        'linkedTaskId': linkedTaskId,
        'createdAt': createdAt,
      };

  Expense copyWith({
    double? amount,
    String? type,
    String? category,
    String? accountId,
    String? note,
    String? date,
    String? receiptImage,
    bool? isRecurring,
    String? linkedTaskId,
  }) =>
      Expense(
        id: id,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        category: category ?? this.category,
        accountId: accountId ?? this.accountId,
        note: note ?? this.note,
        date: date ?? this.date,
        receiptImage: receiptImage ?? this.receiptImage,
        isRecurring: isRecurring ?? this.isRecurring,
        linkedTaskId: linkedTaskId ?? this.linkedTaskId,
        createdAt: createdAt,
      );
}

class Budget {
  final String id;
  final String category;
  final double monthlyLimit;
  final String monthYear;

  const Budget({
    required this.id,
    required this.category,
    required this.monthlyLimit,
    required this.monthYear,
  });

  factory Budget.fromJson(Map<String, dynamic> j) => Budget(
        id: j['id'] as String? ?? _uuid.v4(),
        category: j['category'] as String? ?? 'other',
        monthlyLimit: (j['monthlyLimit'] as num?)?.toDouble() ?? 0,
        monthYear: j['monthYear'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'monthlyLimit': monthlyLimit,
        'monthYear': monthYear,
      };
}

class Resource {
  final String id;
  final ResourceType type;
  final String name;
  final Map<String, dynamic> details;
  final String? fileUrl;
  final String? renewalDate;
  final List<String> tags;
  final int? quantity;
  final int lowStockThreshold;
  final String createdAt;

  const Resource({
    required this.id,
    this.type = ResourceType.document,
    required this.name,
    this.details = const {},
    this.fileUrl,
    this.renewalDate,
    this.tags = const [],
    this.quantity,
    this.lowStockThreshold = 5,
    required this.createdAt,
  });

  factory Resource.fromJson(Map<String, dynamic> j) => Resource(
        id: j['id'] as String? ?? _uuid.v4(),
        type: ResourceType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => ResourceType.document,
        ),
        name: j['name'] as String? ?? '',
        details: Map<String, dynamic>.from(j['details'] as Map? ?? const {}),
        fileUrl: j['fileUrl'] as String?,
        renewalDate: j['renewalDate'] as String?,
        tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        quantity: j['quantity'] as int?,
        lowStockThreshold: j['lowStockThreshold'] as int? ?? 5,
        createdAt: j['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'details': details,
        'fileUrl': fileUrl,
        'renewalDate': renewalDate,
        'tags': tags,
        'quantity': quantity,
        'lowStockThreshold': lowStockThreshold,
        'createdAt': createdAt,
      };

  Resource copyWith({
    ResourceType? type,
    String? name,
    Map<String, dynamic>? details,
    String? fileUrl,
    String? renewalDate,
    List<String>? tags,
    int? quantity,
    int? lowStockThreshold,
  }) =>
      Resource(
        id: id,
        type: type ?? this.type,
        name: name ?? this.name,
        details: details ?? this.details,
        fileUrl: fileUrl ?? this.fileUrl,
        renewalDate: renewalDate ?? this.renewalDate,
        tags: tags ?? this.tags,
        quantity: quantity ?? this.quantity,
        lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
        createdAt: createdAt,
      );
}

/// Focus session model — kept for backward data compatibility.
class FocusSession {
  final String id;
  final String type; // 'focus' | 'short_break' | 'long_break'
  final int durationMinutes;
  final String? linkedTaskId;
  final String startedAt;
  final String? completedAt;
  final bool completed;

  const FocusSession({
    required this.id,
    this.type = 'focus',
    required this.durationMinutes,
    this.linkedTaskId,
    required this.startedAt,
    this.completedAt,
    this.completed = false,
  });

  factory FocusSession.fromJson(Map<String, dynamic> j) => FocusSession(
        id: j['id'] as String? ?? _uuid.v4(),
        type: j['type'] as String? ?? 'focus',
        durationMinutes: j['durationMinutes'] as int? ?? 25,
        linkedTaskId: j['linkedTaskId'] as String?,
        startedAt: j['startedAt'] as String? ?? DateTime.now().toIso8601String(),
        completedAt: j['completedAt'] as String?,
        completed: j['completed'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'durationMinutes': durationMinutes,
        'linkedTaskId': linkedTaskId,
        'startedAt': startedAt,
        'completedAt': completedAt,
        'completed': completed,
      };

  FocusSession copyWith({
    String? type,
    int? durationMinutes,
    String? linkedTaskId,
    String? completedAt,
    bool? completed,
  }) =>
      FocusSession(
        id: id,
        type: type ?? this.type,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        linkedTaskId: linkedTaskId ?? this.linkedTaskId,
        startedAt: startedAt,
        completedAt: completedAt ?? this.completedAt,
        completed: completed ?? this.completed,
      );
}

// ─── Khata (Hisaab-Kitaab) ─────────────────────────────────────────────────

/// A person/party in the Khata ledger.
class KhataPerson {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final String createdAt;

  const KhataPerson({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    required this.createdAt,
  });

  factory KhataPerson.fromJson(Map<String, dynamic> j) => KhataPerson(
        id: j['id'] as String? ?? _uuid.v4(),
        name: j['name'] as String? ?? '',
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        address: j['address'] as String?,
        notes: j['notes'] as String?,
        createdAt: j['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'notes': notes,
        'createdAt': createdAt,
      };

  KhataPerson copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) =>
      KhataPerson(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        address: address ?? this.address,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );
}

/// A single transaction entry in a person's khata.
class KhataEntry {
  final String id;
  final String personId;
  final double amount;
  final String type; // 'given' (they owe you) | 'received' (you owe them)
  final String description;
  final String date;
  final String createdAt;

  const KhataEntry({
    required this.id,
    required this.personId,
    required this.amount,
    this.type = 'given',
    this.description = '',
    required this.date,
    required this.createdAt,
  });

  factory KhataEntry.fromJson(Map<String, dynamic> j) => KhataEntry(
        id: j['id'] as String? ?? _uuid.v4(),
        personId: j['personId'] as String? ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        type: j['type'] as String? ?? 'given',
        description: j['description'] as String? ?? '',
        date: j['date'] as String? ??
            DateTime.now().toIso8601String().substring(0, 10),
        createdAt: j['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'personId': personId,
        'amount': amount,
        'type': type,
        'description': description,
        'date': date,
        'createdAt': createdAt,
      };

  KhataEntry copyWith({
    String? personId,
    double? amount,
    String? type,
    String? description,
    String? date,
  }) =>
      KhataEntry(
        id: id,
        personId: personId ?? this.personId,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        description: description ?? this.description,
        date: date ?? this.date,
        createdAt: createdAt,
      );
}

class AppData {
  final UserPrefs user;
  final List<Task> tasks;
  final List<Note> notes;
  final List<NoteFolder> noteFolders;
  final List<Expense> expenses;
  final List<Account> accounts;
  final List<Budget> budgets;
  final List<Resource> resources;
  final List<FocusSession> focusSessions;
  final List<KhataPerson> khataPersons;
  final List<KhataEntry> khataEntries;
  final List<Habit> habits;
  final List<HabitCompletion> habitCompletions;

  const AppData({
    this.user = const UserPrefs(),
    this.tasks = const [],
    this.notes = const [],
    this.noteFolders = const [...kDefaultFolders],
    this.expenses = const [],
    this.accounts = const [...kDefaultAccounts],
    this.budgets = const [],
    this.resources = const [],
    this.focusSessions = const [],
    this.khataPersons = const [],
    this.khataEntries = const [],
    this.habits = const [],
    this.habitCompletions = const [],
  });

  factory AppData.fromJson(Map<String, dynamic> j) => AppData(
        user: j['user'] != null
            ? UserPrefs.fromJson(j['user'] as Map<String, dynamic>)
            : const UserPrefs(),
        tasks: (j['tasks'] as List?)
                ?.map((e) => Task.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        notes: (j['notes'] as List?)
                ?.map((e) => Note.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        noteFolders: (j['noteFolders'] as List?)
                ?.map((e) => NoteFolder(
                      (e as Map)['id'].toString(),
                      e['name'].toString(),
                    ))
                .toList() ??
            const [...kDefaultFolders],
        expenses: (j['expenses'] as List?)
                ?.map((e) => Expense.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        accounts: (j['accounts'] as List?)
                ?.map((e) => Account(
                      (e as Map)['id'].toString(),
                      e['name'].toString(),
                      e['type'].toString(),
                    ))
                .toList() ??
            const [...kDefaultAccounts],
        budgets: (j['budgets'] as List?)
                ?.map((e) => Budget.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        resources: (j['resources'] as List?)
                ?.map((e) => Resource.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        focusSessions: (j['focusSessions'] as List?)
                ?.map((e) => FocusSession.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        khataPersons: (j['khataPersons'] as List?)
                ?.map((e) => KhataPerson.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        khataEntries: (j['khataEntries'] as List?)
                ?.map((e) => KhataEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        habits: (j['habits'] as List?)
                ?.map((e) => Habit.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        habitCompletions: (j['habitCompletions'] as List?)
                ?.map((e) => HabitCompletion.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'notes': notes.map((n) => n.toJson()).toList(),
        'noteFolders': noteFolders
            .map((f) => {'id': f.id, 'name': f.name})
            .toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'accounts': accounts
            .map((a) => {'id': a.id, 'name': a.name, 'type': a.type})
            .toList(),
        'budgets': budgets.map((b) => b.toJson()).toList(),
        'resources': resources.map((r) => r.toJson()).toList(),
        'focusSessions': focusSessions.map((f) => f.toJson()).toList(),
        'khataPersons': khataPersons.map((p) => p.toJson()).toList(),
        'khataEntries': khataEntries.map((e) => e.toJson()).toList(),
        'habits': habits.map((h) => h.toJson()).toList(),
        'habitCompletions': habitCompletions.map((c) => c.toJson()).toList(),
      };
}

// ─── Habits ─────────────────────────────────────────────────────────────────

/// A repeating habit the user wants to build.
class Habit {
  final String id;
  final String name;
  final String frequency; // 'daily' | 'weekly' | 'custom'
  final List<int> customDays; // 0=Mon...6=Sun for 'custom'
  final int targetCount; // times per day/period
  final String? reminderTime; // HH:mm
  final String color; // hex or named color key
  final String icon; // Lucide icon name
  final String createdAt;
  final bool archived;

  const Habit({
    required this.id,
    required this.name,
    this.frequency = 'daily',
    this.customDays = const [],
    this.targetCount = 1,
    this.reminderTime,
    this.color = 'purple',
    this.icon = 'check',
    required this.createdAt,
    this.archived = false,
  });

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'] as String? ?? _uuid.v4(),
        name: j['name'] as String? ?? '',
        frequency: j['frequency'] as String? ?? 'daily',
        customDays: (j['customDays'] as List?)?.map((e) => e as int).toList() ?? const [],
        targetCount: j['targetCount'] as int? ?? 1,
        reminderTime: j['reminderTime'] as String?,
        color: j['color'] as String? ?? 'purple',
        icon: j['icon'] as String? ?? 'check',
        createdAt: j['createdAt'] as String? ?? DateTime.now().toIso8601String(),
        archived: j['archived'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'frequency': frequency,
        'customDays': customDays,
        'targetCount': targetCount,
        'reminderTime': reminderTime,
        'color': color,
        'icon': icon,
        'createdAt': createdAt,
        'archived': archived,
      };

  Habit copyWith({
    String? name,
    String? frequency,
    List<int>? customDays,
    int? targetCount,
    String? reminderTime,
    String? color,
    String? icon,
    bool? archived,
  }) =>
      Habit(
        id: id,
        name: name ?? this.name,
        frequency: frequency ?? this.frequency,
        customDays: customDays ?? this.customDays,
        targetCount: targetCount ?? this.targetCount,
        reminderTime: reminderTime ?? this.reminderTime,
        color: color ?? this.color,
        icon: icon ?? this.icon,
        createdAt: createdAt,
        archived: archived ?? this.archived,
      );
}

/// A single completion record for a habit on a given date.
class HabitCompletion {
  final String id;
  final String habitId;
  final String date; // yyyy-MM-dd
  final int count; // times completed that day
  final bool skipped; // rest day (streak not broken)

  const HabitCompletion({
    required this.id,
    required this.habitId,
    required this.date,
    this.count = 1,
    this.skipped = false,
  });

  factory HabitCompletion.fromJson(Map<String, dynamic> j) => HabitCompletion(
        id: j['id'] as String? ?? _uuid.v4(),
        habitId: j['habitId'] as String? ?? '',
        date: j['date'] as String? ?? '',
        count: j['count'] as int? ?? 1,
        skipped: j['skipped'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'habitId': habitId,
        'date': date,
        'count': count,
        'skipped': skipped,
      };
}
