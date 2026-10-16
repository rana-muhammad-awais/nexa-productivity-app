import 'package:flutter/services.dart';

/// ─── Nexa Haptics ─────────────────────────────────────────────────────────
/// Semantic haptic feedback that makes interactions feel tactile and premium.
/// Every major action (complete, add, delete, navigate) has a distinct feel.

class NexaHaptics {
  NexaHaptics._();

  static bool enabled = true;

  /// Lightest tap — selecting chips, toggling filters, minor interactions.
  static void light() {
    if (enabled) HapticFeedback.lightImpact();
  }

  /// Standard tap — button presses, navigation, item selection.
  static void medium() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  /// Strong tap — destructive actions, drag-and-drop release.
  static void heavy() {
    if (enabled) HapticFeedback.heavyImpact();
  }

  /// Tick — selection changes, toggle switches, segment controls.
  static void tick() {
    if (enabled) HapticFeedback.selectionClick();
  }

  /// Selection change alias
  static void selection() {
    if (enabled) HapticFeedback.selectionClick();
  }

  /// Success — task completion, expense saved, note saved.
  static void success() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  /// Error — validation failure, delete confirmation.
  static void error() {
    if (enabled) HapticFeedback.heavyImpact();
  }

  /// Warning — approaching budget limit, low stock alert tap.
  static void warning() {
    if (enabled) HapticFeedback.lightImpact();
  }

  /// Tab change — bottom nav tap with distinct feel.
  static void tabChange() {
    if (enabled) HapticFeedback.selectionClick();
  }

  /// FAB pressed — the primary action button.
  static void fab() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  /// Swipe action triggered (dismiss/complete threshold reached).
  static void swipeAction() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  /// Timer tick (Pomodoro focus timer countdown pulse).
  static void timerTick() {
    if (enabled) HapticFeedback.lightImpact();
  }

  /// Timer complete — focus session ended.
  static void timerComplete() {
    if (enabled) HapticFeedback.heavyImpact();
  }
}
