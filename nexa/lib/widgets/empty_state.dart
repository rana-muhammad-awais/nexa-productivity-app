// Re-export EmptyState from glass.dart (the enhanced version with gradient icon circle).
// SectionTitle is kept here for backward compat with home_page / expenses_page imports.
export '../widgets/glass.dart' show EmptyState;

import 'package:flutter/material.dart';

/// Small section header used inside scrollable pages.
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? action;
  final Color? color;
  const SectionTitle(this.text, {super.key, this.action, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Row(
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
          ),
          const Spacer(),
          if (action != null) action!,
        ],
      ),
    );
  }
}
