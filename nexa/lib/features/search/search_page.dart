import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/animations.dart';
import '../../core/theme.dart';
import '../../data/app_store.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/tiles.dart';

/// Unified global search across tasks, notes, expenses, resources.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _query = TextEditingController();
  SearchResult _result = const SearchResult();
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _query.addListener(_doSearch);
  }

  @override
  void dispose() {
    _query.removeListener(_doSearch);
    _query.dispose();
    super.dispose();
  }

  void _doSearch() {
    final r = ref.read(appStoreProvider.notifier).globalSearch(_query.text);
    setState(() {
      _result = r;
      _searched = _query.text.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appStoreProvider).valueOrNull;
    final currency = data?.user.currency ?? 'USD';

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _query,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search tasks, notes, expenses, resources…',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          if (_query.text.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.x),
              onPressed: () {
                _query.clear();
                setState(() {
                  _result = const SearchResult();
                  _searched = false;
                });
              },
            ),
        ],
      ),
      body: !_searched
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.search,
                        size: 48, color: primaryColor(context).withOpacity(0.5)),
                    const SizedBox(height: 12),
                    Text(
                      'Search Everything',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Type any keyword to search tasks, notes, expenses, and resources simultaneously.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: textSecondaryColor(context), fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          : _result.isEmpty
              ? const EmptyState(
                  icon: LucideIcons.searchX,
                  title: 'No results found',
                  text: 'Try searching with a different term.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    if (_result.tasks.isNotEmpty) ...[
                      _sectionHeader('Tasks', _result.tasks.length, LucideIcons.checkSquare),
                      ..._result.tasks.asMap().entries.map((e) => StaggeredFadeIn(
                            index: e.key,
                            child: TaskTile(task: e.value),
                          )),
                    ],
                    if (_result.notes.isNotEmpty) ...[
                      _sectionHeader('Notes', _result.notes.length, LucideIcons.fileText),
                      ..._result.notes.asMap().entries.map((e) => StaggeredFadeIn(
                            index: e.key,
                            child: NoteTile(note: e.value),
                          )),
                    ],
                    if (_result.expenses.isNotEmpty) ...[
                      _sectionHeader('Expenses', _result.expenses.length, LucideIcons.wallet),
                      ..._result.expenses.asMap().entries.map((e) => StaggeredFadeIn(
                            index: e.key,
                            child: ExpenseTile(
                              expense: e.value,
                              currency: currency,
                            ),
                          )),
                    ],
                    if (_result.resources.isNotEmpty) ...[
                      _sectionHeader('Resources', _result.resources.length, LucideIcons.folderLock),
                      ..._result.resources.asMap().entries.map((e) => StaggeredFadeIn(
                            index: e.key,
                            child: ResourceTile(
                              resource: e.value,
                              currency: currency,
                            ),
                          )),
                    ],
                    if (_result.khataPersons.isNotEmpty) ...[
                      _sectionHeader('Khata', _result.khataPersons.length, LucideIcons.bookOpen),
                      ..._result.khataPersons.asMap().entries.map((e) => StaggeredFadeIn(
                            index: e.key,
                            child: ListTile(
                              leading: const Icon(LucideIcons.bookOpen),
                              title: Text(e.value.name),
                              subtitle: Text(e.value.phone ?? e.value.notes ?? ''),
                              dense: true,
                            ),
                          )),
                    ],
                  ],
                ),
    );
  }

  Widget _sectionHeader(String label, int count, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: primaryColor(context)),
          const SizedBox(width: 8),
          Text('$label ($count)',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: primaryColor(context))),
        ],
      ),
    );
  }
}
