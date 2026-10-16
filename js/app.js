import { getState, subscribe, updateUser, globalSearch, exportData, clearAllData, loadSampleData } from './store.js';
import { escapeHtml, refreshIcons } from './utils.js';
import { initUI, closeAll, showQuickMenu, openModal } from './components/ui.js';
import { renderHome } from './pages/home.js';
import { renderTasks, showAddTask } from './pages/tasks.js';
import { renderNotes, showAddNote } from './pages/notes.js';
import { renderExpenses, showAddExpense } from './pages/expenses.js';
import { renderResources, showAddResource } from './pages/resources.js';

const TITLES = { home: 'Home', tasks: 'Tasks', notes: 'Notes', expenses: 'Expenses', resources: 'Resources' };
let currentTab = 'home';

function getResolvedTheme(theme) {
  return theme === 'auto'
    ? (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
    : theme;
}

function applyTheme(theme) {
  const resolved = getResolvedTheme(theme);
  document.documentElement.dataset.theme = resolved;
  document.body.dataset.theme = resolved;

  const themeBtn = document.getElementById('btn-theme');
  if (themeBtn) {
    const icon = themeBtn.querySelector('i');
    if (icon) {
      icon.setAttribute('data-lucide', resolved === 'dark' ? 'moon' : 'sun');
      if (window.lucide) lucide.createIcons();
    }
  }
}

function toggleTheme() {
  const currentTheme = getState().user.theme;
  const resolved = getResolvedTheme(currentTheme);
  const nextTheme = resolved === 'dark' ? 'light' : 'dark';
  updateUser({ theme: nextTheme });
  applyTheme(nextTheme);
}

function navigate(tab) {
  currentTab = tab;
  document.getElementById('page-title').textContent = TITLES[tab] || 'Nexa';
  document.querySelectorAll('.bottom-nav__item').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.tab === tab);
  });
  renderCurrentPage();
}

function renderCurrentPage() {
  const container = document.getElementById('main-content');
  switch (currentTab) {
    case 'home': renderHome(container); break;
    case 'tasks': renderTasks(container); break;
    case 'notes': renderNotes(container); break;
    case 'expenses': renderExpenses(container); break;
    case 'resources': renderResources(container); break;
  }
  refreshIcons();
}

function handleFabClick() {
  if (currentTab === 'home') {
    showQuickMenu([
      { action: 'task', icon: 'check-square', label: 'Add Task' },
      { action: 'note', icon: 'file-text', label: 'Add Note' },
      { action: 'expense', icon: 'wallet', label: 'Add Expense' },
      { action: 'resource', icon: 'folder-lock', label: 'Add Resource' },
    ], action => {
      closeAll();
      switch (action) {
        case 'task': showAddTask(); break;
        case 'note': showAddNote(); break;
        case 'expense': showAddExpense(); break;
        case 'resource': showAddResource(); break;
      }
    });
  } else {
    switch (currentTab) {
      case 'tasks': showAddTask(); break;
      case 'notes': showAddNote(); break;
      case 'expenses': showAddExpense(); break;
      case 'resources': showAddResource(); break;
    }
  }
}

function openSearch() {
  const panel = document.getElementById('search-panel');
  panel.hidden = false;
  panel.innerHTML = `
    <div class="search-panel__header">
      <input class="search-panel__input" id="global-search-input" placeholder="Search tasks, notes, expenses, resources..." autofocus />
      <button class="icon-btn" id="close-search" aria-label="Close"><i data-lucide="x"></i></button>
    </div>
    <div class="search-panel__results" id="search-results">
      <p style="color:var(--text-secondary);text-align:center;padding:32px">Start typing to search...</p>
    </div>
  `;
  requestAnimationFrame(() => panel.classList.add('visible'));
  refreshIcons();

  document.getElementById('close-search').addEventListener('click', closeSearch);
  document.getElementById('global-search-input').addEventListener('input', e => {
    renderSearchResults(e.target.value);
  });
}

function handleGlobalShortcuts(e) {
  // Ignore when typing in inputs or textareas
  const tag = e.target?.tagName?.toLowerCase();
  if (tag === 'input' || tag === 'textarea' || e.target?.isContentEditable) return;

  if (e.key === '/') {
    e.preventDefault();
    openSearch();
    setTimeout(() => document.getElementById('global-search-input')?.focus(), 60);
    return;
  }

  if (e.key === 't') { // add task
    e.preventDefault();
    navigate('tasks');
    setTimeout(() => showAddTask(), 60);
    return;
  }

  if (e.key === 'n') { // add note
    e.preventDefault();
    navigate('notes');
    setTimeout(() => showAddNote(), 60);
    return;
  }

  if (e.key === 'e') { // add expense
    e.preventDefault();
    navigate('expenses');
    setTimeout(() => showAddExpense(), 60);
    return;
  }

  if (e.key === 'r') { // add resource
    e.preventDefault();
    navigate('resources');
    setTimeout(() => showAddResource(), 60);
    return;
  }
}

function closeSearch() {
  const panel = document.getElementById('search-panel');
  panel.classList.remove('visible');
  setTimeout(() => { panel.hidden = true; }, 250);
}

function renderSearchResults(query) {
  const el = document.getElementById('search-results');
  if (!query.trim()) {
    el.innerHTML = '<p style="color:var(--text-secondary);text-align:center;padding:32px">Start typing to search...</p>';
    return;
  }

  const results = globalSearch(query);
  const total = results.tasks.length + results.notes.length + results.expenses.length + results.resources.length;

  if (total === 0) {
    el.innerHTML = '<p style="color:var(--text-secondary);text-align:center;padding:32px">No results found</p>';
    return;
  }

  let html = '';
  const addGroup = (type, items, icon, labelFn) => {
    if (!items.length) return;
    html += `<div class="section"><div class="section__title">${type}</div>`;
    items.forEach(item => {
      html += `
        <div class="search-result" data-type="${type.toLowerCase()}" data-id="${item.id}">
          <div class="search-result__icon search-result__icon--${type.toLowerCase().slice(0, -1)}"><i data-lucide="${icon}"></i></div>
          <div>
            <div class="search-result__type">${type.slice(0, -1)}</div>
            <div>${escapeHtml(labelFn(item))}</div>
          </div>
        </div>
      `;
    });
    html += '</div>';
  };

  addGroup('Tasks', results.tasks, 'check-square', t => t.title);
  addGroup('Notes', results.notes, 'file-text', n => n.title);
  addGroup('Expenses', results.expenses, 'wallet', e => `${e.note || e.category} — $${e.amount}`);
  addGroup('Resources', results.resources, 'folder-lock', r => r.name);

  el.innerHTML = html;
  refreshIcons();

  el.querySelectorAll('.search-result').forEach(result => {
    result.addEventListener('click', () => {
      closeSearch();
      const typeMap = { task: 'tasks', note: 'notes', expense: 'expenses', resource: 'resources' };
      const tab = typeMap[result.dataset.type];
      if (tab) navigate(tab);
    });
  });
}

function openSettings() {
  const user = getState().user;
  openModal('Settings', `
    <div class="settings-group">
      <div class="settings-group__title">Appearance</div>
      <div class="settings-item">
        <span class="settings-item__label">Theme</span>
        <select class="form-select" id="theme-select" style="width:auto">
          <option value="auto" ${user.theme === 'auto' ? 'selected' : ''}>System</option>
          <option value="light" ${user.theme === 'light' ? 'selected' : ''}>Light</option>
          <option value="dark" ${user.theme === 'dark' ? 'selected' : ''}>Dark</option>
        </select>
      </div>
    </div>
    <div class="settings-group">
      <div class="settings-group__title">Preferences</div>
      <div class="settings-item">
        <span class="settings-item__label">Currency</span>
        <select class="form-select" id="currency-select" style="width:auto">
          ${['USD', 'EUR', 'GBP', 'INR', 'PKR', 'CAD', 'AUD'].map(c =>
            `<option value="${c}" ${user.currency === c ? 'selected' : ''}>${c}</option>`
          ).join('')}
        </select>
      </div>
    </div>
    <div class="settings-group">
      <div class="settings-group__title">Data</div>
      <div class="settings-item" id="load-sample" style="cursor:pointer">
        <span class="settings-item__label">Load sample data</span>
        <i data-lucide="database" style="width:18px;height:18px;color:var(--text-secondary)"></i>
      </div>
      <div class="settings-item" id="export-data" style="cursor:pointer">
        <span class="settings-item__label">Export all data (JSON)</span>
        <i data-lucide="download" style="width:18px;height:18px;color:var(--text-secondary)"></i>
      </div>
      <div class="settings-item" id="clear-data" style="cursor:pointer">
        <span class="settings-item__label" style="color:var(--danger)">Clear all data</span>
        <i data-lucide="trash-2" style="width:18px;height:18px;color:var(--danger)"></i>
      </div>
    </div>
    <p style="text-align:center;color:var(--text-secondary);font-size:0.75rem;margin-top:16px">Nexa v1.0 · Offline-first productivity</p>
  `);
  refreshIcons();

  document.getElementById('theme-select')?.addEventListener('change', e => {
    updateUser({ theme: e.target.value });
    applyTheme(e.target.value);
  });

  document.getElementById('currency-select')?.addEventListener('change', e => {
    updateUser({ currency: e.target.value });
    renderCurrentPage();
  });

  document.getElementById('load-sample')?.addEventListener('click', () => {
    loadSampleData();
    document.getElementById('modal-close')?.click();
    renderCurrentPage();
  });

  document.getElementById('export-data')?.addEventListener('click', () => {
    const blob = new Blob([exportData()], { type: 'application/json' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `nexa-export-${new Date().toISOString().slice(0, 10)}.json`;
    a.click();
  });

  document.getElementById('clear-data')?.addEventListener('click', () => {
    if (confirm('Delete all data? This cannot be undone.')) {
      clearAllData();
      document.getElementById('modal-close')?.click();
      renderCurrentPage();
    }
  });
}

function showOnboarding() {
  const el = document.getElementById('onboarding');
  el.hidden = false;
  el.classList.add('visible');
  el.innerHTML = `
    <div class="onboarding__logo"><i data-lucide="sparkles"></i></div>
    <h1 class="onboarding__title">Welcome to Nexa</h1>
    <p class="onboarding__subtitle">Your all-in-one productivity hub — tasks, notes, expenses, and resources in one beautiful app.</p>
    <div class="onboarding__features">
      <div class="onboarding__feature"><i data-lucide="check-square"></i> Manage tasks with smart quick-add</div>
      <div class="onboarding__feature"><i data-lucide="file-text"></i> Capture notes with templates</div>
      <div class="onboarding__feature"><i data-lucide="wallet"></i> Track expenses & budgets</div>
      <div class="onboarding__feature"><i data-lucide="folder-lock"></i> Organize resources & subscriptions</div>
    </div>
    <button class="btn btn--primary btn--block" id="finish-onboarding" style="max-width:320px">Get Started</button>
    <button class="btn btn--ghost btn--block" id="onboard-sample" style="max-width:320px;margin-top:8px">Load sample data</button>
  `;
  refreshIcons();

  document.getElementById('finish-onboarding').addEventListener('click', () => {
    updateUser({ onboarded: true });
    el.classList.remove('visible');
    el.hidden = true;
    renderCurrentPage();
  });

  document.getElementById('onboard-sample').addEventListener('click', () => {
    loadSampleData();
    updateUser({ onboarded: true });
    el.classList.remove('visible');
    el.hidden = true;
    renderCurrentPage();
  });
}

function setAppStatus(message, isError = false) {
  const status = document.getElementById('app-status');
  if (!status) return;
  status.textContent = message;
  status.classList.toggle('app-status--error', isError);
  status.hidden = !message;
}

function hideAppStatus() {
  setAppStatus('', false);
}

function init() {
  try {
    initUI();
    applyTheme(getState().user.theme);

    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
      if (getState().user.theme === 'auto') applyTheme('auto');
    });

    document.querySelectorAll('.bottom-nav__item').forEach(btn => {
      btn.addEventListener('click', () => navigate(btn.dataset.tab));
    });

    document.getElementById('fab')?.addEventListener('click', handleFabClick);
    document.getElementById('btn-theme')?.addEventListener('click', toggleTheme);
    document.getElementById('btn-search')?.addEventListener('click', openSearch);
    document.getElementById('btn-settings')?.addEventListener('click', openSettings);

    document.addEventListener('keydown', handleGlobalShortcuts);

    document.getElementById('main-content')?.addEventListener('refresh', renderCurrentPage);

    subscribe(() => {});

    if (!getState().user.onboarded) showOnboarding();
    else renderCurrentPage();

    refreshIcons();
    hideAppStatus();
  } catch (error) {
    console.error('Nexa startup failed', error);
    const main = document.getElementById('main-content');
    if (main) {
      main.innerHTML = `
        <div class="empty-state">
          <div class="empty-state__icon">⚠️</div>
          <div class="empty-state__title">Unable to load the app</div>
          <div class="empty-state__text">Please refresh the page or clear your browser cache and try again.</div>
        </div>
      `;
    }
    setAppStatus('Unable to load the app. Please refresh the page.', true);
  }
}

window.addEventListener('error', event => {
  const message = event.error?.message || event.message;
  if (message && !message.includes('ResizeObserver loop')) {
    setAppStatus(`Something went wrong: ${message}`, true);
  }
});

window.addEventListener('unhandledrejection', event => {
  const message = event.reason?.message || String(event.reason || 'Unknown error');
  if (message) {
    setAppStatus(`Something went wrong: ${message}`, true);
  }
});

document.addEventListener('DOMContentLoaded', init);
