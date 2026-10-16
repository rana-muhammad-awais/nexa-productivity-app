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
import 'add_khata_person_sheet.dart';
import 'khata_detail_page.dart';

enum _KhataSort { name, highestBalance, recentActivity, newestFirst }

/// Khata (Hisaab-Kitaab) — person-based financial ledger.
class KhataPage extends ConsumerStatefulWidget {
  const KhataPage({super.key});

  static Future<void> openAdder(BuildContext context) =>
      AddKhataPersonSheet.show(context);

  @override
  ConsumerState<KhataPage> createState() => _KhataPageState();
}

class _KhataPageState extends ConsumerState<KhataPage> {
  String _search = '';
  String _filter = 'all'; // all, owe_me, i_owe, settled
  _KhataSort _sortBy = _KhataSort.highestBalance;

  @override
  Widget build(BuildContext context) {
    return StoreGuard(
      child: (data) => _KhataContent(
        data: data,
        search: _search,
        filter: _filter,
        sortBy: _sortBy,
        onSearchChanged: (v) => setState(() => _search = v),
        onFilterChanged: (v) => setState(() => _filter = v),
        onSortChanged: (s) => setState(() => _sortBy = s),
      ),
    );
  }
}

class _KhataContent extends ConsumerWidget {
  final AppData data;
  final String search;
  final String filter;
  final _KhataSort sortBy;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<_KhataSort> onSortChanged;

  const _KhataContent({
    required this.data,
    required this.search,
    required this.filter,
    required this.sortBy,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.read(appStoreProvider.notifier);
    final currency = data.user.currency;

    // Filter persons by search and balance direction
    var persons = data.khataPersons.toList();
    if (search.isNotEmpty) {
      final q = search.toLowerCase();
      persons = persons.where((p) {
        final n = p.name.toLowerCase();
        final ph = (p.phone ?? '').toLowerCase();
        final em = (p.email ?? '').toLowerCase();
        final no = (p.notes ?? '').toLowerCase();
        return n.contains(q) || ph.contains(q) || em.contains(q) || no.contains(q);
      }).toList();
    }

    if (filter == 'owe_me') {
      persons = persons.where((p) => store.khataBalance(p.id) > 0).toList();
    } else if (filter == 'i_owe') {
      persons = persons.where((p) => store.khataBalance(p.id) < 0).toList();
    } else if (filter == 'settled') {
      persons = persons.where((p) => store.khataBalance(p.id) == 0).toList();
    }

    // Sort persons
    switch (sortBy) {
      case _KhataSort.name:
        persons.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case _KhataSort.highestBalance:
        persons.sort((a, b) =>
            store.khataBalance(b.id).abs().compareTo(store.khataBalance(a.id).abs()));
        break;
      case _KhataSort.recentActivity:
        persons.sort((a, b) {
          final aLast = data.khataEntries
              .where((e) => e.personId == a.id)
              .map((e) => e.date)
              .fold('', (max, d) => d.compareTo(max) > 0 ? d : max);
          final bLast = data.khataEntries
              .where((e) => e.personId == b.id)
              .map((e) => e.date)
              .fold('', (max, d) => d.compareTo(max) > 0 ? d : max);
          return bLast.compareTo(aLast);
        });
        break;
      case _KhataSort.newestFirst:
        persons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    // Compute totals
    final totalReceivable = store.totalReceivable();
    final totalPayable = store.totalPayable();
    final netBalance = totalReceivable - totalPayable;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        // Net Balance Card
        StaggeredFadeIn(
          index: 0,
          child: GradientBorderCard(
            gradient: netBalance >= 0
                ? NexaColors.gradKhataGreen
                : NexaColors.gradKhataRed,
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Net Ledger Balance',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondaryColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      CountUpText(
                        value: netBalance.abs(),
                        formatter: (v) =>
                            '${netBalance >= 0 ? '+' : '-'}${formatCurrency(v, currency)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          color: netBalance >= 0
                              ? NexaColors.success
                              : NexaColors.danger,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data.khataPersons.length} parties registered',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: textSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: (netBalance >= 0 ? NexaColors.success : NexaColors.danger)
                        .withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    netBalance >= 0 ? 'Receivable > Payable' : 'Payable > Receivable',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: netBalance >= 0
                          ? NexaColors.success
                          : NexaColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Summary cards (Receivable / Payable)
        StaggeredFadeIn(
          index: 1,
          child: Row(
            children: [
              Expanded(
                child: GradientBorderCard(
                  gradient: NexaColors.gradKhataGreen,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.arrowUpRight,
                              size: 15, color: NexaColors.success),
                          const SizedBox(width: 5),
                          Text('Receivable (Lena)',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color: textSecondaryColor(context),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      CountUpText(
                        value: totalReceivable,
                        formatter: (v) => formatCurrency(v, currency),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: NexaColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GradientBorderCard(
                  gradient: NexaColors.gradKhataRed,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.arrowDownLeft,
                              size: 15, color: NexaColors.danger),
                          const SizedBox(width: 5),
                          Text('Payable (Dena)',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color: textSecondaryColor(context),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      CountUpText(
                        value: totalPayable,
                        formatter: (v) => formatCurrency(v, currency),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
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

        const SizedBox(height: 12),

        // Search bar & Sort Menu
        StaggeredFadeIn(
          index: 2,
          child: Row(
            children: [
              Expanded(
                child: GlassCard(
                  margin: EdgeInsets.zero,
                  padding: EdgeInsets.zero,
                  child: TextField(
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search person, phone, notes...',
                      prefixIcon: Icon(LucideIcons.search,
                          size: 18, color: textSecondaryColor(context)),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<_KhataSort>(
                icon: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: surfaceColor(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: borderColor(context).withOpacity(0.6)),
                  ),
                  child: const Icon(LucideIcons.arrowUpDown, size: 18),
                ),
                onSelected: (val) {
                  NexaHaptics.selection();
                  onSortChanged(val);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: _KhataSort.highestBalance,
                    child: Text('Highest Balance'),
                  ),
                  const PopupMenuItem(
                    value: _KhataSort.recentActivity,
                    child: Text('Recent Activity'),
                  ),
                  const PopupMenuItem(
                    value: _KhataSort.name,
                    child: Text('Name (A-Z)'),
                  ),
                  const PopupMenuItem(
                    value: _KhataSort.newestFirst,
                    child: Text('Recently Added'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Filter chips (All, Owe Me, I Owe, Settled)
        StaggeredFadeIn(
          index: 3,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(context, 'All Parties', 'all'),
                const SizedBox(width: 8),
                _filterChip(context, 'They Owe (Lena)', 'owe_me'),
                const SizedBox(width: 8),
                _filterChip(context, 'You Owe (Dena)', 'i_owe'),
                const SizedBox(width: 8),
                _filterChip(context, 'Settled (0)', 'settled'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Person List
        if (persons.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(LucideIcons.users,
                    size: 40, color: textSecondaryColor(context)),
                const SizedBox(height: 12),
                const Text(
                  'No parties found',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  search.isNotEmpty
                      ? 'No match for "$search".'
                      : 'Add a person or business to start tracking hisaab.',
                  style: TextStyle(
                      color: textSecondaryColor(context), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                GradientButton(
                  'Add First Person',
                  icon: LucideIcons.userPlus,
                  onPressed: () => AddKhataPersonSheet.show(context),
                ),
              ],
            ),
          )
        else
          ...persons.asMap().entries.map((entry) {
            final p = entry.value;
            final bal = store.khataBalance(p.id);
            final entriesCount =
                data.khataEntries.where((e) => e.personId == p.id).length;

            return StaggeredFadeIn(
              index: entry.key + 4,
              child: _PersonCard(
                person: p,
                balance: bal,
                entriesCount: entriesCount,
                currency: currency,
                onTap: () {
                  NexaHaptics.light();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => KhataDetailPage(personId: p.id),
                    ),
                  );
                },
                onLongPress: () =>
                    _showPersonActions(context, ref, p, bal, currency),
              ),
            );
          }),
      ],
    );
  }

  void _showPersonActions(
    BuildContext context,
    WidgetRef ref,
    KhataPerson person,
    double balance,
    String currency,
  ) {
    NexaHaptics.medium();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: NexaColors.gradKhata[0].withOpacity(0.2),
                    child: Text(
                      person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          person.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          balance == 0
                              ? 'Settled (0 balance)'
                              : balance > 0
                                  ? 'Owes you ${formatCurrency(balance, currency)}'
                                  : 'You owe ${formatCurrency(balance.abs(), currency)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: balance >= 0
                                ? NexaColors.success
                                : NexaColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(LucideIcons.bookOpen, size: 20),
              title: const Text('View Full Statement'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => KhataDetailPage(personId: person.id),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.plusCircle,
                  size: 20, color: NexaColors.lightPrimary),
              title: const Text('Add Transaction'),
              onTap: () {
                Navigator.pop(ctx);
                AddKhataEntrySheet.show(context, personId: person.id);
              },
            ),
            if (balance > 0)
              ListTile(
                leading: const Icon(LucideIcons.bellRing,
                    size: 20, color: NexaColors.warning),
                title: const Text('Send Payment Reminder Notification'),
                onTap: () {
                  Navigator.pop(ctx);
                  NotificationService.instance.showKhataReminder(
                    personName: person.name,
                    balance: balance,
                    currency: currency,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reminder queued for ${person.name}')),
                  );
                },
              ),
            if (person.phone != null && person.phone!.isNotEmpty) ...[
              ListTile(
                leading: const Icon(LucideIcons.phoneCall,
                    size: 20, color: NexaColors.success),
                title: Text('Call ${person.phone}'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final uri = Uri.parse('tel:${person.phone}');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
              ),
            ],
            ListTile(
              leading: const Icon(LucideIcons.share2, size: 20),
              title: const Text('Share Summary Statement'),
              onTap: () {
                Navigator.pop(ctx);
                final text =
                    'Nexora Khata: ${person.name} has a net balance of ${formatCurrency(balance.abs(), currency)} (${balance >= 0 ? "due to you" : "you owe"}).';
                Share.share(text);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2,
                  size: 20, color: NexaColors.danger),
              title: const Text('Delete Person',
                  style: TextStyle(color: NexaColors.danger)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    title: const Text('Delete Party?'),
                    content: Text(
                      'Are you sure you want to delete ${person.name} and all associated ledger entries?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx, true),
                        style: TextButton.styleFrom(
                            foregroundColor: NexaColors.danger),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  ref
                      .read(appStoreProvider.notifier)
                      .deleteKhataPerson(person.id);
                  NexaHaptics.medium();
                }
              },
            ),
          ],
        ),
      ),
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
        fontSize: 12,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        color: active ? Colors.white : textSecondaryColor(context),
      ),
      selectedColor: NexaColors.gradKhata[0],
      backgroundColor: surfaceColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(
          color: active
              ? Colors.transparent
              : borderColor(context).withOpacity(0.6)),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final KhataPerson person;
  final double balance;
  final int entriesCount;
  final String currency;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PersonCard({
    required this.person,
    required this.balance,
    required this.entriesCount,
    required this.currency,
    required this.onTap,
    required this.onLongPress,
  });

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  List<Color> _getGradient(String name) {
    final gradients = [
      NexaColors.gradPrimary,
      NexaColors.gradCool,
      NexaColors.gradFocus,
      NexaColors.gradSunrise,
      NexaColors.gradRose,
      NexaColors.gradKhata,
    ];
    final hash = name.trim().isEmpty ? 0 : name.hashCode.abs();
    return gradients[hash % gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(person.name);
    final grad = _getGradient(person.name);

    return GlassCard(
      onTap: onTap,
      onLongPress: onLongPress,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Initials Avatar with hash gradient
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: grad,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: grad.first.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name and Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (person.phone != null && person.phone!.isNotEmpty) ...[
                      Icon(LucideIcons.phone,
                          size: 11, color: textSecondaryColor(context)),
                      const SizedBox(width: 4),
                      Text(
                        person.phone!,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: textSecondaryColor(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '$entriesCount entr${entriesCount == 1 ? 'y' : 'ies'}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: textSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Balance Display
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                balance == 0
                    ? 'Settled'
                    : '${balance > 0 ? '+' : '-'}${formatCurrency(balance.abs(), currency)}',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  color: balance == 0
                      ? textSecondaryColor(context)
                      : balance > 0
                          ? NexaColors.success
                          : NexaColors.danger,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                balance == 0
                    ? 'All clear'
                    : balance > 0
                        ? 'They owe'
                        : 'You owe',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: balance == 0
                      ? textSecondaryColor(context)
                      : balance > 0
                          ? NexaColors.success
                          : NexaColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          Icon(LucideIcons.chevronRight,
              size: 16, color: textSecondaryColor(context)),
        ],
      ),
    );
  }
}
