import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../data/app_store.dart';
import '../../widgets/glass.dart';
import '../../widgets/sheet.dart';

/// Bottom sheet for adding a new Khata person with live initials avatar preview,
/// phone, email, address, and notes.
class AddKhataPersonSheet extends ConsumerStatefulWidget {
  const AddKhataPersonSheet({super.key});

  static Future<void> show(BuildContext context) => showNexaSheet(
        context,
        title: 'Add Person',
        initialSize: 0.78,
        builder: (_) => const AddKhataPersonSheet(),
      );

  @override
  ConsumerState<AddKhataPersonSheet> createState() =>
      _AddKhataPersonSheetState();
}

class _AddKhataPersonSheetState extends ConsumerState<AddKhataPersonSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      NexaHaptics.error();
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Please enter a person or business name')),
      );
      return;
    }

    ref.read(appStoreProvider.notifier).addKhataPerson(
          name: name,
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          email: _email.text.trim().isEmpty ? null : _email.text.trim(),
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );

    NexaHaptics.success();
    Navigator.of(context).maybePop();
  }

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
      NexaColors.gradSuccess,
      NexaColors.gradSunrise,
      NexaColors.gradRose,
    ];
    final hash = name.trim().isEmpty ? 0 : name.hashCode.abs();
    return gradients[hash % gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    final name = _name.text;
    final initials = _getInitials(name);
    final gradient = _getGradient(name);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Live Initials Avatar Preview ──
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // ── Name Input ──
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Person / Business Name *',
              hintText: 'e.g. Ali Khan or Apex Traders',
              prefixIcon: Icon(LucideIcons.user, size: 18),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // ── Phone Input ──
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone (optional)',
              hintText: '+92 300 1234567',
              prefixIcon: Icon(LucideIcons.phone, size: 18),
            ),
          ),
          const SizedBox(height: 12),

          // ── Email Input ──
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address (optional)',
              hintText: 'ali@example.com',
              prefixIcon: Icon(LucideIcons.mail, size: 18),
            ),
          ),
          const SizedBox(height: 12),

          // ── Address Input ──
          TextField(
            controller: _address,
            decoration: const InputDecoration(
              labelText: 'Address / Location (optional)',
              hintText: 'Shop #4, Commercial Plaza, Lahore',
              prefixIcon: Icon(LucideIcons.mapPin, size: 18),
            ),
          ),
          const SizedBox(height: 12),

          // ── Notes Input ──
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes / Relationship (optional)',
              hintText: 'e.g. Raw material supplier, friend, contractor',
              prefixIcon: Icon(LucideIcons.stickyNote, size: 18),
            ),
          ),
          const SizedBox(height: 20),

          // ── Submit Button ──
          GradientButton(
            'Save Person',
            icon: LucideIcons.userPlus,
            onPressed: _submit,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
