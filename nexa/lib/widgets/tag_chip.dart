import 'package:flutter/material.dart';

import '../core/theme.dart';

class TagChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool filled;
  const TagChip(this.label, {super.key, this.color, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final c = color ?? primaryColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(filled ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: c,
        ),
      ),
    );
  }
}

class PriorityDot extends StatelessWidget {
  final String priority;
  const PriorityDot(this.priority, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: NexaColors.priorityColor(priority),
        shape: BoxShape.circle,
      ),
    );
  }
}
