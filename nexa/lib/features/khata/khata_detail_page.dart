import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/animations.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../services/notifications.dart';
import '../../widgets/glass.dart';
import '../../widgets/store_guard.dart';
import 'add_khata_entry_sheet.dart';

/// Detail page for a single Khata person — shows full ledger statement,
/// settle-up shortcuts, statement sharing, call/email buttons, and payment reminders.
class KhataDetailPage extends ConsumerStatefulWidget {
  final String personId;
  const KhataDetailPage({super.key, required this.personId});

  @override
  ConsumerState<KhataDetailPage> createState() => _KhataDetailPageState();
}

class _KhataDetailPageState extends ConsumerState<KhataDetailPage> {
  String _entryFilter = 'all'; // all, given, received

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(appStoreProvider);
    final data = asyncData.valueOrNull;
    final person =
        data?.khataPersons.where((p) => p.id == widget.personId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(person?.name ?? 'Khata Ledger'),
        actions: [
          if (person != null && data != null)
            IconButton(
              icon: const Icon(LucideIcons.share2, size: 20),
              tooltip: 'Share Statement',
              onPressed: () => _shareStatement(context, ref, data, person),
            ),
        ],
      ),
      body: StoreGuard(
        child: (data) {
          final person = data.khataPersons
              .where((p) => p.id == widget.personId)
              .firstOrNull;
          if (person == null) {
            return const Center(child: Text('Person not found'));
          }
          return _DetailContent(
            data: data,
            person: person,
            filter: _entryFilter,
            onFilterChanged: (f) => setState(() => _entryFilter = f),
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: NexaColors.gradKhata,
          ),
          boxShadow: [
            BoxShadow(
              color: NexaColors.gradKhata[0].withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => AddKhataEntrySheet.show(context, personId: widget.personId),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Icon(LucideIcons.plus, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }

  void _shareStatement(
      BuildContext context, WidgetRef ref, AppData data, KhataPerson person) {
    NexaHaptics.tick();
    final store = ref.read(appStoreProvider.notifier);
    final currency = data.user.currency;
    final balance = store.khataBalance(person.id);
    final entries = data.khataEntries
        .where((e) => e.personId == person.id)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final totalGiven = entries
        .where((e) => e.type == 'given')
        .fold(0.0, (s, e) => s + e.amount);
    final totalReceived = entries
        .where((e) => e.type == 'received')
        .fold(0.0, (s, e) => s + e.amount);

    final buffer = StringBuffer();
    buffer.writeln('📋 *Nexora Khata Statement*');
    buffer.writeln('👤 *Party:* ${person.name}');
    if (person.phone != null && person.phone!.isNotEmpty) {
      buffer.writeln('📞 *Phone:* ${person.phone}');
    }
    if (person.email != null && person.email!.isNotEmpty) {
      buffer.writeln('✉️ *Email:* ${person.email}');
    }
    if (person.address != null && person.address!.isNotEmpty) {
      buffer.writeln('📍 *Address:* ${person.address}');
    }
    buffer.writeln('📅 *Statement Date:* ${DateTime.now().toString().substring(0, 10)}');
    buffer.writeln('--------------------------------');
    buffer.writeln(
        '🟢 *Total Given (Lena):* ${formatCurrency(totalGiven, currency)}');
    buffer.writeln(
        '🔴 *Total Received (Dena):* ${formatCurrency(totalReceived, currency)}');
    buffer.writeln('--------------------------------');
    if (balance == 0) {
      buffer.writeln('✅ *Status:* All settled (0 balance)');
    } else if (balance > 0) {
      buffer.writeln(
          '⚠️ *Net Due to You:* ${formatCurrency(balance, currency)} (Please settle soon)');
    } else {
      buffer.writeln(
          'ℹ️ *Net You Owe:* ${formatCurrency(balance.abs(), currency)}');
    }

    if (entries.isNotEmpty) {
      buffer.writeln('\n*Transaction History:*');
      for (final e in entries.take(30)) {
        final symbol = e.type == 'given' ? '🟢+' : '🔴-';
        buffer.writeln(
            '$symbol ${formatCurrency(e.amount, currency)} [${e.date}] ${e.description.isNotEmpty ? "- ${e.description}" : ""}');
      }
    }

    buffer.writeln('\n_Generated via Nexora — Life & Work OS_');
    Share.share(buffer.toString(), subject: 'Khata Statement - ${person.name}');
  }
}

class _DetailContent extends ConsumerWidget {
  final AppData data;
  final KhataPerson person;
  final String filter;
  final ValueChanged<String> onFilterChanged;

  const _DetailContent({
    required this.data,
    required this.person,
    required this.filter,
    required this.onFilterChanged,
  });

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.read(appStoreProvider.notifier);
    final currency = data.user.currency;
    final balance = store.khataBalance(person.id);

    var entries = data.khataEntries
        .where((e) => e.personId == person.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (filter == 'given') {
      entries = entries.where((e) => e.type == 'given').toList();
    } else if (filter == 'received') {
      entries = entries.where((e) => e.type == 'received').toList();
    }

    final totalGiven = data.khataEntries
        .where((e) => e.personId == person.id && e.type == 'given')
        .fold(0.0, (s, e) => s + e.amount);
    final totalReceived = data.khataEntries
        .where((e) => e.personId == person.id && e.type == 'received')
        .fold(0.0, (s, e) => s + e.amount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      children: [
        // Person Header & Balance Card
        StaggeredFadeIn(
          index: 0,
          child: GradientBorderCard(
            gradient: balance >= 0
                ? NexaColors.gradKhataGreen
                : NexaColors.gradKhataRed,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + Name + Contact details
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: balance >= 0
                              ? NexaColors.gradKhataGreen
                              : NexaColors.gradKhataRed,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(person.name),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            person.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (person.phone != null && person.phone!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(LucideIcons.phone, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  person.phone!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondaryColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (person.email != null && person.email!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(LucideIcons.mail, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  person.email!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondaryColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (person.address != null && person.address!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(LucideIcons.mapPin, size: 12),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    person.address!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: textSecondaryColor(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (person.notes != null && person.notes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: surfaceColor(context).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '📝 ${person.notes!}',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: textSecondaryColor(context),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Big Balance Display & Settle Up Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          balance == 0
                              ? 'Status'
                              : balance > 0
                                  ? 'They Owe You'
                                  : 'You Owe Them',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: balance == 0
                                ? textSecondaryColor(context)
                                : balance > 0
                                    ? NexaColors.success
                                    : NexaColors.danger,
                          ),
                        ),
                        const SizedBox(height: 4),
                        CountUpText(
                          value: balance.abs(),
                          formatter: (v) => formatCurrency(v, currency),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: balance == 0
                                ? textSecondaryColor(context)
                                : balance > 0
                                    ? NexaColors.success
                                    : NexaColors.danger,
                          ),
                        ),
                      ],
                    ),
                    // Settle Up Shortcut Button
                    if (balance != 0)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: balance > 0
                              ? NexaColors.success
                              : NexaColors.danger,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(LucideIcons.checkCheck, size: 16),
                        label: const Text('Settle Up',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                        onPressed: () =>
                            _showSettleUpDialog(context, ref, person, balance),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Quick Action Row (Call, Email, Remind, Add Entry)
        Row(
          children: [
            if (person.phone != null && person.phone!.isNotEmpty)
              Expanded(
                child: _QuickActionCard(
                  icon: LucideIcons.phoneCall,
                  label: 'Call',
                  color: NexaColors.success,
                  onTap: () async {
                    final uri = Uri.parse('tel:${person.phone}');
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                ),
              ),
            if (person.phone != null && person.phone!.isNotEmpty)
              const SizedBox(width: 8),
            if (person.email != null && person.email!.isNotEmpty)
              Expanded(
                child: _QuickActionCard(
                  icon: LucideIcons.mail,
                  label: 'Email',
                  color: NexaColors.info,
                  onTap: () async {
                    final uri = Uri.parse('mailto:${person.email}');
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                ),
              ),
            if (person.email != null && person.email!.isNotEmpty)
              const SizedBox(width: 8),
            if (balance > 0)
              Expanded(
                child: _QuickActionCard(
                  icon: LucideIcons.bellRing,
                  label: 'Remind',
                  color: NexaColors.warning,
                  onTap: () {
                    NotificationService.instance.showKhataReminder(
                      personName: person.name,
                      balance: balance,
                      currency: currency,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Notification reminder sent for ${person.name}')),
                    );
                  },
                ),
              ),
            if (balance > 0) const SizedBox(width: 8),
            Expanded(
              child: _QuickActionCard(
                icon: LucideIcons.plusCircle,
                label: 'Add Entry',
                color: NexaColors.lightPrimary,
                onTap: () => AddKhataEntrySheet.show(context, personId: person.id),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Quick Stats Row (Total Given vs Total Received)
        StaggeredFadeIn(
          index: 1,
          child: Row(
            children: [
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.arrowUpRight,
                              size: 14, color: NexaColors.success),
                          const SizedBox(width: 4),
                          Text('Total Given',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondaryColor(context))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatCurrency(totalGiven, currency),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: NexaColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.arrowDownLeft,
                              size: 14, color: NexaColors.danger),
                          const SizedBox(width: 4),
                          Text('Total Received',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondaryColor(context))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatCurrency(totalReceived, currency),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: NexaColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _filterChip(context, 'All Entries', 'all'),
              const SizedBox(width: 8),
              _filterChip(context, 'Given (+)', 'given'),
              const SizedBox(width: 8),
              _filterChip(context, 'Received (-)', 'received'),
            ],
          ),
        ),

        const SectionHeader('Transaction Statement'),

        if (entries.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No transactions recorded yet',
                style: TextStyle(
                    color: textSecondaryColor(context), fontSize: 13.5),
              ),
            ),
          )
        else
          ...entries.asMap().entries.map((entry) {
            final e = entry.value;
            final isGiven = e.type == 'given';
            final color = isGiven ? NexaColors.success : NexaColors.danger;

            return StaggeredFadeIn(
              index: entry.key + 2,
              child: Dismissible(
                key: ValueKey(e.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: NexaColors.danger.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(LucideIcons.trash2,
                      color: NexaColors.danger),
                ),
                confirmDismiss: (_) async {
                  NexaHaptics.swipeAction();
                  ref.read(appStoreProvider.notifier).deleteKhataEntry(e.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Removed ${e.description.isEmpty ? formatCurrency(e.amount, currency) : e.description}'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          ref.read(appStoreProvider.notifier).addKhataEntry(
                                personId: e.personId,
                                amount: e.amount,
                                type: e.type,
                                description: e.description,
                                date: e.date,
                              );
                        },
                      ),
                    ),
                  );
                  return true;
                },
                child: GlassCard(
                  onTap: () {
                    NexaHaptics.light();
                    AddKhataEntrySheet.show(
                      context,
                      personId: person.id,
                      existingEntry: e,
                    );
                  },
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isGiven
                              ? LucideIcons.arrowUpRight
                              : LucideIcons.arrowDownLeft,
                          color: color,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.description.isNotEmpty
                                  ? e.description
                                  : (isGiven
                                      ? 'Amount Given'
                                      : 'Amount Received'),
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              e.date,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: textSecondaryColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isGiven ? '+' : '-'}${formatCurrency(e.amount, currency)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _filterChip(BuildContext context, String label, String value) {
    final active = filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) {
        NexaHaptics.tick();
        onFilterChanged(value);
      },
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        color: active ? Colors.white : textSecondaryColor(context),
      ),
      selectedColor: NexaColors.gradKhata[0],
      backgroundColor: surfaceColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(
          color: active
              ? Colors.transparent
              : borderColor(context).withOpacity(0.6)),
    );
  }

  void _showSettleUpDialog(BuildContext context, WidgetRef ref,
      KhataPerson person, double balance) {
    NexaHaptics.tick();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Settle Up Ledger?'),
        content: Text(
          balance > 0
              ? 'This will record a received payment of ${formatCurrency(balance, data.user.currency)} from ${person.name}, bringing the balance to 0.'
              : 'This will record a payment of ${formatCurrency(balance.abs(), data.user.currency)} given to ${person.name}, bringing the balance to 0.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  balance > 0 ? NexaColors.success : NexaColors.danger,
            ),
            onPressed: () {
              ref.read(appStoreProvider.notifier).addKhataEntry(
                    personId: person.id,
                    amount: balance.abs(),
                    type: balance > 0 ? 'received' : 'given',
                    description: 'Settled full balance',
                    date: todayIsoDate(),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Confirm Settle Up'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
