import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'glass.dart';

/// Bottom sheet wrapper with consistent styling.
Future<T?> showNexaSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
  double initialSize = 0.6,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    useSafeArea: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: initialSize,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) => GlassCard(
        blur: 30,
        radius: 28,
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: textSecondaryColor(ctx).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(title,
                style: const TextStyle(
                    fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                controller: scrollController,
                child: builder(ctx),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Standardized field spacing.
const kFieldGap = SizedBox(height: 12);
