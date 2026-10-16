import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/animations.dart';
import '../core/haptics.dart';
import '../core/theme.dart';
import 'glass.dart';

/// Height of the nav bar content (icon + label + padding).
const _kNavBarHeight = 68.0;

/// Premium floating glass bottom nav bar with embedded center FAB, glossy finish,
/// sliding gradient active pill + badge dots. Layout: 3 tabs | [+] | 3 tabs.
class NexaBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onFab;
  final Map<int, int> badges;
  const NexaBottomNav({
    super.key,
    required this.index,
    required this.onTap,
    required this.onFab,
    this.badges = const {},
  });

  static const _items = [
    _NavItem('Home', LucideIcons.home),
    _NavItem('Tasks', LucideIcons.checkSquare),
    _NavItem('Notes', LucideIcons.fileText),
    // Center FAB goes here (index 3 in layout, not a real tab)
    _NavItem('Money', LucideIcons.wallet),
    _NavItem('Vault', LucideIcons.folderLock),
    _NavItem('Khata', LucideIcons.bookOpen),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final dark = isDark(context);

    return Container(
      height: _kNavBarHeight + 14 + bottomPad,
      padding: EdgeInsets.fromLTRB(12, 0, 12, 14 + bottomPad),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            height: _kNavBarHeight,
            decoration: BoxDecoration(
              color: dark
                  ? const Color(0xFF12121E).withOpacity(0.92)
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: dark
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFFE8E6E1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(dark ? 0.35 : 0.08),
                  blurRadius: 20,
                  spreadRadius: -4,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Top highlight line (glossy shine)
                Positioned(
                  top: 0,
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0),
                          Colors.white.withOpacity(dark ? 0.15 : 0.4),
                          Colors.white.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Content
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Nav items row with center FAB
                        SizedBox(
                          height: _kNavBarHeight,
                          child: Row(
                            children: [
                              ...List.generate(3, (i) {
                                final item = _items[i];
                                final active = i == index;
                                final badge = badges[i] ?? 0;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      NexaHaptics.tabChange();
                                      onTap(i);
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: _NavItemWidget(
                                      item: item,
                                      active: active,
                                      badge: badge,
                                    ),
                                  ),
                                );
                              }),
                              Expanded(
                                child: _CenterFab(onTap: onFab),
                              ),
                              ...List.generate(3, (j) {
                                final tabIndex = j + 3;
                                final item = _items[tabIndex];
                                final active = tabIndex == index;
                                final badge = badges[tabIndex] ?? 0;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      NexaHaptics.tabChange();
                                      onTap(tabIndex);
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: _NavItemWidget(
                                      item: item,
                                      active: active,
                                      badge: badge,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Raised gradient center FAB that sits within the nav bar.
class _CenterFab extends StatelessWidget {
  final VoidCallback onTap;
  const _CenterFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PressableScale(
        onTap: () {
          NexaHaptics.fab();
          onTap();
        },
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: NexaColors.gradPrimary,
            ),
            boxShadow: [
              BoxShadow(
                color: NexaColors.gradPrimary[0].withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(LucideIcons.plus, size: 22, color: Colors.white),
        ),
      ),
    );
  }
}

class _NavItemWidget extends StatefulWidget {
  final _NavItem item;
  final bool active;
  final int badge;
  const _NavItemWidget({
    required this.item,
    required this.active,
    required this.badge,
  });

  @override
  State<_NavItemWidget> createState() => _NavItemWidgetState();
}

class _NavItemWidgetState extends State<_NavItemWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _bounce = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.08), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_NavItemWidget old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _bounceCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = primaryColor(context);
    return AnimatedBuilder(
      animation: _bounce,
      builder: (_, __) => Transform.scale(
        scale: _bounce.value,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(widget.item.icon,
                      size: 20,
                      color: widget.active
                          ? accentColor
                          : textSecondaryColor(context)),
                  if (widget.badge > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: NexaColors.danger,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                            minWidth: 14, minHeight: 14),
                        child: Text(
                          widget.badge > 9 ? '9+' : '${widget.badge}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: widget.active ? FontWeight.w700 : FontWeight.w500,
                  color: widget.active
                      ? accentColor
                      : textSecondaryColor(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              // Active indicator dot
              AnimatedContainer(
                duration: NexaAnim.normal,
                curve: NexaAnim.smooth,
                width: widget.active ? 4 : 0,
                height: widget.active ? 4 : 0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}

/// Context-aware quick-add sheet for the Home tab FAB.
class QuickAddItem {
  final String action;
  final String label;
  final IconData icon;
  final List<Color> gradient;
  const QuickAddItem(this.action, this.label, this.icon, this.gradient);
}

const quickAddItems = [
  QuickAddItem('task', 'Add Task', LucideIcons.checkSquare, NexaColors.gradPrimary),
  QuickAddItem('note', 'Add Note', LucideIcons.fileText, NexaColors.gradWarm),
  QuickAddItem('expense', 'Add Expense', LucideIcons.wallet, [NexaColors.danger, NexaColors.catShopping]),
  QuickAddItem('resource', 'Add Resource', LucideIcons.folderLock, NexaColors.gradSuccess),
  QuickAddItem('khata', 'Add Khata Person', LucideIcons.bookOpen, NexaColors.gradKhata),
];

Future<String?> showQuickAddMenu(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    useSafeArea: true,
    builder: (ctx) => GlassCard(
      blur: 30,
      radius: 28,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: borderColor(ctx),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text('Quick Add',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          ...quickAddItems.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return StaggeredFadeIn(
              index: i,
              child: _QuickTile(
                item: item,
                onTap: () => Navigator.of(ctx).pop(item.action),
              ),
            );
          }),
        ],
      ),
    ),
  );
}

class _QuickTile extends StatelessWidget {
  final QuickAddItem item;
  final VoidCallback onTap;
  const _QuickTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor(context)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: item.gradient),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(item.icon, color: Colors.white, size: 19),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(item.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ),
                Icon(LucideIcons.chevronRight,
                    size: 16, color: textSecondaryColor(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
