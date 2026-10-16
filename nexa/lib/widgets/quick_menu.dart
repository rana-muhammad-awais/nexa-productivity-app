import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/theme.dart';

/// Context-aware quick-add menu shown by the FAB on the Home tab
/// (mirrors the web app's quick-menu: Task / Note / Expense / Resource).
class QuickAddMenu {
  final String action; // 'task' | 'note' | 'expense' | 'resource'
  final String label;
  final IconData icon;
  final Color color;
  const QuickAddMenu({
    required this.action,
    required this.label,
    required this.icon,
    required this.color,
  });
}

const quickAddItems = <QuickAddMenu>[
  QuickAddMenu(
      action: 'task', label: 'Add Task', icon: LucideIcons.checkSquare, color: Color(0xFF5B5FEF)),
  QuickAddMenu(
      action: 'note', label: 'Add Note', icon: LucideIcons.fileText, color: Color(0xFFF59E0B)),
  QuickAddMenu(
      action: 'expense', label: 'Add Expense', icon: LucideIcons.wallet, color: Color(0xFFEF4444)),
  QuickAddMenu(
      action: 'resource', label: 'Add Resource', icon: LucideIcons.folderLock, color: Color(0xFF22C55E)),
];

/// Shows the quick-add sheet and returns the chosen action, or null.
Future<String?> showQuickAddMenu(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Quick Add',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.1,
            children: quickAddItems
                .map((item) => _QuickTile(
                      item: item,
                      onTap: () => Navigator.of(ctx).pop(item.action),
                    ))
                .toList(),
          ),
        ],
      ),
    ),
  );
}

class _QuickTile extends StatelessWidget {
  final QuickAddMenu item;
  final VoidCallback onTap;
  const _QuickTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor(context)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              item.label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
