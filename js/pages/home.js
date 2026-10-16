import { getState } from '../store.js';
import { formatDate, formatCurrency, getGreeting, isOverdue, daysUntil, escapeHtml, refreshIcons } from '../utils.js';
import { getMonthSpend } from './expenses.js';

export function renderHome(container) {
  const state = getState();
  const today = new Date().toISOString().slice(0, 10);
  const currency = state.user.currency;

  const todayTasks = state.tasks.filter(t => !t.isCompleted && t.dueDate === today);
  const overdueTasks = state.tasks.filter(t => isOverdue(t.dueDate, t.isCompleted));
  const upcomingTasks = state.tasks.filter(t => !t.isCompleted && t.dueDate && t.dueDate > today).slice(0, 3);
  const completedToday = state.tasks.filter(t => t.isCompleted && t.dueDate === today).length;
  const totalToday = todayTasks.length + completedToday;
  const completionPct = totalToday ? Math.round((completedToday / totalToday) * 100) : 0;

  const recentNotes = [...state.notes].sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt)).slice(0, 3);
  const monthSpend = getMonthSpend();

  const renewals = state.resources
    .filter(r => r.renewalDate && daysUntil(r.renewalDate) !== null && daysUntil(r.renewalDate) <= 7 && daysUntil(r.renewalDate) >= 0)
    .sort((a, b) => daysUntil(a.renewalDate) - daysUntil(b.renewalDate));

  const lowStock = state.resources.filter(r => r.type === 'inventory' && r.quantity !== null && r.quantity <= r.lowStockThreshold);

  container.innerHTML = `
    <div class="greeting">${getGreeting()} 👋</div>
    <div class="greeting__sub">
      ${todayTasks.length ? `${todayTasks.length} task${todayTasks.length > 1 ? 's' : ''} due today` : 'All clear for today'}
      ${state.user.streak > 0 ? `<span class="streak-badge" style="margin-left:8px"><i data-lucide="flame"></i> ${state.user.streak} day streak</span>` : ''}
    </div>

    ${renewals.length || lowStock.length ? `
      <div class="section">
        ${renewals.map(r => {
          const days = daysUntil(r.renewalDate);
          return `<div class="alert alert--${days <= 2 ? 'danger' : 'warning'}">
            <i data-lucide="bell"></i>
            <span><strong>${escapeHtml(r.name)}</strong> renews ${days === 0 ? 'today' : `in ${days} day${days > 1 ? 's' : ''}`}</span>
          </div>`;
        }).join('')}
        ${lowStock.map(r => `
          <div class="alert alert--warning">
            <i data-lucide="package"></i>
            <span><strong>${escapeHtml(r.name)}</strong> — low stock (${r.quantity} left)</span>
          </div>
        `).join('')}
      </div>
    ` : ''}

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
        ${overdueTasks.slice(0, 3).map(t => `
          <div class="task-item" data-task="${t.id}" tabindex="0">
            <div class="task-check" data-action="toggle"></div>
            <div class="task-item__content">
              <div class="task-item__title">${escapeHtml(t.title)}</div>
              <div class="task-item__meta overdue">${formatDate(t.dueDate)}</div>
            </div>
          </div>
        `).join('')}
      </div>
    ` : ''}

    <div class="section">
      <div class="card__header">
        <span class="card__title">Today's Tasks</span>
        <button class="btn btn--sm btn--ghost" data-nav="tasks">View all</button>
      </div>
      ${todayTasks.length ? todayTasks.map(t => `
        <div class="task-item" data-task="${t.id}" tabindex="0">
          <div class="task-check" data-action="toggle"></div>
          <div class="task-item__content">
            <div class="task-item__title">${escapeHtml(t.title)}</div>
            <div class="task-item__meta">
              <span class="priority priority--${t.priority}"></span>
              ${t.dueTime || ''}
              ${t.tags.map(tag => `<span class="tag">#${escapeHtml(tag)}</span>`).join('')}
            </div>
          </div>
        </div>
      `).join('') : `<p style="color:var(--text-secondary);font-size:0.875rem;padding:8px 0">No tasks due today 🎉</p>`}
    </div>

    ${upcomingTasks.length ? `
      <div class="section">
        <div class="card__header"><span class="card__title">Upcoming</span></div>
        ${upcomingTasks.map(t => `
            <div class="task-item" data-task="${t.id}" tabindex="0">
            <div class="task-check"></div>
            <div class="task-item__content">
              <div class="task-item__title">${escapeHtml(t.title)}</div>
              <div class="task-item__meta">${formatDate(t.dueDate)}</div>
            </div>
          </div>
        `).join('')}
      </div>
    ` : ''}

    <div class="section">
      <div class="card__header">
        <span class="card__title">Recent Notes</span>
        <button class="btn btn--sm btn--ghost" data-nav="notes">View all</button>
      </div>
      ${recentNotes.length ? recentNotes.map(n => `
        <div class="note-item" data-note="${n.id}" tabindex="0">
          <div class="note-item__title">${n.pinned ? '📌 ' : ''}${escapeHtml(n.title)}</div>
          <div class="note-item__preview">${escapeHtml(n.body.slice(0, 80))}</div>
        </div>
      `).join('') : `<p style="color:var(--text-secondary);font-size:0.875rem;padding:8px 0">No notes yet</p>`}
    </div>
  `;

  container.querySelectorAll('[data-nav]').forEach(el => {
    el.addEventListener('click', () => {
      document.querySelector(`[data-tab="${el.dataset.nav}"]`)?.click();
    });
  });

  container.querySelectorAll('[data-action="toggle"]').forEach(el => {
    el.addEventListener('click', e => {
      e.stopPropagation();
      const taskId = el.closest('[data-task]')?.dataset.task;
      if (taskId) {
        import('../store.js').then(({ toggleTask }) => {
          toggleTask(taskId);
          document.getElementById('main-content').dispatchEvent(new Event('refresh'));
        });
      }
    });
  });

  refreshIcons();
}
