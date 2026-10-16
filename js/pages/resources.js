import { getState, addResource, updateResource, deleteResource, RESOURCE_TYPES } from '../store.js';
import { escapeHtml, daysUntil, formatCurrency, refreshIcons } from '../utils.js';
import { openBottomSheet, emptyState, bindEmptyAction } from '../components/ui.js';

let currentType = 'all';

export function renderResources(container) {
  const state = getState();
  let resources = [...state.resources];
  if (currentType !== 'all') resources = resources.filter(r => r.type === currentType);

  container.innerHTML = `
    <div class="resource-tabs">
      <button class="resource-tab ${currentType === 'all' ? 'active' : ''}" data-type="all">All</button>
      ${Object.entries(RESOURCE_TYPES).map(([key, val]) => `
        <button class="resource-tab ${currentType === key ? 'active' : ''}" data-type="${key}">${val.label}</button>
      `).join('')}
    </div>
    <div id="resources-list"></div>
  `;

  container.querySelectorAll('.resource-tab').forEach(tab => {
    tab.addEventListener('click', () => {
      currentType = tab.dataset.type;
      renderResources(container);
    });
  });

  const listEl = container.querySelector('#resources-list');
  if (resources.length === 0) {
    listEl.innerHTML = emptyState('folder-lock', 'No resources yet', 'Store documents, track subscriptions, manage inventory, and save important contacts.', 'Add Resource', () => showAddResource());
    bindEmptyAction(() => showAddResource());
    return;
  }

  listEl.innerHTML = resources.map(renderResourceItem).join('');
  listEl.querySelectorAll('.resource-item').forEach(item => {
    item.addEventListener('click', () => showResourceDetail(item.dataset.id));
    item.addEventListener('keydown', e => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        showResourceDetail(item.dataset.id);
      }
    });
  });
  refreshIcons();
}

function renderResourceItem(r) {
  const typeInfo = RESOURCE_TYPES[r.type] || { icon: 'file', label: r.type };
  let sub = '';

  if (r.type === 'subscription') {
    const days = daysUntil(r.renewalDate);
    const cost = r.details?.cost;
    sub = `${cost ? formatCurrency(cost, getState().user.currency) + '/mo · ' : ''}${days !== null ? (days <= 0 ? 'Renews today' : `Renews in ${days}d`) : 'No renewal date'}`;
  } else if (r.type === 'inventory') {
    sub = `Qty: ${r.quantity ?? '?'}${r.quantity <= r.lowStockThreshold ? ' · ⚠️ Low stock' : ''}`;
  } else if (r.type === 'contact') {
    sub = r.details?.phone || r.details?.email || '';
  } else if (r.type === 'document') {
    sub = r.details?.expiry ? `Expires: ${r.details.expiry}` : (r.tags?.join(', ') || 'Document');
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
  const r = getState().resources.find(x => x.id === id);
  if (!r) return;

  const detailsHtml = Object.entries(r.details || {}).map(([k, v]) =>
    `<div style="display:flex;justify-content:space-between;padding:8px 0;border-bottom:1px solid var(--border)">
      <span style="color:var(--text-secondary);font-size:0.8125rem;text-transform:capitalize">${escapeHtml(k)}</span>
      <span style="font-size:0.875rem">${escapeHtml(String(v))}</span>
    </div>`
  ).join('');

  openBottomSheet(r.name, `
    <div style="margin-bottom:16px">
      <span class="tag">${RESOURCE_TYPES[r.type]?.label || r.type}</span>
      ${r.tags?.map(t => `<span class="tag">#${escapeHtml(t)}</span>`).join('') || ''}
    </div>
    ${detailsHtml || '<p style="color:var(--text-secondary)">No additional details</p>'}
    ${r.renewalDate ? `<p style="margin-top:12px;font-size:0.875rem">Renewal: <strong>${r.renewalDate}</strong></p>` : ''}
    ${r.quantity !== null ? `<p style="margin-top:8px;font-size:0.875rem">Quantity: <strong>${r.quantity}</strong></p>` : ''}
    <div style="display:flex;gap:8px;margin-top:20px">
      <button class="btn btn--secondary" style="flex:1" id="edit-resource">Edit</button>
      <button class="btn btn--danger" id="delete-resource">Delete</button>
    </div>
  `);

  setTimeout(() => {
    document.getElementById('delete-resource')?.addEventListener('click', () => {
      deleteResource(id);
      document.getElementById('overlay').click();
      document.getElementById('main-content').dispatchEvent(new Event('refresh'));
    });
    document.getElementById('edit-resource')?.addEventListener('click', () => {
      document.getElementById('overlay').click();
      showAddResource(r);
    });
  }, 50);
}

export function showAddResource(existing) {
  const r = existing || {};
  openBottomSheet(existing ? 'Edit Resource' : 'Add Resource', `
    <form id="add-resource-form">
      <div class="form-group">
        <label class="form-label">Type</label>
        <select class="form-select" name="type" id="resource-type">
          ${Object.entries(RESOURCE_TYPES).map(([k, v]) => `<option value="${k}" ${r.type === k ? 'selected' : ''}>${v.label}</option>`).join('')}
        </select>
      </div>
      <div class="form-group">
        <label class="form-label">Name</label>
        <input class="form-input" name="name" value="${escapeHtml(r.name || '')}" required />
      </div>
      <div id="type-fields">
        ${getTypeFields(r.type || 'document', r)}
      </div>
      <div class="form-group">
        <label class="form-label">Tags (comma separated)</label>
        <input class="form-input" name="tags" value="${(r.tags || []).join(', ')}" placeholder="work, important" />
      </div>
      <button type="submit" class="btn btn--primary btn--block">${existing ? 'Save' : 'Add Resource'}</button>
    </form>
  `, (data) => {
    const type = data.type;
    const details = {};
    if (type === 'subscription') {
      details.plan = data.plan || '';
      details.cost = parseFloat(data.cost) || 0;
    } else if (type === 'document') {
      details.number = data.docNumber || '';
      details.expiry = data.expiry || '';
    } else if (type === 'inventory') {
      details.location = data.location || '';
    } else if (type === 'contact') {
      details.phone = data.phone || '';
      details.email = data.email || '';
      details.role = data.role || '';
    }

    const payload = {
      type,
      name: data.name,
      details,
      renewalDate: data.renewalDate || null,
      quantity: type === 'inventory' ? parseInt(data.quantity) || 0 : null,
      lowStockThreshold: parseInt(data.lowStockThreshold) || 5,
      tags: data.tags ? data.tags.split(',').map(t => t.trim()).filter(Boolean) : [],
    };

    if (existing) updateResource(existing.id, payload);
    else addResource(payload);

    document.getElementById('overlay').click();
    document.getElementById('main-content').dispatchEvent(new Event('refresh'));
  });

  setTimeout(() => {
    document.getElementById('resource-type')?.addEventListener('change', e => {
      document.getElementById('type-fields').innerHTML = getTypeFields(e.target.value, {});
    });
  }, 50);
}

function getTypeFields(type, r) {
  const d = r.details || {};
  switch (type) {
    case 'subscription':
      return `
        <div class="form-group"><label class="form-label">Plan</label><input class="form-input" name="plan" value="${escapeHtml(d.plan || '')}" /></div>
        <div class="form-group"><label class="form-label">Monthly Cost</label><input class="form-input" type="number" name="cost" value="${d.cost || ''}" step="0.01" /></div>
        <div class="form-group"><label class="form-label">Renewal Date</label><input class="form-input" type="date" name="renewalDate" value="${r.renewalDate || ''}" /></div>
      `;
    case 'document':
      return `
        <div class="form-group"><label class="form-label">Reference Number</label><input class="form-input" name="docNumber" value="${escapeHtml(d.number || '')}" /></div>
        <div class="form-group"><label class="form-label">Expiry Date</label><input class="form-input" type="date" name="expiry" value="${d.expiry || ''}" /></div>
      `;
    case 'inventory':
      return `
        <div class="form-group"><label class="form-label">Quantity</label><input class="form-input" type="number" name="quantity" value="${r.quantity ?? ''}" min="0" /></div>
        <div class="form-group"><label class="form-label">Low Stock Alert</label><input class="form-input" type="number" name="lowStockThreshold" value="${r.lowStockThreshold ?? 5}" min="0" /></div>
        <div class="form-group"><label class="form-label">Location</label><input class="form-input" name="location" value="${escapeHtml(d.location || '')}" /></div>
      `;
    case 'contact':
      return `
        <div class="form-group"><label class="form-label">Phone</label><input class="form-input" name="phone" value="${escapeHtml(d.phone || '')}" /></div>
        <div class="form-group"><label class="form-label">Email</label><input class="form-input" name="email" type="email" value="${escapeHtml(d.email || '')}" /></div>
        <div class="form-group"><label class="form-label">Role</label><input class="form-input" name="role" value="${escapeHtml(d.role || '')}" /></div>
      `;
    default:
      return '';
  }
}

export function getUpcomingRenewals() {
  return getState().resources.filter(r => r.renewalDate && daysUntil(r.renewalDate) !== null && daysUntil(r.renewalDate) <= 7);
}
