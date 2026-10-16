const STORAGE_KEY = 'nexa-data-v1';

const DEFAULT_STATE = {
  user: {
    name: 'User',
    theme: 'auto',
    currency: 'USD',
    onboarded: false,
    streak: 0,
    lastCompletionDate: null,
  },
  tasks: [],
  notes: [],
  noteFolders: [
    { id: 'inbox', name: 'Inbox', icon: 'inbox' },
    { id: 'work', name: 'Work', icon: 'briefcase' },
    { id: 'personal', name: 'Personal', icon: 'user' },
  ],
  expenses: [],
  accounts: [
    { id: 'cash', name: 'Cash', type: 'cash' },
    { id: 'bank', name: 'Bank', type: 'bank' },
    { id: 'credit', name: 'Credit Card', type: 'credit' },
  ],
  budgets: [],
  resources: [],
  reminders: [],
};

let state = loadState();
const listeners = new Set();

function loadState() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      return { ...DEFAULT_STATE, ...parsed, user: { ...DEFAULT_STATE.user, ...parsed.user } };
    }
  } catch (e) {
    console.warn('Failed to load state', e);
  }
  return structuredClone(DEFAULT_STATE);
}

function persist() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  listeners.forEach(fn => fn(state));
}

export function subscribe(fn) {
  listeners.add(fn);
  return () => listeners.delete(fn);
}

export function getState() {
  return state;
}

export function updateUser(updates) {
  state.user = { ...state.user, ...updates };
  persist();
}

function uid() {
  return crypto.randomUUID();
}

// ─── Tasks ───

export function addTask(data) {
  const task = {
    id: uid(),
    title: data.title,
    description: data.description || '',
    dueDate: data.dueDate || null,
    dueTime: data.dueTime || null,
    priority: data.priority || 'medium',
    tags: data.tags || [],
    listId: data.listId || 'inbox',
    isCompleted: false,
    subtasks: data.subtasks || [],
    recurrence: data.recurrence || null,
    linkedNoteId: data.linkedNoteId || null,
    order: state.tasks.length,
    createdAt: new Date().toISOString(),
  };
  state.tasks.push(task);
  persist();
  return task;
}

export function updateTask(id, updates) {
  const idx = state.tasks.findIndex(t => t.id === id);
  if (idx === -1) return null;
  state.tasks[idx] = { ...state.tasks[idx], ...updates };
  persist();
  return state.tasks[idx];
}

export function toggleTask(id) {
  const task = state.tasks.find(t => t.id === id);
  if (!task) return;
  task.isCompleted = !task.isCompleted;
  if (task.isCompleted) updateStreak();
  persist();
}

export function deleteTask(id) {
  state.tasks = state.tasks.filter(t => t.id !== id);
  persist();
}

export function reorderTasks(orderedIds) {
  orderedIds.forEach((id, i) => {
    const t = state.tasks.find(x => x.id === id);
    if (t) t.order = i;
  });
  persist();
}

function updateStreak() {
  const today = new Date().toISOString().slice(0, 10);
  const yesterday = new Date(Date.now() - 86400000).toISOString().slice(0, 10);
  if (state.user.lastCompletionDate === today) return;
  if (state.user.lastCompletionDate === yesterday) {
    state.user.streak = (state.user.streak || 0) + 1;
  } else {
    state.user.streak = 1;
  }
  state.user.lastCompletionDate = today;
}

// ─── Notes ───

export function addNote(data) {
  const note = {
    id: uid(),
    title: data.title || 'Untitled',
    body: data.body || '',
    folderId: data.folderId || 'inbox',
    tags: data.tags || [],
    pinned: data.pinned || false,
    attachments: data.attachments || [],
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  state.notes.unshift(note);
  persist();
  return note;
}

export function updateNote(id, updates) {
  const idx = state.notes.findIndex(n => n.id === id);
  if (idx === -1) return null;
  state.notes[idx] = { ...state.notes[idx], ...updates, updatedAt: new Date().toISOString() };
  persist();
  return state.notes[idx];
}

export function deleteNote(id) {
  state.notes = state.notes.filter(n => n.id !== id);
  persist();
}

export function togglePinNote(id) {
  const note = state.notes.find(n => n.id === id);
  if (note) { note.pinned = !note.pinned; persist(); }
}

// ─── Expenses ───

export function addExpense(data) {
  const expense = {
    id: uid(),
    amount: parseFloat(data.amount) || 0,
    type: data.type || 'expense',
    category: data.category || 'other',
    accountId: data.accountId || 'cash',
    note: data.note || '',
    date: data.date || new Date().toISOString().slice(0, 10),
    receiptImage: data.receiptImage || null,
    isRecurring: data.isRecurring || false,
    linkedTaskId: data.linkedTaskId || null,
    createdAt: new Date().toISOString(),
  };
  state.expenses.unshift(expense);
  persist();
  return expense;
}

export function deleteExpense(id) {
  state.expenses = state.expenses.filter(e => e.id !== id);
  persist();
}

export function setBudget(category, limit, monthYear) {
  const existing = state.budgets.findIndex(b => b.category === category && b.monthYear === monthYear);
  const budget = { id: uid(), category, monthlyLimit: parseFloat(limit), monthYear };
  if (existing >= 0) state.budgets[existing] = budget;
  else state.budgets.push(budget);
  persist();
}

// ─── Resources ───

export function addResource(data) {
  const resource = {
    id: uid(),
    type: data.type || 'document',
    name: data.name,
    details: data.details || {},
    fileUrl: data.fileUrl || null,
    renewalDate: data.renewalDate || null,
    tags: data.tags || [],
    quantity: data.quantity ?? null,
    lowStockThreshold: data.lowStockThreshold ?? 5,
    createdAt: new Date().toISOString(),
  };
  state.resources.unshift(resource);
  persist();
  return resource;
}

export function updateResource(id, updates) {
  const idx = state.resources.findIndex(r => r.id === id);
  if (idx === -1) return null;
  state.resources[idx] = { ...state.resources[idx], ...updates };
  persist();
  return state.resources[idx];
}

export function deleteResource(id) {
  state.resources = state.resources.filter(r => r.id !== id);
  persist();
}

// ─── Search ───

export function globalSearch(query) {
  const q = query.toLowerCase().trim();
  if (!q) return { tasks: [], notes: [], expenses: [], resources: [] };

  return {
    tasks: state.tasks.filter(t =>
      t.title.toLowerCase().includes(q) ||
      t.description?.toLowerCase().includes(q) ||
      t.tags?.some(tag => tag.toLowerCase().includes(q))
    ),
    notes: state.notes.filter(n =>
      n.title.toLowerCase().includes(q) ||
      n.body.toLowerCase().includes(q) ||
      n.tags?.some(tag => tag.toLowerCase().includes(q))
    ),
    expenses: state.expenses.filter(e =>
      e.note?.toLowerCase().includes(q) ||
      e.category.toLowerCase().includes(q)
    ),
    resources: state.resources.filter(r =>
      r.name.toLowerCase().includes(q) ||
      r.tags?.some(tag => tag.toLowerCase().includes(q))
    ),
  };
}

// ─── Export / Sample ───

export function exportData() {
  return JSON.stringify(state, null, 2);
}

export function clearAllData() {
  state = structuredClone(DEFAULT_STATE);
  persist();
}

export function loadSampleData() {
  const today = new Date();
  const fmt = d => d.toISOString().slice(0, 10);
  const tomorrow = new Date(today); tomorrow.setDate(tomorrow.getDate() + 1);
  const nextWeek = new Date(today); nextWeek.setDate(nextWeek.getDate() + 7);

  state.tasks = [
    { id: uid(), title: 'Team standup meeting', description: 'Daily sync with the team', dueDate: fmt(today), dueTime: '10:00', priority: 'high', tags: ['work'], listId: 'work', isCompleted: false, subtasks: [], recurrence: null, linkedNoteId: null, order: 0, createdAt: new Date().toISOString() },
    { id: uid(), title: 'Pay electricity bill', description: '', dueDate: fmt(tomorrow), dueTime: '18:00', priority: 'urgent', tags: ['bills'], listId: 'inbox', isCompleted: false, subtasks: [], recurrence: 'monthly', linkedNoteId: null, order: 1, createdAt: new Date().toISOString() },
    { id: uid(), title: 'Buy groceries', description: 'Milk, eggs, bread, vegetables', dueDate: fmt(today), dueTime: null, priority: 'medium', tags: ['shopping'], listId: 'inbox', isCompleted: false, subtasks: [{ id: uid(), title: 'Milk', done: false }, { id: uid(), title: 'Eggs', done: true }], recurrence: null, linkedNoteId: null, order: 2, createdAt: new Date().toISOString() },
    { id: uid(), title: 'Review project proposal', description: '', dueDate: fmt(nextWeek), dueTime: null, priority: 'low', tags: ['work'], listId: 'work', isCompleted: true, subtasks: [], recurrence: null, linkedNoteId: null, order: 3, createdAt: new Date().toISOString() },
  ];

  state.notes = [
    { id: uid(), title: 'Meeting Notes — Q3 Planning', body: '# Q3 Planning\n\n## Goals\n- Launch MVP by August\n- Hire 2 engineers\n\n## Action Items\n- [ ] Draft roadmap\n- [x] Schedule interviews', folderId: 'work', tags: ['meetings'], pinned: true, attachments: [], createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() },
    { id: uid(), title: 'Recipe: Pasta Carbonara', body: '## Ingredients\n- 400g spaghetti\n- 200g guanciale\n- 4 egg yolks\n- Pecorino Romano\n\n## Steps\n1. Boil pasta\n2. Crisp guanciale\n3. Mix eggs with cheese\n4. Combine off heat', folderId: 'personal', tags: ['recipe'], pinned: false, attachments: [], createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() },
    { id: uid(), title: 'Journal — Today', body: 'Feeling productive today. Finished the project review and started planning next week.', folderId: 'personal', tags: ['journal'], pinned: false, attachments: [], createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() },
  ];

  state.expenses = [
    { id: uid(), amount: 45.50, type: 'expense', category: 'food', accountId: 'credit', note: 'Lunch at cafe', date: fmt(today), receiptImage: null, isRecurring: false, linkedTaskId: null, createdAt: new Date().toISOString() },
    { id: uid(), amount: 12.00, type: 'expense', category: 'transport', accountId: 'cash', note: 'Uber ride', date: fmt(today), receiptImage: null, isRecurring: false, linkedTaskId: null, createdAt: new Date().toISOString() },
    { id: uid(), amount: 3500, type: 'income', category: 'other', accountId: 'bank', note: 'Freelance payment', date: fmt(new Date(today.getFullYear(), today.getMonth(), 1)), receiptImage: null, isRecurring: false, linkedTaskId: null, createdAt: new Date().toISOString() },
    { id: uid(), amount: 15.99, type: 'expense', category: 'bills', accountId: 'credit', note: 'Netflix subscription', date: fmt(new Date(today.getFullYear(), today.getMonth(), 5)), receiptImage: null, isRecurring: true, linkedTaskId: null, createdAt: new Date().toISOString() },
    { id: uid(), amount: 89.00, type: 'expense', category: 'shopping', accountId: 'credit', note: 'Amazon order', date: fmt(new Date(today.getTime() - 86400000 * 2)), receiptImage: null, isRecurring: false, linkedTaskId: null, createdAt: new Date().toISOString() },
  ];

  state.budgets = [
    { id: uid(), category: 'food', monthlyLimit: 500, monthYear: `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}` },
    { id: uid(), category: 'transport', monthlyLimit: 200, monthYear: `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}` },
    { id: uid(), category: 'shopping', monthlyLimit: 300, monthYear: `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}` },
  ];

  state.resources = [
    { id: uid(), type: 'subscription', name: 'Netflix', details: { plan: 'Standard', cost: 15.99 }, fileUrl: null, renewalDate: fmt(new Date(today.getFullYear(), today.getMonth() + 1, 5)), tags: ['entertainment'], quantity: null, lowStockThreshold: 5, createdAt: new Date().toISOString() },
    { id: uid(), type: 'subscription', name: 'Spotify', details: { plan: 'Premium', cost: 9.99 }, fileUrl: null, renewalDate: fmt(new Date(today.getFullYear(), today.getMonth() + 1, 15)), tags: ['entertainment'], quantity: null, lowStockThreshold: 5, createdAt: new Date().toISOString() },
    { id: uid(), type: 'document', name: 'Passport', details: { number: '****1234', expiry: '2028-06-15' }, fileUrl: null, renewalDate: '2028-06-15', tags: ['id'], quantity: null, lowStockThreshold: 5, createdAt: new Date().toISOString() },
    { id: uid(), type: 'inventory', name: 'Office Paper (A4)', details: { location: 'Storage closet' }, fileUrl: null, renewalDate: null, tags: ['office'], quantity: 3, lowStockThreshold: 5, createdAt: new Date().toISOString() },
    { id: uid(), type: 'contact', name: 'Dr. Sarah Chen', details: { phone: '+1 555-0123', email: 'sarah.chen@clinic.com', role: 'Primary care' }, fileUrl: null, renewalDate: null, tags: ['medical'], quantity: null, lowStockThreshold: 5, createdAt: new Date().toISOString() },
  ];

  state.user.streak = 3;
  persist();
}

export const CATEGORIES = {
  food: 'Food',
  transport: 'Transport',
  bills: 'Bills',
  shopping: 'Shopping',
  other: 'Other',
};

export const PRIORITIES = ['low', 'medium', 'high', 'urgent'];

export const RESOURCE_TYPES = {
  document: { label: 'Documents', icon: 'file-badge' },
  subscription: { label: 'Subscriptions', icon: 'repeat' },
  inventory: { label: 'Inventory', icon: 'package' },
  contact: { label: 'Contacts', icon: 'contact' },
};

export const NOTE_TEMPLATES = {
  meeting: { title: 'Meeting Notes', body: '# Meeting Notes\n\n**Date:** \n**Attendees:** \n\n## Agenda\n1. \n\n## Notes\n\n## Action Items\n- [ ] ' },
  journal: { title: 'Journal Entry', body: '## How am I feeling today?\n\n## What went well?\n\n## What could be better?\n' },
  recipe: { title: 'Recipe', body: '## Ingredients\n- \n\n## Instructions\n1. \n\n## Notes\n' },
};
