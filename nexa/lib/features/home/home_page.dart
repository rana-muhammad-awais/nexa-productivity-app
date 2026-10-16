import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/animations.dart';
import '../../core/constants.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../widgets/glass.dart';
import '../../widgets/store_guard.dart';
import '../../widgets/tiles.dart';
import '../expenses/add_expense_sheet.dart';
import '../expenses/currency_converter_sheet.dart';
import '../khata/add_khata_person_sheet.dart';
import '../notes/note_editor_page.dart';
import '../notes/notes_page.dart';
import '../resources/add_resource_sheet.dart';
import '../tasks/add_task_sheet.dart';
import '../tasks/focus_timer_page.dart';
import '../tasks/task_detail_sheet.dart';

/// Home dashboard — personal OS command center with productivity metrics,
/// daily financial pace, habit checklist, urgent alerts, and recent activities.
class HomePage extends ConsumerWidget {
  final ValueChanged<int> onNavigate;
  const HomePage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StoreGuard(
      child: (data) => _HomeContent(data: data, onNavigate: onNavigate),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  final AppData data;
  final ValueChanged<int> onNavigate;
  const _HomeContent({required this.data, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = data.user.currency;
    final today = todayIsoDate();
    final store = ref.read(appStoreProvider.notifier);

    // Tasks metrics
    final todayTasks =
        data.tasks.where((t) => !t.isCompleted && t.dueDate == today).toList();
    final overdueTasks =
        data.tasks.where((t) => isOverdue(t.dueDate, t.isCompleted)).toList();
    final completedToday =
        data.tasks.where((t) => t.isCompleted && t.dueDate == today).length;
    final totalTodayTasks = todayTasks.length + completedToday;
    final taskPct = totalTodayTasks > 0 ? (completedToday / totalTodayTasks * 100).round() : 100;

    // Habits metrics
    final habits = data.habits;
    final todayCompletions = data.habitCompletions
        .where((c) => c.date == today && (c.count > 0 || c.skipped))
        .map((c) => c.habitId)
        .toSet();
    final completedHabitsCount = habits.where((h) => todayCompletions.contains(h.id)).length;
    final habitPct = habits.isNotEmpty ? (completedHabitsCount / habits.length * 100).round() : 100;

    // Focus session metric
    final focusMins = store.todayFocusMinutes();

    // Composite Daily Productivity Score (0-100)
    final productivityScore = habits.isEmpty && totalTodayTasks == 0
        ? 100
        : ((taskPct * 0.5) + (habitPct * 0.4) + (focusMins > 0 ? 10 : 0))
            .clamp(0, 100)
            .round();

    // Financial metrics
    final todaySpend = data.expenses
        .where((e) => e.type == 'expense' && e.date == today)
        .fold(0.0, (s, e) => s + e.amount);

    final currentMonthKey = monthYearKey();
    final monthSpend = data.expenses
        .where((e) => e.type == 'expense' && e.date.startsWith(currentMonthKey))
        .fold(0.0, (s, e) => s + e.amount);

    final totalBudget = data.budgets
        .where((b) => b.monthYear == currentMonthKey)
        .fold(0.0, (s, b) => s + b.monthlyLimit);
    final remainingBudget = totalBudget > 0 ? (totalBudget - monthSpend) : null;

    // Urgent Alerts (Renewals & Low Stock)
    final renewals = data.resources
        .where((r) =>
            r.renewalDate != null &&
            daysUntil(r.renewalDate) != null &&
            daysUntil(r.renewalDate)! >= 0 &&
            daysUntil(r.renewalDate)! <= 7)
        .toList()
      ..sort((a, b) => daysUntil(a.renewalDate)!.compareTo(daysUntil(b.renewalDate)!));

    final inventoryLow = data.resources
        .where((r) =>
            r.type == ResourceType.inventory &&
            r.quantity != null &&
            r.quantity! <= r.lowStockThreshold)
        .toList();

    // Khata balances
    final totalReceivable = store.totalReceivable();
    final totalPayable = store.totalPayable();

    // Recent Notes
    final recentNotes = [...data.notes]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // Dynamic Recent Activity Feed (top 5 events across modules)
    final activities = _buildRecentActivities(data);

    final userName = data.user.name.isEmpty ? 'Friend' : data.user.name;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        // ── 1. Greeting & Productivity Ring ───────────────────────────
        StaggeredFadeIn(
          index: 0,
          child: GlassCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${getGreeting()}, $userName',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(width: 4),
                          const Text('👋', style: TextStyle(fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        todayTasks.isEmpty
                            ? 'All tasks completed for today ✨'
                            : '${todayTasks.length} task${todayTasks.length > 1 ? 's' : ''} remaining today',
                        style: TextStyle(
                            color: textSecondaryColor(context), fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (data.user.streak > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: NexaColors.catShopping.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.flame,
                                      size: 14, color: NexaColors.catShopping),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${data.user.streak}d streak',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: NexaColors.catShopping,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (focusMins > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: NexaColors.catBills.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.timer,
                                      size: 14, color: NexaColors.catBills),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${focusMins}m focus',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: NexaColors.catBills,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Productivity Ring
                Column(
                  children: [
                    ProgressRing(
                      percent: productivityScore.toDouble(),
                      size: 64,
                      stroke: 7,
                      gradient: NexaColors.gradPrimary,
                      center: Text(
                        '$productivityScore%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Daily Score',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: textSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // ── 2. Quick Action Launcher Chips ─────────────────────────────
        StaggeredFadeIn(
          index: 1,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _quickActionChip(
                  context,
                  label: '+ Task',
                  icon: LucideIcons.checkSquare,
                  gradient: NexaColors.gradPrimary,
                  onTap: () => AddTaskSheet.show(context),
                ),
                const SizedBox(width: 8),
                _quickActionChip(
                  context,
                  label: '+ Money',
                  icon: LucideIcons.wallet,
                  gradient: NexaColors.gradSuccess,
                  onTap: () => AddExpenseSheet.show(context),
                ),
                const SizedBox(width: 8),
                _quickActionChip(
                  context,
                  label: '⚡ Focus',
                  icon: LucideIcons.timer,
                  gradient: NexaColors.gradCool,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FocusTimerPage()),
                  ),
                ),
                const SizedBox(width: 8),
                _quickActionChip(
                  context,
                  label: '+ Note',
                  icon: LucideIcons.fileText,
                  gradient: NexaColors.gradWarm,
                  onTap: () => NotesPage.openAdder(context),
                ),
                const SizedBox(width: 8),
                _quickActionChip(
                  context,
                  label: '+ Khata',
                  icon: LucideIcons.bookOpen,
                  gradient: NexaColors.gradKhata,
                  onTap: () => AddKhataPersonSheet.show(context),
                ),
                const SizedBox(width: 8),
                _quickActionChip(
                  context,
                  label: '+ Vault',
                  icon: LucideIcons.folderLock,
                  gradient: const [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  onTap: () => AddResourceSheet.show(context),
                ),
                const SizedBox(width: 8),
                _quickActionChip(
                  context,
                  label: '💱 Convert',
                  icon: LucideIcons.arrowLeftRight,
                  gradient: const [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                  onTap: () {
                    NexaHaptics.tick();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const CurrencyConverterSheet(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // ── 3. Urgent Alerts (Renewals & Low Stock) ─────────────────────
        if (renewals.isNotEmpty || inventoryLow.isNotEmpty) ...[
          const SizedBox(height: 14),
          StaggeredFadeIn(
            index: 2,
            child: Column(
              children: [
                ...renewals.map((r) {
                  final d = daysUntil(r.renewalDate)!;
                  final danger = d <= 2;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: (danger ? NexaColors.danger : NexaColors.warning)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (danger ? NexaColors.danger : NexaColors.warning)
                            .withOpacity(0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.bell,
                            size: 18,
                            color: danger ? NexaColors.danger : NexaColors.warning),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${r.name}: ${d == 0 ? 'Expires/Renews TODAY!' : 'Renews in $d day${d == 1 ? '' : 's'}'}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                ...inventoryLow.map((r) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: NexaColors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: NexaColors.warning.withOpacity(0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.package,
                              size: 18, color: NexaColors.warning),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Low Stock Alert: ${r.name} (${r.quantity} left)',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],

        const SizedBox(height: 14),

        // ── 4. Financial Summary Card ──────────────────────────────────
        StaggeredFadeIn(
          index: 3,
          child: GradientBorderCard(
            gradient: NexaColors.gradWarm,
            onTap: () => onNavigate(3),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Financial Snapshot',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textSecondaryColor(context),
                      ),
                    ),
                    Text(
                      'View Money →',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: primaryColor(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Spent Today',
                              style: TextStyle(
                                  fontSize: 11, color: textSecondaryColor(context))),
                          const SizedBox(height: 2),
                          Text(
                            formatCurrency(todaySpend, currency),
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 34,
                      color: borderColor(context),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            remainingBudget != null ? 'Budget Left' : 'This Month',
                            style: TextStyle(
                                fontSize: 11, color: textSecondaryColor(context)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            remainingBudget != null
                                ? formatCurrency(remainingBudget, currency)
                                : formatCurrency(monthSpend, currency),
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: remainingBudget != null && remainingBudget < 0
                                  ? NexaColors.danger
                                  : NexaColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── 5. Today's Habits Check-off Row ────────────────────────────
        if (habits.isNotEmpty) ...[
          const SizedBox(height: 14),
          StaggeredFadeIn(
            index: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SectionHeader(
                      "Today's Habits ($completedHabitsCount/${habits.length})",
                    ),
                    TextButton(
                      onPressed: () => onNavigate(1),
                      child: const Text('View All', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: habits.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final h = habits[i];
                      final isDone = todayCompletions.contains(h.id);
                      final streak = store.habitCurrentStreak(h.id);

                      return GestureDetector(
                        onTap: () {
                          NexaHaptics.success();
                          store.toggleHabitCompletion(h.id, today);
                        },
                        child: AnimatedContainer(
                          duration: NexaAnim.fast,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDone
                                ? NexaColors.success.withOpacity(0.12)
                                : surfaceColor(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDone
                                  ? NexaColors.success.withOpacity(0.5)
                                  : borderColor(context),
                              width: isDone ? 1.4 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? NexaColors.success
                                      : primaryColor(context).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isDone ? LucideIcons.check : LucideIcons.circle,
                                  size: 14,
                                  color: isDone ? Colors.white : primaryColor(context),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    h.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      decoration:
                                          isDone ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  if (streak > 0)
                                    Text(
                                      '🔥 $streak day streak',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: NexaColors.catShopping,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── 6. Khata Summary Card ──────────────────────────────────────
        const SizedBox(height: 14),
        StaggeredFadeIn(
          index: 5,
          child: GlassCard(
            onTap: () => onNavigate(5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: NexaColors.gradKhata),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.bookOpen, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Khata Ledger',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14.5)),
                      Text(
                        data.khataPersons.isEmpty
                            ? 'Track hisaab-kitaab with people'
                            : '${data.khataPersons.length} contacts logged',
                        style: TextStyle(
                            fontSize: 12, color: textSecondaryColor(context)),
                      ),
                    ],
                  ),
                ),
                if (totalReceivable > 0 || totalPayable > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (totalReceivable > 0)
                        Text(
                          '+${formatCurrency(totalReceivable, currency)} (You\'ll get)',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: NexaColors.success,
                          ),
                        ),
                      if (totalPayable > 0)
                        Text(
                          '-${formatCurrency(totalPayable, currency)} (You owe)',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: NexaColors.danger,
                          ),
                        ),
                    ],
                  )
                else
                  const Icon(LucideIcons.chevronRight, size: 16),
              ],
            ),
          ),
        ),

        // ── 7. Overdue Tasks (if any) ──────────────────────────────────
        if (overdueTasks.isNotEmpty) ...[
          const SizedBox(height: 10),
          const SectionHeader('Overdue Tasks', color: NexaColors.danger),
          ...overdueTasks.take(3).map((t) => TaskTile(
                task: t,
                onToggle: () => store.toggleTask(t.id),
                onTap: () => TaskDetailSheet.show(context, t.id),
              )),
        ],

        // ── 8. Today's Tasks ───────────────────────────────────────────
        const SizedBox(height: 10),
        SectionHeader(
          "Today's Tasks",
          action: TextButton(
            onPressed: () => onNavigate(1),
            child: const Text('View All', style: TextStyle(fontSize: 12)),
          ),
        ),
        if (todayTasks.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(LucideIcons.sparkles,
                    color: NexaColors.success, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('No pending tasks for today! Enjoy your day 🎉',
                      style: TextStyle(
                          color: textSecondaryColor(context), fontSize: 13.5)),
                ),
              ],
            ),
          )
        else
          ...todayTasks.map((t) => TaskTile(
                task: t,
                onToggle: () => store.toggleTask(t.id),
                onTap: () => TaskDetailSheet.show(context, t.id),
              )),

        // ── 9. Recent Activity Feed ────────────────────────────────────
        if (activities.isNotEmpty) ...[
          const SizedBox(height: 16),
          const SectionHeader('Recent Activity'),
          ...activities.map((act) => _activityTile(context, act)),
        ],

        // ── 10. Recent Notes ───────────────────────────────────────────
        const SizedBox(height: 14),
        SectionHeader(
          'Recent Notes',
          action: TextButton(
            onPressed: () => onNavigate(2),
            child: const Text('View All', style: TextStyle(fontSize: 12)),
          ),
        ),
        if (recentNotes.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: Text('No notes created yet',
                style: TextStyle(
                    color: textSecondaryColor(context), fontSize: 13.5)),
          )
        else
          ...recentNotes.take(3).map((n) => NoteTile(
                note: n,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NoteEditorPage(noteId: n.id),
                  ),
                ),
              )),
      ],
    );
  }

  Widget _activityTile(BuildContext context, _Activity act) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: act.color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(act.icon, size: 16, color: act.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    act.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    act.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              act.timeAgo,
              style: TextStyle(
                fontSize: 11,
                color: textSecondaryColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        NexaHaptics.tick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: surfaceColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor(context),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 12, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_Activity> _buildRecentActivities(AppData data) {
    final list = <_Activity>[];

    // Tasks completed or created
    for (final t in data.tasks.take(4)) {
      list.add(_Activity(
        title: t.title,
        subtitle: t.isCompleted ? 'Task completed' : 'Task pending',
        timestamp: t.completedAt ?? t.createdAt,
        icon: t.isCompleted ? LucideIcons.checkCircle2 : LucideIcons.circle,
        color: t.isCompleted ? NexaColors.success : NexaColors.lightPrimary,
      ));
    }

    // Expenses added
    for (final e in data.expenses.take(4)) {
      list.add(_Activity(
        title: e.note.isEmpty ? e.category : e.note,
        subtitle: '${e.type == 'income' ? 'Income' : 'Expense'} recorded',
        timestamp: e.createdAt,
        icon: LucideIcons.wallet,
        color: e.type == 'income' ? NexaColors.success : NexaColors.danger,
      ));
    }

    // Notes modified
    for (final n in data.notes.take(3)) {
      list.add(_Activity(
        title: n.title.isEmpty ? 'Untitled Note' : n.title,
        subtitle: 'Note edited',
        timestamp: n.updatedAt,
        icon: LucideIcons.fileText,
        color: NexaColors.catEntertainment,
      ));
    }

    // Sort descending by timestamp
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list.take(5).toList();
  }
}

class _Activity {
  final String title;
  final String subtitle;
  final String timestamp;
  final IconData icon;
  final Color color;

  const _Activity({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    required this.color,
  });

  String get timeAgo {
    try {
      final dt = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return '';
    }
  }
}
