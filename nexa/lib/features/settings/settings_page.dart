import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/animations.dart';
import '../../core/constants.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../services/auth_service.dart';
import '../../services/export.dart';
import '../../services/notifications.dart';
import '../../widgets/glass.dart';
import '../../widgets/lock_screen.dart';
import '../../widgets/logo.dart';
import '../../widgets/nav_scaffold.dart';
import '../../widgets/store_guard.dart';

/// Settings & Preferences — complete command center for customization,
/// notifications, data backup, appearance, and system settings.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: StoreGuard(
        child: (data) => _SettingsContent(data: data),
      ),
    );
  }
}

class _SettingsContent extends ConsumerWidget {
  final AppData data;
  const _SettingsContent({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = data.user;
    final store = ref.read(appStoreProvider.notifier);

    // Sync haptics enabled state
    NexaHaptics.enabled = user.hapticsEnabled;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 50),
      children: [
        // ── 1. Profile Header Card ───────────────────────────────────
        StaggeredFadeIn(
          index: 0,
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: NexaColors.gradPrimary),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user.name.isEmpty ? 'U' : user.name[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        'Nexora Personal OS · ${data.tasks.length} tasks · ${data.expenses.length} records',
                        style: TextStyle(
                            fontSize: 12, color: textSecondaryColor(context)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.edit2, size: 18),
                  onPressed: () => _editProfileName(context, store, user.name),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── 2. Appearance & Theme ────────────────────────────────────
        _sectionLabel(context, 'Appearance & Theme'),
        StaggeredFadeIn(
          index: 1,
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _settingRow(
                  context,
                  icon: LucideIcons.palette,
                  label: 'Theme Mode',
                  trailing: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'auto', label: Text('Auto')),
                      ButtonSegment(value: 'light', label: Text('Light')),
                      ButtonSegment(value: 'dark', label: Text('Dark')),
                    ],
                    selected: {user.theme},
                    onSelectionChanged: (s) {
                      NexaHaptics.tick();
                      store.updateUser((u) => u.copyWith(theme: s.first));
                    },
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
                const Divider(height: 1),
                _settingRow(
                  context,
                  icon: LucideIcons.sparkles,
                  label: 'Accent Color',
                  trailing: _AccentColorPicker(
                    selected: user.accentColor,
                    onChanged: (c) {
                      NexaHaptics.tick();
                      store.updateUser((u) => u.copyWith(accentColor: c));
                    },
                  ),
                ),
                const Divider(height: 1),
                _settingRow(
                  context,
                  icon: LucideIcons.type,
                  label: 'Font Size',
                  trailing: SegmentedButton<String>(
                    segments: kFontSizes.entries
                        .map((e) =>
                            ButtonSegment(value: e.key, label: Text(e.value)))
                        .toList(),
                    selected: {user.fontSize},
                    onSelectionChanged: (s) {
                      NexaHaptics.tick();
                      store.updateUser((u) => u.copyWith(fontSize: s.first));
                    },
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  secondary: const Icon(LucideIcons.minimize2, size: 20),
                  title: const Text('Compact UI Mode',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Tighter padding for high information density',
                      style: TextStyle(fontSize: 12)),
                  value: user.compactMode,
                  onChanged: (v) {
                    NexaHaptics.tick();
                    store.updateUser((u) => u.copyWith(compactMode: v));
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  secondary: const Icon(LucideIcons.vibrate, size: 20),
                  title: const Text('Haptic Feedback',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Tactile response on button taps and actions',
                      style: TextStyle(fontSize: 12)),
                  value: user.hapticsEnabled,
                  onChanged: (v) {
                    NexaHaptics.enabled = v;
                    NexaHaptics.tick();
                    store.updateUser((u) => u.copyWith(hapticsEnabled: v));
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── 3. Notification Center ───────────────────────────────────
        _sectionLabel(context, 'Notifications & Alerts'),
        StaggeredFadeIn(
          index: 2,
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  secondary: const Icon(LucideIcons.bellRing, size: 20),
                  title: const Text('Master Notifications',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  subtitle: const Text('Enable scheduled alarms and alerts',
                      style: TextStyle(fontSize: 12)),
                  value: user.notificationReminders,
                  onChanged: (v) async {
                    NexaHaptics.tick();
                    if (v) {
                      final granted = await NotificationService.instance.requestPermission();
                      if (!granted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please grant notification permission in system settings')),
                        );
                      }
                    }
                    store.updateUser((u) => u.copyWith(notificationReminders: v));
                  },
                ),
                if (user.notificationReminders) ...[
                  const Divider(height: 1),
                  _settingRow(
                    context,
                    icon: LucideIcons.sunrise,
                    label: 'Daily Morning Brief',
                    trailing: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () async {
                        NexaHaptics.tick();
                        final parts = user.dailyBriefTime.split(':');
                        final initial = TimeOfDay(
                          hour: int.tryParse(parts.first) ?? 8,
                          minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
                        );
                        final selected = await showTimePicker(
                          context: context,
                          initialTime: initial,
                        );
                        if (selected != null) {
                          final timeStr =
                              '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
                          store.updateUser((u) => u.copyWith(dailyBriefTime: timeStr));
                        }
                      },
                      child: Text(user.dailyBriefTime),
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    secondary: const Icon(LucideIcons.checkSquare, size: 18),
                    title: const Text('Task Due Reminders',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    subtitle: const Text('Exact-time alarms for scheduled tasks',
                        style: TextStyle(fontSize: 11.5)),
                    value: user.notifyTasks,
                    onChanged: (v) {
                      NexaHaptics.tick();
                      store.updateUser((u) => u.copyWith(notifyTasks: v));
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    secondary: const Icon(LucideIcons.alertCircle, size: 18),
                    title: const Text('Budget Overspend Warnings',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    subtitle: const Text('Alert at 80% and 100% of category limit',
                        style: TextStyle(fontSize: 11.5)),
                    value: user.notifyBudgets,
                    onChanged: (v) {
                      NexaHaptics.tick();
                      store.updateUser((u) => u.copyWith(notifyBudgets: v));
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    secondary: const Icon(LucideIcons.repeat, size: 18),
                    title: const Text('Renewal & Expiry Reminders',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    subtitle: const Text('3 days and 1 day before subscriptions/docs expire',
                        style: TextStyle(fontSize: 11.5)),
                    value: user.notifyRenewals,
                    onChanged: (v) {
                      NexaHaptics.tick();
                      store.updateUser((u) => u.copyWith(notifyRenewals: v));
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    secondary: const Icon(LucideIcons.bookOpen, size: 18),
                    title: const Text('Khata Payment Reminders',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    subtitle: const Text('Collection reminders for outstanding balances',
                        style: TextStyle(fontSize: 11.5)),
                    value: user.notifyKhata,
                    onChanged: (v) {
                      NexaHaptics.tick();
                      store.updateUser((u) => u.copyWith(notifyKhata: v));
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    secondary: const Icon(LucideIcons.flame, size: 18),
                    title: const Text('Daily Habit Prompts',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    subtitle: const Text('Check-in notification to maintain streaks',
                        style: TextStyle(fontSize: 11.5)),
                    value: user.notifyHabits,
                    onChanged: (v) {
                      NexaHaptics.tick();
                      store.updateUser((u) => u.copyWith(notifyHabits: v));
                    },
                  ),
                  const Divider(height: 1),
                  _actionTile(
                    context,
                    icon: LucideIcons.refreshCw,
                    label: 'Reschedule All Alarms',
                    subtitle: 'Synchronize notifications with current database',
                    onTap: () async {
                      NexaHaptics.tick();
                      await NotificationService.instance.rescheduleAll(data);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All notifications synchronized!')),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── 4. General Preferences ───────────────────────────────────
        _sectionLabel(context, 'Regional & Defaults'),
        StaggeredFadeIn(
          index: 3,
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _settingRow(
                  context,
                  icon: LucideIcons.banknote,
                  label: 'Currency',
                  trailing: DropdownButton<String>(
                    value: user.currency,
                    underline: const SizedBox(),
                    isDense: true,
                    items: kCurrencySymbols.keys
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(kCurrencySymbols[c] ?? '',
                                      style: const TextStyle(fontSize: 14)),
                                  const SizedBox(width: 4),
                                  Text(c, style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) {
                      NexaHaptics.tick();
                      store.updateUser((u) => u.copyWith(currency: v ?? 'USD'));
                    },
                  ),
                ),
                const Divider(height: 1),
                _settingRow(
                  context,
                  icon: LucideIcons.calendar,
                  label: 'Date Format',
                  trailing: DropdownButton<String>(
                    value: user.dateFormat,
                    underline: const SizedBox(),
                    isDense: true,
                    items: kDateFormats.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value, style: const TextStyle(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      NexaHaptics.tick();
                      store.updateUser(
                          (u) => u.copyWith(dateFormat: v ?? 'yyyy-MM-dd'));
                    },
                  ),
                ),
                const Divider(height: 1),
                _settingRow(
                  context,
                  icon: LucideIcons.calendarCheck,
                  label: 'Start of Week',
                  trailing: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'monday', label: Text('Mon')),
                      ButtonSegment(value: 'sunday', label: Text('Sun')),
                    ],
                    selected: {user.startOfWeek},
                    onSelectionChanged: (s) {
                      NexaHaptics.tick();
                      store.updateUser((u) => u.copyWith(startOfWeek: s.first));
                    },
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
                const Divider(height: 1),
                _settingRow(
                  context,
                  icon: LucideIcons.shoppingBag,
                  label: 'Default Category',
                  trailing: DropdownButton<String>(
                    value: user.defaultExpenseCategory,
                    underline: const SizedBox(),
                    isDense: true,
                    items: kCategories.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value, style: const TextStyle(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      NexaHaptics.tick();
                      store.updateUser(
                          (u) => u.copyWith(defaultExpenseCategory: v ?? 'other'));
                    },
                  ),
                ),
                const Divider(height: 1),
                _settingRow(
                  context,
                  icon: LucideIcons.bookOpen,
                  label: 'Default Khata Entry',
                  trailing: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'given', label: Text('Given')),
                      ButtonSegment(value: 'received', label: Text('Got')),
                    ],
                    selected: {user.defaultKhataEntryType},
                    onSelectionChanged: (s) {
                      NexaHaptics.tick();
                      store.updateUser(
                          (u) => u.copyWith(defaultKhataEntryType: s.first));
                    },
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  secondary: const Icon(LucideIcons.fingerprint, size: 20),
                  title: const Text('Biometric Lock',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Require biometric authentication on launch',
                      style: TextStyle(fontSize: 12)),
                  value: user.biometricLock,
                  onChanged: (v) async {
                    NexaHaptics.tick();
                    if (v) {
                      final canAuth = await AuthService.instance.canAuthenticate();
                      if (!canAuth) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Biometrics / Device Passcode not configured on this device'),
                            ),
                          );
                        }
                        return;
                      }
                      final ok = await AuthService.instance.authenticate(
                        reason: 'Confirm biometrics to enable App Lock',
                      );
                      if (!ok) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Authentication canceled or failed')),
                          );
                        }
                        return;
                      }
                    }
                    store.updateUser((u) => u.copyWith(biometricLock: v));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(v ? 'Biometric App Lock enabled' : 'Biometric App Lock disabled'),
                        ),
                      );
                    }
                  },
                ),
                if (user.biometricLock) ...[
                  const Divider(height: 1),
                  _actionTile(
                    context,
                    icon: LucideIcons.lock,
                    label: 'Lock Nexora Now',
                    subtitle: 'Test biometric lock immediately',
                    onTap: () {
                      AuthService.instance.lockApp();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => LockScreen(
                            onUnlocked: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const NavScaffold()),
                              );
                            },
                          ),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── 5. Data & Backup ─────────────────────────────────────────
        _sectionLabel(context, 'Data Management & Privacy'),
        StaggeredFadeIn(
          index: 4,
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  secondary: const Icon(LucideIcons.hardDrive, size: 20),
                  title: const Text('Auto Local Backup',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Continuous debounced local state persistence',
                      style: TextStyle(fontSize: 12)),
                  value: user.autoBackup,
                  onChanged: (v) {
                    NexaHaptics.tick();
                    store.updateUser((u) => u.copyWith(autoBackup: v));
                  },
                ),
                const Divider(height: 1),
                _actionTile(
                  context,
                  icon: LucideIcons.database,
                  label: 'Load Sample Data',
                  subtitle: 'Populate demo tasks, notes, expenses & khata entries',
                  onTap: () {
                    NexaHaptics.success();
                    store.loadSampleData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sample demo data loaded successfully!')),
                    );
                  },
                ),
                const Divider(height: 1),
                _actionTile(
                  context,
                  icon: LucideIcons.fileJson,
                  label: 'Export Complete Backup (JSON)',
                  subtitle: 'Export full offline encrypted-ready JSON backup',
                  onTap: () {
                    NexaHaptics.light();
                    final json = store.exportJson();
                    ExportService.instance.shareJson(json);
                  },
                ),
                const Divider(height: 1),
                _actionTile(
                  context,
                  icon: LucideIcons.clipboardCopy,
                  label: 'Copy Backup to Clipboard',
                  subtitle: 'Copy full raw JSON data for quick transfer',
                  onTap: () async {
                    NexaHaptics.light();
                    final json = store.exportJson();
                    await Clipboard.setData(ClipboardData(text: json));
                    if (context.mounted) {
                      NexaHaptics.success();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Full JSON backup copied to clipboard!')),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                _actionTile(
                  context,
                  icon: LucideIcons.fileSpreadsheet,
                  label: 'Export Expenses (CSV)',
                  subtitle: 'Spreadsheet-compatible transaction history',
                  onTap: () {
                    NexaHaptics.light();
                    ExportService.instance.shareExpensesCsv(
                      data.expenses,
                      user.currency,
                    );
                  },
                ),
                const Divider(height: 1),
                _actionTile(
                  context,
                  icon: LucideIcons.clipboardPaste,
                  label: 'Import from Clipboard',
                  subtitle: 'Inspect and restore backup directly from clipboard',
                  onTap: () => _importFromClipboard(context, store),
                ),
                const Divider(height: 1),
                _actionTile(
                  context,
                  icon: LucideIcons.fileInput,
                  label: 'Import Backup (JSON File / Text)',
                  subtitle: 'Restore your data from a JSON file string',
                  onTap: () => _showImportDialog(context, store),
                ),
                const Divider(height: 1),
                _actionTile(
                  context,
                  icon: LucideIcons.trash2,
                  label: 'Clear All App Data',
                  subtitle: 'Permanently wipe local database with double confirmation',
                  color: NexaColors.danger,
                  onTap: () async {
                    NexaHaptics.warning();
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete all local data?'),
                        content: const Text(
                            'This will irreversibly delete all tasks, notes, expenses, khata entries, and vault resources.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel')),
                          FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor: NexaColors.danger),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Confirm Clear'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) {
                      NexaHaptics.heavy();
                      store.clearAllData();
                      Navigator.of(context).popUntil((r) => r.isFirst);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All data cleared.')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── 6. About Section ─────────────────────────────────────────
        _sectionLabel(context, 'About Nexora'),
        StaggeredFadeIn(
          index: 5,
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _actionTile(
                  context,
                  icon: LucideIcons.info,
                  label: 'Version',
                  subtitle: 'v4.0 SuperOS Edition · Offline-first',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _actionTile(
                  context,
                  icon: LucideIcons.code2,
                  label: 'Open Source Licenses',
                  subtitle: 'Flutter, Riverpod, fl_chart, Lucide',
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Nexora',
                    applicationVersion: 'v4.0 SuperOS Edition',
                  ),
                ),
                const Divider(height: 1),
                _actionTile(
                  context,
                  icon: LucideIcons.shieldCheck,
                  label: 'Privacy Guarantee',
                  subtitle: '100% offline, zero telemetry, zero analytics tracking',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Zero-Knowledge Offline Privacy'),
                        content: const Text(
                            'Nexora stores all your data strictly on your device storage. No servers, no tracking, no ads, no telemetry. Your personal data is completely yours.'),
                        actions: [
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Got it'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),

        // ── Footer ───────────────────────────────────────────────────
        Center(
          child: Column(
            children: [
              const NexoraLogo(size: 60),
              const SizedBox(height: 12),
              Text(
                'Nexora',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: primaryColor(context),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'The Ultimate Personal OS\nTasks · Notes · Expenses · Vault · Khata',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12, color: textSecondaryColor(context)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor(context).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('v4.0 Master Release',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: TextStyle(
              color: textSecondaryColor(context),
              fontSize: 12,
              fontWeight: FontWeight.w700)),
    );
  }

  void _editProfileName(
      BuildContext context, AppStore store, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile Name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Your Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              store.updateUser((u) => u.copyWith(name: ctrl.text.trim()));
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromClipboard(
      BuildContext context, AppStore store) async {
    NexaHaptics.light();
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard is empty or does not contain text')),
        );
      }
      return;
    }
    if (context.mounted) {
      _inspectAndConfirmImport(context, store, text);
    }
  }

  void _inspectAndConfirmImport(
      BuildContext context, AppStore store, String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('JSON root must be an object');
      }

      final taskCount = (decoded['tasks'] as List?)?.length ?? 0;
      final expenseCount = (decoded['expenses'] as List?)?.length ?? 0;
      final noteCount = (decoded['notes'] as List?)?.length ?? 0;
      final khataCount = (decoded['khataEntries'] as List?)?.length ?? 0;
      final resourceCount = (decoded['resources'] as List?)?.length ?? 0;
      final habitCount = (decoded['habits'] as List?)?.length ?? 0;
      final userName =
          (decoded['user'] as Map?)?['name']?.toString() ?? 'Unknown User';

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Verify Backup Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Found valid Nexora backup for $userName:',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
              const SizedBox(height: 12),
              _statRow(LucideIcons.checkSquare, '$taskCount Tasks'),
              _statRow(LucideIcons.wallet, '$expenseCount Transactions'),
              _statRow(LucideIcons.fileText, '$noteCount Notes'),
              _statRow(LucideIcons.bookOpen, '$khataCount Khata Entries'),
              _statRow(LucideIcons.shield, '$resourceCount Vault Items'),
              _statRow(LucideIcons.flame, '$habitCount Daily Habits'),
              const SizedBox(height: 12),
              const Text(
                '⚠️ Restoring will replace your current database with this backup.',
                style: TextStyle(
                  fontSize: 12,
                  color: NexaColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final success = store.importJson(rawJson);
                Navigator.pop(ctx);
                if (success) {
                  NexaHaptics.success();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup restored successfully!')),
                  );
                } else {
                  NexaHaptics.error();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to restore backup')),
                  );
                }
              },
              child: const Text('Confirm Restore'),
            ),
          ],
        ),
      );
    } catch (e) {
      NexaHaptics.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid backup JSON: $e')),
      );
    }
  }

  static Widget _statRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF8B5CF6)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context, AppStore store) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import JSON Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paste your exported JSON data below to inspect and restore.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Paste backup JSON here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = ctrl.text.trim();
              Navigator.pop(ctx);
              if (text.isNotEmpty) {
                _inspectAndConfirmImport(context, store, text);
              }
            },
            child: const Text('Inspect & Restore'),
          ),
        ],
      ),
    );
  }

  Widget _settingRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: textSecondaryColor(context)),
          const SizedBox(width: 14),
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          Flexible(child: trailing),
        ],
      ),
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? textSecondaryColor(context)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: color ??
                              Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: textSecondaryColor(context))),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight,
                size: 16, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

/// Color picker dots for accent color.
class _AccentColorPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _AccentColorPicker({required this.selected, required this.onChanged});

  static const _colors = {
    'purple': Color(0xFF8B5CF6),
    'blue': Color(0xFF3B82F6),
    'teal': Color(0xFF14B8A6),
    'orange': Color(0xFFF97316),
    'pink': Color(0xFFEC4899),
    'green': Color(0xFF22C55E),
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _colors.entries.map((e) {
        final isSelected = e.key == selected;
        return GestureDetector(
          onTap: () => onChanged(e.key),
          child: Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: e.value,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: e.value.withOpacity(0.5), blurRadius: 6)]
                  : null,
            ),
            child: isSelected
                ? const Icon(LucideIcons.check, size: 13, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
