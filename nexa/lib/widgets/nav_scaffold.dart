import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/animations.dart';
import '../core/haptics.dart';
import '../core/theme.dart';
import '../data/app_store.dart';
import '../data/models.dart';
import '../features/expenses/expenses_page.dart';
import '../features/home/home_page.dart';
import '../features/khata/khata_page.dart';
import '../features/notes/notes_page.dart';
import '../features/resources/resources_page.dart';
import '../features/tasks/tasks_page.dart';
import 'glass.dart';
import 'logo.dart';
import 'nav.dart';

/// Root shell: gradient canvas + floating glass nav with embedded FAB.
class NavScaffold extends ConsumerStatefulWidget {
  const NavScaffold({super.key});

  @override
  ConsumerState<NavScaffold> createState() => _NavScaffoldState();
}

class _NavScaffoldState extends ConsumerState<NavScaffold> {
  int _index = 0;

  static const _titles = [
    'Home', 'Tasks', 'Notes', 'Money', 'Vault', 'Khata',
  ];

  void _goTo(int i) {
    if (i == _index) return;
    setState(() => _index = i);
  }

  Future<void> _onFab() async {
    if (_index != 0) {
      _addDirect(_index);
      return;
    }
    final action = await showQuickAddMenu(context);
    if (action == null || !mounted) return;
    switch (action) {
      case 'task':
        setState(() => _index = 1);
        if (mounted) await TasksPage.openAdder(context);
      case 'note':
        setState(() => _index = 2);
        if (mounted) await NotesPage.openAdder(context);
      case 'expense':
        setState(() => _index = 3);
        if (mounted) await ExpensesPage.openAdder(context);
      case 'resource':
        setState(() => _index = 4);
        if (mounted) await ResourcesPage.openAdder(context);
      case 'khata':
        setState(() => _index = 5);
        if (mounted) await KhataPage.openAdder(context);
    }
  }

  void _addDirect(int index) async {
    switch (index) {
      case 1:
        await TasksPage.openAdder(context);
      case 2:
        await NotesPage.openAdder(context);
      case 3:
        await ExpensesPage.openAdder(context);
      case 4:
        await ResourcesPage.openAdder(context);
      case 5:
        await KhataPage.openAdder(context);
    }
  }

  void _cycleTheme() {
    NexaHaptics.tick();
    final cur = ref.read(appStoreProvider).requireValue.user.theme;
    final next = cur == 'dark' ? 'light' : 'dark';
    ref.read(appStoreProvider.notifier).updateUser((u) => u.copyWith(theme: next));
  }

  Map<int, int> _buildBadges(AppData data) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final overdue = data.tasks
        .where((t) => !t.isCompleted && t.dueDate != null && t.dueDate!.compareTo(today) < 0)
        .length;
    // Renewals within 3 days
    final urgentRenewals = data.resources
        .where((r) {
          if (r.renewalDate == null) return false;
          final d = DateTime.tryParse(r.renewalDate!);
          if (d == null) return false;
          return d.difference(DateTime.now()).inDays <= 3 &&
              d.difference(DateTime.now()).inDays >= 0;
        })
        .length;
    return {
      if (overdue > 0) 1: overdue,
      if (urgentRenewals > 0) 4: urgentRenewals,
    };
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appStoreProvider);
    final badges = data.hasValue ? _buildBadges(data.requireValue) : <int, int>{};
    final user = data.hasValue ? data.requireValue.user : null;

    return Scaffold(
      extendBody: false,
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top bar — brand logo / title + profile & action icons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 12, 6),
                child: Row(
                  children: [
                    if (_index == 0) ...[
                      const NexoraLogo(size: 36, showGlow: true),
                      const SizedBox(width: 10),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: NexaColors.gradPrimary,
                        ).createShader(bounds),
                        child: const Text(
                          'Nexora',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor(context).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: primaryColor(context).withOpacity(0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'OS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: primaryColor(context),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Other tabs: Back / Profile avatar & title
                      GestureDetector(
                        onTap: () => Navigator.of(context).pushNamed('/settings'),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: NexaColors.gradPrimary,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              (user?.name ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _titles[_index],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Theme toggle
                    _topActionBtn(
                      onTap: _cycleTheme,
                      child: AnimatedSwitcher(
                        duration: NexaAnim.normal,
                        transitionBuilder: (child, anim) => RotationTransition(
                          turns: Tween(begin: 0.75, end: 1.0).animate(anim),
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: Icon(
                          isDark(context) ? LucideIcons.sun : LucideIcons.moon,
                          key: ValueKey(isDark(context)),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Search
                    _topActionBtn(
                      onTap: () => Navigator.of(context).pushNamed('/search'),
                      child: const Icon(LucideIcons.search, size: 18),
                    ),
                    const SizedBox(width: 6),
                    // Settings
                    _topActionBtn(
                      onTap: () =>
                          Navigator.of(context).pushNamed('/settings'),
                      child: const Icon(LucideIcons.settings, size: 18),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: NexaAnim.normal,
                  switchInCurve: NexaAnim.smooth,
                  switchOutCurve: NexaAnim.smooth,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.02),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_index),
                    child: _buildPage(_index),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // No separate FAB — it's embedded in the nav bar now
      bottomNavigationBar: NexaBottomNav(
        index: _index,
        onTap: _goTo,
        onFab: _onFab,
        badges: badges,
      ),
    );
  }

  Widget _buildPage(int index) => switch (index) {
        0 => HomePage(onNavigate: _goTo),
        1 => const TasksPage(),
        2 => const NotesPage(),
        3 => const ExpensesPage(),
        4 => const ResourcesPage(),
        5 => const KhataPage(),
        _ => const SizedBox.shrink(),
      };

  Widget _topActionBtn({required VoidCallback onTap, required Widget child}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: surfaceColor(context).withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor(context).withOpacity(0.6),
          width: 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Exposed so other modules can navigate; kept here for locality.
extension NavExtras on BuildContext {
  void popToRoot() => Navigator.of(this).popUntil((r) => r.isFirst);
}
