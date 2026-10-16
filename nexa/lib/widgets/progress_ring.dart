// Re-export ProgressRing from glass.dart (the enhanced animated version).
// StatCard, BudgetBar, TagChipRaw are kept here.
export '../widgets/glass.dart' show ProgressRing;

import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Stat card for the dashboard grids.
class StatCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const StatCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor(context)),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: card,
    );
  }
}

/// A horizontal budget progress bar with label + value above it.
class BudgetBar extends StatelessWidget {
  final String label;
  final double spent;
  final double? limit;
  final Color color;
  const BudgetBar({
    super.key,
    required this.label,
    required this.spent,
    this.limit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (limit != null && limit! > 0)
        ? (spent / limit!).clamp(0.0, 1.0)
        : 0.0;
    final over = limit != null && spent >= limit!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              TagChipRaw(label, color),
              const Spacer(),
              Text(
                limit != null
                    ? '${_fmt(spent)} / ${_fmt(limit!)}'
                    : _fmt(spent),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          if (limit != null) ...[
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: borderColor(context),
                  valueColor:
                      AlwaysStoppedAnimation(over ? NexaColors.danger : color),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(double v) => v == v.roundToDouble()
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(2);
}

class TagChipRaw extends StatelessWidget {
  final String label;
  final Color color;
  const TagChipRaw(this.label, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
