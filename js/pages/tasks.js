import { getState, toggleTask, deleteTask, addTask, updateTask } from '../store.js';
import { formatDate, isOverdue, escapeHtml, parseNaturalLanguage } from '../utils.js';
import { openBottomSheet, emptyState, bindEmptyAction } from '../components/ui.js';

let currentView = 'list';

export function renderTasks(container) {
  const state = getState();
  const tasks = [...state.tasks].sort((a, b) => a.order - b.order);

  container.innerHTML = `
    <div class="view-toggle">
      <button class="view-toggle__btn ${currentView === 'list' ? 'active' : ''}" data-view="list">List</button>
      <button class="view-toggle__btn ${currentView === 'kanban' ? 'active' : ''}" data-view="kanban">Kanban</button>
      <button class="view-toggle__btn ${currentView === 'calendar' ? 'active' : ''}" data-view="calendar">Calendar</button>
    </div>
    <div id="tasks-view"></div>
  `;

  container.querySelectorAll('.view-toggle__btn').forEach(btn => {
    btn.addEventListener('click', () => {
      currentView = btn.dataset.view;
      renderTasks(container);
    });
  });

  const viewEl = container.querySelector('#tasks-view');
  if (currentView === 'list') renderListView(viewEl, tasks);
  else if (currentView === 'kanban') renderKanbanView(viewEl, tasks);
  else renderCalendarView(viewEl, tasks);
}

function renderListView(el, tasks) {
  const active = tasks.filter(t => !t.isCompleted);
  const done = tasks.filter(t => t.isCompleted);

  if (tasks.length === 0) {
    el.innerHTML = emptyState('check-square', 'No tasks yet', 'Add your first task to get started.', 'Add Task', () => showAddTask());
    bindEmptyAction(() => showAddTask());
    return;
  }

  el.innerHTML = `
    ${active.length ? `<div class="section"><div class="section__title">Active (${active.length})</div>${active.map(renderTaskItem).join('')}</div>` : ''}
    ${done.length ? `<div class="section"><div class="section__title">Completed (${done.length})</div>${done.map(renderTaskItem).join('')}</div>` : ''}
  `;
  bindTaskEvents(el);
}

function renderTaskItem(task) {
  const overdue = isOverdue(task.dueDate, task.isCompleted);
  return `
    <div class="task-item ${task.isCompleted ? 'completed' : ''}" data-id="${task.id}" tabindex="0">
      <div class="task-check ${task.isCompleted ? 'checked' : ''}" data-action="toggle">
        ${task.isCompleted ? '<i data-lucide="check"></i>' : ''}
      </div>
      <div class="task-item__content">
        <div class="task-item__title">${escapeHtml(task.title)}</div>
        <div class="task-item__meta ${overdue ? 'overdue' : ''}">
          <span class="priority priority--${task.priority}"></span>
          ${task.dueDate ? `<span>${formatDate(task.dueDate)}${task.dueTime ? ' ' + task.dueTime : ''}</span>` : ''}
          ${task.tags.map(t => `<span class="tag">#${escapeHtml(t)}</span>`).join('')}
          ${task.subtasks?.length ? `<span>${task.subtasks.filter(s => s.done).length}/${task.subtasks.length} subtasks</span>` : ''}
        </div>
      </div>
    </div>
  `;
}

function bindTaskEvents(el) {
  el.querySelectorAll('.task-item').forEach(item => {
    const id = item.dataset.id;
    item.querySelector('[data-action="toggle"]')?.addEventListener('click', e => {
      e.stopPropagation();
      toggleTask(id);
      renderTasks(document.getElementById('main-content'));
    });
    item.addEventListener('click', () => showTaskDetail(id));
    item.addEventListener('keydown', e => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        showTaskDetail(id);
      }
    });
  });
}

function renderKanbanView(el, tasks) {
  const cols = { urgent: [], high: [], medium: [], low: [] };
  tasks.filter(t => !t.isCompleted).forEach(t => {
    (cols[t.priority] || cols.medium).push(t);
  });

  el.innerHTML = `<div class="kanban">${Object.entries(cols).map(([pri, items]) => `
    <div class="kanban__col">
      <div class="kanban__col-title"><span class="priority priority--${pri}"></span> ${pri}</div>
      ${items.map(t => `<div class="kanban__card" data-id="${t.id}">${escapeHtml(t.title)}</div>`).join('')}
    </div>
  `).join('')}</div>`;

  el.querySelectorAll('.kanban__card').forEach(card => {
    card.addEventListener('click', () => showTaskDetail(card.dataset.id));
  });
}

function renderCalendarView(el, tasks) {
  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth();
  const firstDay = new Date(year, month, 1).getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const todayStr = now.toISOString().slice(0, 10);

  const taskDates = new Set(tasks.filter(t => t.dueDate).map(t => t.dueDate));

  let html = `<div class="section__title">${now.toLocaleDateString('en-US', { month: 'long', year: 'numeric' })}</div>`;
  html += '<div class="calendar-grid">';
  ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].forEach(d => {
    html += `<div class="calendar-grid__head">${d}</div>`;
  });
  for (let i = 0; i < firstDay; i++) html += '<div></div>';
  for (let d = 1; d <= daysInMonth; d++) {
    const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
    const isToday = dateStr === todayStr;
    const hasTasks = taskDates.has(dateStr);
    html += `<div class="calendar-grid__day ${isToday ? 'today' : ''} ${hasTasks ? 'has-tasks' : ''}" data-date="${dateStr}">${d}</div>`;
  }
  html += '</div>';

  const dayTasks = tasks.filter(t => t.dueDate?.startsWith(`${year}-${String(month + 1).padStart(2, '0')}`));
  if (dayTasks.length) {
    html += `<div class="section" style="margin-top:16px"><div class="section__title">This month</div>${dayTasks.map(renderTaskItem).join('')}</div>`;
  }

  el.innerHTML = html;
  bindTaskEvents(el);
}

function showTaskDetail(id) {
  const task = getState().tasks.find(t => t.id === id);
  if (!task) return;

  openBottomSheet('Task Details', `
    <form id="task-edit-form">
      <div class="form-group">
        <label class="form-label">Title</label>
        <input class="form-input" name="title" value="${escapeHtml(task.title)}" required />
      </div>
      <div class="form-group">
        <label class="form-label">Description</label>
        <textarea class="form-textarea" name="description">${escapeHtml(task.description || '')}</textarea>
      </div>
      <div class="form-group">
        <label class="form-label">Due Date</label>
        <input class="form-input" type="date" name="dueDate" value="${task.dueDate || ''}" />
      </div>
      <div class="form-group">
        <label class="form-label">Priority</label>
        <select class="form-select" name="priority">
          ${['low', 'medium', 'high', 'urgent'].map(p => `<option value="${p}" ${task.priority === p ? 'selected' : ''}>${p.charAt(0).toUpperCase() + p.slice(1)}</option>`).join('')}
        </select>
      </div>
      <div style="display:flex;gap:8px;margin-top:16px">
        <button type="submit" class="btn btn--primary" style="flex:1">Save</button>
        <button type="button" class="btn btn--danger" id="delete-task">Delete</button>
      </div>
    </form>
  `, (data) => {
    updateTask(id, data);
    document.getElementById('main-content').dispatchEvent(new Event('refresh'));
  });

  setTimeout(() => {
    document.getElementById('delete-task')?.addEventListener('click', () => {
      deleteTask(id);
      document.getElementById('overlay').click();
      document.getElementById('main-content').dispatchEvent(new Event('refresh'));
    });
  }, 50);
}

export function showAddTask(prefill = '') {
  openBottomSheet('Add Task', `
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
    document.getElementById('overlay').click();
    document.getElementById('main-content').dispatchEvent(new Event('refresh'));
  });
}
