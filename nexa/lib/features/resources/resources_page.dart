import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/animations.dart';
import '../../core/constants.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/app_store.dart';
import '../../widgets/glass.dart';
import '../../widgets/store_guard.dart';
import '../../widgets/tiles.dart';
import 'add_resource_sheet.dart';
import 'resource_detail_sheet.dart';

class ResourcesPage extends ConsumerStatefulWidget {
  const ResourcesPage({super.key});

  static Future<void> openAdder(BuildContext context) =>
      AddResourceSheet.show(context);

  @override
  ConsumerState<ResourcesPage> createState() => _ResourcesPageState();
}

class _ResourcesPageState extends ConsumerState<ResourcesPage> {
  String _type = 'all';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return StoreGuard(
      child: (data) {
        final currency = data.user.currency;
        var resources = _type == 'all'
            ? data.resources
            : data.resources.where((r) => r.type.name == _type).toList();

        if (_search.isNotEmpty) {
          final q = _search.toLowerCase();
          resources = resources
              .where((r) =>
                  r.name.toLowerCase().contains(q) ||
                  (r.details['notes']?.toString().toLowerCase().contains(q) ?? false) ||
                  (r.details['username']?.toString().toLowerCase().contains(q) ?? false) ||
                  (r.details['ssid']?.toString().toLowerCase().contains(q) ?? false) ||
                  r.tags.any((t) => t.toLowerCase().contains(q)))
              .toList();
        }

        // Subscriptions calculations
        final subs = data.resources
            .where((r) => r.type == ResourceType.subscription && r.details['cost'] != null)
            .toList();
        final monthlyBurn = subs.fold(0.0, (s, r) {
          final cost = (r.details['cost'] as num?)?.toDouble() ?? 0.0;
          final cycle = r.details['billingCycle'] as String? ?? 'monthly';
          if (cycle == 'yearly') return s + (cost / 12);
          if (cycle == 'weekly') return s + (cost * 4.33);
          return s + cost;
        });
        final annualBurn = monthlyBurn * 12;

        // Inventory total asset valuation and low stock count
        final inventoryItems = data.resources
            .where((r) => r.type == ResourceType.inventory)
            .toList();
        final totalInventoryValue = inventoryItems.fold(0.0, (sum, r) {
          final qty = r.quantity ?? 0;
          final unitCost = (r.details['unitCost'] as num?)?.toDouble() ?? 0.0;
          return sum + (qty * unitCost);
        });
        final lowStockItems = inventoryItems
            .where((r) => r.quantity != null && r.quantity! <= r.lowStockThreshold)
            .toList();

        // Expiring Soon (next 7 days)
        final expiringSoon = data.resources.where((r) {
          if (r.renewalDate == null || r.renewalDate!.isEmpty) return false;
          final days = daysUntil(r.renewalDate);
          return days != null && days >= 0 && days <= 7;
        }).toList();

        return Column(
          children: [
            // Category selector tabs
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _tab('all', 'All Vault', LucideIcons.folderLock),
                  ...kResourceTypeLabels.entries.map((e) =>
                      _tab(e.key.name, e.value, kResourceTypeIconData[e.key])),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Search input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search passwords, cards, docs, inventory...',
                    prefixIcon: Icon(LucideIcons.search,
                        size: 18, color: textSecondaryColor(context)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                children: [
                  // Expiring Soon Alert Banner
                  if (expiringSoon.isNotEmpty && _search.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GradientBorderCard(
                        gradient: NexaColors.gradWarm,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(LucideIcons.alarmClock,
                                    color: NexaColors.warning, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Expiring Soon (${expiringSoon.length})',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: NexaColors.warning,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ...expiringSoon.map((r) {
                              final d = daysUntil(r.renewalDate);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${r.name} (${kResourceTypeLabels[r.type] ?? r.type.name})',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: NexaColors.warning.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        d == 0 ? 'Today!' : 'in $d days',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: NexaColors.warning),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                  // Subscription Monthly & Annual Burn Summary Banner
                  if ((_type == 'all' || _type == 'subscription') && subs.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GradientBorderCard(
                        gradient: NexaColors.gradCool,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Active Subscriptions Burn',
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: textSecondaryColor(context)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${formatCurrency(monthlyBurn, currency)} / mo',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF6366F1),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${formatCurrency(annualBurn, currency)} projected annual cost · ${subs.length} active',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: textSecondaryColor(context)),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.repeat,
                                  color: Color(0xFF6366F1), size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Inventory Total Valuation & Low Stock Banner
                  if ((_type == 'all' || _type == 'inventory') && inventoryItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: NexaColors.catShopping.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.boxes,
                                  color: NexaColors.catShopping, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Inventory Asset Value',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: textSecondaryColor(context)),
                                  ),
                                  Text(
                                    formatCurrency(totalInventoryValue, currency),
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800),
                                  ),
                                  if (lowStockItems.isNotEmpty)
                                    Text(
                                      '⚠️ ${lowStockItems.length} item(s) low on stock',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: NexaColors.warning),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (resources.isEmpty)
                    EmptyState(
                      icon: LucideIcons.folderLock,
                      title: 'No resources found',
                      text: _search.isNotEmpty
                          ? 'No items matched your search query.'
                          : 'Store credentials, track subscriptions, log inventory, and secure your documents.',
                      buttonLabel: _search.isEmpty ? 'Add to Vault' : null,
                      onButton: _search.isEmpty
                          ? () => AddResourceSheet.show(context)
                          : null,
                    )
                  else
                    ...resources.asMap().entries.map((entry) {
                      final i = entry.key;
                      final r = entry.value;
                      return StaggeredFadeIn(
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Dismissible(
                            key: ValueKey('res_${r.id}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: NexaColors.danger.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(LucideIcons.trash2,
                                  color: NexaColors.danger, size: 22),
                            ),
                            onDismissed: (_) {
                              NexaHaptics.warning();
                              final store = ref.read(appStoreProvider.notifier);
                              store.deleteResource(r.id);
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Deleted "${r.name}"'),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: () {
                                      NexaHaptics.tick();
                                      store.addResource(r);
                                    },
                                  ),
                                ),
                              );
                            },
                            child: ResourceTile(
                              resource: r,
                              currency: currency,
                              onTap: () => ResourceDetailSheet.show(context, r.id),
                              onIncrement: r.type == ResourceType.inventory
                                  ? () {
                                      NexaHaptics.tick();
                                      ref
                                          .read(appStoreProvider.notifier)
                                          .updateResource(
                                            r.id,
                                            (res) => res.copyWith(
                                              quantity: (res.quantity ?? 0) + 1,
                                            ),
                                          );
                                    }
                                  : null,
                              onDecrement: r.type == ResourceType.inventory
                                  ? () {
                                      NexaHaptics.tick();
                                      final q = (r.quantity ?? 0);
                                      if (q > 0) {
                                        ref
                                            .read(appStoreProvider.notifier)
                                            .updateResource(
                                              r.id,
                                              (res) => res.copyWith(
                                                quantity: q - 1,
                                              ),
                                            );
                                      }
                                    }
                                  : null,
                            ),
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
    );
  }

  Widget _tab(String id, String label, [dynamic icon]) {
    final active = _type == id;
    final color = primaryColor(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          NexaHaptics.selection();
          setState(() => _type = id);
        },
        child: AnimatedContainer(
          duration: NexaAnim.fast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.18) : surfaceColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? color : borderColor(context),
              width: active ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon as IconData,
                  size: 14,
                  color: active ? color : textSecondaryColor(context),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? color : textSecondaryColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
