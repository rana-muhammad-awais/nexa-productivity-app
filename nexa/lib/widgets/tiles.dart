import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/constants.dart';
import '../core/haptics.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../data/models.dart';
import 'glass.dart';

// ─── Task Tile ───────────────────────────────────────────────────────────
class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  const TaskTile({super.key, required this.task, this.onTap, this.onToggle});

  @override
  Widget build(BuildContext context) {
    final overdue = isOverdue(task.dueDate, task.isCompleted);
    final subDone = task.subtasks.where((s) => s.done).length;
    final priorityCol = NexaColors.priorityColor(task.priority);

    return GlassCard(
      onTap: onTap,
      elevated: overdue && !task.isCompleted,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Checkbox with animated scale & haptics
          GestureDetector(
            onTap: () {
              NexaHaptics.tick();
              onToggle?.call();
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: task.isCompleted
                    ? const LinearGradient(
                        colors: [NexaColors.success, Color(0xFF14B8A6)])
                    : null,
                color: task.isCompleted ? null : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted
                      ? Colors.transparent
                      : borderColor(context).withOpacity(0.8),
                  width: 2,
                ),
                boxShadow: task.isCompleted
                    ? [
                        BoxShadow(
                          color: NexaColors.success.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: task.isCompleted
                  ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),

          // Priority bar
          Container(
            width: 3.5,
            height: 36,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: priorityCol,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: priorityCol.withOpacity(0.4),
                  blurRadius: 6,
                )
              ],
            ),
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: textSecondaryColor(context),
                    color: task.isCompleted
                        ? textSecondaryColor(context)
                        : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.dueDate != null ||
                    task.tags.isNotEmpty ||
                    task.subtasks.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 7,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (task.dueDate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: (overdue && !task.isCompleted
                                    ? NexaColors.danger
                                    : textSecondaryColor(context))
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.calendar,
                                size: 11,
                                color: overdue && !task.isCompleted
                                    ? NexaColors.danger
                                    : textSecondaryColor(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${formatDate(task.dueDate)}${task.dueTime != null ? ' · ${task.dueTime}' : ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: overdue && !task.isCompleted
                                      ? NexaColors.danger
                                      : textSecondaryColor(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ...task.tags.map((t) =>
                          GradientPill('#$t', color: primaryColor(context))),
                      if (task.subtasks.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: subDone == task.subtasks.length
                                ? NexaColors.success.withOpacity(0.12)
                                : surfaceColor(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.listChecks,
                                size: 11,
                                color: subDone == task.subtasks.length
                                    ? NexaColors.success
                                    : textSecondaryColor(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$subDone/${task.subtasks.length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: subDone == task.subtasks.length
                                      ? NexaColors.success
                                      : textSecondaryColor(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Note Tile ───────────────────────────────────────────────────────────
class NoteTile extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;
  const NoteTile({super.key, required this.note, this.onTap});

  @override
  Widget build(BuildContext context) {
    final preview = notePreview(note.body);
    final accentCol = NexaColors.noteColor(note.color);
    final hasColor = note.color != null && accentCol != NexaColors.noteDefault;

    return GlassCard(
      onTap: onTap,
      tint: hasColor ? accentCol.withOpacity(isDark(context) ? 0.12 : 0.08) : null,
      border: hasColor
          ? Border.all(color: accentCol.withOpacity(0.35), width: 1.2)
          : null,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (note.pinned) ...[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: NexaColors.warning.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(LucideIcons.pin,
                      size: 13, color: NexaColors.warning),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  note.title.isEmpty ? 'Untitled Note' : note.title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(LucideIcons.chevronRight,
                  size: 16, color: textSecondaryColor(context)),
            ],
          ),
          if (preview.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondaryColor(context),
                  height: 1.4,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: surfaceColor(context).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.folder,
                        size: 10, color: textSecondaryColor(context)),
                    const SizedBox(width: 4),
                    Text(
                      note.folderId,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: textSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                formatDate(note.updatedAt),
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondaryColor(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Expense Tile ────────────────────────────────────────────────────────
class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final String currency;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  const ExpenseTile({
    super.key,
    required this.expense,
    required this.currency,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = expense.type == 'income';
    final color = isIncome
        ? NexaColors.success
        : NexaColors.categoryColor(expense.category);
    final cat = kCategories[expense.category] ?? expense.category;

    return Dismissible(
      key: ValueKey(expense.id),
      direction: onDelete != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: NexaColors.danger.withOpacity(0.2),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(LucideIcons.trash2, color: NexaColors.danger),
      ),
      confirmDismiss: (_) async {
        onDelete?.call();
        return false;
      },
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            // Category icon with gradient box
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient:
                    LinearGradient(colors: [color, color.withOpacity(0.65)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                kCategoryIcons[expense.category] as IconData? ??
                    (isIncome ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.note.isEmpty ? cat : expense.note,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      GradientPill(cat, color: color),
                      const SizedBox(width: 6),
                      Text(
                        expense.date,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: textSecondaryColor(context),
                        ),
                      ),
                      if (expense.isRecurring) ...[
                        const SizedBox(width: 6),
                        const Icon(LucideIcons.repeat,
                            size: 11, color: NexaColors.catTransport),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${isIncome ? '+' : '-'}${formatCurrency(expense.amount, currency)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
                color: isIncome ? NexaColors.success : NexaColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Resource Tile ───────────────────────────────────────────────────────
class ResourceTile extends StatelessWidget {
  final Resource resource;
  final String currency;
  final VoidCallback? onTap;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const ResourceTile({
    super.key,
    required this.resource,
    required this.currency,
    this.onTap,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _style(resource.type);
    final sub = _subtitle(resource, currency);

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient:
                  LinearGradient(colors: [color, color.withOpacity(0.65)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sub.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      sub,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondaryColor(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          // If inventory: show +/- buttons
          if (resource.type == ResourceType.inventory &&
              onIncrement != null &&
              onDecrement != null) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  icon: const Icon(LucideIcons.minusCircle, size: 20),
                  onPressed: onDecrement,
                ),
                Text(
                  '${resource.quantity ?? 0}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  icon: const Icon(LucideIcons.plusCircle, size: 20),
                  onPressed: onIncrement,
                ),
              ],
            ),
          ] else ...[
            Icon(LucideIcons.chevronRight,
                size: 16, color: textSecondaryColor(context)),
          ],
        ],
      ),
    );
  }

  (IconData, Color) _style(ResourceType t) => switch (t) {
        ResourceType.subscription => (LucideIcons.repeat, NexaColors.catBills),
        ResourceType.inventory => (LucideIcons.package, NexaColors.catShopping),
        ResourceType.contact =>
          (LucideIcons.contact, NexaColors.catTransport),
        ResourceType.document => (LucideIcons.fileBadge, NexaColors.catFood),
        ResourceType.password => (LucideIcons.keyRound, NexaColors.catEntertainment),
        ResourceType.wifiPassword => (LucideIcons.wifi, NexaColors.catEducation),
        ResourceType.bankCard => (LucideIcons.creditCard, NexaColors.catInvestment),
      };

  String _subtitle(Resource r, String currency) {
    switch (r.type) {
      case ResourceType.subscription:
        final cost = r.details['cost'];
        final days = daysUntil(r.renewalDate);
        final costStr = cost != null
            ? '${formatCurrency((cost as num).toDouble(), currency)}/mo · '
            : '';
        return days == null
            ? 'No renewal date'
            : days <= 0
                ? 'Renews today'
                : '$costStr${days}d left';
      case ResourceType.inventory:
        final low = (r.quantity ?? 0) <= r.lowStockThreshold;
        return 'Qty: ${r.quantity ?? '?'}${low ? ' · ⚠️ Low' : ''}';
      case ResourceType.contact:
        return (r.details['phone'] ?? r.details['email'] ?? '').toString();
      case ResourceType.document:
        final expiry = r.details['expiry'];
        return expiry != null && expiry.toString().isNotEmpty
            ? 'Expires: $expiry'
            : (r.tags.isNotEmpty ? r.tags.join(', ') : 'Document');
      case ResourceType.password:
        return r.details['username']?.toString() ?? 'Stored password';
      case ResourceType.wifiPassword:
        return r.details['ssid']?.toString() ?? 'WiFi network';
      case ResourceType.bankCard:
        final last4 = r.details['lastFour']?.toString() ?? '••••';
        return '•••• •••• •••• $last4';
    }
  }
}
