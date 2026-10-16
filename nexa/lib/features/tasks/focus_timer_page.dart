import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../data/app_store.dart';
import '../../widgets/glass.dart';

enum _SessionMode { focus, shortBreak, longBreak }

/// Full-featured Pomodoro Focus Timer with circular progress,
/// custom intervals, task linkage, haptic ticks, and session analytics.
class FocusTimerPage extends ConsumerStatefulWidget {
  const FocusTimerPage({super.key});

  @override
  ConsumerState<FocusTimerPage> createState() => _FocusTimerPageState();
}

class _FocusTimerPageState extends ConsumerState<FocusTimerPage>
    with SingleTickerProviderStateMixin {
  _SessionMode _mode = _SessionMode.focus;
  final int _focusDuration = 25; // minutes
  final int _shortBreakDuration = 5;
  final int _longBreakDuration = 15;

  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  String? _linkedTaskId;
  int _completedSessionsToday = 0;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _currentDurationMinutes => switch (_mode) {
        _SessionMode.focus => _focusDuration,
        _SessionMode.shortBreak => _shortBreakDuration,
        _SessionMode.longBreak => _longBreakDuration,
      };

  int get _totalSeconds => _currentDurationMinutes * 60;

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _totalSeconds;
    });
  }

  void _toggleTimer() {
    if (_isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    NexaHaptics.medium();
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        if (_remainingSeconds % 60 == 0) {
          NexaHaptics.timerTick();
        }
      } else {
        _onSessionComplete();
      }
    });
  }

  void _pauseTimer() {
    NexaHaptics.light();
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _onSessionComplete() {
    _timer?.cancel();
    NexaHaptics.timerComplete();

    if (_mode == _SessionMode.focus) {
      // Record completed focus session in app store
      ref.read(appStoreProvider.notifier).startFocusSession(
            type: 'focus',
            durationMinutes: _focusDuration,
            linkedTaskId: _linkedTaskId,
          );

      setState(() {
        _completedSessionsToday++;
        // Cycle: 4 focus sessions then long break, otherwise short break
        if (_completedSessionsToday % 4 == 0) {
          _mode = _SessionMode.longBreak;
        } else {
          _mode = _SessionMode.shortBreak;
        }
      });
    } else {
      setState(() {
        _mode = _SessionMode.focus;
      });
    }

    _resetTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _mode == _SessionMode.focus
              ? '✨ Break over! Ready to focus?'
              : '🎉 Great job! Time for a well-deserved break.',
        ),
      ),
    );
  }

  void _switchMode(_SessionMode m) {
    if (_mode == m) return;
    NexaHaptics.selection();
    _timer?.cancel();
    setState(() {
      _mode = m;
      _isRunning = false;
      _remainingSeconds = _totalSeconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final data = ref.watch(appStoreProvider).valueOrNull;
    final tasks = data?.tasks.where((t) => !t.isCompleted).toList() ?? [];

    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final progress = _totalSeconds > 0
        ? ((_totalSeconds - _remainingSeconds) / _totalSeconds) * 100
        : 0.0;

    final themeColor = switch (_mode) {
      _SessionMode.focus => NexaColors.lightPrimary,
      _SessionMode.shortBreak => NexaColors.success,
      _SessionMode.longBreak => NexaColors.info,
    };

    final todayMinutes =
        ref.read(appStoreProvider.notifier).todayFocusMinutes();
    final weekSessions =
        ref.read(appStoreProvider.notifier).weekFocusSessions();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Mode Switcher Pills
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: dark ? NexaColors.darkSurface2 : NexaColors.lightSurface2,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _modeButton('Focus', _SessionMode.focus, NexaColors.lightPrimary),
                _modeButton('Short Break', _SessionMode.shortBreak, NexaColors.success),
                _modeButton('Long Break', _SessionMode.longBreak, NexaColors.info),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Circular Countdown Dial with ProgressRing
          ProgressRing(
            percent: progress,
            size: 260,
            stroke: 12,
            gradient: [themeColor, themeColor.withOpacity(0.75)],
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    color: dark ? NexaColors.darkText : NexaColors.lightText,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    switch (_mode) {
                      _SessionMode.focus => 'Deep Focus',
                      _SessionMode.shortBreak => 'Short Rest',
                      _SessionMode.longBreak => 'Long Rest',
                    },
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: themeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Control Buttons (Reset, Play/Pause, Skip)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Reset Button
              IconButton(
                onPressed: _resetTimer,
                iconSize: 26,
                icon: const Icon(LucideIcons.rotateCcw),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor:
                      dark ? NexaColors.darkSurface2 : NexaColors.lightSurface2,
                ),
              ),
              const SizedBox(width: 20),

              // Play / Pause Primary Button
              GestureDetector(
                onTap: _toggleTimer,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [themeColor, themeColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.withOpacity(0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRunning ? LucideIcons.pause : LucideIcons.play,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Skip Button
              IconButton(
                onPressed: _onSessionComplete,
                iconSize: 26,
                icon: const Icon(LucideIcons.skipForward),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor:
                      dark ? NexaColors.darkSurface2 : NexaColors.lightSurface2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Optional: Link to Active Task
          if (tasks.isNotEmpty) ...[
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(LucideIcons.target, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _linkedTaskId,
                        hint: const Text('Focus on a specific task...'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('General Focus (No task linked)'),
                          ),
                          ...tasks.map((t) => DropdownMenuItem<String?>(
                                value: t.id,
                                child: Text(t.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (val) => setState(() => _linkedTaskId = val),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Focus Analytics Stats Row
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.zap,
                              size: 16, color: NexaColors.warning),
                          const SizedBox(width: 6),
                          Text('Today',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondaryColor(context))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$todayMinutes min',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.calendarCheck,
                              size: 16, color: NexaColors.success),
                          const SizedBox(width: 6),
                          Text('This Week',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondaryColor(context))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$weekSessions sessions',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeButton(String title, _SessionMode mode, Color activeColor) {
    final active = _mode == mode;
    final dark = isDark(context);

    return Expanded(
      child: GestureDetector(
        onTap: () => _switchMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? (dark
                    ? activeColor.withOpacity(0.2)
                    : activeColor.withOpacity(0.12))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: active
                ? Border.all(color: activeColor.withOpacity(0.5), width: 1.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active
                  ? activeColor
                  : (dark ? NexaColors.darkTextSec : NexaColors.lightTextSec),
            ),
          ),
        ),
      ),
    );
  }
}
