import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../widgets/glass.dart';
import '../../widgets/sheet.dart';

/// Add/edit resource with type-specific fields matching detail viewer.
class AddResourceSheet extends ConsumerStatefulWidget {
  final Resource? existing;
  const AddResourceSheet({super.key, this.existing});

  static Future<void> show(BuildContext context, {Resource? existing}) =>
      showNexaSheet(
        context,
        title: existing != null ? 'Edit Vault Item' : 'Add Vault Item',
        initialSize: 0.85,
        builder: (_) => AddResourceSheet(existing: existing),
      );

  @override
  ConsumerState<AddResourceSheet> createState() => _AddResourceSheetState();
}

class _AddResourceSheetState extends ConsumerState<AddResourceSheet> {
  final _nameCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _planCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _renewalCtrl = TextEditingController();
  final _docNumCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _unitCostCtrl = TextEditingController();
  final _lowCtrl = TextEditingController(text: '5');
  final _locCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _cardholderCtrl = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _ssidCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  ResourceType _type = ResourceType.document;
  String _billingCycle = 'monthly';
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    if (r != null) {
      _type = r.type;
      _nameCtrl.text = r.name;
      _tagsCtrl.text = r.tags.join(', ');
      _planCtrl.text = (r.details['plan'] ?? '').toString();
      _costCtrl.text = (r.details['cost'] ?? '').toString();
      _billingCycle = (r.details['billingCycle'] ?? 'monthly').toString();
      _renewalCtrl.text = r.renewalDate ?? '';
      _docNumCtrl.text = (r.details['docNumber'] ?? r.details['number'] ?? '').toString();
      _expiryCtrl.text = r.renewalDate ?? (r.details['expiry'] ?? '').toString();
      _qtyCtrl.text = (r.quantity ?? '').toString();
      _unitCostCtrl.text = (r.details['unitCost'] ?? '').toString();
      _lowCtrl.text = r.lowStockThreshold.toString();
      _locCtrl.text = (r.details['location'] ?? '').toString();
      _phoneCtrl.text = (r.details['phone'] ?? '').toString();
      _emailCtrl.text = (r.details['email'] ?? r.details['username'] ?? '').toString();
      _roleCtrl.text = (r.details['role'] ?? '').toString();
      _cardholderCtrl.text = (r.details['cardholder'] ?? '').toString();
      _cardNumberCtrl.text = (r.details['cardNumber'] ?? r.details['lastFour'] ?? '').toString();
      _bankCtrl.text = (r.details['bank'] ?? '').toString();
      _passwordCtrl.text = (r.details['password'] ?? '').toString();
      _urlCtrl.text = (r.details['url'] ?? '').toString();
      _ssidCtrl.text = (r.details['ssid'] ?? '').toString();
      _notesCtrl.text = (r.details['notes'] ?? '').toString();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tagsCtrl.dispose();
    _planCtrl.dispose();
    _costCtrl.dispose();
    _renewalCtrl.dispose();
    _docNumCtrl.dispose();
    _expiryCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCostCtrl.dispose();
    _lowCtrl.dispose();
    _locCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _roleCtrl.dispose();
    _cardholderCtrl.dispose();
    _cardNumberCtrl.dispose();
    _bankCtrl.dispose();
    _passwordCtrl.dispose();
    _urlCtrl.dispose();
    _ssidCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    final details = <String, dynamic>{};
    String? renewalDate;

    if (_notesCtrl.text.trim().isNotEmpty) {
      details['notes'] = _notesCtrl.text.trim();
    }

    switch (_type) {
      case ResourceType.subscription:
        details['plan'] = _planCtrl.text.trim();
        details['cost'] = double.tryParse(_costCtrl.text) ?? 0.0;
        details['billingCycle'] = _billingCycle;
        renewalDate = _renewalCtrl.text.trim().isEmpty ? null : _renewalCtrl.text.trim();
        break;
      case ResourceType.document:
        details['docNumber'] = _docNumCtrl.text.trim();
        renewalDate = _expiryCtrl.text.trim().isEmpty ? null : _expiryCtrl.text.trim();
        break;
      case ResourceType.inventory:
        details['location'] = _locCtrl.text.trim();
        details['unitCost'] = double.tryParse(_unitCostCtrl.text) ?? 0.0;
        break;
      case ResourceType.contact:
        details['phone'] = _phoneCtrl.text.trim();
        details['email'] = _emailCtrl.text.trim();
        details['role'] = _roleCtrl.text.trim();
        break;
      case ResourceType.password:
        details['username'] = _emailCtrl.text.trim();
        details['password'] = _passwordCtrl.text.trim();
        details['url'] = _urlCtrl.text.trim();
        break;
      case ResourceType.wifiPassword:
        details['ssid'] = _ssidCtrl.text.trim().isEmpty ? _nameCtrl.text.trim() : _ssidCtrl.text.trim();
        details['password'] = _passwordCtrl.text.trim();
        break;
      case ResourceType.bankCard:
        details['cardholder'] = _cardholderCtrl.text.trim();
        details['cardNumber'] = _cardNumberCtrl.text.trim();
        details['bank'] = _bankCtrl.text.trim();
        details['expiry'] = _expiryCtrl.text.trim();
        break;
    }

    final resource = Resource(
      id: widget.existing?.id ?? '',
      type: _type,
      name: _nameCtrl.text.trim(),
      details: details,
      renewalDate: renewalDate,
      tags: _parseTags(_tagsCtrl.text),
      quantity: _type == ResourceType.inventory
          ? (int.tryParse(_qtyCtrl.text) ?? 0)
          : null,
      lowStockThreshold: int.tryParse(_lowCtrl.text) ?? 5,
      createdAt: widget.existing?.createdAt ?? DateTime.now().toIso8601String(),
    );

    final store = ref.read(appStoreProvider.notifier);
    if (widget.existing != null) {
      store.updateResource(widget.existing!.id, (_) => resource);
    } else {
      store.addResource(resource);
    }
    NexaHaptics.success();
    Navigator.of(context).maybePop();
  }

  List<String> _parseTags(String s) => s
      .split(',')
      .map((t) => t.trim().toLowerCase())
      .where((t) => t.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Vault Item Type Picker Dropdown
        DropdownButtonFormField<ResourceType>(
          value: _type,
          decoration: InputDecoration(
            labelText: 'Vault Item Category',
            prefixIcon: Icon(
              kResourceTypeIconData[_type] ?? LucideIcons.box,
              size: 20,
              color: primaryColor(context),
            ),
          ),
          items: ResourceType.values
              .map((t) => DropdownMenuItem(
                  value: t,
                  child: Row(
                    children: [
                      Icon(kResourceTypeIconData[t] ?? LucideIcons.box, size: 16),
                      const SizedBox(width: 8),
                      Text(kResourceTypeLabels[t] ?? t.name),
                    ],
                  )))
              .toList(),
          onChanged: (v) {
            NexaHaptics.selection();
            setState(() => _type = v ?? ResourceType.document);
          },
        ),
        const SizedBox(height: 12),

        // Item Name / Title
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelText: _type == ResourceType.contact
                ? 'Contact Name'
                : (_type == ResourceType.wifiPassword ? 'Network Name' : 'Item Name / Label'),
            hintText: _type == ResourceType.subscription
                ? 'e.g., Netflix, Spotify, AWS'
                : (_type == ResourceType.password ? 'e.g., Google Account' : 'e.g., Passport, Office Desk'),
          ),
        ),
        const SizedBox(height: 12),

        // Dynamic Type-Specific Fields
        _typeFields(),
        const SizedBox(height: 12),

        // Notes
        TextField(
          controller: _notesCtrl,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            hintText: 'Additional details or memo',
          ),
        ),
        const SizedBox(height: 12),

        // Tags
        TextField(
          controller: _tagsCtrl,
          decoration: const InputDecoration(
            labelText: 'Tags (comma separated)',
            hintText: 'work, personal, finance',
          ),
        ),
        const SizedBox(height: 24),

        // Submit Button
        GradientButton(
          widget.existing != null ? 'Save Changes' : 'Add to Vault',
          onPressed: _submit,
        ),
      ],
    );
  }

  Widget _typeFields() {
    return switch (_type) {
      ResourceType.subscription => Column(
          children: [
            TextField(
              controller: _planCtrl,
              decoration: const InputDecoration(
                labelText: 'Plan / Tier',
                hintText: 'e.g., Family Plan, Pro Monthly',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _costCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Cost',
                      hintText: '0.00',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _billingCycle,
                    decoration: const InputDecoration(labelText: 'Cycle'),
                    items: const [
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                      DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    ],
                    onChanged: (v) => setState(() => _billingCycle = v ?? 'monthly'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _dateField('Next Renewal Date', _renewalCtrl),
          ],
        ),
      ResourceType.document => Column(
          children: [
            TextField(
              controller: _docNumCtrl,
              decoration: const InputDecoration(
                labelText: 'Document / Reference Number',
                hintText: 'e.g., AB1234567',
              ),
            ),
            const SizedBox(height: 10),
            _dateField('Expiry Date', _expiryCtrl),
          ],
        ),
      ResourceType.inventory => Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity in Stock',
                      hintText: '0',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _lowCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Low Stock Alert At',
                      hintText: '5',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _unitCostCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Unit Cost (optional)',
                      hintText: '0.00',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _locCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Location / Shelf',
                      hintText: 'e.g., Box 3, Garage',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ResourceType.contact => Column(
          children: [
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+1 234 567 8900',
                prefixIcon: Icon(LucideIcons.phone, size: 18),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'person@example.com',
                prefixIcon: Icon(LucideIcons.mail, size: 18),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _roleCtrl,
              decoration: const InputDecoration(
                labelText: 'Role / Relationship',
                hintText: 'e.g., Accountant, Landlord, Doctor',
              ),
            ),
          ],
        ),
      ResourceType.password => Column(
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Username / Email',
                hintText: 'user@example.com',
                prefixIcon: Icon(LucideIcons.user, size: 18),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(LucideIcons.lock, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 18,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _urlCtrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Website / App URL',
                hintText: 'https://example.com',
                prefixIcon: Icon(LucideIcons.globe, size: 18),
              ),
            ),
          ],
        ),
      ResourceType.wifiPassword => Column(
          children: [
            TextField(
              controller: _ssidCtrl,
              decoration: const InputDecoration(
                labelText: 'SSID (Network Name)',
                hintText: 'e.g., Home_5G',
                prefixIcon: Icon(LucideIcons.wifi, size: 18),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'WiFi Password',
                prefixIcon: const Icon(LucideIcons.keyRound, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 18,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
          ],
        ),
      ResourceType.bankCard => Column(
          children: [
            TextField(
              controller: _cardholderCtrl,
              decoration: const InputDecoration(
                labelText: 'Cardholder Name',
                hintText: 'JOHN DOE',
                prefixIcon: Icon(LucideIcons.user, size: 18),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cardNumberCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Card Number (or last 4 digits)',
                hintText: '•••• •••• •••• 1234',
                prefixIcon: Icon(LucideIcons.creditCard, size: 18),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bankCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Bank Name',
                      hintText: 'Chase, HBL, etc.',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _expiryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Expiry (MM/YY)',
                      hintText: '12/28',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
    };
  }

  Widget _dateField(String label, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(LucideIcons.calendar, size: 18),
      ),
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 30)),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (d != null) {
          ctrl.text =
              '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        }
      },
    );
  }
}
