import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/animations.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../data/app_store.dart';
import '../../widgets/glass.dart';
import '../../widgets/logo.dart';

/// Premium first-run onboarding experience with PageView swipe, animated orbs,
/// and personal name input.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageCtrl = PageController();
  final TextEditingController _nameCtrl = TextEditingController(text: 'User');
  int _page = 0;

  static const _pages = [
    _OnboardSlide(
      icon: LucideIcons.sparkles,
      title: 'Welcome to Nexora',
      subtitle: 'Your All-in-One Life & Work OS',
      body:
          'Tasks, Notes, Expenses, Resources, and Khata — integrated seamlessly into a calm, offline-first experience.',
      gradient: NexaColors.gradPrimary,
    ),
    _OnboardSlide(
      icon: LucideIcons.checkSquare,
      title: 'Smart Task Management',
      subtitle: 'Natural Language & Subtasks',
      body:
          'Type "Pay bills tomorrow 6pm #finance" for instant scheduling. Organise with Kanban boards, calendar views, and streak tracking.',
      gradient: NexaColors.gradCool,
    ),
    _OnboardSlide(
      icon: LucideIcons.fileText,
      title: 'Rich Markdown Notes',
      subtitle: 'Folders, Tags & Formatting',
      body:
          'Capture thoughts with live Markdown preview, quick formatting toolbar, color accents, and meeting templates.',
      gradient: NexaColors.gradWarm,
    ),
    _OnboardSlide(
      icon: LucideIcons.wallet,
      title: 'Financial Insights',
      subtitle: 'Expenses & Budget Alerts',
      body:
          'Track spending by category, set monthly budgets with progress rings, and inspect visual spending reports.',
      gradient: NexaColors.gradSuccess,
    ),
    _OnboardSlide(
      icon: LucideIcons.bookOpen,
      title: 'Khata (Hisaab-Kitaab)',
      subtitle: 'Person-Based Financial Ledger',
      body:
          'Track who owes you and who you owe. Manage transactions per person with running balances and instant summaries.',
      gradient: NexaColors.gradKhata,
    ),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _finish() {
    NexaHaptics.success();
    final name = _nameCtrl.text.trim();
    ref.read(appStoreProvider.notifier).updateUser(
          (u) => u.copyWith(
            onboarded: true,
            name: name.isEmpty ? 'User' : name,
          ),
        );
  }

  void _nextPage() {
    NexaHaptics.tick();
    if (_page < _pages.length - 1) {
      _pageCtrl.nextPage(
          duration: NexaAnim.normal, curve: NexaAnim.smooth);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentGradient = _pages[_page].gradient;

    return Scaffold(
      body: GradientBackground(
        colors: currentGradient,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                // Top header skip
                Align(
                  alignment: Alignment.centerRight,
                  child: _page < _pages.length - 1
                      ? TextButton(
                          onPressed: _finish,
                          child: Text('Skip',
                              style: TextStyle(
                                  color: textSecondaryColor(context),
                                  fontWeight: FontWeight.w600)),
                        )
                      : const SizedBox(height: 48),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: _pages.length,
                    itemBuilder: (ctx, i) {
                      final slide = _pages[i];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon orb or Nexora Logo
                          if (i == 0)
                            const NexoraLogo(size: 110, showGlow: true)
                          else
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: slide.gradient,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: slide.gradient[0].withOpacity(0.4),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(slide.icon,
                                  size: 50, color: Colors.white),
                            ),
                          const SizedBox(height: 32),

                          // Title
                          Text(
                            slide.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          if (slide.subtitle != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              slide.subtitle!,
                              style: TextStyle(
                                color: primaryColor(context),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Body
                          Text(
                            slide.body,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              height: 1.5,
                              color: textSecondaryColor(context),
                              fontSize: 15,
                            ),
                          ),

                          // If last page: Name input field
                          if (i == _pages.length - 1) ...[
                            const SizedBox(height: 24),
                            GlassCard(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: TextField(
                                controller: _nameCtrl,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  hintText: 'What is your name?',
                                ),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),

                // Indicator dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: NexaAnim.fast,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: active
                            ? LinearGradient(colors: currentGradient)
                            : null,
                        color: active ? null : borderColor(context),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 28),

                // Action button
                GradientButton(
                  _page < _pages.length - 1 ? 'Continue' : "Get Started with Nexora",
                  gradient: currentGradient,
                  onPressed: _nextPage,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardSlide {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String body;
  final List<Color> gradient;
  const _OnboardSlide({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.body,
    required this.gradient,
  });
}
