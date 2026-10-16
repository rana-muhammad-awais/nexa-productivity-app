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
import 'note_editor_page.dart';

enum _NoteSort { updated, created, title, color }

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  static Future<void> openAdder(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const _TemplatePicker(),
    );
  }

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  String _folder = 'all';
  String _query = '';
  bool _isGrid = false;
  _NoteSort _sort = _NoteSort.updated;
  final Set<String> _selectedNoteIds = {};
  bool _isMultiSelect = false;

  void _toggleNoteSelection(String id) {
    NexaHaptics.tick();
    setState(() {
      if (_selectedNoteIds.contains(id)) {
        _selectedNoteIds.remove(id);
        if (_selectedNoteIds.isEmpty) _isMultiSelect = false;
      } else {
        _selectedNoteIds.add(id);
      }
    });
  }

  void _deleteSelectedNotes() {
    NexaHaptics.medium();
    final store = ref.read(appStoreProvider.notifier);
    for (final id in _selectedNoteIds) {
      store.deleteNote(id);
    }
    setState(() {
      _selectedNoteIds.clear();
      _isMultiSelect = false;
    });
  }

  void _promptAddFolder(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            hintText: 'e.g. Projects, Personal, Archive',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                ref.read(appStoreProvider.notifier).addNoteFolder(name);
                NexaHaptics.success();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Create Folder'),
          ),
        ],
      ),
    );
  }

  void _showFolderOptions(BuildContext context, NoteFolder folder) {
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
            ListTile(
              leading: const Icon(LucideIcons.edit2, size: 20),
              title: const Text('Rename Folder'),
              onTap: () {
                Navigator.pop(ctx);
                _promptRenameFolder(context, folder);
              },
            ),
            if (folder.id != 'inbox')
              ListTile(
                leading: const Icon(LucideIcons.trash2,
                    size: 20, color: NexaColors.danger),
                title: const Text('Delete Folder',
                    style: TextStyle(color: NexaColors.danger)),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(appStoreProvider.notifier).deleteNoteFolder(folder.id);
                  if (_folder == folder.id) setState(() => _folder = 'all');
                  NexaHaptics.medium();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _promptRenameFolder(BuildContext context, NoteFolder folder) {
    final ctrl = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                ref
                    .read(appStoreProvider.notifier)
                    .renameNoteFolder(folder.id, name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StoreGuard(
      child: (data) {
        var notes = [...data.notes];
        if (_folder != 'all') {
          notes = notes.where((n) => n.folderId == _folder).toList();
        }
        if (_query.isNotEmpty) {
          final q = _query.toLowerCase();
          notes = notes
              .where((n) =>
                  n.title.toLowerCase().contains(q) ||
                  n.body.toLowerCase().contains(q) ||
                  n.tags.any((t) => t.toLowerCase().contains(q)))
              .toList();
        }

        // Sorting
        notes.sort((a, b) {
          if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
          return switch (_sort) {
            _NoteSort.updated => b.updatedAt.compareTo(a.updatedAt),
            _NoteSort.created => b.createdAt.compareTo(a.createdAt),
            _NoteSort.title =>
              a.title.toLowerCase().compareTo(b.title.toLowerCase()),
            _NoteSort.color => (a.color ?? '').compareTo(b.color ?? ''),
          };
        });

        return Column(
          children: [
            // Search Bar & Grid/List Toggle & Sort
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(LucideIcons.search, size: 18),
                        hintText: 'Search notes & tags…',
                        isDense: true,
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(LucideIcons.x, size: 16),
                                onPressed: () => setState(() => _query = ''),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Grid / List toggle
                  IconButton(
                    icon: Icon(_isGrid ? LucideIcons.list : LucideIcons.layoutGrid),
                    tooltip: _isGrid ? 'List View' : 'Grid View',
                    onPressed: () {
                      NexaHaptics.tick();
                      setState(() => _isGrid = !_isGrid);
                    },
                  ),
                  // Sort menu
                  PopupMenuButton<_NoteSort>(
                    icon: const Icon(LucideIcons.arrowUpDown, size: 18),
                    onSelected: (val) {
                      NexaHaptics.selection();
                      setState(() => _sort = val);
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: _NoteSort.updated,
                        child: Text('Last Updated'),
                      ),
                      const PopupMenuItem(
                        value: _NoteSort.created,
                        child: Text('Date Created'),
                      ),
                      const PopupMenuItem(
                        value: _NoteSort.title,
                        child: Text('Title (A-Z)'),
                      ),
                      const PopupMenuItem(
                        value: _NoteSort.color,
                        child: Text('Color Tag'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Folder Filter Chips Bar with note count & Add Folder button
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _folderChip(
                    'all',
                    'All Notes',
                    count: data.notes.length,
                  ),
                  ...data.noteFolders.map((f) => _folderChip(
                        f.id,
                        f.name,
                        count:
                            data.notes.where((n) => n.folderId == f.id).length,
                        onLongPress: () => _showFolderOptions(context, f),
                      )),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, right: 6),
                    child: ActionChip(
                      avatar: const Icon(LucideIcons.folderPlus, size: 14),
                      label: const Text('Folder', style: TextStyle(fontSize: 12)),
                      onPressed: () => _promptAddFolder(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Notes View (List or Grid)
            Expanded(
              child: notes.isEmpty
                  ? EmptyState(
                      icon: LucideIcons.fileText,
                      title: 'No notes found',
                      text: _query.isNotEmpty
                          ? 'No notes match "$_query".'
                          : 'Capture ideas, meeting notes, or journal entries.',
                      buttonLabel: 'Add Note',
                      onButton: () => _openNewNote(context, ref),
                    )
                  : Stack(
                      children: [
                        _isGrid
                            ? GridView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 120),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 0.85,
                                ),
                                itemCount: notes.length,
                                itemBuilder: (ctx, i) {
                                  final n = notes[i];
                                  final isSel =
                                      _selectedNoteIds.contains(n.id);
                                  return GestureDetector(
                                    onLongPress: () =>
                                        _toggleNoteSelection(n.id),
                                    child: _GridNoteTile(
                                      note: n,
                                      isSelected: isSel,
                                      isMultiSelect: _isMultiSelect,
                                      onTap: () {
                                        if (_isMultiSelect) {
                                          _toggleNoteSelection(n.id);
                                        } else {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => NoteEditorPage(
                                                  noteId: n.id),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  );
                                },
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 120),
                                itemCount: notes.length,
                                itemBuilder: (ctx, i) {
                                  final n = notes[i];
                                  final isSel =
                                      _selectedNoteIds.contains(n.id);
                                  return StaggeredFadeIn(
                                    index: i,
                                    child: GestureDetector(
                                      onLongPress: () =>
                                          _toggleNoteSelection(n.id),
                                      child: Row(
                                        children: [
                                          if (_isMultiSelect)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8),
                                              child: Checkbox(
                                                value: isSel,
                                                onChanged: (_) =>
                                                    _toggleNoteSelection(n.id),
                                              ),
                                            ),
                                          Expanded(
                                            child: NoteTile(
                                              note: n,
                                              onTap: () {
                                                if (_isMultiSelect) {
                                                  _toggleNoteSelection(n.id);
                                                } else {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          NoteEditorPage(
                                                              noteId: n.id),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                        // Multi-select bottom bar
                        if (_isMultiSelect)
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 20,
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Text(
                                    '${_selectedNoteIds.length} notes selected',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: _deleteSelectedNotes,
                                    icon: const Icon(LucideIcons.trash2,
                                        size: 16, color: NexaColors.danger),
                                    label: const Text(
                                      'Delete',
                                      style: TextStyle(
                                          color: NexaColors.danger),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.x, size: 18),
                                    onPressed: () => setState(() {
                                      _selectedNoteIds.clear();
                                      _isMultiSelect = false;
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _folderChip(
    String id,
    String name, {
    int count = 0,
    VoidCallback? onLongPress,
  }) {
    final active = _folder == id;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: ChoiceChip(
          label: Text('$name ($count)'),
          selected: active,
          onSelected: (_) {
            NexaHaptics.tick();
            setState(() => _folder = id);
          },
          labelStyle: TextStyle(
            color: active ? Colors.white : textSecondaryColor(context),
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
          selectedColor: primaryColor(context),
        ),
      ),
    );
  }

  void _openNewNote(BuildContext context, WidgetRef ref) {
    final note = ref.read(appStoreProvider.notifier).addNote(
          title: 'Untitled Note',
          body: '',
          folderId: _folder == 'all' ? 'inbox' : _folder,
        );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoteEditorPage(noteId: note.id)),
    );
  }
}

class _GridNoteTile extends StatelessWidget {
  final Note note;
  final bool isSelected;
  final bool isMultiSelect;
  final VoidCallback onTap;

  const _GridNoteTile({
    required this.note,
    required this.isSelected,
    required this.isMultiSelect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final accentCol = NexaColors.noteColor(note.color);
    final hasColor = note.color != null && accentCol != NexaColors.noteDefault;

    return GlassCard(
      onTap: onTap,
      tint: hasColor
          ? accentCol.withOpacity(dark ? 0.15 : 0.08)
          : (isSelected ? primaryColor(context).withOpacity(0.12) : null),
      border: isSelected
          ? Border.all(color: primaryColor(context), width: 2)
          : (hasColor
              ? Border.all(color: accentCol.withOpacity(0.35), width: 1.2)
              : null),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (note.pinned) ...[
                const Icon(LucideIcons.pin, size: 12, color: NexaColors.warning),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  note.title.isEmpty ? 'Untitled' : note.title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isMultiSelect)
                Icon(
                  isSelected
                      ? LucideIcons.checkCircle2
                      : LucideIcons.circle,
                  size: 16,
                  color: isSelected ? primaryColor(context) : textSecondaryColor(context),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              notePreview(note.body),
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: textSecondaryColor(context),
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            note.updatedAt.substring(0, 10),
            style: TextStyle(
              fontSize: 10,
              color: textSecondaryColor(context).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplatePicker extends ConsumerWidget {
  const _TemplatePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'New Note',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Start with a blank note or choose a curated template:',
            style: TextStyle(fontSize: 12.5, color: textSecondaryColor(context)),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor(context).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.filePlus, size: 20),
            ),
            title: const Text('Blank Note',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Empty canvas for anything'),
            onTap: () {
              Navigator.pop(context);
              final n = ref.read(appStoreProvider.notifier).addNote(
                    title: 'Untitled Note',
                    body: '',
                  );
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => NoteEditorPage(noteId: n.id)),
              );
            },
          ),
          ...kNoteTemplates.map((t) => ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: NexaColors.gradPrimary[1].withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(t.icon as IconData? ?? LucideIcons.fileText,
                      size: 20),
                ),
                title: Text(t.title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(t.body.split('\n').first),
                onTap: () {
                  Navigator.pop(context);
                  final n = ref.read(appStoreProvider.notifier).addNote(
                        title: t.title,
                        body: t.body,
                      );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => NoteEditorPage(noteId: n.id)),
                  );
                },
              )),
        ],
      ),
    );
  }
}
