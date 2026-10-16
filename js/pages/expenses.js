import { getState, addExpense, deleteExpense, setBudget, CATEGORIES } from '../store.js';
import { formatCurrency, getMonthYear, autoCategorizeExpense, escapeHtml, refreshIcons } from '../utils.js';
import { openBottomSheet, emptyState, bindEmptyAction } from '../components/ui.js';

let currentTab = 'overview';
let charts = {};

export function renderExpenses(container) {
  container.innerHTML = `
    <div class="expense-tabs">
      <button class="expense-tab ${currentTab === 'overview' ? 'active' : ''}" data-tab="overview">Overview</button>
      <button class="expense-tab ${currentTab === 'transactions' ? 'active' : ''}" data-tab="transactions">Transactions</button>
      <button class="expense-tab ${currentTab === 'budgets' ? 'active' : ''}" data-tab="budgets">Budgets</button>
      <button class="expense-tab ${currentTab === 'reports' ? 'active' : ''}" data-tab="reports">Reports</button>
    </div>
    <div id="expense-content"></div>
  `;

  container.querySelectorAll('.expense-tab').forEach(tab => {
    tab.addEventListener('click', () => {
      currentTab = tab.dataset.tab;
      Object.values(charts).forEach(c => c.destroy?.());
      charts = {};
      renderExpenses(container);
    });
  });

  const content = container.querySelector('#expense-content');
  if (currentTab === 'overview') renderOverview(content);
  else if (currentTab === 'transactions') renderTransactions(content);
  else if (currentTab === 'budgets') renderBudgets(content);
  else renderReports(content);
}

function getMonthExpenses() {
  const monthYear = getMonthYear();
  return getState().expenses.filter(e => e.date?.startsWith(monthYear));
}

function renderOverview(el) {
  const monthExp = getMonthExpenses();
  const totalExp = monthExp.filter(e => e.type === 'expense').reduce((s, e) => s + e.amount, 0);
  const totalInc = monthExp.filter(e => e.type === 'income').reduce((s, e) => s + e.amount, 0);
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
      ${monthExp.slice(0, 5).map(renderExpenseItem).join('') || '<p style="color:var(--text-secondary);font-size:0.875rem">No transactions this month</p>'}
    </div>
  `;
}

function renderTransactions(el) {
  const expenses = getState().expenses;
  if (expenses.length === 0) {
    el.innerHTML = emptyState('wallet', 'No expenses yet', 'Track your spending by adding your first transaction.', 'Add Expense', () => showAddExpense());
    bindEmptyAction(() => showAddExpense());
    return;
  }
  el.innerHTML = expenses.map(renderExpenseItem).join('');
  el.querySelectorAll('.resource-item').forEach(item => {
    item.querySelector('[data-delete]')?.addEventListener('click', e => {
      e.stopPropagation();
      deleteExpense(item.dataset.id);
      document.getElementById('main-content').dispatchEvent(new Event('refresh'));
    });
  });
}

function renderExpenseItem(exp) {
  const currency = getState().user.currency;
  const catLabel = CATEGORIES[exp.category] || exp.category;
  return `
    <div class="resource-item" data-id="${exp.id}">
      <div class="resource-item__icon"><i data-lucide="${exp.type === 'income' ? 'arrow-down-left' : 'arrow-up-right'}"></i></div>
      <div class="resource-item__content">
        <div class="resource-item__title">${escapeHtml(exp.note || catLabel)}</div>
        <div class="resource-item__sub">
          <span class="tag tag--${exp.category}">${catLabel}</span>
          ${exp.date}
          ${exp.isRecurring ? ' · Recurring' : ''}
        </div>
      </div>
      <div style="font-weight:600;color:${exp.type === 'income' ? 'var(--success)' : 'var(--danger)'}">
        ${exp.type === 'income' ? '+' : '-'}${formatCurrency(exp.amount, currency)}
      </div>
      <button class="icon-btn" data-delete aria-label="Delete"><i data-lucide="trash-2"></i></button>
    </div>
  `;
}

function renderBudgets(el) {
  const monthYear = getMonthYear();
  const budgets = getState().budgets.filter(b => b.monthYear === monthYear);
  const monthExp = getMonthExpenses().filter(e => e.type === 'expense');
  const currency = getState().user.currency;

  const spentByCat = {};
  monthExp.forEach(e => { spentByCat[e.category] = (spentByCat[e.category] || 0) + e.amount; });

  el.innerHTML = `
    <div class="section">
      ${Object.entries(CATEGORIES).map(([key, label]) => {
        const budget = budgets.find(b => b.category === key);
        const spent = spentByCat[key] || 0;
        const limit = budget?.monthlyLimit || 0;
        const pct = limit ? Math.min(100, (spent / limit) * 100) : 0;
        return `
          <div class="budget-bar">
            <div class="budget-bar__header">
              <span class="tag tag--${key}">${label}</span>
              <span>${formatCurrency(spent, currency)}${limit ? ` / ${formatCurrency(limit, currency)}` : ''}</span>
            </div>
            ${limit ? `<div class="budget-bar__track"><div class="budget-bar__fill ${pct >= 100 ? 'over' : ''}" style="width:${pct}%"></div></div>` : ''}
          </div>
        `;
      }).join('')}
    </div>
    <button class="btn btn--secondary btn--block" id="set-budget">Set Budget Limits</button>
  `;

  document.getElementById('set-budget')?.addEventListener('click', showSetBudget);
  refreshIcons();
}

function showSetBudget() {
  openBottomSheet('Set Monthly Budgets', `
    <form id="budget-form">
      ${Object.entries(CATEGORIES).map(([key, label]) => {
        const b = getState().budgets.find(x => x.category === key && x.monthYear === getMonthYear());
        return `
          <div class="form-group">
            <label class="form-label">${label}</label>
            <input class="form-input" type="number" name="${key}" placeholder="Monthly limit" value="${b?.monthlyLimit || ''}" min="0" step="0.01" />
          </div>
        `;
      }).join('')}
      <button type="submit" class="btn btn--primary btn--block">Save Budgets</button>
    </form>
  `, (data) => {
    const my = getMonthYear();
    Object.entries(data).forEach(([cat, limit]) => {
      if (limit) setBudget(cat, limit, my);
    });
    document.getElementById('overlay').click();
    document.getElementById('main-content').dispatchEvent(new Event('refresh'));
  });
}

function renderReports(el) {
  const monthExp = getMonthExpenses().filter(e => e.type === 'expense');
  const currency = getState().user.currency;

  if (monthExp.length === 0) {
    el.innerHTML = emptyState('bar-chart-3', 'No data yet', 'Add some expenses to see reports.', 'Add Expense', () => showAddExpense());
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
  const isDark = document.documentElement.dataset.theme === 'dark';
  const textColor = isDark ? '#9CA3AF' : '#6B7280';
  const catColors = { food: '#F97316', transport: '#8B5CF6', bills: '#EF4444', shopping: '#EC4899', other: '#6B7280' };

  const byCat = {};
  monthExp.forEach(e => { byCat[e.category] = (byCat[e.category] || 0) + e.amount; });

  const pieCtx = document.getElementById('pie-chart');
  if (pieCtx) {
    charts.pie = new Chart(pieCtx, {
      type: 'doughnut',
      data: {
        labels: Object.keys(byCat).map(k => CATEGORIES[k] || k),
        datasets: [{ data: Object.values(byCat), backgroundColor: Object.keys(byCat).map(k => catColors[k] || '#6B7280') }],
      },
      options: { plugins: { legend: { labels: { color: textColor } } } },
    });
  }

  const byDay = {};
  monthExp.forEach(e => { byDay[e.date] = (byDay[e.date] || 0) + e.amount; });
  const lineCtx = document.getElementById('line-chart');
  if (lineCtx) {
    charts.line = new Chart(lineCtx, {
      type: 'line',
      data: {
        labels: Object.keys(byDay).sort(),
        datasets: [{ label: 'Spending', data: Object.keys(byDay).sort().map(d => byDay[d]), borderColor: '#5B5FEF', tension: 0.3, fill: false }],
      },
      options: { scales: { x: { ticks: { color: textColor } }, y: { ticks: { color: textColor } } }, plugins: { legend: { labels: { color: textColor } } } },
    });
  }

  const allMonth = getMonthExpenses();
  const totalExp = allMonth.filter(e => e.type === 'expense').reduce((s, e) => s + e.amount, 0);
  const totalInc = allMonth.filter(e => e.type === 'income').reduce((s, e) => s + e.amount, 0);
  const barCtx = document.getElementById('bar-chart');
  if (barCtx) {
    charts.bar = new Chart(barCtx, {
      type: 'bar',
      data: {
        labels: ['Income', 'Expenses'],
        datasets: [{ data: [totalInc, totalExp], backgroundColor: ['#22C55E', '#EF4444'] }],
      },
      options: { scales: { x: { ticks: { color: textColor } }, y: { ticks: { color: textColor } } }, plugins: { legend: { display: false } } },
    });
  }
}

export function showAddExpense() {
  const today = new Date().toISOString().slice(0, 10);
  openBottomSheet('Add Transaction', `
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
          ${Object.entries(CATEGORIES).map(([k, v]) => `<option value="${k}">${v}</option>`).join('')}
        </select>
      </div>
      <div class="form-group">
        <label class="form-label">Account</label>
        <select class="form-select" name="accountId">
          ${getState().accounts.map(a => `<option value="${a.id}">${escapeHtml(a.name)}</option>`).join('')}
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
    if (!data.category || data.category === 'other') {
      data.category = autoCategorizeExpense(data.note);
    }
    addExpense(data);
    document.getElementById('overlay').click();
    document.getElementById('main-content').dispatchEvent(new Event('refresh'));
  });

  setTimeout(() => {
    document.getElementById('expense-note')?.addEventListener('input', e => {
      const cat = autoCategorizeExpense(e.target.value);
      const sel = document.getElementById('expense-category');
      if (sel) sel.value = cat;
    });
  }, 50);
}

export function getMonthSpend() {
  const monthExp = getMonthExpenses().filter(e => e.type === 'expense');
  return monthExp.reduce((s, e) => s + e.amount, 0);
}
