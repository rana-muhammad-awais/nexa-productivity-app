import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/animations.dart';
import '../../core/constants.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../data/app_store.dart';
import '../../data/models.dart';

/// Note editor with live preview toggle, rich markdown formatting toolbar,
/// reading time estimate, interactive checklist progress tracker,
/// zen writing mode, note color tinting, and markdown sharing.
class NoteEditorPage extends ConsumerStatefulWidget {
  final String noteId;
  const NoteEditorPage({super.key, required this.noteId});

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late String _folderId;
  String? _color;
  bool _preview = false;
  bool _saving = false;
  bool _zenMode = false;

  @override
  void initState() {
    super.initState();
    final data = ref.read(appStoreProvider).valueOrNull;
    final n = data?.notes.firstWhere((x) => x.id == widget.noteId,
        orElse: () => Note(
            id: widget.noteId,
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String()));
    _title = TextEditingController(text: n?.title ?? '');
    _body = TextEditingController(text: n?.body ?? '');
    _folderId = n?.folderId ?? 'inbox';
    _color = n?.color;

    _body.addListener(_onTextChange);
    _title.addListener(_onTextChange);
  }

  void _onTextChange() {
    setState(() => _saving = true);
    _persist();
  }

  void _persist() {
    ref.read(appStoreProvider.notifier).updateNote(
          widget.noteId,
          (n) => n.copyWith(
            title: _title.text.isEmpty ? 'Untitled' : _title.text,
            body: _body.text,
            folderId: _folderId,
            color: _color,
          ),
        );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _saving = false);
    });
  }

  void _insertFormatting(String prefix, [String suffix = '']) {
    NexaHaptics.tick();
    final text = _body.text;
    final selection = _body.selection;
    if (selection.start < 0) {
      _body.text = '$text$prefix$suffix';
      return;
    }
    final selected = selection.textInside(text);
    final replacement = '$prefix$selected$suffix';
    _body.value = TextEditingValue(
      text: selection.textBefore(text) + replacement + selection.textAfter(text),
      selection: TextSelection.collapsed(
        offset: selection.start + prefix.length + selected.length,
      ),
    );
  }

  void _shareNote() {
    NexaHaptics.tick();
    final title = _title.text.isEmpty ? 'Untitled Note' : _title.text;
    final content = '# $title\n\n${_body.text}';
    Share.share(content, subject: title);
  }

  void _duplicateNote() {
    NexaHaptics.success();
    final copy = ref.read(appStoreProvider.notifier).duplicateNote(widget.noteId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note duplicated successfully')),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => NoteEditorPage(noteId: copy.id)),
    );
  }

  @override
  void dispose() {
    _title.removeListener(_onTextChange);
    _body.removeListener(_onTextChange);
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    final asyncData = ref.watch(appStoreProvider);
    final data = asyncData.valueOrNull;
    final note = data?.notes.firstWhere(
      (n) => n.id == widget.noteId,
      orElse: () => Note(
          id: widget.noteId,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String()),
    );
    final folders = data?.noteFolders ?? kDefaultFolders;

    // Word & Reading time count
    final words = _body.text.trim().isEmpty
        ? 0
        : _body.text.trim().split(RegExp(r'\s+')).length;
    final readTimeMinutes = (words / 200).ceil();

    // Checklists progress calculation
    final totalCheckItems = RegExp(r'-\s*\[[ xX]\]').allMatches(_body.text).length;
    final doneCheckItems = RegExp(r'-\s*\[[xX]\]').allMatches(_body.text).length;
    final checkProgress = totalCheckItems > 0
        ? (doneCheckItems / totalCheckItems)
        : 0.0;

    return Scaffold(
      appBar: _zenMode
          ? null
          : AppBar(
              title: Row(
                children: [
                  const Text('Edit Note'),
                  const SizedBox(width: 8),
                  AnimatedOpacity(
                    opacity: _saving ? 1.0 : 0.0,
                    duration: NexaAnim.fast,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primaryColor(context).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Saving…',
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(_zenMode ? LucideIcons.minimize2 : LucideIcons.maximize2),
                  tooltip: 'Zen Mode',
                  onPressed: () {
                    NexaHaptics.tick();
                    setState(() => _zenMode = !_zenMode);
                  },
                ),
                IconButton(
                  icon: Icon(_preview ? LucideIcons.edit : LucideIcons.eye),
                  tooltip: _preview ? 'Edit' : 'Preview',
                  onPressed: () {
                    NexaHaptics.tick();
                    setState(() => _preview = !_preview);
                  },
                ),
                IconButton(
                  icon: Icon(note?.pinned == true
                      ? LucideIcons.pinOff
                      : LucideIcons.pin),
                  tooltip: note?.pinned == true ? 'Unpin' : 'Pin',
                  onPressed: () {
                    NexaHaptics.tick();
                    ref
                        .read(appStoreProvider.notifier)
                        .togglePinNote(widget.noteId);
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.moreVertical, size: 20),
                  onSelected: (val) {
                    if (val == 'share') {
                      _shareNote();
                    } else if (val == 'duplicate') {
                      _duplicateNote();
                    } else if (val == 'delete') {
                      _confirmDelete();
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(LucideIcons.share2, size: 16),
                          SizedBox(width: 8),
                          Text('Share as Markdown'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(LucideIcons.copy, size: 16),
                          SizedBox(width: 8),
                          Text('Duplicate Note'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(LucideIcons.trash2,
                              size: 16, color: NexaColors.danger),
                          SizedBox(width: 8),
                          Text('Delete Note',
                              style: TextStyle(color: NexaColors.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            children: [
              if (_zenMode) ...[
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(LucideIcons.minimize2, size: 18),
                    tooltip: 'Exit Zen Mode',
                    onPressed: () => setState(() => _zenMode = false),
                  ),
                ),
              ],

              // Title input
              TextField(
                controller: _title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: 'Note Title',
                ),
              ),

              // Folder selector + color pickers
              if (!_zenMode) ...[
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _folderId,
                        isDense: true,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: folders
                            .map((f) => DropdownMenuItem(
                                value: f.id, child: Text(f.name)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _folderId = v);
                            _persist();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Color dots
                    ...['blue', 'purple', 'green', 'orange', 'pink', 'teal'].map((c) {
                      final active = _color == c;
                      return GestureDetector(
                        onTap: () {
                          NexaHaptics.tick();
                          setState(() => _color = active ? null : c);
                          _persist();
                        },
                        child: Container(
                          width: 22,
                          height: 22,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: NexaColors.noteColor(c),
                            shape: BoxShape.circle,
                            border: active
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Checklist Progress Bar (if checklists exist)
              if (totalCheckItems > 0 && !_zenMode) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: NexaColors.lightPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: NexaColors.lightPrimary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.checkSquare,
                          size: 16, color: NexaColors.lightPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Checklist: $doneCheckItems of $totalCheckItems done (${(checkProgress * 100).round()}%)',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: checkProgress,
                                minHeight: 4,
                                backgroundColor:
                                    NexaColors.lightPrimary.withOpacity(0.15),
                                valueColor: AlwaysStoppedAnimation(
                                  checkProgress >= 1.0
                                      ? NexaColors.success
                                      : NexaColors.lightPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Formatting Toolbar
              if (!_preview && !_zenMode)
                Container(
                  height: 40,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _toolBtn(LucideIcons.bold, 'Bold', () => _insertFormatting('**', '**')),
                      _toolBtn(LucideIcons.italic, 'Italic', () => _insertFormatting('*', '*')),
                      _toolBtn(LucideIcons.heading1, 'H1', () => _insertFormatting('# ')),
                      _toolBtn(LucideIcons.heading2, 'H2', () => _insertFormatting('## ')),
                      _toolBtn(LucideIcons.checkSquare, 'Checklist', () => _insertFormatting('- [ ] ')),
                      _toolBtn(LucideIcons.list, 'Bullet list', () => _insertFormatting('- ')),
                      _toolBtn(LucideIcons.quote, 'Quote', () => _insertFormatting('> ')),
                      _toolBtn(LucideIcons.strikethrough, 'Strike', () => _insertFormatting('~~', '~~')),
                      _toolBtn(LucideIcons.code, 'Code', () => _insertFormatting('`', '`')),
                      _toolBtn(LucideIcons.link, 'Link', () => _insertFormatting('[title](url)')),
                      _toolBtn(LucideIcons.minus, 'Rule', () => _insertFormatting('\n---\n')),
                    ],
                  ),
                ),

              // Editor / Preview
              Expanded(
                child: _preview
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: dark
                              ? NexaColors.darkSurface1
                              : NexaColors.lightSurface1,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: dark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.black.withOpacity(0.08),
                          ),
                        ),
                        child: Markdown(
                          data: _body.text.isEmpty
                              ? '*Empty note. Write some markdown!*'
                              : _body.text,
                        ),
                      )
                    : TextField(
                        controller: _body,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                        decoration: const InputDecoration(
                          hintText: 'Start writing markdown…',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
              ),

              // Word count & Reading time footer
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                alignment: Alignment.centerRight,
                child: Text(
                  '$words words · ~$readTimeMinutes min read',
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondaryColor(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        icon: Icon(icon, size: 16),
        tooltip: tooltip,
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    NexaHaptics.warning();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This note will be permanently removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: NexaColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      ref.read(appStoreProvider.notifier).deleteNote(widget.noteId);
      Navigator.of(context).pop();
    }
  }
}
