import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/animations.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../services/notifications.dart';
import '../../widgets/glass.dart';
import '../../widgets/sheet.dart';

/// Habit Tracker with daily check-ins, skip/rest days, streak counters,
/// visual completion heatmap, and scheduled reminders.
class HabitsPage extends ConsumerStatefulWidget {
  const HabitsPage({super.key});

  @override
  ConsumerState<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends ConsumerState<HabitsPage> {
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appStoreProvider).valueOrNull;
    final habits = data?.habits ?? [];
    final completions = data?.habitCompletions ?? [];
    final today = todayIsoDate();

    final store = ref.read(appStoreProvider.notifier);

    // Calculate today's completion stats
    final totalHabits = habits.length;
    final completedToday = habits.where((h) {
      return completions.any((c) => c.habitId == h.id && c.date == today && c.count > 0);
    }).length;
    final pctToday = totalHabits > 0 ? (completedToday / totalHabits) * 100 : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        // Daily Progress Summary Card
        StaggeredFadeIn(
          index: 0,
          child: GradientBorderCard(
            gradient: pctToday >= 100
                ? NexaColors.gradSuccess
                : NexaColors.gradPrimary,
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Habit Goals',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondaryColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedToday / $totalHabits Completed',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pctToday >= 100
                            ? '🎉 Perfect! All habits conquered today.'
                            : '${(100 - pctToday).toStringAsFixed(0)}% remaining today',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: pctToday >= 100
                              ? NexaColors.success
                              : textSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: (pctToday >= 100
                            ? NexaColors.success
                            : NexaColors.lightPrimary)
                        .withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${pctToday.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: pctToday >= 100
                            ? NexaColors.success
                            : NexaColors.lightPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Add Habit Quick Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionHeader('Your Habits'),
            TextButton.icon(
              onPressed: () => _showAddHabitSheet(context),
              icon: const Icon(LucideIcons.plusCircle, size: 16),
              label: const Text('Add Habit', style: TextStyle(fontSize: 12.5)),
            ),
          ],
        ),

        if (habits.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(LucideIcons.sparkles,
                    size: 40, color: textSecondaryColor(context)),
                const SizedBox(height: 12),
                const Text(
                  'No habits tracked yet',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'Build positive daily routines like reading, working out, or drinking water.',
                  style: TextStyle(
                      color: textSecondaryColor(context), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                GradientButton(
                  'Create Your First Habit',
                  icon: LucideIcons.plus,
                  onPressed: () => _showAddHabitSheet(context),
                ),
              ],
            ),
          )
        else
          ...habits.asMap().entries.map((item) {
            final h = item.value;
            final isDoneToday = completions.any(
                (c) => c.habitId == h.id && c.date == today && c.count > 0);
            final isSkippedToday = completions.any(
                (c) => c.habitId == h.id && c.date == today && c.skipped);
            final currentStreak = store.habitCurrentStreak(h.id);
            final bestStreak = store.habitBestStreak(h.id);
            final color = _habitColor(h.color);

            return StaggeredFadeIn(
              index: item.key + 1,
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Habit Title Row with Action Toggles
                    Row(
                      children: [
                        // Checkbox Tap
                        GestureDetector(
                          onTap: () {
                            NexaHaptics.tick();
                            store.toggleHabitCompletion(h.id, today);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDoneToday
                                  ? color
                                  : (isSkippedToday
                                      ? NexaColors.warning.withOpacity(0.2)
                                      : color.withOpacity(0.12)),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDoneToday
                                    ? color
                                    : (isSkippedToday
                                        ? NexaColors.warning
                                        : color.withOpacity(0.4)),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              isDoneToday
                                  ? LucideIcons.check
                                  : (isSkippedToday
                                      ? LucideIcons.coffee
                                      : _habitIcon(h.icon)),
                              size: 18,
                              color: isDoneToday
                                  ? Colors.white
                                  : (isSkippedToday
                                      ? NexaColors.warning
                                      : color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title & Frequency Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                h.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  decoration: isDoneToday
                                      ? TextDecoration.none
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    capitalize(h.frequency),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: textSecondaryColor(context),
                                    ),
                                  ),
                                  if (h.reminderTime != null) ...[
                                    Text(' · ⏰ ${h.reminderTime}',
                                        style: TextStyle(
                                            fontSize: 11.5,
                                            color:
                                                textSecondaryColor(context))),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Streak Indicator Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: NexaColors.warning.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.flame,
                                  size: 15, color: NexaColors.warning),
                              const SizedBox(width: 4),
                              Text(
                                '$currentStreak',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: NexaColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),

                        // More Menu (Skip, Delete)
                        PopupMenuButton<String>(
                          icon: Icon(LucideIcons.moreVertical,
                              size: 18, color: textSecondaryColor(context)),
                          onSelected: (val) {
                            if (val == 'skip') {
                              NexaHaptics.tick();
                              store.skipHabitDay(h.id, today);
                            } else if (val == 'delete') {
                              NexaHaptics.medium();
                              store.deleteHabit(h.id);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'skip',
                              child: Text(isSkippedToday
                                  ? 'Unmark Rest Day'
                                  : 'Mark Rest Day (Keep streak)'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete Habit',
                                  style: TextStyle(color: NexaColors.danger)),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 14-Day Micro Heatmap Bar
                    _HeatmapRow(
                      habitId: h.id,
                      completions: completions,
                      accentColor: color,
                    ),

                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current: $currentStreak days · Best: $bestStreak days',
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondaryColor(context),
                          ),
                        ),
                        if (isDoneToday)
                          const Text(
                            'Completed today ✨',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: NexaColors.success,
                            ),
                          )
                        else if (isSkippedToday)
                          const Text(
                            'Rest day taken ☕',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: NexaColors.warning,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  void _showAddHabitSheet(BuildContext context) {
    showNexaSheet(
      context,
      title: 'New Habit',
      initialSize: 0.72,
      builder: (_) => const _AddHabitSheet(),
    );
  }

  Color _habitColor(String key) => switch (key) {
        'blue' => NexaColors.noteBlue,
        'purple' => NexaColors.notePurple,
        'green' => NexaColors.noteGreen,
        'orange' => NexaColors.noteOrange,
        'pink' => NexaColors.notePink,
        _ => NexaColors.lightPrimary,
      };

  IconData _habitIcon(String icon) => switch (icon) {
        'book' => LucideIcons.book,
        'dumbbell' => LucideIcons.dumbbell,
        'droplet' => LucideIcons.droplet,
        'heart' => LucideIcons.heart,
        'brain' => LucideIcons.brain,
        'code' => LucideIcons.code,
        _ => LucideIcons.check,
      };
}

class _HeatmapRow extends StatelessWidget {
  final String habitId;
  final List<HabitCompletion> completions;
  final Color accentColor;

  const _HeatmapRow({
    required this.habitId,
    required this.completions,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayList = List.generate(14, (i) => now.subtract(Duration(days: 13 - i)));

    return Row(
      children: dayList.map((d) {
        final dStr =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        final isCompleted = completions
            .any((c) => c.habitId == habitId && c.date == dStr && c.count > 0);
        final isSkipped = completions
            .any((c) => c.habitId == habitId && c.date == dStr && c.skipped);

        final fill = isCompleted
            ? accentColor
            : (isSkipped
                ? NexaColors.warning.withOpacity(0.4)
                : Colors.white.withOpacity(0.08));

        return Expanded(
          child: Container(
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AddHabitSheet extends ConsumerStatefulWidget {
  const _AddHabitSheet();

  @override
  ConsumerState<_AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends ConsumerState<_AddHabitSheet> {
  final _name = TextEditingController();
  String _frequency = 'daily';
  final String _color = 'purple';
  final String _icon = 'check';
  String? _reminderTime = '08:00';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;

    final habit = ref.read(appStoreProvider.notifier).addHabit(
          name: name,
          frequency: _frequency,
          reminderTime: _reminderTime,
          color: _color,
          icon: _icon,
        );

    // Schedule notification if reminder set
    if (_reminderTime != null) {
      NotificationService.instance.scheduleHabitReminder(
        habitId: habit.id,
        habitName: habit.name,
        time: _reminderTime!,
      );
    }

    NexaHaptics.success();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Habit Name',
            hintText: 'e.g. Read 20 pages, 30 min workout, Drink water',
            prefixIcon: Icon(LucideIcons.sparkles, size: 18),
          ),
        ),
        const SizedBox(height: 14),

        // Frequency Selector
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'daily', label: Text('Daily')),
            ButtonSegment(value: 'weekly', label: Text('Weekly')),
          ],
          selected: {_frequency},
          onSelectionChanged: (s) => setState(() => _frequency = s.first),
        ),
        const SizedBox(height: 14),

        // Reminder Time Picker
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(LucideIcons.bell, size: 20),
          title: const Text('Daily Reminder'),
          trailing: Text(
            _reminderTime ?? 'Off',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          onTap: () async {
            final t = await showTimePicker(
              context: context,
              initialTime: const TimeOfDay(hour: 8, minute: 0),
            );
            if (t != null) {
              setState(() {
                _reminderTime =
                    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
              });
            }
          },
        ),
        const SizedBox(height: 18),

        GradientButton('Create Habit', icon: LucideIcons.plus, onPressed: _submit),
        const SizedBox(height: 12),
      ],
    );
  }
}
