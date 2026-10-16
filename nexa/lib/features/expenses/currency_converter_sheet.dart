import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../widgets/glass.dart';

class CurrencyConverterSheet extends StatefulWidget {
  final String? initialFromCurrency;
  final String? initialToCurrency;
  final double? initialAmount;
  final ValueChanged<double>? onApplyAmount;

  const CurrencyConverterSheet({
    super.key,
    this.initialFromCurrency,
    this.initialToCurrency,
    this.initialAmount,
    this.onApplyAmount,
  });

  @override
  State<CurrencyConverterSheet> createState() => _CurrencyConverterSheetState();
}

class _CurrencyConverterSheetState extends State<CurrencyConverterSheet> {
  // Exchange rates relative to 1 USD
  static const Map<String, double> _kRatesToUsd = {
    'USD': 1.0,
    'EUR': 0.92,
    'GBP': 0.79,
    'PKR': 278.50,
    'INR': 83.60,
    'AED': 3.67,
    'SAR': 3.75,
    'CAD': 1.36,
    'AUD': 1.51,
    'JPY': 156.40,
    'CNY': 7.25,
    'CHF': 0.90,
    'TRY': 32.80,
    'SGD': 1.35,
    'MYR': 4.71,
    'BRL': 5.35,
  };

  static const Map<String, String> _kCurrencyNames = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'PKR': 'Pakistani Rupee',
    'INR': 'Indian Rupee',
    'AED': 'UAE Dirham',
    'SAR': 'Saudi Riyal',
    'CAD': 'Canadian Dollar',
    'AUD': 'Australian Dollar',
    'JPY': 'Japanese Yen',
    'CNY': 'Chinese Yuan',
    'CHF': 'Swiss Franc',
    'TRY': 'Turkish Lira',
    'SGD': 'Singapore Dollar',
    'MYR': 'Malaysian Ringgit',
    'BRL': 'Brazilian Real',
  };

  late String _fromCurrency;
  late String _toCurrency;
  late TextEditingController _amountController;
  bool _customRateEnabled = false;
  late TextEditingController _customRateController;

  @override
  void initState() {
    super.initState();
    _fromCurrency = widget.initialFromCurrency ?? 'USD';
    _toCurrency = widget.initialToCurrency ?? 'PKR';
    if (_fromCurrency == _toCurrency) {
      _toCurrency = _fromCurrency == 'USD' ? 'PKR' : 'USD';
    }

    final initAmt = widget.initialAmount ?? 100.0;
    _amountController = TextEditingController(
      text: initAmt == initAmt.roundToDouble()
          ? initAmt.toStringAsFixed(0)
          : initAmt.toStringAsFixed(2),
    );

    final initialRate = _effectiveRate();
    _customRateController =
        TextEditingController(text: initialRate.toStringAsFixed(4));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customRateController.dispose();
    super.dispose();
  }

  double _effectiveRate() {
    if (_customRateEnabled) {
      final custom = double.tryParse(_customRateController.text.trim());
      if (custom != null && custom > 0) return custom;
    }
    final fromUsd = _kRatesToUsd[_fromCurrency] ?? 1.0;
    final toUsd = _kRatesToUsd[_toCurrency] ?? 1.0;
    // (1 / fromUsd) converts FROM to USD, then * toUsd converts USD to TO
    return (1.0 / fromUsd) * toUsd;
  }

  double _calculateResult() {
    final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
    return amt * _effectiveRate();
  }

  void _swapCurrencies() {
    NexaHaptics.tick();
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      _customRateEnabled = false;
      _customRateController.text = _effectiveRate().toStringAsFixed(4);
    });
  }

  void _addQuickAmount(double delta) {
    NexaHaptics.tick();
    final current = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final next = current + delta;
    _amountController.text = next.toStringAsFixed(0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final rate = _effectiveRate();
    final result = _calculateResult();
    final inverseRate = rate > 0 ? (1.0 / rate) : 0.0;
    final fromSymbol = kCurrencySymbols[_fromCurrency] ?? _fromCurrency;
    final toSymbol = kCurrencySymbols[_toCurrency] ?? _toCurrency;
    final primary = primaryColor(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) => GlassCard(
        blur: 30,
        radius: 28,
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: textSecondaryColor(ctx).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Currency Converter',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Converter Card
                    GlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          // FROM CURRENCY ROW
                          Row(
                            children: [
                              _buildCurrencyDropdown(
                                label: 'From',
                                value: _fromCurrency,
                                onChanged: (v) {
                                  if (v == null) return;
                                  NexaHaptics.tick();
                                  setState(() {
                                    _fromCurrency = v;
                                    if (_fromCurrency == _toCurrency) {
                                      _toCurrency = _fromCurrency == 'USD'
                                          ? 'PKR'
                                          : 'USD';
                                    }
                                    _customRateController.text =
                                        _effectiveRate().toStringAsFixed(4);
                                  });
                                },
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextField(
                                  controller: _amountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                  textAlign: TextAlign.end,
                                  decoration: InputDecoration(
                                    prefixText: '$fromSymbol ',
                                    prefixStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    hintText: '0',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // SWAP BUTTON & RATE PILL
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '1 $_fromCurrency = ${rate < 0.01 ? rate.toStringAsFixed(4) : rate.toStringAsFixed(2)} $_toCurrency',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: primary,
                                  ),
                                ),
                              ),
                              IconButton.filledTonal(
                                icon: const Icon(LucideIcons.arrowUpDown,
                                    size: 16),
                                onPressed: _swapCurrencies,
                                tooltip: 'Swap Currencies',
                                style: IconButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: primary.withOpacity(0.12),
                                  foregroundColor: primary,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          // TO CURRENCY ROW (RESULT)
                          Row(
                            children: [
                              _buildCurrencyDropdown(
                                label: 'To',
                                value: _toCurrency,
                                onChanged: (v) {
                                  if (v == null) return;
                                  NexaHaptics.tick();
                                  setState(() {
                                    _toCurrency = v;
                                    if (_fromCurrency == _toCurrency) {
                                      _fromCurrency = _toCurrency == 'USD'
                                          ? 'EUR'
                                          : 'USD';
                                    }
                                    _customRateController.text =
                                        _effectiveRate().toStringAsFixed(4);
                                  });
                                },
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$toSymbol ${result.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: primary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    Text(
                                      _kCurrencyNames[_toCurrency] ?? '',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: textSecondaryColor(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // QUICK AMOUNT CHIPS
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _quickChip('+10'),
                          _quickChip('+50'),
                          _quickChip('+100'),
                          _quickChip('+500'),
                          _quickChip('+1000'),
                          _quickChip('+5000'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // INVERSE RATE & DETAILS
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.info,
                              size: 16, color: Color(0xFF9CA3AF)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '1 $_toCurrency = ${inverseRate < 0.01 ? inverseRate.toStringAsFixed(4) : inverseRate.toStringAsFixed(3)} $_fromCurrency',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondaryColor(context),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              NexaHaptics.tick();
                              setState(() {
                                _customRateEnabled = !_customRateEnabled;
                              });
                            },
                            child: Text(
                              _customRateEnabled
                                  ? 'Use Auto Rate'
                                  : 'Custom Rate',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_customRateEnabled) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _customRateController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText:
                              'Custom Exchange Rate (1 $_fromCurrency = ? $_toCurrency)',
                          hintText: rate.toStringAsFixed(4),
                          prefixIcon: const Icon(LucideIcons.edit2, size: 16),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ACTION BUTTONS
                    if (widget.onApplyAmount != null)
                      GradientButton(
                        'Apply $toSymbol ${result.toStringAsFixed(2)} to Expense',
                        icon: LucideIcons.check,
                        onPressed: () {
                          NexaHaptics.success();
                          widget.onApplyAmount!(result);
                          Navigator.of(context).pop();
                        },
                      )
                    else
                      GradientButton(
                        'Done',
                        icon: LucideIcons.check,
                        onPressed: () {
                          NexaHaptics.light();
                          Navigator.of(context).pop();
                        },
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickChip(String label) {
    final value = double.tryParse(label.replaceAll('+', '')) ?? 0.0;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        onPressed: () => _addQuickAmount(value),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildCurrencyDropdown({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        isDense: true,
        icon: const Icon(LucideIcons.chevronDown, size: 14),
        items: _kRatesToUsd.keys.map((c) {
          final sym = kCurrencySymbols[c] ?? c;
          return DropdownMenuItem(
            value: c,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  c,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '($sym)',
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondaryColor(context),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
