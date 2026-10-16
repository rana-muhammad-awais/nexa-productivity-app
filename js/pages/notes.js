import { getState, addNote, updateNote, deleteNote, togglePinNote, NOTE_TEMPLATES } from '../store.js';
import { escapeHtml, stripMarkdown, renderMarkdown, refreshIcons } from '../utils.js';
import { openBottomSheet, openModal, emptyState, bindEmptyAction } from '../components/ui.js';

let currentFolder = 'all';
let searchQuery = '';

export function renderNotes(container) {
  const state = getState();
  let notes = [...state.notes];

  if (currentFolder !== 'all') notes = notes.filter(n => n.folderId === currentFolder);
  if (searchQuery) {
    const q = searchQuery.toLowerCase();
    notes = notes.filter(n => n.title.toLowerCase().includes(q) || n.body.toLowerCase().includes(q));
  }

  notes.sort((a, b) => {
    if (a.pinned !== b.pinned) return a.pinned ? -1 : 1;
    return new Date(b.updatedAt) - new Date(a.updatedAt);
  });

  container.innerHTML = `
    <div class="form-group" style="margin-bottom:12px">
      <input class="form-input" id="note-search" placeholder="Search notes..." value="${escapeHtml(searchQuery)}" />
    </div>
    <div class="folder-chips">
      <button class="folder-chip ${currentFolder === 'all' ? 'active' : ''}" data-folder="all">All</button>
      ${state.noteFolders.map(f => `
        <button class="folder-chip ${currentFolder === f.id ? 'active' : ''}" data-folder="${f.id}">${escapeHtml(f.name)}</button>
      `).join('')}
    </div>
    <div id="notes-list"></div>
  `;

  container.querySelector('#note-search')?.addEventListener('input', e => {
    searchQuery = e.target.value;
    renderNotes(container);
  });

  container.querySelectorAll('.folder-chip').forEach(chip => {
    chip.addEventListener('click', () => {
      currentFolder = chip.dataset.folder;
      renderNotes(container);
    });
  });

  const listEl = container.querySelector('#notes-list');
  if (notes.length === 0) {
    listEl.innerHTML = emptyState('file-text', 'No notes yet', 'Capture ideas, meeting notes, or journal entries.', 'Add Note', () => showAddNote());
    bindEmptyAction(() => showAddNote());
    return;
  }

  listEl.innerHTML = notes.map(note => `
    <div class="note-item ${note.pinned ? 'pinned' : ''}" data-id="${note.id}" tabindex="0">
      <div class="note-item__title">${note.pinned ? '📌 ' : ''}${escapeHtml(note.title)}</div>
      <div class="note-item__preview">${escapeHtml(stripMarkdown(note.body).slice(0, 100))}</div>
      <div class="note-item__meta">
        <span>${new Date(note.updatedAt).toLocaleDateString()}</span>
        ${note.tags.map(t => `<span class="tag">#${escapeHtml(t)}</span>`).join('')}
      </div>
    </div>
  `).join('');

  listEl.querySelectorAll('.note-item').forEach(item => {
    item.addEventListener('click', () => showNoteEditor(item.dataset.id));
    item.addEventListener('keydown', e => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        showNoteEditor(item.dataset.id);
      }
    });
  });
}

function showNoteEditor(id) {
  const note = getState().notes.find(n => n.id === id);
  if (!note) return;

  openModal(note.title, `
    <div style="margin-bottom:12px;display:flex;gap:8px">
      <button class="btn btn--sm btn--ghost" id="pin-note">${note.pinned ? 'Unpin' : 'Pin'}</button>
      <button class="btn btn--sm btn--danger" id="delete-note">Delete</button>
    </div>
    <div class="form-group">
      <label class="form-label">Title</label>
      <input class="form-input" id="edit-note-title" value="${escapeHtml(note.title)}" />
    </div>
    <div class="form-group">
      <label class="form-label">Body (Markdown supported)</label>
      <textarea class="form-textarea" id="edit-note-body" style="min-height:200px;font-family:monospace">${escapeHtml(note.body)}</textarea>
    </div>
    <div class="form-group">
      <label class="form-label">Folder</label>
      <select class="form-select" id="edit-note-folder">
        ${getState().noteFolders.map(f => `<option value="${f.id}" ${note.folderId === f.id ? 'selected' : ''}>${escapeHtml(f.name)}</option>`).join('')}
      </select>
    </div>
    <div id="note-preview" style="margin-bottom:16px;padding:12px;background:var(--bg);border-radius:var(--radius-md);font-size:0.875rem"></div>
    <button class="btn btn--primary btn--block" id="save-note">Save</button>
  `);

  const preview = document.getElementById('note-preview');
  const bodyEl = document.getElementById('edit-note-body');
  const updatePreview = () => { preview.innerHTML = renderMarkdown(bodyEl.value); };
  bodyEl.addEventListener('input', updatePreview);
  updatePreview();

  document.getElementById('pin-note')?.addEventListener('click', () => {
    togglePinNote(id);
    document.getElementById('modal-close')?.click();
    document.getElementById('main-content').dispatchEvent(new Event('refresh'));
  });

  document.getElementById('delete-note')?.addEventListener('click', () => {
    deleteNote(id);
    document.getElementById('modal-close')?.click();
    document.getElementById('main-content').dispatchEvent(new Event('refresh'));
  });

  document.getElementById('save-note')?.addEventListener('click', () => {
    updateNote(id, {
      title: document.getElementById('edit-note-title').value,
      body: bodyEl.value,
      folderId: document.getElementById('edit-note-folder').value,
    });
    document.getElementById('modal-close')?.click();
    document.getElementById('main-content').dispatchEvent(new Event('refresh'));
  });
}

export function showAddNote(templateKey) {
  const tmpl = templateKey ? NOTE_TEMPLATES[templateKey] : null;
  openBottomSheet('Add Note', `
    <form id="add-note-form">
      ${!templateKey ? `
        <div class="form-group">
          <label class="form-label">Template</label>
          <select class="form-select" name="template" id="note-template-select">
            <option value="">Blank note</option>
            <option value="meeting">Meeting Notes</option>
            <option value="journal">Journal Entry</option>
            <option value="recipe">Recipe</option>
          </select>
        </div>
      ` : ''}
      <div class="form-group">
        <label class="form-label">Title</label>
        <input class="form-input" name="title" value="${tmpl ? escapeHtml(tmpl.title) : ''}" placeholder="Note title" required />
      </div>
      <div class="form-group">
        <label class="form-label">Body</label>
        <textarea class="form-textarea" name="body" placeholder="Start writing...">${tmpl ? escapeHtml(tmpl.body) : ''}</textarea>
      </div>
      <div class="form-group">
        <label class="form-label">Folder</label>
        <select class="form-select" name="folderId">
          ${getState().noteFolders.map(f => `<option value="${f.id}">${escapeHtml(f.name)}</option>`).join('')}
        </select>
      </div>
      <button type="submit" class="btn btn--primary btn--block">Create Note</button>
    </form>
  `, (data) => {
    addNote(data);
    document.getElementById('overlay').click();
    document.getElementById('main-content').dispatchEvent(new Event('refresh'));
  });

  setTimeout(() => {
    document.getElementById('note-template-select')?.addEventListener('change', e => {
      const t = NOTE_TEMPLATES[e.target.value];
      if (t) {
        document.querySelector('[name="title"]').value = t.title;
        document.querySelector('[name="body"]').value = t.body;
      }
    });
  }, 50);
}
