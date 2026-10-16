import { refreshIcons } from '../utils.js';

let overlayEl, sheetEl, modalEl;

export function initUI() {
  overlayEl = document.getElementById('overlay');
  sheetEl = document.getElementById('bottom-sheet');
  modalEl = document.getElementById('modal');

  overlayEl.addEventListener('click', closeAll);
}

export function closeAll() {
  overlayEl.hidden = true;
  overlayEl.classList.remove('visible');
  sheetEl.hidden = true;
  sheetEl.classList.remove('visible');
  modalEl.hidden = true;
  modalEl.classList.remove('visible');
  document.querySelector('.quick-menu')?.remove();
}

export function openBottomSheet(title, bodyHtml, onSubmit) {
  sheetEl.innerHTML = `
    <div class="bottom-sheet__handle"></div>
    <div class="bottom-sheet__header">
      <h2 class="bottom-sheet__title">${title}</h2>
      <button class="icon-btn" id="sheet-close" aria-label="Close"><i data-lucide="x"></i></button>
    </div>
    <div class="bottom-sheet__body">${bodyHtml}</div>
  `;
  overlayEl.hidden = false;
  sheetEl.hidden = false;
  requestAnimationFrame(() => {
    overlayEl.classList.add('visible');
    sheetEl.classList.add('visible');
  });
  refreshIcons();

  document.getElementById('sheet-close')?.addEventListener('click', closeAll);

  const form = sheetEl.querySelector('form');
  if (form && onSubmit) {
    form.addEventListener('submit', e => {
      e.preventDefault();
      const fd = new FormData(form);
      const data = Object.fromEntries(fd.entries());
      onSubmit(data, form);
    });
  }
}

export function openModal(title, bodyHtml) {
  modalEl.innerHTML = `
    <div class="modal__header">
      <h2 class="modal__title">${title}</h2>
      <button class="icon-btn" id="modal-close" aria-label="Close"><i data-lucide="x"></i></button>
    </div>
    <div class="modal__body">${bodyHtml}</div>
  `;
  overlayEl.hidden = false;
  modalEl.hidden = false;
  requestAnimationFrame(() => {
    overlayEl.classList.add('visible');
    modalEl.classList.add('visible');
  });
  refreshIcons();
  document.getElementById('modal-close')?.addEventListener('click', closeAll);
}

export function showQuickMenu(items, onSelect) {
  document.querySelector('.quick-menu')?.remove();
  const menu = document.createElement('div');
  menu.className = 'quick-menu';
  menu.innerHTML = items.map(item =>
    `<button class="quick-menu__item" data-action="${item.action}">
      <i data-lucide="${item.icon}"></i>${item.label}
    </button>`
  ).join('');
  document.body.appendChild(menu);
  refreshIcons();
  menu.querySelectorAll('.quick-menu__item').forEach(btn => {
    btn.addEventListener('click', () => {
      menu.remove();
      onSelect(btn.dataset.action);
    });
  });
}

export function emptyState(icon, title, text, btnLabel, onClick) {
  return `
    <div class="empty-state">
      <div class="empty-state__icon"><i data-lucide="${icon}"></i></div>
      <div class="empty-state__title">${title}</div>
      <div class="empty-state__text">${text}</div>
      ${btnLabel ? `<button class="btn btn--primary" id="empty-action">${btnLabel}</button>` : ''}
    </div>
  `;
}

export function bindEmptyAction(onClick) {
  document.getElementById('empty-action')?.addEventListener('click', onClick);
}
