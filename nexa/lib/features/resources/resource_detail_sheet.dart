import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../services/auth_service.dart';
import '../../widgets/glass.dart';
import '../../widgets/sheet.dart';
import '../../widgets/tag_chip.dart';

/// Resource detail view with type-specific layouts: masked passwords with eye toggles,
/// WiFi copy shortcuts, inventory live +/- stepper, subscription annual projection,
/// document expiry badges, and direct call/email contact actions.
class ResourceDetailSheet extends ConsumerStatefulWidget {
  final String resourceId;
  const ResourceDetailSheet({super.key, required this.resourceId});

  static Future<void> show(BuildContext context, String id) => showNexaSheet(
        context,
        title: '',
        initialSize: 0.78,
        builder: (_) => ResourceDetailSheet(resourceId: id),
      );

  @override
  ConsumerState<ResourceDetailSheet> createState() =>
      _ResourceDetailSheetState();
}

class _ResourceDetailSheetState extends ConsumerState<ResourceDetailSheet> {
  bool _obscured = true;

  Future<void> _handleUnmaskToggle(bool currentlyObscured, VoidCallback toggleAction) async {
    if (currentlyObscured) {
      final user = ref.read(appStoreProvider).valueOrNull?.user;
      if (user?.biometricLock == true) {
        final canAuth = await AuthService.instance.canAuthenticate();
        if (canAuth) {
          final ok = await AuthService.instance.authenticate(
            reason: 'Authenticate to reveal sensitive vault credentials',
          );
          if (!ok) return;
        }
      }
    }
    NexaHaptics.tick();
    toggleAction();
  }

  void _copyToClipboard(String text, String label) {
    NexaHaptics.tick();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  void _confirmDelete(Resource resource) async {
    NexaHaptics.warning();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vault Item?'),
        content: Text('Are you sure you want to delete "${resource.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: NexaColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      ref.read(appStoreProvider.notifier).deleteResource(resource.id);
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(appStoreProvider);
    final resources = asyncData.valueOrNull?.resources ?? [];
    final currency = asyncData.valueOrNull?.user.currency ?? 'USD';

    final resource = resources.firstWhere(
      (r) => r.id == widget.resourceId,
      orElse: () => Resource(
        id: widget.resourceId,
        name: 'Unknown',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    final details = resource.details;
    final (iconData, typeColor) = _style(resource.type);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Type icon & name
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: typeColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kResourceTypeLabels[resource.type] ?? resource.type.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tags
          if (resource.tags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ...resource.tags.map((t) => TagChip('#$t')),
              ],
            ),
          const SizedBox(height: 16),

          // ── Type-Specific Interactive Cards ──
          if (resource.type == ResourceType.password) ...[
            _detailRow(
              context,
              label: 'Username / Email',
              value: details['username']?.toString() ?? '—',
              onCopy: details['username'] != null
                  ? () => _copyToClipboard(
                      details['username'].toString(), 'Username')
                  : null,
            ),
            _maskedRow(
              context,
              label: 'Password',
              value: details['password']?.toString() ?? '••••••••',
              obscured: _obscured,
              onToggle: () => setState(() => _obscured = !_obscured),
              onCopy: details['password'] != null
                  ? () => _copyToClipboard(
                      details['password'].toString(), 'Password')
                  : null,
            ),
            if (details['url'] != null && details['url'].toString().isNotEmpty)
              _detailRow(
                context,
                label: 'Website URL',
                value: details['url'].toString(),
                trailingIcon: LucideIcons.externalLink,
                onAction: () async {
                  var url = details['url'].toString();
                  if (!url.startsWith('http://') && !url.startsWith('https://')) {
                    url = 'https://$url';
                  }
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
              ),
          ] else if (resource.type == ResourceType.wifiPassword) ...[
            _detailRow(
              context,
              label: 'WiFi Network (SSID)',
              value: details['ssid']?.toString() ?? resource.name,
              onCopy: () => _copyToClipboard(
                  details['ssid']?.toString() ?? resource.name, 'SSID'),
            ),
            _maskedRow(
              context,
              label: 'WiFi Password',
              value: details['password']?.toString() ?? '—',
              obscured: _obscured,
              onToggle: () => setState(() => _obscured = !_obscured),
              onCopy: details['password'] != null
                  ? () => _copyToClipboard(
                      details['password'].toString(), 'WiFi password')
                  : null,
            ),
            if (details['security'] != null)
              _detailRow(
                context,
                label: 'Security Type',
                value: details['security'].toString(),
              ),
          ] else if (resource.type == ResourceType.bankCard) ...[
            _detailRow(
              context,
              label: 'Cardholder Name',
              value: details['cardholder']?.toString() ?? '—',
            ),
            _maskedRow(
              context,
              label: 'Card Number',
              value: details['cardNumber']?.toString() ?? '•••• •••• •••• ••••',
              obscured: _obscured,
              onToggle: () => setState(() => _obscured = !_obscured),
              onCopy: details['cardNumber'] != null
                  ? () => _copyToClipboard(
                      details['cardNumber'].toString(), 'Card number')
                  : null,
            ),
            Row(
              children: [
                Expanded(
                  child: _detailRow(
                    context,
                    label: 'Expiry',
                    value: details['expiry']?.toString() ?? '—',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _detailRow(
                    context,
                    label: 'Bank',
                    value: details['bank']?.toString() ?? '—',
                  ),
                ),
              ],
            ),
          ] else if (resource.type == ResourceType.subscription) ...[
            Builder(builder: (ctx) {
              final cost = (details['cost'] as num?)?.toDouble() ?? 0.0;
              final cycle = details['billingCycle']?.toString() ?? 'monthly';
              final annualCost = cycle == 'yearly'
                  ? cost
                  : (cycle == 'weekly' ? cost * 52 : cost * 12);
              final renewalDays = daysUntil(resource.renewalDate);

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Recurring Cost',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: textSecondaryColor(context))),
                              const SizedBox(height: 4),
                              Text(
                                '${formatCurrency(cost, currency)} / $cycle',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800),
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
                              Text('Annual Projection',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: textSecondaryColor(context))),
                              const SizedBox(height: 4),
                              Text(
                                formatCurrency(annualCost, currency),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (resource.renewalDate != null)
                    _detailRow(
                      context,
                      label: 'Next Renewal Date',
                      value: resource.renewalDate!,
                      badge: renewalDays != null
                          ? (renewalDays <= 3
                              ? 'Renews in $renewalDays days ⚠️'
                              : 'In $renewalDays days')
                          : null,
                      badgeColor: renewalDays != null && renewalDays <= 3
                          ? NexaColors.warning
                          : NexaColors.success,
                    ),
                ],
              );
            }),
          ] else if (resource.type == ResourceType.document) ...[
            Builder(builder: (ctx) {
              final days = daysUntil(resource.renewalDate);
              final isExpired = days != null && days < 0;
              final isExpiringSoon = days != null && days >= 0 && days <= 14;

              return Column(
                children: [
                  if (details['docNumber'] != null)
                    _maskedRow(
                      context,
                      label: 'Document Number',
                      value: details['docNumber'].toString(),
                      obscured: _obscured,
                      onToggle: () => setState(() => _obscured = !_obscured),
                      onCopy: () => _copyToClipboard(
                          details['docNumber'].toString(), 'Document number'),
                    ),
                  if (resource.renewalDate != null)
                    _detailRow(
                      context,
                      label: 'Expiration Date',
                      value: resource.renewalDate!,
                      badge: isExpired
                          ? 'EXPIRED (${days.abs()}d ago)'
                          : (isExpiringSoon
                              ? 'Expires in $days days'
                              : (days != null ? '$days days valid' : null)),
                      badgeColor: isExpired
                          ? NexaColors.danger
                          : (isExpiringSoon
                              ? NexaColors.warning
                              : NexaColors.success),
                    ),
                ],
              );
            }),
          ] else if (resource.type == ResourceType.inventory) ...[
            Builder(builder: (ctx) {
              final qty = resource.quantity ?? 0;
              final unitCost = (details['unitCost'] as num?)?.toDouble() ?? 0.0;
              final totalValue = qty * unitCost;
              final isLow = qty <= resource.lowStockThreshold;

              return Column(
                children: [
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('In Stock Quantity',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  if (isLow) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: NexaColors.danger.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('LOW STOCK',
                                          style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: NexaColors.danger)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('$qty units',
                                  style: const TextStyle(
                                      fontSize: 24, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                        // Quick +/- Stepper
                        IconButton(
                          icon: const Icon(LucideIcons.minusCircle, size: 28),
                          onPressed: qty > 0
                              ? () {
                                  NexaHaptics.tick();
                                  ref
                                      .read(appStoreProvider.notifier)
                                      .updateResource(
                                        resource.id,
                                        (r) => r.copyWith(quantity: qty - 1),
                                      );
                                }
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.plusCircle, size: 28),
                          onPressed: () {
                            NexaHaptics.tick();
                            ref
                                .read(appStoreProvider.notifier)
                                .updateResource(
                                  resource.id,
                                  (r) => r.copyWith(quantity: qty + 1),
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (unitCost > 0)
                    _detailRow(
                      context,
                      label: 'Unit Cost / Total Value',
                      value:
                          '${formatCurrency(unitCost, currency)} ea · Total: ${formatCurrency(totalValue, currency)}',
                    ),
                  if (details['location'] != null)
                    _detailRow(
                      context,
                      label: 'Storage Location',
                      value: details['location'].toString(),
                    ),
                ],
              );
            }),
          ] else if (resource.type == ResourceType.contact) ...[
            if (details['phone'] != null)
              _detailRow(
                context,
                label: 'Phone Number',
                value: details['phone'].toString(),
                trailingIcon: LucideIcons.phoneCall,
                onAction: () async {
                  final uri = Uri.parse('tel:${details['phone']}');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                onCopy: () =>
                    _copyToClipboard(details['phone'].toString(), 'Phone'),
              ),
            if (details['email'] != null)
              _detailRow(
                context,
                label: 'Email',
                value: details['email'].toString(),
                trailingIcon: LucideIcons.mail,
                onAction: () async {
                  final uri = Uri.parse('mailto:${details['email']}');
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                onCopy: () =>
                    _copyToClipboard(details['email'].toString(), 'Email'),
              ),
            if (details['role'] != null)
              _detailRow(
                context,
                label: 'Role / Relationship',
                value: details['role'].toString(),
              ),
          ],

          // Notes
          if (details['notes'] != null &&
              details['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surfaceColor(context).withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '📝 ${details['notes']}',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: textSecondaryColor(context),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Action Button: Delete
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(resource),
            icon: const Icon(LucideIcons.trash2, size: 18, color: NexaColors.danger),
            label: const Text(
              'Delete Item',
              style: TextStyle(color: NexaColors.danger, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: NexaColors.danger.withOpacity(0.4)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _detailRow(
    BuildContext context, {
    required String label,
    required String value,
    String? badge,
    Color? badgeColor,
    VoidCallback? onCopy,
    VoidCallback? onAction,
    IconData? trailingIcon,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: textSecondaryColor(context)),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                if (badge != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? NexaColors.lightPrimary).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: badgeColor ?? NexaColors.lightPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onAction != null && trailingIcon != null)
            IconButton(
              icon: Icon(trailingIcon, size: 18, color: NexaColors.lightPrimary),
              onPressed: onAction,
            ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(LucideIcons.copy, size: 18),
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }

  Widget _maskedRow(
    BuildContext context, {
    required String label,
    required String value,
    required bool obscured,
    required VoidCallback onToggle,
    VoidCallback? onCopy,
  }) {
    final display = obscured ? '••••••••••••' : value;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: textSecondaryColor(context)),
                ),
                const SizedBox(height: 4),
                Text(
                  display,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: obscured ? 2.0 : 0.0,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(obscured ? LucideIcons.eye : LucideIcons.eyeOff, size: 18),
            onPressed: () => _handleUnmaskToggle(obscured, onToggle),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(LucideIcons.copy, size: 18),
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }

  (IconData, Color) _style(ResourceType t) => switch (t) {
        ResourceType.subscription => (LucideIcons.repeat, NexaColors.catBills),
        ResourceType.inventory => (LucideIcons.package, NexaColors.catShopping),
        ResourceType.contact => (LucideIcons.contact, NexaColors.catTransport),
        ResourceType.document => (LucideIcons.fileBadge, NexaColors.info),
        ResourceType.password => (LucideIcons.keyRound, NexaColors.catEntertainment),
        ResourceType.wifiPassword => (LucideIcons.wifi, NexaColors.catHealth),
        ResourceType.bankCard => (LucideIcons.creditCard, NexaColors.catSalary),
      };
}
