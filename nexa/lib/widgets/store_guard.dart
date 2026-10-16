import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../core/animations.dart';
import '../core/theme.dart';
import '../data/app_store.dart';
import '../data/models.dart';
import 'glass.dart';

/// Bridges the async [AppStore] to UI. Shows a shimmer skeleton while loading
/// and a retry affordance on error — so consumers just deal with [AppData].
class StoreGuard extends ConsumerWidget {
  final Widget Function(AppData data) child;
  const StoreGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(appStoreProvider);
    return async.when(
      loading: () => const _Skeleton(),
      error: (e, _) => _ErrorState(message: e.toString(), ref: ref),
      data: child,
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, i) => StaggeredFadeIn(
        index: i,
        child: const ShimmerBox(height: 72),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final WidgetRef ref;
  const _ErrorState({required this.message, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: NexaColors.danger),
            const SizedBox(height: 12),
            const Text('Something went wrong',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: textSecondaryColor(context))),
            const SizedBox(height: 16),
            GradientButton('Retry',
                onPressed: () => ref.invalidate(appStoreProvider)),
          ],
        ),
      ),
    );
  }
}

/// Wraps a list so each child fades + slides in with a stagger.
class StaggeredListView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  const StaggeredListView({super.key, required this.itemCount, required this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: ListView.builder(
        shrinkWrap: false,
        itemCount: itemCount,
        itemBuilder: (ctx, i) => AnimationConfiguration.staggeredList(
          position: i,
          duration: const Duration(milliseconds: 350),
          child: SlideAnimation(
            verticalOffset: 24,
            child: FadeInAnimation(child: itemBuilder(ctx, i)),
          ),
        ),
      ),
    );
  }
}
