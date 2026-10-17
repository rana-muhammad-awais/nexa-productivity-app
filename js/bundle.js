(() => {
  var __defProp = Object.defineProperty;
  var __getOwnPropNames = Object.getOwnPropertyNames;
  var __esm = (fn, res, err) => function __init() {
    if (err) throw err[0];
    try {
      return fn && (res = (0, fn[__getOwnPropNames(fn)[0]])(fn = 0)), res;
    } catch (e) {
      throw err = [e], e;
    }
  };
  var __export = (target, all) => {
    for (var name in all)
      __defProp(target, name, { get: all[name], enumerable: true });
  };

  // js/store.js
  var store_exports = {};
  __export(store_exports, {
    CATEGORIES: () => CATEGORIES,
    NOTE_TEMPLATES: () => NOTE_TEMPLATES,
    PRIORITIES: () => PRIORITIES,
    RESOURCE_TYPES: () => RESOURCE_TYPES,
    addExpense: () => addExpense,
    addNote: () => addNote,
    addResource: () => addResource,
    addTask: () => addTask,
    clearAllData: () => clearAllData,
    deleteExpense: () => deleteExpense,
    deleteNote: () => deleteNote,
    deleteResource: () => deleteResource,
    deleteTask: () => deleteTask,
    exportData: () => exportData,
    getState: () => getState,
    globalSearch: () => globalSearch,
    loadSampleData: () => loadSampleData,
    reorderTasks: () => reorderTasks,
    setBudget: () => setBudget,
    subscribe: () => subscribe,
    togglePinNote: () => togglePinNote,
    toggleTask: () => toggleTask,
    updateNote: () => updateNote,
    updateResource: () => updateResource,
    updateTask: () => updateTask,
    updateUser: () => updateUser
  });
  function loadState() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) {
        const parsed = JSON.parse(raw);
        return { ...DEFAULT_STATE, ...parsed, user: { ...DEFAULT_STATE.user, ...parsed.user } };
      }
    } catch (e) {
      console.warn("Failed to load state", e);
    }
    return structuredClone(DEFAULT_STATE);
  }
  function persist() {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    listeners.forEach((fn) => fn(state));
  }
  function subscribe(fn) {
    listeners.add(fn);
    return () => listeners.delete(fn);
  }
  function getState() {
    return state;
  }
  function updateUser(updates) {
    state.user = { ...state.user, ...updates };
    persist();
  }
  function uid() {
    return crypto.randomUUID();
  }
  function addTask(data) {
    const task = {
      id: uid(),
      title: data.title,
      description: data.description || "",
      dueDate: data.dueDate || null,
      dueTime: data.dueTime || null,
      priority: data.priority || "medium",
      tags: data.tags || [],
      listId: data.listId || "inbox",
      isCompleted: false,
      subtasks: data.subtasks || [],
      recurrence: data.recurrence || null,
      linkedNoteId: data.linkedNoteId || null,
      order: state.tasks.length,
      createdAt: (/* @__PURE__ */ new Date()).toISOString()
    };
    state.tasks.push(task);
    persist();
    return task;
  }
  function updateTask(id, updates) {
    const idx = state.tasks.findIndex((t) => t.id === id);
    if (idx === -1) return null;
    state.tasks[idx] = { ...state.tasks[idx], ...updates };
    persist();
    return state.tasks[idx];
  }
  function toggleTask(id) {
    const task = state.tasks.find((t) => t.id === id);
    if (!task) return;
    task.isCompleted = !task.isCompleted;
    if (task.isCompleted) updateStreak();
    persist();
  }
  function deleteTask(id) {
    state.tasks = state.tasks.filter((t) => t.id !== id);
    persist();
  }
  function reorderTasks(orderedIds) {
    orderedIds.forEach((id, i) => {
      const t = state.tasks.find((x) => x.id === id);
      if (t) t.order = i;
    });
    persist();
  }
  function updateStreak() {
    const today = (/* @__PURE__ */ new Date()).toISOString().slice(0, 10);
    const yesterday = new Date(Date.now() - 864e5).toISOString().slice(0, 10);
    if (state.user.lastCompletionDate === today) return;
    if (state.user.lastCompletionDate === yesterday) {
      state.user.streak = (state.user.streak || 0) + 1;
    } else {
      state.user.streak = 1;
    }
    state.user.lastCompletionDate = today;
  }
  function addNote(data) {
    const note = {
      id: uid(),
      title: data.title || "Untitled",
      body: data.body || "",
      folderId: data.folderId || "inbox",
      tags: data.tags || [],
      pinned: data.pinned || false,
      attachments: data.attachments || [],
      createdAt: (/* @__PURE__ */ new Date()).toISOString(),
      updatedAt: (/* @__PURE__ */ new Date()).toISOString()
    };
    state.notes.unshift(note);
    persist();
    return note;
  }
  function updateNote(id, updates) {
    const idx = state.notes.findIndex((n) => n.id === id);
    if (idx === -1) return null;
    state.notes[idx] = { ...state.notes[idx], ...updates, updatedAt: (/* @__PURE__ */ new Date()).toISOString() };
    persist();
    return state.notes[idx];
  }
  function deleteNote(id) {
    state.notes = state.notes.filter((n) => n.id !== id);
    persist();
  }
  function togglePinNote(id) {
    const note = state.notes.find((n) => n.id === id);
    if (note) {
      note.pinned = !note.pinned;
      persist();
    }
  }
  function addExpense(data) {
    const expense = {
      id: uid(),
      amount: parseFloat(data.amount) || 0,
      type: data.type || "expense",
      category: data.category || "other",
      accountId: data.accountId || "cash",
      note: data.note || "",
      date: data.date || (/* @__PURE__ */ new Date()).toISOString().slice(0, 10),
      receiptImage: data.receiptImage || null,
      isRecurring: data.isRecurring || false,
      linkedTaskId: data.linkedTaskId || null,
      createdAt: (/* @__PURE__ */ new Date()).toISOString()
    };
    state.expenses.unshift(expense);
    persist();
    return expense;
  }
  function deleteExpense(id) {
    state.expenses = state.expenses.filter((e) => e.id !== id);
    persist();
  }
  function setBudget(category, limit, monthYear) {
    const existing = state.budgets.findIndex((b) => b.category === category && b.monthYear === monthYear);
    const budget = { id: uid(), category, monthlyLimit: parseFloat(limit), monthYear };
    if (existing >= 0) state.budgets[existing] = budget;
    else state.budgets.push(budget);
    persist();
  }
  function addResource(data) {
    const resource = {
      id: uid(),
      type: data.type || "document",
      name: data.name,
      details: data.details || {},
      fileUrl: data.fileUrl || null,
      renewalDate: data.renewalDate || null,
      tags: data.tags || [],
      quantity: data.quantity ?? null,
      lowStockThreshold: data.lowStockThreshold ?? 5,
      createdAt: (/* @__PURE__ */ new Date()).toISOString()
    };
    state.resources.unshift(resource);
    persist();
    return resource;
  }
  function updateResource(id, updates) {
    const idx = state.resources.findIndex((r) => r.id === id);
    if (idx === -1) return null;
    state.resources[idx] = { ...state.resources[idx], ...updates };
    persist();
    return state.resources[idx];
  }
  function deleteResource(id) {
    state.resources = state.resources.filter((r) => r.id !== id);
    persist();
  }
  function globalSearch(query) {
    const q = query.toLowerCase().trim();
    if (!q) return { tasks: [], notes: [], expenses: [], resources: [] };
    return {
      tasks: state.tasks.filter(
        (t) => t.title.toLowerCase().includes(q) || t.description?.toLowerCase().includes(q) || t.tags?.some((tag) => tag.toLowerCase().includes(q))
      ),
      notes: state.notes.filter(
        (n) => n.title.toLowerCase().includes(q) || n.body.toLowerCase().includes(q) || n.tags?.some((tag) => tag.toLowerCase().includes(q))
      ),
      expenses: state.expenses.filter(
        (e) => e.note?.toLowerCase().includes(q) || e.category.toLowerCase().includes(q)
      ),
      resources: state.resources.filter(
        (r) => r.name.toLowerCase().includes(q) || r.tags?.some((tag) => tag.toLowerCase().includes(q))
      )
    };
  }
  function exportData() {
    return JSON.stringify(state, null, 2);
  }
  function clearAllData() {
    state = structuredClone(DEFAULT_STATE);
    persist();
  }
  function loadSampleData() {
    const today = /* @__PURE__ */ new Date();
    const fmt = (d) => d.toISOString().slice(0, 10);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    const nextWeek = new Date(today);
    nextWeek.setDate(nextWeek.getDate() + 7);
    state.tasks = [
      { id: uid(), title: "Team standup meeting", description: "Daily sync with the team", dueDate: fmt(today), dueTime: "10:00", priority: "high", tags: ["work"], listId: "work", isCompleted: false, subtasks: [], recurrence: null, linkedNoteId: null, order: 0, createdAt: (/* @__PURE__ */ new Date()).toISOString() },
      { id: uid(), title: "Pay electricity bill", description: "", dueDate: fmt(tomorrow), dueTime: "18:00", priority: "urgent", tags: ["bills"], listId: "inbox", isCompleted: false, subtasks: [], recurrence: "monthly", linkedNoteId: null, order: 1, createdAt: (/* @__PURE__ */ new Date()).toISOString() },
      { id: uid(), title: "Buy groceries", description: "Milk, eggs, bread, vegetables", dueDate: fmt(today), dueTime: null, priority: "medium", tags: ["shopping"], listId: "inbox", isCompleted: false, subtasks: [{ id: uid(), title: "Milk", done: false }, { id: uid(), title: "Eggs", done: true }], recurrence: null, linkedNoteId: null, order: 2, createdAt: (/* @__PURE__ */ new Date()).toISOString() },
      { id: uid(), title: "Review project proposal", description: "", dueDate: fmt(nextWeek), dueTime: null, priority: "low", tags: ["work"], listId: "work", isCompleted: true, subtasks: [], recurrence: null, linkedNoteId: null, order: 3, createdAt: (/* @__PURE__ */ new Date()).toISOString() }
    ];
    state.notes = [
      { id: uid(), title: "Meeting Notes \u2014 Q3 Planning", body: "# Q3 Planning\n\n## Goals\n- Launch MVP by August\n- Hire 2 engineers\n\n## Action Items\n- [ ] Draft roadmap\n- [x] Schedule interviews", folderId: "work", tags: ["meetings"], pinned: true, attachments: [], createdAt: (/* @__PURE__ */ new Date()).toISOString(), updatedAt: (/* @__PURE__ */ new Date()).toISOString() },
      { id: uid(), title: "Recipe: Pasta Carbonara", body: "## Ingredients\n- 400g spaghetti\n- 200g guanciale\n- 4 egg yolks\n- Pecorino Romano\n\n## Steps\n1. Boil pasta\n2. Crisp guanciale\n3. Mix eggs with cheese\n4. Combine off heat", folderId: "personal", tags: ["recipe"], pinned: false, attachments: [], createdAt: (/* @__PURE__ */ new Date()).toISOString(), updatedAt: (/* @__PURE__ */ new Date()).toISOString() },
      { id: uid(), title: "Journal \u2014 Today", body: "Feeling productive today. Finished the project review and started planning next week.", folderId: "personal", tags: ["journal"], pinned: false, attachments: [], createdAt: (/* @__PURE__ */ new Date()).toISOString(), updatedAt: (/* @__PURE__ */ new Date()).toISOString() }
    ];
    state.expenses = [
      { id: uid(), amount: 45.5, type: "expense", category: "food", accountId: "credit", note: "Lunch at cafe", date: fmt(today), receiptImage: null, isRecurring: false, linkedTaskId: null, createdAt: (/* @__PURE__ */ new Date()).toISOString() },
      { id: uid(), amount: 12, type: "expense", category: "transport", accountId: "cash", note: "Uber ride", date: fmt(today), receiptImage: null, isRecurring: false, linkedTaskId: null, createdAt: (/* @__PURE__ */ new Date()).toISOString() },
      { id: uid(), amount: 3500, type: "income", category: "other", accountId: "bank", note: "Freelance payment", date: fmt(new Date(today.getFullYear(), today.getMonth(), 1)), receiptImage: null, isRecurring: false, linkedTaskId: null, createdAt: (/* @__PURE__ */ new Date()).toISOString() },
      { id: uid(), amount: 15.99, type: "expense", category: "bills", accountId: "credit", note: "Netflix subscription", date: fmt(new Date(today.getFullYear(), today.getMonth(), 5)), receiptImage: null, isRecurring: true, linkedTaskId: null, createdAt: (/* @__PURE__ */ new Date()).toISOString() },
      { id: uid(), amount: 89, type: "expense", category: "shopping", accountId: "credit", note: "Amazon order", date: fmt(new Date(today.getTime() - 864e5 * 2)), receiptImage: null, isRecurring: false, linkedTaskId: null, createdAt: (/* @__PURE__ */ new Date()).toISOString() }
    ];
    state.budgets = [
      { id: uid(), category: "food", monthlyLimit: 500, monthYear: `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}` },
      { id: uid(), category: "transport", monthlyLimit: 200, monthYear: `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}` },
      { id: uid(), category: "shopping", monthlyLimit: 300, monthYear: `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}` }
    ];
    state.resources = [
      { id: uid(), type: "subscription", name: "Netflix", details: { plan: "Standard", cost: 15.99 }, fileUrl: null, renewalDate: fmt(new Date(today.getFullYear(), today.getMonth() + 1, 5)), tags: ["entertainment"], quantity: null, lowStockThreshold: 5, createdAt: (/* @__PURE__ */ new Date()).toISOString() },
      { id: uid(), type: "subscription", name: "Spotify", details: { plan: "Premium", cost: 9.99 }, fileUrl: null, renewalDate: fmt(new Date(today.getFullYear(), today.getMonth() + 1, 15)), tags: ["entertainment"], quantity: null, lowStockThreshold: 5, createdAt: (/* @__PURE__ */ new Date()).toISOString() },
      { id: uid(), type: "document", name: "Passport", details: { number: "****1234", expiry: "2028-06-15" }, fileUrl: null, renewalDate: "2028-06-15", tags: ["id"], quantity: null, lowStockThreshold: 5, createdAt: (/* @__PURE__ */ new Date()).toISOString() },
      { id: uid(), type: "inventory", name: "Office Paper (A4)", details: { location: "Storage closet" }, fileUrl: null, renewalDate: null, tags: ["office"], quantity: 3, lowStockThreshold: 5, createdAt: (/* @__PURE__ */ new Date()).toISOString() },
      { id: uid(), type: "contact", name: "Dr. Sarah Chen", details: { phone: "+1 555-0123", email: "sarah.chen@clinic.com", role: "Primary care" }, fileUrl: null, renewalDate: null, tags: ["medical"], quantity: null, lowStockThreshold: 5, createdAt: (/* @__PURE__ */ new Date()).toISOString() }
    ];
    state.user.streak = 3;
    persist();
  }
  var STORAGE_KEY, DEFAULT_STATE, state, listeners, CATEGORIES, PRIORITIES, RESOURCE_TYPES, NOTE_TEMPLATES;
  var init_store = __esm({
    "js/store.js"() {
      STORAGE_KEY = "nexa-data-v1";
      DEFAULT_STATE = {
        user: {
          name: "User",
          theme: "auto",
          currency: "USD",
          onboarded: false,
          streak: 0,
          lastCompletionDate: null
        },
        tasks: [],
        notes: [],
        noteFolders: [
          { id: "inbox", name: "Inbox", icon: "inbox" },
          { id: "work", name: "Work", icon: "briefcase" },
          { id: "personal", name: "Personal", icon: "user" }
        ],
        expenses: [],
        accounts: [
          { id: "cash", name: "Cash", type: "cash" },
          { id: "bank", name: "Bank", type: "bank" },
          { id: "credit", name: "Credit Card", type: "credit" }
        ],
        budgets: [],
        resources: [],
        reminders: []
      };
      state = loadState();
      listeners = /* @__PURE__ */ new Set();
      CATEGORIES = {
        food: "Food",
        transport: "Transport",
        bills: "Bills",
        shopping: "Shopping",
        other: "Other"
      };
      PRIORITIES = ["low", "medium", "high", "urgent"];
      RESOURCE_TYPES = {
        document: { label: "Documents", icon: "file-badge" },
        subscription: { label: "Subscriptions", icon: "repeat" },
        inventory: { label: "Inventory", icon: "package" },
        contact: { label: "Contacts", icon: "contact" }
      };
      NOTE_TEMPLATES = {
        meeting: { title: "Meeting Notes", body: "# Meeting Notes\n\n**Date:** \n**Attendees:** \n\n## Agenda\n1. \n\n## Notes\n\n## Action Items\n- [ ] " },
        journal: { title: "Journal Entry", body: "## How am I feeling today?\n\n## What went well?\n\n## What could be better?\n" },
        recipe: { title: "Recipe", body: "## Ingredients\n- \n\n## Instructions\n1. \n\n## Notes\n" }
      };
    }
  });

  // js/app.js
  init_store();

  // js/utils.js
  function formatDate(dateStr) {
    if (!dateStr) return "";
    const d = /* @__PURE__ */ new Date(dateStr + (dateStr.includes("T") ? "" : "T00:00:00"));
    const today = /* @__PURE__ */ new Date();
    today.setHours(0, 0, 0, 0);
    const target = new Date(d);
    target.setHours(0, 0, 0, 0);
    const diff = Math.round((target - today) / 864e5);
    if (diff === 0) return "Today";
    if (diff === 1) return "Tomorrow";
    if (diff === -1) return "Yesterday";
    if (diff > 1 && diff <= 7) return d.toLocaleDateString("en-US", { weekday: "long" });
    return d.toLocaleDateString("en-US", { month: "short", day: "numeric" });
  }
  function formatCurrency(amount, currency = "USD") {
    return new Intl.NumberFormat("en-US", { style: "currency", currency }).format(amount);
  }
  function getGreeting() {
    const h = (/* @__PURE__ */ new Date()).getHours();
    if (h < 12) return "Good morning";
    if (h < 17) return "Good afternoon";
    return "Good evening";
  }
  function isOverdue(dueDate, isCompleted) {
    if (!dueDate || isCompleted) return false;
    const today = (/* @__PURE__ */ new Date()).toISOString().slice(0, 10);
    return dueDate < today;
  }
  function getMonthYear(date = /* @__PURE__ */ new Date()) {
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
  }
  function daysUntil(dateStr) {
    if (!dateStr) return null;
    const target = /* @__PURE__ */ new Date(dateStr + "T00:00:00");
    const today = /* @__PURE__ */ new Date();
    today.setHours(0, 0, 0, 0);
    return Math.ceil((target - today) / 864e5);
  }
  function parseNaturalLanguage(input) {
    const result = { title: input, dueDate: null, dueTime: null, tags: [], priority: "medium" };
    const tagMatches = input.match(/#\w+/g);
    if (tagMatches) {
      result.tags = tagMatches.map((t) => t.slice(1).toLowerCase());
      result.title = result.title.replace(/#\w+/g, "").trim();
    }
    const priorityWords = { urgent: "urgent", asap: "urgent", important: "high", high: "high" };
    for (const [word, pri] of Object.entries(priorityWords)) {
      if (new RegExp(`\\b${word}\\b`, "i").test(result.title)) {
        result.priority = pri;
        result.title = result.title.replace(new RegExp(`\\b${word}\\b`, "gi"), "").trim();
      }
    }
    const timeMatch = result.title.match(/(\d{1,2})(?::(\d{2}))?\s*(am|pm)/i);
    if (timeMatch) {
      let h = parseInt(timeMatch[1]);
      const m = timeMatch[2] || "00";
      if (timeMatch[3].toLowerCase() === "pm" && h < 12) h += 12;
      if (timeMatch[3].toLowerCase() === "am" && h === 12) h = 0;
      result.dueTime = `${String(h).padStart(2, "0")}:${m}`;
      result.title = result.title.replace(timeMatch[0], "").trim();
    }
    const dateWords = {
      today: 0,
      tonight: 0,
      tomorrow: 1,
      monday: null,
      tuesday: null,
      wednesday: null,
      thursday: null,
      friday: null,
      saturday: null,
      sunday: null
    };
    for (const [word, offset] of Object.entries(dateWords)) {
      const regex = new RegExp(`\\b${word}\\b`, "i");
      if (regex.test(result.title)) {
        const d = /* @__PURE__ */ new Date();
        if (offset === 0 || offset === 1) {
          d.setDate(d.getDate() + offset);
        } else if (offset === null) {
          const days = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"];
          const target = days.indexOf(word);
          const current = d.getDay();
          let diff = target - current;
          if (diff <= 0) diff += 7;
          d.setDate(d.getDate() + diff);
        }
        result.dueDate = d.toISOString().slice(0, 10);
        result.title = result.title.replace(regex, "").trim();
        break;
      }
    }
    result.title = result.title.replace(/\s+/g, " ").trim();
    return result;
  }
  function autoCategorizeExpense(note) {
    const text = (note || "").toLowerCase();
    const rules = {
      food: ["food", "restaurant", "cafe", "coffee", "lunch", "dinner", "grocery", "uber eats", "doordash", "pizza", "starbucks"],
      transport: ["uber", "lyft", "taxi", "gas", "fuel", "parking", "transit", "metro", "bus", "train"],
      bills: ["rent", "electric", "water", "internet", "phone", "insurance", "netflix", "spotify", "subscription"],
      shopping: ["amazon", "target", "walmart", "shop", "clothes", "shoes", "order"]
    };
    for (const [cat, keywords] of Object.entries(rules)) {
      if (keywords.some((kw) => text.includes(kw))) return cat;
    }
    return "other";
  }
  function stripMarkdown(text) {
    return text.replace(/^#+\s+/gm, "").replace(/\*\*(.+?)\*\*/g, "$1").replace(/\*(.+?)\*/g, "$1").replace(/- \[.\]\s/g, "").replace(/^-\s/gm, "").replace(/\n/g, " ").trim();
  }
  function renderMarkdown(text) {
    return text.replace(/^### (.+)$/gm, "<h3>$1</h3>").replace(/^## (.+)$/gm, "<h2>$1</h2>").replace(/^# (.+)$/gm, "<h1>$1</h1>").replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>").replace(/\*(.+?)\*/g, "<em>$1</em>").replace(/^- \[x\] (.+)$/gm, '<div class="md-check done">\u2713 $1</div>').replace(/^- \[ \] (.+)$/gm, '<div class="md-check">\u25CB $1</div>').replace(/^- (.+)$/gm, "<li>$1</li>").replace(/(<li>.*<\/li>\n?)+/g, (m) => `<ul>${m}</ul>`).replace(/\n/g, "<br>");
  }
  function escapeHtml(str) {
    const div = document.createElement("div");
    div.textContent = str;
    return div.innerHTML;
  }
  function refreshIcons() {
    if (typeof window !== "undefined" && window.lucide && typeof window.lucide.createIcons === "function") {
      window.lucide.createIcons();
    }
  }

  // js/components/ui.js
  var overlayEl;
  var sheetEl;
  var modalEl;
  function initUI() {
    overlayEl = document.getElementById("overlay");
    sheetEl = document.getElementById("bottom-sheet");
    modalEl = document.getElementById("modal");
    overlayEl.addEventListener("click", closeAll);
  }
  function closeAll() {
    overlayEl.hidden = true;
    overlayEl.classList.remove("visible");
    sheetEl.hidden = true;
    sheetEl.classList.remove("visible");
    modalEl.hidden = true;
    modalEl.classList.remove("visible");
    document.querySelector(".quick-menu")?.remove();
  }
  function openBottomSheet(title, bodyHtml, onSubmit) {
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
      overlayEl.classList.add("visible");
      sheetEl.classList.add("visible");
    });
    refreshIcons();
    document.getElementById("sheet-close")?.addEventListener("click", closeAll);
    const form = sheetEl.querySelector("form");
    if (form && onSubmit) {
      form.addEventListener("submit", (e) => {
        e.preventDefault();
        const fd = new FormData(form);
        const data = Object.fromEntries(fd.entries());
        onSubmit(data, form);
      });
    }
  }
  function openModal(title, bodyHtml) {
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
      overlayEl.classList.add("visible");
      modalEl.classList.add("visible");
    });
    refreshIcons();
    document.getElementById("modal-close")?.addEventListener("click", closeAll);
  }
  function showQuickMenu(items, onSelect) {
    document.querySelector(".quick-menu")?.remove();
    const menu = document.createElement("div");
    menu.className = "quick-menu";
    menu.innerHTML = items.map(
      (item) => `<button class="quick-menu__item" data-action="${item.action}">
      <i data-lucide="${item.icon}"></i>${item.label}
    </button>`
    ).join("");
    document.body.appendChild(menu);
    refreshIcons();
    menu.querySelectorAll(".quick-menu__item").forEach((btn) => {
      btn.addEventListener("click", () => {
        menu.remove();
        onSelect(btn.dataset.action);
      });
    });
  }
  function emptyState(icon, title, text, btnLabel, onClick) {
    return `
    <div class="empty-state">
      <div class="empty-state__icon"><i data-lucide="${icon}"></i></div>
      <div class="empty-state__title">${title}</div>
      <div class="empty-state__text">${text}</div>
      ${btnLabel ? `<button class="btn btn--primary" id="empty-action">${btnLabel}</button>` : ""}
    </div>
  `;
  }
  function bindEmptyAction(onClick) {
    document.getElementById("empty-action")?.addEventListener("click", onClick);
  }

  // js/pages/home.js
  init_store();

  // js/pages/expenses.js
  init_store();
  var currentTab = "overview";
  var charts = {};
  function renderExpenses(container) {
    container.innerHTML = `
    <div class="expense-tabs">
      <button class="expense-tab ${currentTab === "overview" ? "active" : ""}" data-tab="overview">Overview</button>
      <button class="expense-tab ${currentTab === "transactions" ? "active" : ""}" data-tab="transactions">Transactions</button>
      <button class="expense-tab ${currentTab === "budgets" ? "active" : ""}" data-tab="budgets">Budgets</button>
      <button class="expense-tab ${currentTab === "reports" ? "active" : ""}" data-tab="reports">Reports</button>
    </div>
    <div id="expense-content"></div>
  `;
    container.querySelectorAll(".expense-tab").forEach((tab) => {
      tab.addEventListener("click", () => {
        currentTab = tab.dataset.tab;
        Object.values(charts).forEach((c) => c.destroy?.());
        charts = {};
        renderExpenses(container);
      });
    });
    const content = container.querySelector("#expense-content");
    if (currentTab === "overview") renderOverview(content);
    else if (currentTab === "transactions") renderTransactions(content);
    else if (currentTab === "budgets") renderBudgets(content);
    else renderReports(content);
  }
  function getMonthExpenses() {
    const monthYear = getMonthYear();
    return getState().expenses.filter((e) => e.date?.startsWith(monthYear));
  }
  function renderOverview(el) {
    const monthExp = getMonthExpenses();
    const totalExp = monthExp.filter((e) => e.type === "expense").reduce((s, e) => s + e.amount, 0);
    const totalInc = monthExp.filter((e) => e.type === "income").reduce((s, e) => s + e.amount, 0);
    const currency = getState().user.currency;
    el.innerHTML = `
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-card__value negative">${formatCurrency(totalExp, currency)}</div>
        <div class="stat-card__label">Spent this month</div>
      </div>
      <div class="stat-card">
        <div class="stat-card__value positive">${formatCurrency(totalInc, currency)}</div>
        <div class="stat-card__label">Income this month</div>
      </div>
    </div>
    <div class="section">
      <div class="section__title">Recent Transactions</div>
      ${monthExp.slice(0, 5).map(renderExpenseItem).join("") || '<p style="color:var(--text-secondary);font-size:0.875rem">No transactions this month</p>'}
    </div>
  `;
  }
  function renderTransactions(el) {
    const expenses = getState().expenses;
    if (expenses.length === 0) {
      el.innerHTML = emptyState("wallet", "No expenses yet", "Track your spending by adding your first transaction.", "Add Expense", () => showAddExpense());
      bindEmptyAction(() => showAddExpense());
      return;
    }
    el.innerHTML = expenses.map(renderExpenseItem).join("");
    el.querySelectorAll(".resource-item").forEach((item) => {
      item.querySelector("[data-delete]")?.addEventListener("click", (e) => {
        e.stopPropagation();
        deleteExpense(item.dataset.id);
        document.getElementById("main-content").dispatchEvent(new Event("refresh"));
      });
    });
  }
  function renderExpenseItem(exp) {
    const currency = getState().user.currency;
    const catLabel = CATEGORIES[exp.category] || exp.category;
    return `
    <div class="resource-item" data-id="${exp.id}">
      <div class="resource-item__icon"><i data-lucide="${exp.type === "income" ? "arrow-down-left" : "arrow-up-right"}"></i></div>
      <div class="resource-item__content">
        <div class="resource-item__title">${escapeHtml(exp.note || catLabel)}</div>
        <div class="resource-item__sub">
          <span class="tag tag--${exp.category}">${catLabel}</span>
          ${exp.date}
          ${exp.isRecurring ? " \xB7 Recurring" : ""}
        </div>
      </div>
      <div style="font-weight:600;color:${exp.type === "income" ? "var(--success)" : "var(--danger)"}">
        ${exp.type === "income" ? "+" : "-"}${formatCurrency(exp.amount, currency)}
      </div>
      <button class="icon-btn" data-delete aria-label="Delete"><i data-lucide="trash-2"></i></button>
    </div>
  `;
  }
  function renderBudgets(el) {
    const monthYear = getMonthYear();
    const budgets = getState().budgets.filter((b) => b.monthYear === monthYear);
    const monthExp = getMonthExpenses().filter((e) => e.type === "expense");
    const currency = getState().user.currency;
    const spentByCat = {};
    monthExp.forEach((e) => {
      spentByCat[e.category] = (spentByCat[e.category] || 0) + e.amount;
    });
    el.innerHTML = `
    <div class="section">
      ${Object.entries(CATEGORIES).map(([key, label]) => {
      const budget = budgets.find((b) => b.category === key);
      const spent = spentByCat[key] || 0;
      const limit = budget?.monthlyLimit || 0;
      const pct = limit ? Math.min(100, spent / limit * 100) : 0;
      return `
          <div class="budget-bar">
            <div class="budget-bar__header">
              <span class="tag tag--${key}">${label}</span>
              <span>${formatCurrency(spent, currency)}${limit ? ` / ${formatCurrency(limit, currency)}` : ""}</span>
            </div>
            ${limit ? `<div class="budget-bar__track"><div class="budget-bar__fill ${pct >= 100 ? "over" : ""}" style="width:${pct}%"></div></div>` : ""}
          </div>
        `;
    }).join("")}
    </div>
    <button class="btn btn--secondary btn--block" id="set-budget">Set Budget Limits</button>
  `;
    document.getElementById("set-budget")?.addEventListener("click", showSetBudget);
    refreshIcons();
  }
  function showSetBudget() {
    openBottomSheet("Set Monthly Budgets", `
    <form id="budget-form">
      ${Object.entries(CATEGORIES).map(([key, label]) => {
      const b = getState().budgets.find((x) => x.category === key && x.monthYear === getMonthYear());
      return `
          <div class="form-group">
            <label class="form-label">${label}</label>
            <input class="form-input" type="number" name="${key}" placeholder="Monthly limit" value="${b?.monthlyLimit || ""}" min="0" step="0.01" />
          </div>
        `;
    }).join("")}
      <button type="submit" class="btn btn--primary btn--block">Save Budgets</button>
    </form>
  `, (data) => {
      const my = getMonthYear();
      Object.entries(data).forEach(([cat, limit]) => {
        if (limit) setBudget(cat, limit, my);
      });
      document.getElementById("overlay").click();
      document.getElementById("main-content").dispatchEvent(new Event("refresh"));
    });
  }
  function renderReports(el) {
    const monthExp = getMonthExpenses().filter((e) => e.type === "expense");
    const currency = getState().user.currency;
    if (monthExp.length === 0) {
      el.innerHTML = emptyState("bar-chart-3", "No data yet", "Add some expenses to see reports.", "Add Expense", () => showAddExpense());
      bindEmptyAction(() => showAddExpense());
      return;
    }
    el.innerHTML = `
    <div class="chart-container">
      <div class="chart-container__title">Spending by Category</div>
      <canvas id="pie-chart" height="200"></canvas>
    </div>
    <div class="chart-container">
      <div class="chart-container__title">Daily Spending</div>
      <canvas id="line-chart" height="200"></canvas>
    </div>
    <div class="chart-container">
      <div class="chart-container__title">Income vs Expense</div>
      <canvas id="bar-chart" height="200"></canvas>
    </div>
  `;
    setTimeout(() => renderCharts(monthExp, currency), 100);
  }
  function renderCharts(monthExp, currency) {
    const isDark = document.documentElement.dataset.theme === "dark";
    const textColor = isDark ? "#9CA3AF" : "#6B7280";
    const catColors = { food: "#F97316", transport: "#8B5CF6", bills: "#EF4444", shopping: "#EC4899", other: "#6B7280" };
    const byCat = {};
    monthExp.forEach((e) => {
      byCat[e.category] = (byCat[e.category] || 0) + e.amount;
    });
    const pieCtx = document.getElementById("pie-chart");
    if (pieCtx) {
      charts.pie = new Chart(pieCtx, {
        type: "doughnut",
        data: {
          labels: Object.keys(byCat).map((k) => CATEGORIES[k] || k),
          datasets: [{ data: Object.values(byCat), backgroundColor: Object.keys(byCat).map((k) => catColors[k] || "#6B7280") }]
        },
        options: { plugins: { legend: { labels: { color: textColor } } } }
      });
    }
    const byDay = {};
    monthExp.forEach((e) => {
      byDay[e.date] = (byDay[e.date] || 0) + e.amount;
    });
    const lineCtx = document.getElementById("line-chart");
    if (lineCtx) {
      charts.line = new Chart(lineCtx, {
        type: "line",
        data: {
          labels: Object.keys(byDay).sort(),
          datasets: [{ label: "Spending", data: Object.keys(byDay).sort().map((d) => byDay[d]), borderColor: "#5B5FEF", tension: 0.3, fill: false }]
        },
        options: { scales: { x: { ticks: { color: textColor } }, y: { ticks: { color: textColor } } }, plugins: { legend: { labels: { color: textColor } } } }
      });
    }
    const allMonth = getMonthExpenses();
    const totalExp = allMonth.filter((e) => e.type === "expense").reduce((s, e) => s + e.amount, 0);
    const totalInc = allMonth.filter((e) => e.type === "income").reduce((s, e) => s + e.amount, 0);
    const barCtx = document.getElementById("bar-chart");
    if (barCtx) {
      charts.bar = new Chart(barCtx, {
        type: "bar",
        data: {
          labels: ["Income", "Expenses"],
          datasets: [{ data: [totalInc, totalExp], backgroundColor: ["#22C55E", "#EF4444"] }]
        },
        options: { scales: { x: { ticks: { color: textColor } }, y: { ticks: { color: textColor } } }, plugins: { legend: { display: false } } }
      });
    }
  }
  function showAddExpense() {
    const today = (/* @__PURE__ */ new Date()).toISOString().slice(0, 10);
    openBottomSheet("Add Transaction", `
    <form id="add-expense-form">
      <div class="form-group">
        <label class="form-label">Type</label>
        <select class="form-select" name="type">
          <option value="expense">Expense</option>
          <option value="income">Income</option>
        </select>
      </div>
      <div class="form-group">
        <label class="form-label">Amount</label>
        <input class="form-input" type="number" name="amount" placeholder="0.00" min="0" step="0.01" required />
      </div>
      <div class="form-group">
        <label class="form-label">Note / Description</label>
        <input class="form-input" name="note" placeholder="What was it for?" id="expense-note" />
      </div>
      <div class="form-group">
        <label class="form-label">Category</label>
        <select class="form-select" name="category" id="expense-category">
          ${Object.entries(CATEGORIES).map(([k, v]) => `<option value="${k}">${v}</option>`).join("")}
        </select>
      </div>
      <div class="form-group">
        <label class="form-label">Account</label>
        <select class="form-select" name="accountId">
          ${getState().accounts.map((a) => `<option value="${a.id}">${escapeHtml(a.name)}</option>`).join("")}
        </select>
      </div>
      <div class="form-group">
        <label class="form-label">Date</label>
        <input class="form-input" type="date" name="date" value="${today}" />
      </div>
      <div class="form-group">
        <label style="display:flex;align-items:center;gap:8px;font-size:0.875rem">
          <input type="checkbox" name="isRecurring" value="true" /> Recurring expense
        </label>
      </div>
      <button type="submit" class="btn btn--primary btn--block">Add Transaction</button>
    </form>
  `, (data) => {
      if (!data.category || data.category === "other") {
        data.category = autoCategorizeExpense(data.note);
      }
      addExpense(data);
      document.getElementById("overlay").click();
      document.getElementById("main-content").dispatchEvent(new Event("refresh"));
    });
    setTimeout(() => {
      document.getElementById("expense-note")?.addEventListener("input", (e) => {
        const cat = autoCategorizeExpense(e.target.value);
        const sel = document.getElementById("expense-category");
        if (sel) sel.value = cat;
      });
    }, 50);
  }
  function getMonthSpend() {
    const monthExp = getMonthExpenses().filter((e) => e.type === "expense");
    return monthExp.reduce((s, e) => s + e.amount, 0);
  }

  // js/pages/home.js
  function renderHome(container) {
    const state2 = getState();
    const today = (/* @__PURE__ */ new Date()).toISOString().slice(0, 10);
    const currency = state2.user.currency;
    const todayTasks = state2.tasks.filter((t) => !t.isCompleted && t.dueDate === today);
    const overdueTasks = state2.tasks.filter((t) => isOverdue(t.dueDate, t.isCompleted));
    const upcomingTasks = state2.tasks.filter((t) => !t.isCompleted && t.dueDate && t.dueDate > today).slice(0, 3);
    const completedToday = state2.tasks.filter((t) => t.isCompleted && t.dueDate === today).length;
    const totalToday = todayTasks.length + completedToday;
    const completionPct = totalToday ? Math.round(completedToday / totalToday * 100) : 0;
    const recentNotes = [...state2.notes].sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt)).slice(0, 3);
    const monthSpend = getMonthSpend();
    const renewals = state2.resources.filter((r) => r.renewalDate && daysUntil(r.renewalDate) !== null && daysUntil(r.renewalDate) <= 7 && daysUntil(r.renewalDate) >= 0).sort((a, b) => daysUntil(a.renewalDate) - daysUntil(b.renewalDate));
    const lowStock = state2.resources.filter((r) => r.type === "inventory" && r.quantity !== null && r.quantity <= r.lowStockThreshold);
    container.innerHTML = `
    <div class="greeting">${getGreeting()} \u{1F44B}</div>
    <div class="greeting__sub">
      ${todayTasks.length ? `${todayTasks.length} task${todayTasks.length > 1 ? "s" : ""} due today` : "All clear for today"}
      ${state2.user.streak > 0 ? `<span class="streak-badge" style="margin-left:8px"><i data-lucide="flame"></i> ${state2.user.streak} day streak</span>` : ""}
    </div>

    ${renewals.length || lowStock.length ? `
      <div class="section">
        ${renewals.map((r) => {
      const days = daysUntil(r.renewalDate);
      return `<div class="alert alert--${days <= 2 ? "danger" : "warning"}">
            <i data-lucide="bell"></i>
            <span><strong>${escapeHtml(r.name)}</strong> renews ${days === 0 ? "today" : `in ${days} day${days > 1 ? "s" : ""}`}</span>
          </div>`;
    }).join("")}
        ${lowStock.map((r) => `
          <div class="alert alert--warning">
            <i data-lucide="package"></i>
            <span><strong>${escapeHtml(r.name)}</strong> \u2014 low stock (${r.quantity} left)</span>
          </div>
        `).join("")}
      </div>
    ` : ""}

    <div class="stats-grid">
      <div class="stat-card" style="cursor:pointer" data-nav="tasks">
        <div style="display:flex;align-items:center;gap:12px">
          <div class="progress-ring">
            <svg width="80" height="80" viewBox="0 0 80 80">
              <circle cx="40" cy="40" r="34" fill="none" stroke="var(--border)" stroke-width="6"/>
              <circle cx="40" cy="40" r="34" fill="none" stroke="var(--primary)" stroke-width="6"
                stroke-dasharray="${2 * Math.PI * 34}" stroke-dashoffset="${2 * Math.PI * 34 * (1 - completionPct / 100)}"
                stroke-linecap="round" transform="rotate(-90 40 40)"/>
            </svg>
            <div class="progress-ring__text">${completionPct}%</div>
          </div>
          <div>
            <div class="stat-card__label">Today's Progress</div>
            <div style="font-size:0.8125rem;color:var(--text-secondary);margin-top:2px">${completedToday}/${totalToday || 0} done</div>
          </div>
        </div>
      </div>
      <div class="stat-card" style="cursor:pointer" data-nav="expenses">
        <div class="stat-card__value negative">${formatCurrency(monthSpend, currency)}</div>
        <div class="stat-card__label">Spent this month</div>
      </div>
    </div>

    ${overdueTasks.length ? `
      <div class="section">
        <div class="card__header"><span class="card__title" style="color:var(--danger)">Overdue</span></div>
        ${overdueTasks.slice(0, 3).map((t) => `
          <div class="task-item" data-task="${t.id}" tabindex="0">
            <div class="task-check" data-action="toggle"></div>
            <div class="task-item__content">
              <div class="task-item__title">${escapeHtml(t.title)}</div>
              <div class="task-item__meta overdue">${formatDate(t.dueDate)}</div>
            </div>
          </div>
        `).join("")}
      </div>
    ` : ""}

    <div class="section">
      <div class="card__header">
        <span class="card__title">Today's Tasks</span>
        <button class="btn btn--sm btn--ghost" data-nav="tasks">View all</button>
      </div>
      ${todayTasks.length ? todayTasks.map((t) => `
        <div class="task-item" data-task="${t.id}" tabindex="0">
          <div class="task-check" data-action="toggle"></div>
          <div class="task-item__content">
            <div class="task-item__title">${escapeHtml(t.title)}</div>
            <div class="task-item__meta">
              <span class="priority priority--${t.priority}"></span>
              ${t.dueTime || ""}
              ${t.tags.map((tag) => `<span class="tag">#${escapeHtml(tag)}</span>`).join("")}
            </div>
          </div>
        </div>
      `).join("") : `<p style="color:var(--text-secondary);font-size:0.875rem;padding:8px 0">No tasks due today \u{1F389}</p>`}
    </div>

    ${upcomingTasks.length ? `
      <div class="section">
        <div class="card__header"><span class="card__title">Upcoming</span></div>
        ${upcomingTasks.map((t) => `
            <div class="task-item" data-task="${t.id}" tabindex="0">
            <div class="task-check"></div>
            <div class="task-item__content">
              <div class="task-item__title">${escapeHtml(t.title)}</div>
              <div class="task-item__meta">${formatDate(t.dueDate)}</div>
            </div>
          </div>
        `).join("")}
      </div>
    ` : ""}

    <div class="section">
      <div class="card__header">
        <span class="card__title">Recent Notes</span>
        <button class="btn btn--sm btn--ghost" data-nav="notes">View all</button>
      </div>
      ${recentNotes.length ? recentNotes.map((n) => `
        <div class="note-item" data-note="${n.id}" tabindex="0">
          <div class="note-item__title">${n.pinned ? "\u{1F4CC} " : ""}${escapeHtml(n.title)}</div>
          <div class="note-item__preview">${escapeHtml(n.body.slice(0, 80))}</div>
        </div>
      `).join("") : `<p style="color:var(--text-secondary);font-size:0.875rem;padding:8px 0">No notes yet</p>`}
    </div>
  `;
    container.querySelectorAll("[data-nav]").forEach((el) => {
      el.addEventListener("click", () => {
        document.querySelector(`[data-tab="${el.dataset.nav}"]`)?.click();
      });
    });
    container.querySelectorAll('[data-action="toggle"]').forEach((el) => {
      el.addEventListener("click", (e) => {
        e.stopPropagation();
        const taskId = el.closest("[data-task]")?.dataset.task;
        if (taskId) {
          Promise.resolve().then(() => (init_store(), store_exports)).then(({ toggleTask: toggleTask2 }) => {
            toggleTask2(taskId);
            document.getElementById("main-content").dispatchEvent(new Event("refresh"));
          });
        }
      });
    });
    refreshIcons();
  }

  // js/pages/tasks.js
  init_store();
  var currentView = "list";
  function renderTasks(container) {
    const state2 = getState();
    const tasks = [...state2.tasks].sort((a, b) => a.order - b.order);
    container.innerHTML = `
    <div class="view-toggle">
      <button class="view-toggle__btn ${currentView === "list" ? "active" : ""}" data-view="list">List</button>
      <button class="view-toggle__btn ${currentView === "kanban" ? "active" : ""}" data-view="kanban">Kanban</button>
      <button class="view-toggle__btn ${currentView === "calendar" ? "active" : ""}" data-view="calendar">Calendar</button>
    </div>
    <div id="tasks-view"></div>
  `;
    container.querySelectorAll(".view-toggle__btn").forEach((btn) => {
      btn.addEventListener("click", () => {
        currentView = btn.dataset.view;
        renderTasks(container);
      });
    });
    const viewEl = container.querySelector("#tasks-view");
    if (currentView === "list") renderListView(viewEl, tasks);
    else if (currentView === "kanban") renderKanbanView(viewEl, tasks);
    else renderCalendarView(viewEl, tasks);
  }
  function renderListView(el, tasks) {
    const active = tasks.filter((t) => !t.isCompleted);
    const done = tasks.filter((t) => t.isCompleted);
    if (tasks.length === 0) {
      el.innerHTML = emptyState("check-square", "No tasks yet", "Add your first task to get started.", "Add Task", () => showAddTask());
      bindEmptyAction(() => showAddTask());
      return;
    }
    el.innerHTML = `
    ${active.length ? `<div class="section"><div class="section__title">Active (${active.length})</div>${active.map(renderTaskItem).join("")}</div>` : ""}
    ${done.length ? `<div class="section"><div class="section__title">Completed (${done.length})</div>${done.map(renderTaskItem).join("")}</div>` : ""}
  `;
    bindTaskEvents(el);
  }
  function renderTaskItem(task) {
    const overdue = isOverdue(task.dueDate, task.isCompleted);
    return `
    <div class="task-item ${task.isCompleted ? "completed" : ""}" data-id="${task.id}" tabindex="0">
      <div class="task-check ${task.isCompleted ? "checked" : ""}" data-action="toggle">
        ${task.isCompleted ? '<i data-lucide="check"></i>' : ""}
      </div>
      <div class="task-item__content">
        <div class="task-item__title">${escapeHtml(task.title)}</div>
        <div class="task-item__meta ${overdue ? "overdue" : ""}">
          <span class="priority priority--${task.priority}"></span>
          ${task.dueDate ? `<span>${formatDate(task.dueDate)}${task.dueTime ? " " + task.dueTime : ""}</span>` : ""}
          ${task.tags.map((t) => `<span class="tag">#${escapeHtml(t)}</span>`).join("")}
          ${task.subtasks?.length ? `<span>${task.subtasks.filter((s) => s.done).length}/${task.subtasks.length} subtasks</span>` : ""}
        </div>
      </div>
    </div>
  `;
  }
  function bindTaskEvents(el) {
    el.querySelectorAll(".task-item").forEach((item) => {
      const id = item.dataset.id;
      item.querySelector('[data-action="toggle"]')?.addEventListener("click", (e) => {
        e.stopPropagation();
        toggleTask(id);
        renderTasks(document.getElementById("main-content"));
      });
      item.addEventListener("click", () => showTaskDetail(id));
      item.addEventListener("keydown", (e) => {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          showTaskDetail(id);
        }
      });
    });
  }
  function renderKanbanView(el, tasks) {
    const cols = { urgent: [], high: [], medium: [], low: [] };
    tasks.filter((t) => !t.isCompleted).forEach((t) => {
      (cols[t.priority] || cols.medium).push(t);
    });
    el.innerHTML = `<div class="kanban">${Object.entries(cols).map(([pri, items]) => `
    <div class="kanban__col">
      <div class="kanban__col-title"><span class="priority priority--${pri}"></span> ${pri}</div>
      ${items.map((t) => `<div class="kanban__card" data-id="${t.id}">${escapeHtml(t.title)}</div>`).join("")}
    </div>
  `).join("")}</div>`;
    el.querySelectorAll(".kanban__card").forEach((card) => {
      card.addEventListener("click", () => showTaskDetail(card.dataset.id));
    });
  }
  function renderCalendarView(el, tasks) {
    const now = /* @__PURE__ */ new Date();
    const year = now.getFullYear();
    const month = now.getMonth();
    const firstDay = new Date(year, month, 1).getDay();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const todayStr = now.toISOString().slice(0, 10);
    const taskDates = new Set(tasks.filter((t) => t.dueDate).map((t) => t.dueDate));
    let html = `<div class="section__title">${now.toLocaleDateString("en-US", { month: "long", year: "numeric" })}</div>`;
    html += '<div class="calendar-grid">';
    ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"].forEach((d) => {
      html += `<div class="calendar-grid__head">${d}</div>`;
    });
    for (let i = 0; i < firstDay; i++) html += "<div></div>";
    for (let d = 1; d <= daysInMonth; d++) {
      const dateStr = `${year}-${String(month + 1).padStart(2, "0")}-${String(d).padStart(2, "0")}`;
      const isToday = dateStr === todayStr;
      const hasTasks = taskDates.has(dateStr);
      html += `<div class="calendar-grid__day ${isToday ? "today" : ""} ${hasTasks ? "has-tasks" : ""}" data-date="${dateStr}">${d}</div>`;
    }
    html += "</div>";
    const dayTasks = tasks.filter((t) => t.dueDate?.startsWith(`${year}-${String(month + 1).padStart(2, "0")}`));
    if (dayTasks.length) {
      html += `<div class="section" style="margin-top:16px"><div class="section__title">This month</div>${dayTasks.map(renderTaskItem).join("")}</div>`;
    }
    el.innerHTML = html;
    bindTaskEvents(el);
  }
  function showTaskDetail(id) {
    const task = getState().tasks.find((t) => t.id === id);
    if (!task) return;
    openBottomSheet("Task Details", `
    <form id="task-edit-form">
      <div class="form-group">
        <label class="form-label">Title</label>
        <input class="form-input" name="title" value="${escapeHtml(task.title)}" required />
      </div>
      <div class="form-group">
        <label class="form-label">Description</label>
        <textarea class="form-textarea" name="description">${escapeHtml(task.description || "")}</textarea>
      </div>
      <div class="form-group">
        <label class="form-label">Due Date</label>
        <input class="form-input" type="date" name="dueDate" value="${task.dueDate || ""}" />
      </div>
      <div class="form-group">
        <label class="form-label">Priority</label>
        <select class="form-select" name="priority">
          ${["low", "medium", "high", "urgent"].map((p) => `<option value="${p}" ${task.priority === p ? "selected" : ""}>${p.charAt(0).toUpperCase() + p.slice(1)}</option>`).join("")}
        </select>
      </div>
      <div style="display:flex;gap:8px;margin-top:16px">
        <button type="submit" class="btn btn--primary" style="flex:1">Save</button>
        <button type="button" class="btn btn--danger" id="delete-task">Delete</button>
      </div>
    </form>
  `, (data) => {
      updateTask(id, data);
      document.getElementById("main-content").dispatchEvent(new Event("refresh"));
    });
    setTimeout(() => {
      document.getElementById("delete-task")?.addEventListener("click", () => {
        deleteTask(id);
        document.getElementById("overlay").click();
        document.getElementById("main-content").dispatchEvent(new Event("refresh"));
      });
    }, 50);
  }
  function showAddTask(prefill = "") {
    openBottomSheet("Add Task", `
    <form id="add-task-form">
      <div class="form-group">
        <label class="form-label">Quick add (natural language)</label>
        <input class="form-input" name="raw" placeholder='Pay rent tomorrow 6pm #bills' value="${escapeHtml(prefill)}" autofocus />
        <small style="color:var(--text-secondary);font-size:0.75rem;margin-top:4px;display:block">Try: "Team meeting Friday 3pm #work urgent"</small>
      </div>
      <div class="form-group">
        <label class="form-label">Or fill manually</label>
        <input class="form-input" name="title" placeholder="Task title" />
      </div>
      <div class="form-group">
        <label class="form-label">Due Date</label>
        <input class="form-input" type="date" name="dueDate" />
      </div>
      <div class="form-group">
        <label class="form-label">Priority</label>
        <select class="form-select" name="priority">
          <option value="low">Low</option>
          <option value="medium" selected>Medium</option>
          <option value="high">High</option>
          <option value="urgent">Urgent</option>
        </select>
      </div>
      <button type="submit" class="btn btn--primary btn--block">Add Task</button>
    </form>
  `, (data) => {
      if (data.raw) {
        const parsed = parseNaturalLanguage(data.raw);
        addTask(parsed);
      } else if (data.title) {
        addTask({ title: data.title, dueDate: data.dueDate || null, priority: data.priority });
      }
      document.getElementById("overlay").click();
      document.getElementById("main-content").dispatchEvent(new Event("refresh"));
    });
  }

  // js/pages/notes.js
  init_store();
  var currentFolder = "all";
  var searchQuery = "";
  function renderNotes(container) {
    const state2 = getState();
    let notes = [...state2.notes];
    if (currentFolder !== "all") notes = notes.filter((n) => n.folderId === currentFolder);
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      notes = notes.filter((n) => n.title.toLowerCase().includes(q) || n.body.toLowerCase().includes(q));
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
      <button class="folder-chip ${currentFolder === "all" ? "active" : ""}" data-folder="all">All</button>
      ${state2.noteFolders.map((f) => `
        <button class="folder-chip ${currentFolder === f.id ? "active" : ""}" data-folder="${f.id}">${escapeHtml(f.name)}</button>
      `).join("")}
    </div>
    <div id="notes-list"></div>
  `;
    container.querySelector("#note-search")?.addEventListener("input", (e) => {
      searchQuery = e.target.value;
      renderNotes(container);
    });
    container.querySelectorAll(".folder-chip").forEach((chip) => {
      chip.addEventListener("click", () => {
        currentFolder = chip.dataset.folder;
        renderNotes(container);
      });
    });
    const listEl = container.querySelector("#notes-list");
    if (notes.length === 0) {
      listEl.innerHTML = emptyState("file-text", "No notes yet", "Capture ideas, meeting notes, or journal entries.", "Add Note", () => showAddNote());
      bindEmptyAction(() => showAddNote());
      return;
    }
    listEl.innerHTML = notes.map((note) => `
    <div class="note-item ${note.pinned ? "pinned" : ""}" data-id="${note.id}" tabindex="0">
      <div class="note-item__title">${note.pinned ? "\u{1F4CC} " : ""}${escapeHtml(note.title)}</div>
      <div class="note-item__preview">${escapeHtml(stripMarkdown(note.body).slice(0, 100))}</div>
      <div class="note-item__meta">
        <span>${new Date(note.updatedAt).toLocaleDateString()}</span>
        ${note.tags.map((t) => `<span class="tag">#${escapeHtml(t)}</span>`).join("")}
      </div>
    </div>
  `).join("");
    listEl.querySelectorAll(".note-item").forEach((item) => {
      item.addEventListener("click", () => showNoteEditor(item.dataset.id));
      item.addEventListener("keydown", (e) => {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          showNoteEditor(item.dataset.id);
        }
      });
    });
  }
  function showNoteEditor(id) {
    const note = getState().notes.find((n) => n.id === id);
    if (!note) return;
    openModal(note.title, `
    <div style="margin-bottom:12px;display:flex;gap:8px">
      <button class="btn btn--sm btn--ghost" id="pin-note">${note.pinned ? "Unpin" : "Pin"}</button>
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
        ${getState().noteFolders.map((f) => `<option value="${f.id}" ${note.folderId === f.id ? "selected" : ""}>${escapeHtml(f.name)}</option>`).join("")}
      </select>
    </div>
    <div id="note-preview" style="margin-bottom:16px;padding:12px;background:var(--bg);border-radius:var(--radius-md);font-size:0.875rem"></div>
    <button class="btn btn--primary btn--block" id="save-note">Save</button>
  `);
    const preview = document.getElementById("note-preview");
    const bodyEl = document.getElementById("edit-note-body");
    const updatePreview = () => {
      preview.innerHTML = renderMarkdown(bodyEl.value);
    };
    bodyEl.addEventListener("input", updatePreview);
    updatePreview();
    document.getElementById("pin-note")?.addEventListener("click", () => {
      togglePinNote(id);
      document.getElementById("modal-close")?.click();
      document.getElementById("main-content").dispatchEvent(new Event("refresh"));
    });
    document.getElementById("delete-note")?.addEventListener("click", () => {
      deleteNote(id);
      document.getElementById("modal-close")?.click();
      document.getElementById("main-content").dispatchEvent(new Event("refresh"));
    });
    document.getElementById("save-note")?.addEventListener("click", () => {
      updateNote(id, {
        title: document.getElementById("edit-note-title").value,
        body: bodyEl.value,
        folderId: document.getElementById("edit-note-folder").value
      });
      document.getElementById("modal-close")?.click();
      document.getElementById("main-content").dispatchEvent(new Event("refresh"));
    });
  }
  function showAddNote(templateKey) {
    const tmpl = templateKey ? NOTE_TEMPLATES[templateKey] : null;
    openBottomSheet("Add Note", `
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
      ` : ""}
      <div class="form-group">
        <label class="form-label">Title</label>
        <input class="form-input" name="title" value="${tmpl ? escapeHtml(tmpl.title) : ""}" placeholder="Note title" required />
      </div>
      <div class="form-group">
        <label class="form-label">Body</label>
        <textarea class="form-textarea" name="body" placeholder="Start writing...">${tmpl ? escapeHtml(tmpl.body) : ""}</textarea>
      </div>
      <div class="form-group">
        <label class="form-label">Folder</label>
        <select class="form-select" name="folderId">
          ${getState().noteFolders.map((f) => `<option value="${f.id}">${escapeHtml(f.name)}</option>`).join("")}
        </select>
      </div>
      <button type="submit" class="btn btn--primary btn--block">Create Note</button>
    </form>
  `, (data) => {
      addNote(data);
      document.getElementById("overlay").click();
      document.getElementById("main-content").dispatchEvent(new Event("refresh"));
    });
    setTimeout(() => {
      document.getElementById("note-template-select")?.addEventListener("change", (e) => {
        const t = NOTE_TEMPLATES[e.target.value];
        if (t) {
          document.querySelector('[name="title"]').value = t.title;
          document.querySelector('[name="body"]').value = t.body;
        }
      });
    }, 50);
  }

  // js/pages/resources.js
  init_store();
  var currentType = "all";
  function renderResources(container) {
    const state2 = getState();
    let resources = [...state2.resources];
    if (currentType !== "all") resources = resources.filter((r) => r.type === currentType);
    container.innerHTML = `
    <div class="resource-tabs">
      <button class="resource-tab ${currentType === "all" ? "active" : ""}" data-type="all">All</button>
      ${Object.entries(RESOURCE_TYPES).map(([key, val]) => `
        <button class="resource-tab ${currentType === key ? "active" : ""}" data-type="${key}">${val.label}</button>
      `).join("")}
    </div>
    <div id="resources-list"></div>
  `;
    container.querySelectorAll(".resource-tab").forEach((tab) => {
      tab.addEventListener("click", () => {
        currentType = tab.dataset.type;
        renderResources(container);
      });
    });
    const listEl = container.querySelector("#resources-list");
    if (resources.length === 0) {
      listEl.innerHTML = emptyState("folder-lock", "No resources yet", "Store documents, track subscriptions, manage inventory, and save important contacts.", "Add Resource", () => showAddResource());
      bindEmptyAction(() => showAddResource());
      return;
    }
    listEl.innerHTML = resources.map(renderResourceItem).join("");
    listEl.querySelectorAll(".resource-item").forEach((item) => {
      item.addEventListener("click", () => showResourceDetail(item.dataset.id));
      item.addEventListener("keydown", (e) => {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          showResourceDetail(item.dataset.id);
        }
      });
    });
    refreshIcons();
  }
  function renderResourceItem(r) {
    const typeInfo = RESOURCE_TYPES[r.type] || { icon: "file", label: r.type };
    let sub = "";
    if (r.type === "subscription") {
      const days = daysUntil(r.renewalDate);
      const cost = r.details?.cost;
      sub = `${cost ? formatCurrency(cost, getState().user.currency) + "/mo \xB7 " : ""}${days !== null ? days <= 0 ? "Renews today" : `Renews in ${days}d` : "No renewal date"}`;
    } else if (r.type === "inventory") {
      sub = `Qty: ${r.quantity ?? "?"}${r.quantity <= r.lowStockThreshold ? " \xB7 \u26A0\uFE0F Low stock" : ""}`;
    } else if (r.type === "contact") {
      sub = r.details?.phone || r.details?.email || "";
    } else if (r.type === "document") {
      sub = r.details?.expiry ? `Expires: ${r.details.expiry}` : r.tags?.join(", ") || "Document";
    }
    return `
    <div class="resource-item" data-id="${r.id}" style="cursor:pointer" tabindex="0">
      <div class="resource-item__icon"><i data-lucide="${typeInfo.icon}"></i></div>
      <div class="resource-item__content">
        <div class="resource-item__title">${escapeHtml(r.name)}</div>
        <div class="resource-item__sub">${escapeHtml(sub)}</div>
      </div>
      <i data-lucide="chevron-right" style="color:var(--text-secondary);width:18px;height:18px"></i>
    </div>
  `;
  }
  function showResourceDetail(id) {
    const r = getState().resources.find((x) => x.id === id);
    if (!r) return;
    const detailsHtml = Object.entries(r.details || {}).map(
      ([k, v]) => `<div style="display:flex;justify-content:space-between;padding:8px 0;border-bottom:1px solid var(--border)">
      <span style="color:var(--text-secondary);font-size:0.8125rem;text-transform:capitalize">${escapeHtml(k)}</span>
      <span style="font-size:0.875rem">${escapeHtml(String(v))}</span>
    </div>`
    ).join("");
    openBottomSheet(r.name, `
    <div style="margin-bottom:16px">
      <span class="tag">${RESOURCE_TYPES[r.type]?.label || r.type}</span>
      ${r.tags?.map((t) => `<span class="tag">#${escapeHtml(t)}</span>`).join("") || ""}
    </div>
    ${detailsHtml || '<p style="color:var(--text-secondary)">No additional details</p>'}
    ${r.renewalDate ? `<p style="margin-top:12px;font-size:0.875rem">Renewal: <strong>${r.renewalDate}</strong></p>` : ""}
    ${r.quantity !== null ? `<p style="margin-top:8px;font-size:0.875rem">Quantity: <strong>${r.quantity}</strong></p>` : ""}
    <div style="display:flex;gap:8px;margin-top:20px">
      <button class="btn btn--secondary" style="flex:1" id="edit-resource">Edit</button>
      <button class="btn btn--danger" id="delete-resource">Delete</button>
    </div>
  `);
    setTimeout(() => {
      document.getElementById("delete-resource")?.addEventListener("click", () => {
        deleteResource(id);
        document.getElementById("overlay").click();
        document.getElementById("main-content").dispatchEvent(new Event("refresh"));
      });
      document.getElementById("edit-resource")?.addEventListener("click", () => {
        document.getElementById("overlay").click();
        showAddResource(r);
      });
    }, 50);
  }
  function showAddResource(existing) {
    const r = existing || {};
    openBottomSheet(existing ? "Edit Resource" : "Add Resource", `
    <form id="add-resource-form">
      <div class="form-group">
        <label class="form-label">Type</label>
        <select class="form-select" name="type" id="resource-type">
          ${Object.entries(RESOURCE_TYPES).map(([k, v]) => `<option value="${k}" ${r.type === k ? "selected" : ""}>${v.label}</option>`).join("")}
        </select>
      </div>
      <div class="form-group">
        <label class="form-label">Name</label>
        <input class="form-input" name="name" value="${escapeHtml(r.name || "")}" required />
      </div>
      <div id="type-fields">
        ${getTypeFields(r.type || "document", r)}
      </div>
      <div class="form-group">
        <label class="form-label">Tags (comma separated)</label>
        <input class="form-input" name="tags" value="${(r.tags || []).join(", ")}" placeholder="work, important" />
      </div>
      <button type="submit" class="btn btn--primary btn--block">${existing ? "Save" : "Add Resource"}</button>
    </form>
  `, (data) => {
      const type = data.type;
      const details = {};
      if (type === "subscription") {
        details.plan = data.plan || "";
        details.cost = parseFloat(data.cost) || 0;
      } else if (type === "document") {
        details.number = data.docNumber || "";
        details.expiry = data.expiry || "";
      } else if (type === "inventory") {
        details.location = data.location || "";
      } else if (type === "contact") {
        details.phone = data.phone || "";
        details.email = data.email || "";
        details.role = data.role || "";
      }
      const payload = {
        type,
        name: data.name,
        details,
        renewalDate: data.renewalDate || null,
        quantity: type === "inventory" ? parseInt(data.quantity) || 0 : null,
        lowStockThreshold: parseInt(data.lowStockThreshold) || 5,
        tags: data.tags ? data.tags.split(",").map((t) => t.trim()).filter(Boolean) : []
      };
      if (existing) updateResource(existing.id, payload);
      else addResource(payload);
      document.getElementById("overlay").click();
      document.getElementById("main-content").dispatchEvent(new Event("refresh"));
    });
    setTimeout(() => {
      document.getElementById("resource-type")?.addEventListener("change", (e) => {
        document.getElementById("type-fields").innerHTML = getTypeFields(e.target.value, {});
      });
    }, 50);
  }
  function getTypeFields(type, r) {
    const d = r.details || {};
    switch (type) {
      case "subscription":
        return `
        <div class="form-group"><label class="form-label">Plan</label><input class="form-input" name="plan" value="${escapeHtml(d.plan || "")}" /></div>
        <div class="form-group"><label class="form-label">Monthly Cost</label><input class="form-input" type="number" name="cost" value="${d.cost || ""}" step="0.01" /></div>
        <div class="form-group"><label class="form-label">Renewal Date</label><input class="form-input" type="date" name="renewalDate" value="${r.renewalDate || ""}" /></div>
      `;
      case "document":
        return `
        <div class="form-group"><label class="form-label">Reference Number</label><input class="form-input" name="docNumber" value="${escapeHtml(d.number || "")}" /></div>
        <div class="form-group"><label class="form-label">Expiry Date</label><input class="form-input" type="date" name="expiry" value="${d.expiry || ""}" /></div>
      `;
      case "inventory":
        return `
        <div class="form-group"><label class="form-label">Quantity</label><input class="form-input" type="number" name="quantity" value="${r.quantity ?? ""}" min="0" /></div>
        <div class="form-group"><label class="form-label">Low Stock Alert</label><input class="form-input" type="number" name="lowStockThreshold" value="${r.lowStockThreshold ?? 5}" min="0" /></div>
        <div class="form-group"><label class="form-label">Location</label><input class="form-input" name="location" value="${escapeHtml(d.location || "")}" /></div>
      `;
      case "contact":
        return `
        <div class="form-group"><label class="form-label">Phone</label><input class="form-input" name="phone" value="${escapeHtml(d.phone || "")}" /></div>
        <div class="form-group"><label class="form-label">Email</label><input class="form-input" name="email" type="email" value="${escapeHtml(d.email || "")}" /></div>
        <div class="form-group"><label class="form-label">Role</label><input class="form-input" name="role" value="${escapeHtml(d.role || "")}" /></div>
      `;
      default:
        return "";
    }
  }

  // js/app.js
  var TITLES = { home: "Home", tasks: "Tasks", notes: "Notes", expenses: "Expenses", resources: "Resources" };
  var currentTab2 = "home";
  function getResolvedTheme(theme) {
    return theme === "auto" ? window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light" : theme;
  }
  function applyTheme(theme) {
    const resolved = getResolvedTheme(theme);
    document.documentElement.dataset.theme = resolved;
    document.body.dataset.theme = resolved;
    const themeBtn = document.getElementById("btn-theme");
    if (themeBtn) {
      const icon = themeBtn.querySelector("i");
      if (icon) {
        icon.setAttribute("data-lucide", resolved === "dark" ? "moon" : "sun");
        if (typeof window !== "undefined" && window.lucide && typeof window.lucide.createIcons === "function") {
          window.lucide.createIcons();
        }
      }
    }
  }
  function toggleTheme() {
    const currentTheme = getState().user.theme;
    const resolved = getResolvedTheme(currentTheme);
    const nextTheme = resolved === "dark" ? "light" : "dark";
    updateUser({ theme: nextTheme });
    applyTheme(nextTheme);
  }
  function navigate(tab) {
    currentTab2 = tab;
    document.getElementById("page-title").textContent = TITLES[tab] || "Nexa";
    document.querySelectorAll(".bottom-nav__item").forEach((btn) => {
      btn.classList.toggle("active", btn.dataset.tab === tab);
    });
    renderCurrentPage();
  }
  function renderCurrentPage() {
    const container = document.getElementById("main-content");
    switch (currentTab2) {
      case "home":
        renderHome(container);
        break;
      case "tasks":
        renderTasks(container);
        break;
      case "notes":
        renderNotes(container);
        break;
      case "expenses":
        renderExpenses(container);
        break;
      case "resources":
        renderResources(container);
        break;
    }
    refreshIcons();
  }
  function handleFabClick() {
    if (currentTab2 === "home") {
      showQuickMenu([
        { action: "task", icon: "check-square", label: "Add Task" },
        { action: "note", icon: "file-text", label: "Add Note" },
        { action: "expense", icon: "wallet", label: "Add Expense" },
        { action: "resource", icon: "folder-lock", label: "Add Resource" }
      ], (action) => {
        closeAll();
        switch (action) {
          case "task":
            showAddTask();
            break;
          case "note":
            showAddNote();
            break;
          case "expense":
            showAddExpense();
            break;
          case "resource":
            showAddResource();
            break;
        }
      });
    } else {
      switch (currentTab2) {
        case "tasks":
          showAddTask();
          break;
        case "notes":
          showAddNote();
          break;
        case "expenses":
          showAddExpense();
          break;
        case "resources":
          showAddResource();
          break;
      }
    }
  }
  function openSearch() {
    const panel = document.getElementById("search-panel");
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
    requestAnimationFrame(() => panel.classList.add("visible"));
    refreshIcons();
    document.getElementById("close-search").addEventListener("click", closeSearch);
    document.getElementById("global-search-input").addEventListener("input", (e) => {
      renderSearchResults(e.target.value);
    });
  }
  function handleGlobalShortcuts(e) {
    const tag = e.target?.tagName?.toLowerCase();
    if (tag === "input" || tag === "textarea" || e.target?.isContentEditable) return;
    if (e.key === "/") {
      e.preventDefault();
      openSearch();
      setTimeout(() => document.getElementById("global-search-input")?.focus(), 60);
      return;
    }
    if (e.key === "t") {
      e.preventDefault();
      navigate("tasks");
      setTimeout(() => showAddTask(), 60);
      return;
    }
    if (e.key === "n") {
      e.preventDefault();
      navigate("notes");
      setTimeout(() => showAddNote(), 60);
      return;
    }
    if (e.key === "e") {
      e.preventDefault();
      navigate("expenses");
      setTimeout(() => showAddExpense(), 60);
      return;
    }
    if (e.key === "r") {
      e.preventDefault();
      navigate("resources");
      setTimeout(() => showAddResource(), 60);
      return;
    }
  }
  function closeSearch() {
    const panel = document.getElementById("search-panel");
    panel.classList.remove("visible");
    setTimeout(() => {
      panel.hidden = true;
    }, 250);
  }
  function renderSearchResults(query) {
    const el = document.getElementById("search-results");
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
    let html = "";
    const addGroup = (type, items, icon, labelFn) => {
      if (!items.length) return;
      html += `<div class="section"><div class="section__title">${type}</div>`;
      items.forEach((item) => {
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
      html += "</div>";
    };
    addGroup("Tasks", results.tasks, "check-square", (t) => t.title);
    addGroup("Notes", results.notes, "file-text", (n) => n.title);
    addGroup("Expenses", results.expenses, "wallet", (e) => `${e.note || e.category} \u2014 $${e.amount}`);
    addGroup("Resources", results.resources, "folder-lock", (r) => r.name);
    el.innerHTML = html;
    refreshIcons();
    el.querySelectorAll(".search-result").forEach((result) => {
      result.addEventListener("click", () => {
        closeSearch();
        const typeMap = { task: "tasks", note: "notes", expense: "expenses", resource: "resources" };
        const tab = typeMap[result.dataset.type];
        if (tab) navigate(tab);
      });
    });
  }
  function openSettings() {
    const user = getState().user;
    openModal("Settings", `
    <div class="settings-group">
      <div class="settings-group__title">Appearance</div>
      <div class="settings-item">
        <span class="settings-item__label">Theme</span>
        <select class="form-select" id="theme-select" style="width:auto">
          <option value="auto" ${user.theme === "auto" ? "selected" : ""}>System</option>
          <option value="light" ${user.theme === "light" ? "selected" : ""}>Light</option>
          <option value="dark" ${user.theme === "dark" ? "selected" : ""}>Dark</option>
        </select>
      </div>
    </div>
    <div class="settings-group">
      <div class="settings-group__title">Preferences</div>
      <div class="settings-item">
        <span class="settings-item__label">Currency</span>
        <select class="form-select" id="currency-select" style="width:auto">
          ${["USD", "EUR", "GBP", "INR", "PKR", "CAD", "AUD"].map(
      (c) => `<option value="${c}" ${user.currency === c ? "selected" : ""}>${c}</option>`
    ).join("")}
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
    <p style="text-align:center;color:var(--text-secondary);font-size:0.75rem;margin-top:16px">Nexa v1.0 \xB7 Offline-first productivity</p>
  `);
    refreshIcons();
    document.getElementById("theme-select")?.addEventListener("change", (e) => {
      updateUser({ theme: e.target.value });
      applyTheme(e.target.value);
    });
    document.getElementById("currency-select")?.addEventListener("change", (e) => {
      updateUser({ currency: e.target.value });
      renderCurrentPage();
    });
    document.getElementById("load-sample")?.addEventListener("click", () => {
      loadSampleData();
      document.getElementById("modal-close")?.click();
      renderCurrentPage();
    });
    document.getElementById("export-data")?.addEventListener("click", () => {
      const blob = new Blob([exportData()], { type: "application/json" });
      const a = document.createElement("a");
      a.href = URL.createObjectURL(blob);
      a.download = `nexa-export-${(/* @__PURE__ */ new Date()).toISOString().slice(0, 10)}.json`;
      a.click();
    });
    document.getElementById("clear-data")?.addEventListener("click", () => {
      if (confirm("Delete all data? This cannot be undone.")) {
        clearAllData();
        document.getElementById("modal-close")?.click();
        renderCurrentPage();
      }
    });
  }
  function showOnboarding() {
    const el = document.getElementById("onboarding");
    el.hidden = false;
    el.classList.add("visible");
    el.innerHTML = `
    <div class="onboarding__logo"><i data-lucide="sparkles"></i></div>
    <h1 class="onboarding__title">Welcome to Nexa</h1>
    <p class="onboarding__subtitle">Your all-in-one productivity hub \u2014 tasks, notes, expenses, and resources in one beautiful app.</p>
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
    document.getElementById("finish-onboarding").addEventListener("click", () => {
      updateUser({ onboarded: true });
      el.classList.remove("visible");
      el.hidden = true;
      renderCurrentPage();
    });
    document.getElementById("onboard-sample").addEventListener("click", () => {
      loadSampleData();
      updateUser({ onboarded: true });
      el.classList.remove("visible");
      el.hidden = true;
      renderCurrentPage();
    });
  }
  function setAppStatus(message, isError = false) {
    const status = document.getElementById("app-status");
    if (!status) return;
    status.textContent = message;
    status.classList.toggle("app-status--error", isError);
    status.hidden = !message;
  }
  function hideAppStatus() {
    setAppStatus("", false);
  }
  function init() {
    try {
      initUI();
      applyTheme(getState().user.theme);
      window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", () => {
        if (getState().user.theme === "auto") applyTheme("auto");
      });
      document.querySelectorAll(".bottom-nav__item").forEach((btn) => {
        btn.addEventListener("click", () => navigate(btn.dataset.tab));
      });
      document.getElementById("fab")?.addEventListener("click", handleFabClick);
      document.getElementById("btn-theme")?.addEventListener("click", toggleTheme);
      document.getElementById("btn-search")?.addEventListener("click", openSearch);
      document.getElementById("btn-settings")?.addEventListener("click", openSettings);
      document.addEventListener("keydown", handleGlobalShortcuts);
      document.getElementById("main-content")?.addEventListener("refresh", renderCurrentPage);
      subscribe(() => {
      });
      renderCurrentPage();
      if (!getState().user.onboarded) {
        showOnboarding();
      }
      refreshIcons();
      hideAppStatus();
    } catch (error) {
      console.error("Nexa startup failed", error);
      const main = document.getElementById("main-content");
      if (main) {
        main.innerHTML = `
        <div class="empty-state">
          <div class="empty-state__icon">\u26A0\uFE0F</div>
          <div class="empty-state__title">Unable to load the app</div>
          <div class="empty-state__text">Please refresh the page or clear your browser cache and try again.</div>
        </div>
      `;
      }
      setAppStatus("Unable to load the app. Please refresh the page.", true);
    }
  }
  window.addEventListener("error", (event) => {
    const message = event.error?.message || event.message;
    if (message && !message.includes("ResizeObserver loop")) {
      setAppStatus(`Something went wrong: ${message}`, true);
    }
  });
  window.addEventListener("unhandledrejection", (event) => {
    const message = event.reason?.message || String(event.reason || "Unknown error");
    if (message) {
      setAppStatus(`Something went wrong: ${message}`, true);
    }
  });
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
