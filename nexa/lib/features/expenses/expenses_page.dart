import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/animations.dart';
import '../../core/constants.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';
import '../../widgets/glass.dart';
import '../../widgets/store_guard.dart';
import '../../widgets/tiles.dart';
import 'add_expense_sheet.dart';
import 'currency_converter_sheet.dart';
import 'edit_expense_sheet.dart';
import 'set_budget_sheet.dart';

enum _Tab { overview, transactions, budgets, reports }
enum _DateRange { thisMonth, lastMonth, last90Days, allTime }
enum _SortBy { newest, oldest, highestAmount, lowestAmount }

class ExpensesPage extends ConsumerStatefulWidget {
  const ExpensesPage({super.key});

  static Future<void> openAdder(BuildContext context) =>
      AddExpenseSheet.show(context);

  @override
  ConsumerState<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends ConsumerState<ExpensesPage> {
  _Tab _tab = _Tab.overview;
  _DateRange _range = _DateRange.thisMonth;
  String _searchQuery = '';
  String _typeFilter = 'all'; // 'all', 'expense', 'income'
  String _selectedCategory = 'all';
  _SortBy _sortBy = _SortBy.newest;

  @override
  Widget build(BuildContext context) {
    return StoreGuard(
      child: (data) {
        final currency = data.user.currency;
        final filteredExpenses = _filterExpenses(data.expenses);

        return Column(
          children: [
            _tabs,
            Expanded(
              child: switch (_tab) {
                _Tab.overview => _Overview(
                    allExpenses: data.expenses,
                    range: _range,
                    currency: currency,
                    onRangeChanged: (r) => setState(() => _range = r),
                  ),
                _Tab.transactions => _Transactions(
                    expenses: filteredExpenses,
                    currency: currency,
                    searchQuery: _searchQuery,
                    typeFilter: _typeFilter,
                    selectedCategory: _selectedCategory,
                    sortBy: _sortBy,
                    onSearchChanged: (q) => setState(() => _searchQuery = q),
                    onTypeFilterChanged: (t) => setState(() => _typeFilter = t),
                    onCategoryChanged: (c) => setState(() => _selectedCategory = c),
                    onSortChanged: (s) => setState(() => _sortBy = s),
                  ),
                _Tab.budgets => _Budgets(currency: currency, data: data),
                _Tab.reports => filteredExpenses.isEmpty
                    ? EmptyState(
                        icon: LucideIcons.barChart3,
                        title: 'No data for this period',
                        text: 'Add or record transactions to view rich visual analytics.',
                        buttonLabel: 'Add Expense',
                        onButton: () => AddExpenseSheet.show(context),
                      )
                    : _Reports(
                        expenses: filteredExpenses,
                        currency: currency,
                        range: _range,
                        onRangeChanged: (r) => setState(() => _range = r),
                      ),
              },
            ),
          ],
        );
      },
    );
  }

  List<Expense> _filterExpenses(List<Expense> list) {
    final now = DateTime.now();
    var filtered = list.where((e) {
      final d = DateTime.tryParse(e.date);
      if (d == null) return true;

      // Date range filter
      final matchesRange = switch (_range) {
        _DateRange.thisMonth =>
          d.year == now.year && d.month == now.month,
        _DateRange.lastMonth =>
          d.year == (now.month == 1 ? now.year - 1 : now.year) &&
              d.month == (now.month == 1 ? 12 : now.month - 1),
        _DateRange.last90Days =>
          now.difference(d).inDays <= 90,
        _DateRange.allTime => true,
      };
      if (!matchesRange) return false;

      // Type filter
      if (_typeFilter != 'all' && e.type != _typeFilter) return false;

      // Category filter
      if (_selectedCategory != 'all' && e.category != _selectedCategory) {
        return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final cat = (kCategories[e.category] ?? e.category).toLowerCase();
        final note = e.note.toLowerCase();
        if (!cat.contains(q) && !note.contains(q)) return false;
      }

      return true;
    }).toList();

    // Sorting
    switch (_sortBy) {
      case _SortBy.newest:
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case _SortBy.oldest:
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case _SortBy.highestAmount:
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case _SortBy.lowestAmount:
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    return filtered;
  }

  Widget get _tabs => Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: surfaceColor(context).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor(context).withOpacity(0.6)),
                ),
                child: Row(
                  children: [
                    _tabBtn('Overview', _Tab.overview),
                    _tabBtn('Transactions', _Tab.transactions),
                    _tabBtn('Budgets', _Tab.budgets),
                    _tabBtn('Reports', _Tab.reports),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Currency Converter',
              icon: const Icon(LucideIcons.arrowLeftRight, size: 18),
              onPressed: () {
                NexaHaptics.tick();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const CurrencyConverterSheet(),
                );
              },
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _tabBtn(String label, _Tab t) {
    final active = _tab == t;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          NexaHaptics.tick();
          setState(() => _tab = t);
        },
        child: AnimatedContainer(
          duration: NexaAnim.fast,
          padding: const EdgeInsets.symmetric(vertical: 8.5),
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(colors: NexaColors.gradPrimary)
                : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: NexaColors.gradPrimary[0].withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : textSecondaryColor(context),
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Overview ───────────────────────────────────────────────────────────
class _Overview extends ConsumerWidget {
  final List<Expense> allExpenses;
  final _DateRange range;
  final String currency;
  final ValueChanged<_DateRange> onRangeChanged;

  const _Overview({
    required this.allExpenses,
    required this.range,
    required this.currency,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final todayStr = todayIsoDate();
    final thisMonthPrefix = todayStr.substring(0, 7);

    final periodExpenses = allExpenses.where((e) {
      final d = DateTime.tryParse(e.date);
      if (d == null) return true;
      return switch (range) {
        _DateRange.thisMonth => d.year == now.year && d.month == now.month,
        _DateRange.lastMonth =>
          d.year == (now.month == 1 ? now.year - 1 : now.year) &&
              d.month == (now.month == 1 ? 12 : now.month - 1),
        _DateRange.last90Days => now.difference(d).inDays <= 90,
        _DateRange.allTime => true,
      };
    }).toList();

    final spent = periodExpenses
        .where((e) => e.type == 'expense')
        .fold(0.0, (s, e) => s + e.amount);
    final income = periodExpenses
        .where((e) => e.type == 'income')
        .fold(0.0, (s, e) => s + e.amount);
    final balance = income - spent;

    // Daily spending comparison calculation (Today vs Month's daily average)
    final thisMonthExpenses = allExpenses
        .where((e) => e.date.startsWith(thisMonthPrefix) && e.type == 'expense')
        .toList();
    final monthSpentTotal =
        thisMonthExpenses.fold(0.0, (s, e) => s + e.amount);
    final dayOfMonth = now.day > 0 ? now.day : 1;
    final avgDailySpend = monthSpentTotal / dayOfMonth;
    final todaySpend = thisMonthExpenses
        .where((e) => e.date == todayStr)
        .fold(0.0, (s, e) => s + e.amount);
    final isUnderAverage = todaySpend <= avgDailySpend;

    // Top 3 spending categories
    final catTotals = <String, double>{};
    for (final e in periodExpenses.where((e) => e.type == 'expense')) {
      catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
    }
    final sortedCats = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sortedCats.take(3).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      children: [
        // Date range pill selector
        _dateRangeSelector(context),
        const SizedBox(height: 10),

        // Net Balance Card
        StaggeredFadeIn(
          index: 0,
          child: GradientBorderCard(
            gradient:
                balance >= 0 ? NexaColors.gradSuccess : NexaColors.gradWarm,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Net Balance (${_rangeLabel(range)})',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: textSecondaryColor(context)),
                      ),
                      const SizedBox(height: 6),
                      CountUpText(
                        value: balance,
                        formatter: (v) => formatCurrency(v, currency),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                          color: balance >= 0
                              ? NexaColors.success
                              : NexaColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: (balance >= 0
                            ? NexaColors.success
                            : NexaColors.danger)
                        .withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    balance >= 0
                        ? LucideIcons.trendingUp
                        : LucideIcons.trendingDown,
                    color:
                        balance >= 0 ? NexaColors.success : NexaColors.danger,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Spent vs Income Two-Column Cards
        StaggeredFadeIn(
          index: 1,
          child: Row(
            children: [
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: NexaColors.danger.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(LucideIcons.arrowUpRight,
                                size: 14, color: NexaColors.danger),
                          ),
                          const SizedBox(width: 8),
                          Text('Spent',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondaryColor(context))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CountUpText(
                        value: spent,
                        formatter: (v) => formatCurrency(v, currency),
                        style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color: NexaColors.danger),
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
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: NexaColors.success.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(LucideIcons.arrowDownLeft,
                                size: 14, color: NexaColors.success),
                          ),
                          const SizedBox(width: 8),
                          Text('Income',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondaryColor(context))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CountUpText(
                        value: income,
                        formatter: (v) => formatCurrency(v, currency),
                        style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color: NexaColors.success),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Daily Spend vs Average Bar ──
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.clock, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Daily Spending Pace',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isUnderAverage ? NexaColors.success : NexaColors.warning)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isUnderAverage ? 'Under daily avg 👍' : 'Above daily avg ⚠️',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isUnderAverage
                            ? NexaColors.success
                            : NexaColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Today\'s Spent',
                            style: TextStyle(
                                fontSize: 11,
                                color: textSecondaryColor(context))),
                        const SizedBox(height: 3),
                        Text(
                          formatCurrency(todaySpend, currency),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isUnderAverage
                                ? NexaColors.success
                                : NexaColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: borderColor(context).withOpacity(0.5),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Daily Average (MTD)',
                            style: TextStyle(
                                fontSize: 11,
                                color: textSecondaryColor(context))),
                        const SizedBox(height: 3),
                        Text(
                          formatCurrency(avgDailySpend, currency),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
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

        // ── Top 3 Spending Categories ──
        if (top3.isNotEmpty) ...[
          const SizedBox(height: 14),
          const SectionHeader('Top Spending Categories'),
          ...top3.asMap().entries.map((item) {
            final rank = item.key + 1;
            final catKey = item.value.key;
            final catAmt = item.value.value;
            final catName = kCategories[catKey] ?? catKey;
            final catCol = NexaColors.categoryColor(catKey);
            final pct = spent > 0 ? (catAmt / spent) : 0.0;

            return GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: catCol.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: catCol,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        kCategoryIcons[catKey] as IconData? ?? LucideIcons.tag,
                        size: 16,
                        color: catCol,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          catName,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        formatCurrency(catAmt, currency),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: catCol.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation(catCol),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],

        const SizedBox(height: 14),
        const SectionHeader('Recent Transactions'),
        if (periodExpenses.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No transactions recorded in this period',
                style: TextStyle(
                    color: textSecondaryColor(context), fontSize: 13.5),
              ),
            ),
          )
        else
          ...periodExpenses
              .take(6)
              .toList()
              .asMap()
              .entries
              .map((entry) => StaggeredFadeIn(
                    index: entry.key + 2,
                    child: ExpenseTile(
                      expense: entry.value,
                      currency: currency,
                      onTap: () {
                        NexaHaptics.light();
                        EditExpenseSheet.show(context, entry.value);
                      },
                      onDelete: () {
                        final deleted = entry.value;
                        NexaHaptics.swipeAction();
                        ref
                            .read(appStoreProvider.notifier)
                            .deleteExpense(deleted.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Deleted "${deleted.note.isEmpty ? (kCategories[deleted.category] ?? deleted.category) : deleted.note}"',
                            ),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                ref.read(appStoreProvider.notifier).addExpense(
                                      amount: deleted.amount,
                                      type: deleted.type,
                                      category: deleted.category,
                                      accountId: deleted.accountId,
                                      note: deleted.note,
                                      date: deleted.date,
                                      isRecurring: deleted.isRecurring,
                                    );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  )),
      ],
    );
  }

  Widget _dateRangeSelector(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _DateRange.values.map((r) {
          final active = range == r;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_rangeLabel(r)),
              selected: active,
              onSelected: (_) {
                NexaHaptics.tick();
                onRangeChanged(r);
              },
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? Colors.white : textSecondaryColor(context),
              ),
              selectedColor: NexaColors.gradPrimary[0],
              backgroundColor: surfaceColor(context),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              side: BorderSide(
                  color: active
                      ? Colors.transparent
                      : borderColor(context).withOpacity(0.6)),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _rangeLabel(_DateRange r) => switch (r) {
        _DateRange.thisMonth => 'This Month',
        _DateRange.lastMonth => 'Last Month',
        _DateRange.last90Days => 'Last 90 Days',
        _DateRange.allTime => 'All Time',
      };
}

// ─── Transactions Tab with Search & Filter ──────────────────────────────
class _Transactions extends ConsumerWidget {
  final List<Expense> expenses;
  final String currency;
  final String searchQuery;
  final String typeFilter;
  final String selectedCategory;
  final _SortBy sortBy;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onTypeFilterChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<_SortBy> onSortChanged;

  const _Transactions({
    required this.expenses,
    required this.currency,
    required this.searchQuery,
    required this.typeFilter,
    required this.selectedCategory,
    required this.sortBy,
    required this.onSearchChanged,
    required this.onTypeFilterChanged,
    required this.onCategoryChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Search & Filter Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search note or category...',
                        prefixIcon: const Icon(LucideIcons.search, size: 18),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(LucideIcons.x, size: 16),
                                onPressed: () => onSearchChanged(''),
                              )
                            : null,
                      ),
                      onChanged: onSearchChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Sort button
                  PopupMenuButton<_SortBy>(
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: surfaceColor(context),
                        borderRadius: BorderRadius.circular(12),
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
                        value: _SortBy.newest,
                        child: Text('Newest Date'),
                      ),
                      const PopupMenuItem(
                        value: _SortBy.oldest,
                        child: Text('Oldest Date'),
                      ),
                      const PopupMenuItem(
                        value: _SortBy.highestAmount,
                        child: Text('Highest Amount'),
                      ),
                      const PopupMenuItem(
                        value: _SortBy.lowestAmount,
                        child: Text('Lowest Amount'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Type Filters Row
              Row(
                children: [
                  _filterChip(context, 'All', 'all', typeFilter == 'all',
                      () => onTypeFilterChanged('all')),
                  const SizedBox(width: 8),
                  _filterChip(context, 'Expenses', 'expense',
                      typeFilter == 'expense',
                      () => onTypeFilterChanged('expense')),
                  const SizedBox(width: 8),
                  _filterChip(context, 'Income', 'income',
                      typeFilter == 'income',
                      () => onTypeFilterChanged('income')),
                ],
              ),
              const SizedBox(height: 6),

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _categoryFilterChip(context, 'All Categories', 'all'),
                    ...kCategories.entries.map((entry) =>
                        _categoryFilterChip(context, entry.value, entry.key)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Transaction List
        Expanded(
          child: expenses.isEmpty
              ? const EmptyState(
                  icon: LucideIcons.filterX,
                  title: 'No matching transactions',
                  text: 'Try adjusting your search or category filters.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  itemCount: expenses.length,
                  itemBuilder: (ctx, i) {
                    final e = expenses[i];
                    return StaggeredFadeIn(
                      index: i,
                      child: ExpenseTile(
                        expense: e,
                        currency: currency,
                        onTap: () {
                          NexaHaptics.light();
                          EditExpenseSheet.show(context, e);
                        },
                        onDelete: () {
                          final deleted = e;
                          NexaHaptics.swipeAction();
                          ref
                              .read(appStoreProvider.notifier)
                              .deleteExpense(deleted.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Deleted "${deleted.note.isEmpty ? (kCategories[deleted.category] ?? deleted.category) : deleted.note}"',
                              ),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () {
                                  ref
                                      .read(appStoreProvider.notifier)
                                      .addExpense(
                                        amount: deleted.amount,
                                        type: deleted.type,
                                        category: deleted.category,
                                        accountId: deleted.accountId,
                                        note: deleted.note,
                                        date: deleted.date,
                                        isRecurring: deleted.isRecurring,
                                      );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterChip(BuildContext context, String label, String value,
      bool active, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) {
        NexaHaptics.tick();
        onTap();
      },
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        color: active ? Colors.white : textSecondaryColor(context),
      ),
      selectedColor: NexaColors.gradPrimary[0],
      backgroundColor: surfaceColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(
          color: active
              ? Colors.transparent
              : borderColor(context).withOpacity(0.6)),
    );
  }

  Widget _categoryFilterChip(
      BuildContext context, String label, String catKey) {
    final active = selectedCategory == catKey;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: active,
        onSelected: (_) {
          NexaHaptics.tick();
          onCategoryChanged(catKey);
        },
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active ? Colors.white : textSecondaryColor(context),
        ),
        selectedColor: catKey == 'all'
            ? NexaColors.gradPrimary[0]
            : NexaColors.categoryColor(catKey),
        backgroundColor: surfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(
          color: active
              ? Colors.transparent
              : borderColor(context).withOpacity(0.5),
        ),
      ),
    );
  }
}

// ─── Budgets Tab ────────────────────────────────────────────────────────
class _Budgets extends ConsumerWidget {
  final String currency;
  final AppData data;
  const _Budgets({required this.currency, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final my = monthYearKey();
    final budgets = data.budgets.where((b) => b.monthYear == my).toList();
    final monthExp = data.expenses
        .where((e) => e.date.startsWith(my) && e.type == 'expense');

    final spentByCat = <String, double>{};
    for (final e in monthExp) {
      spentByCat[e.category] = (spentByCat[e.category] ?? 0) + e.amount;
    }

    final totalBudget =
        budgets.fold(0.0, (sum, b) => sum + b.monthlyLimit);
    final totalSpent = spentByCat.values.fold(0.0, (sum, val) => sum + val);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      children: [
        // Overall Budget Health Card
        if (totalBudget > 0)
          GradientBorderCard(
            gradient: totalSpent > totalBudget
                ? NexaColors.gradWarm
                : NexaColors.gradCool,
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Budget Usage',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textSecondaryColor(context))),
                      const SizedBox(height: 4),
                      Text(
                        '${formatCurrency(totalSpent, currency)} / ${formatCurrency(totalBudget, currency)}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        totalSpent > totalBudget
                            ? '🚨 Over budget by ${formatCurrency(totalSpent - totalBudget, currency)}'
                            : '✨ ${formatCurrency(totalBudget - totalSpent, currency)} remaining',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: totalSpent > totalBudget
                              ? NexaColors.danger
                              : NexaColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                ProgressRing(
                  percent: (totalSpent / totalBudget) * 100,
                  size: 60,
                  stroke: 6,
                ),
              ],
            ),
          ),

        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionHeader('Category Budgets'),
            TextButton.icon(
              onPressed: () => SetBudgetSheet.show(context),
              icon: const Icon(LucideIcons.slidersHorizontal, size: 15),
              label: const Text('Adjust Budgets', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        ...kCategories.entries.map((entry) {
          final b = budgets.firstWhere(
            (x) => x.category == entry.key,
            orElse: () => Budget(
                id: '',
                category: entry.key,
                monthlyLimit: 0,
                monthYear: my),
          );
          final spentAmt = spentByCat[entry.key] ?? 0.0;
          final limit = b.monthlyLimit;
          final pct = limit > 0 ? (spentAmt / limit) : 0.0;
          final isOver = limit > 0 && spentAmt > limit;
          final color = NexaColors.categoryColor(entry.key);

          // Color transition: green for < 70%, amber for 70-90%, red for > 90%
          final barColor = isOver || pct >= 0.9
              ? NexaColors.danger
              : (pct >= 0.7 ? NexaColors.warning : NexaColors.success);

          return GlassCard(
            onTap: () => SetBudgetSheet.show(context),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        kCategoryIcons[entry.key] as IconData? ?? LucideIcons.tag,
                        size: 15,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.value,
                              style: const TextStyle(
                                  fontSize: 13.5, fontWeight: FontWeight.w700)),
                          Text(
                            limit > 0
                                ? '${formatCurrency(spentAmt, currency)} of ${formatCurrency(limit, currency)}'
                                : 'No budget set',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: textSecondaryColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (limit > 0)
                      Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: barColor,
                        ),
                      )
                    else
                      Text(
                        'Set',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: NexaColors.gradPrimary[0],
                        ),
                      ),
                  ],
                ),
                if (limit > 0) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: barColor.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation(barColor),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─── Reports Tab ────────────────────────────────────────────────────────
class _Reports extends StatelessWidget {
  final List<Expense> expenses;
  final String currency;
  final _DateRange range;
  final ValueChanged<_DateRange> onRangeChanged;

  const _Reports({
    required this.expenses,
    required this.currency,
    required this.range,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final spentExpenses =
        expenses.where((e) => e.type == 'expense').toList();
    final totalSpent =
        spentExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalIncome = expenses
        .where((e) => e.type == 'income')
        .fold(0.0, (sum, e) => sum + e.amount);

    final savingsRate = totalIncome > 0
        ? ((totalIncome - totalSpent) / totalIncome) * 100
        : 0.0;

    // Daily breakdown for line chart (past 30 days)
    final dailyMap = <String, double>{};
    for (final e in spentExpenses) {
      dailyMap[e.date] = (dailyMap[e.date] ?? 0) + e.amount;
    }
    final sortedDates = dailyMap.keys.toList()..sort();
    final recentDates = sortedDates.length > 14
        ? sortedDates.sublist(sortedDates.length - 14)
        : sortedDates;

    final lineSpots = <FlSpot>[];
    for (var i = 0; i < recentDates.length; i++) {
      final amt = dailyMap[recentDates[i]] ?? 0.0;
      lineSpots.add(FlSpot(i.toDouble(), amt));
    }

    final catMap = <String, double>{};
    for (final e in spentExpenses) {
      catMap[e.category] = (catMap[e.category] ?? 0) + e.amount;
    }
    final sortedCats = catMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Daily average
    final activeDays = dailyMap.isNotEmpty ? dailyMap.keys.length : 1;
    final avgDaily = totalSpent / activeDays;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      children: [
        // Savings Rate Card
        StaggeredFadeIn(
          index: 0,
          child: GradientBorderCard(
            gradient: savingsRate >= 20
                ? NexaColors.gradSuccess
                : savingsRate >= 0
                    ? NexaColors.gradCool
                    : NexaColors.gradWarm,
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Savings Rate',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textSecondaryColor(context)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${savingsRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: savingsRate >= 0
                              ? NexaColors.success
                              : NexaColors.danger,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        savingsRate >= 30
                            ? '🌟 Excellent financial discipline!'
                            : savingsRate >= 10
                                ? '👍 Good progress on savings.'
                                : savingsRate >= 0
                                    ? '⚠️ Spending almost matched income.'
                                    : '🚨 Expenses exceeded income.',
                        style: TextStyle(
                            fontSize: 11,
                            color: textSecondaryColor(context)),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: (savingsRate >= 0
                            ? NexaColors.success
                            : NexaColors.danger)
                        .withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    savingsRate >= 0
                        ? LucideIcons.piggyBank
                        : LucideIcons.alertTriangle,
                    color: savingsRate >= 0
                        ? NexaColors.success
                        : NexaColors.danger,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Average Daily Spending Metric
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: NexaColors.lightPrimary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.calendarDays,
                    size: 22, color: NexaColors.lightPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Average Daily Spend',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textSecondaryColor(context))),
                    const SizedBox(height: 2),
                    Text(
                      formatCurrency(avgDaily, currency),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Daily Spending Trend LineChart ──
        if (lineSpots.length >= 2) ...[
          const SizedBox(height: 12),
          const SectionHeader('Daily Spending Trend'),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(14, 18, 18, 14),
            child: SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: borderColor(context).withOpacity(0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: lineSpots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: NexaColors.catBills,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            NexaColors.catBills.withOpacity(0.3),
                            NexaColors.catBills.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        // ── Spending by Category PieChart ──
        if (sortedCats.isNotEmpty) ...[
          const SizedBox(height: 12),
          const SectionHeader('Spending by Category'),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2.5,
                      centerSpaceRadius: 40,
                      sections: sortedCats.map((entry) {
                        final pct = totalSpent > 0
                            ? (entry.value / totalSpent) * 100
                            : 0.0;
                        final color = NexaColors.categoryColor(entry.key);
                        return PieChartSectionData(
                          color: color,
                          value: entry.value,
                          title: '${pct.toStringAsFixed(0)}%',
                          radius: 46,
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Category Legend
                ...sortedCats.map((entry) {
                  final catName = kCategories[entry.key] ?? entry.key;
                  final pct = totalSpent > 0
                      ? (entry.value / totalSpent) * 100
                      : 0.0;
                  final color = NexaColors.categoryColor(entry.key);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(catName,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Text(
                          '${pct.toStringAsFixed(1)}%  ',
                          style: TextStyle(
                              fontSize: 12,
                              color: textSecondaryColor(context)),
                        ),
                        Text(
                          formatCurrency(entry.value, currency),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],

        // ── Income vs Expense Comparison Bar Chart ──
        if (totalIncome > 0 || totalSpent > 0) ...[
          const SizedBox(height: 12),
          const SectionHeader('Income vs Expense Comparison'),
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (totalIncome > totalSpent ? totalIncome : totalSpent) *
                      1.15,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          return Text(
                            val == 0 ? 'Income' : 'Expense',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: val == 0
                                  ? NexaColors.success
                                  : NexaColors.danger,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [
                      BarChartRodData(
                        toY: totalIncome,
                        gradient: const LinearGradient(
                            colors: NexaColors.gradSuccess),
                        width: 32,
                        borderRadius: BorderRadius.circular(8),
                      )
                    ]),
                    BarChartGroupData(x: 1, barRods: [
                      BarChartRodData(
                        toY: totalSpent,
                        gradient:
                            const LinearGradient(colors: NexaColors.gradWarm),
                        width: 32,
                        borderRadius: BorderRadius.circular(8),
                      )
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
