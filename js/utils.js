export function formatDate(dateStr) {
  if (!dateStr) return '';
  const d = new Date(dateStr + (dateStr.includes('T') ? '' : 'T00:00:00'));
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const target = new Date(d);
  target.setHours(0, 0, 0, 0);
  const diff = Math.round((target - today) / 86400000);

  if (diff === 0) return 'Today';
  if (diff === 1) return 'Tomorrow';
  if (diff === -1) return 'Yesterday';
  if (diff > 1 && diff <= 7) return d.toLocaleDateString('en-US', { weekday: 'long' });

  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

export function formatCurrency(amount, currency = 'USD') {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency }).format(amount);
}

export function getGreeting() {
  const h = new Date().getHours();
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

export function isOverdue(dueDate, isCompleted) {
  if (!dueDate || isCompleted) return false;
  const today = new Date().toISOString().slice(0, 10);
  return dueDate < today;
}

export function getMonthYear(date = new Date()) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
}

export function daysUntil(dateStr) {
  if (!dateStr) return null;
  const target = new Date(dateStr + 'T00:00:00');
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return Math.ceil((target - today) / 86400000);
}

export function parseNaturalLanguage(input) {
  const result = { title: input, dueDate: null, dueTime: null, tags: [], priority: 'medium' };

  const tagMatches = input.match(/#\w+/g);
  if (tagMatches) {
    result.tags = tagMatches.map(t => t.slice(1).toLowerCase());
    result.title = result.title.replace(/#\w+/g, '').trim();
  }

  const priorityWords = { urgent: 'urgent', asap: 'urgent', important: 'high', high: 'high' };
  for (const [word, pri] of Object.entries(priorityWords)) {
    if (new RegExp(`\\b${word}\\b`, 'i').test(result.title)) {
      result.priority = pri;
      result.title = result.title.replace(new RegExp(`\\b${word}\\b`, 'gi'), '').trim();
    }
  }

  const timeMatch = result.title.match(/(\d{1,2})(?::(\d{2}))?\s*(am|pm)/i);
  if (timeMatch) {
    let h = parseInt(timeMatch[1]);
    const m = timeMatch[2] || '00';
    if (timeMatch[3].toLowerCase() === 'pm' && h < 12) h += 12;
    if (timeMatch[3].toLowerCase() === 'am' && h === 12) h = 0;
    result.dueTime = `${String(h).padStart(2, '0')}:${m}`;
    result.title = result.title.replace(timeMatch[0], '').trim();
  }

  const dateWords = {
    today: 0, tonight: 0, tomorrow: 1,
    monday: null, tuesday: null, wednesday: null, thursday: null,
    friday: null, saturday: null, sunday: null,
  };

  for (const [word, offset] of Object.entries(dateWords)) {
    const regex = new RegExp(`\\b${word}\\b`, 'i');
    if (regex.test(result.title)) {
      const d = new Date();
      if (offset === 0 || offset === 1) {
        d.setDate(d.getDate() + offset);
      } else if (offset === null) {
        const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
        const target = days.indexOf(word);
        const current = d.getDay();
        let diff = target - current;
        if (diff <= 0) diff += 7;
        d.setDate(d.getDate() + diff);
      }
      result.dueDate = d.toISOString().slice(0, 10);
      result.title = result.title.replace(regex, '').trim();
      break;
    }
  }

  result.title = result.title.replace(/\s+/g, ' ').trim();
  return result;
}

export function autoCategorizeExpense(note) {
  const text = (note || '').toLowerCase();
  const rules = {
    food: ['food', 'restaurant', 'cafe', 'coffee', 'lunch', 'dinner', 'grocery', 'uber eats', 'doordash', 'pizza', 'starbucks'],
    transport: ['uber', 'lyft', 'taxi', 'gas', 'fuel', 'parking', 'transit', 'metro', 'bus', 'train'],
    bills: ['rent', 'electric', 'water', 'internet', 'phone', 'insurance', 'netflix', 'spotify', 'subscription'],
    shopping: ['amazon', 'target', 'walmart', 'shop', 'clothes', 'shoes', 'order'],
  };
  for (const [cat, keywords] of Object.entries(rules)) {
    if (keywords.some(kw => text.includes(kw))) return cat;
  }
  return 'other';
}

export function stripMarkdown(text) {
  return text
    .replace(/^#+\s+/gm, '')
    .replace(/\*\*(.+?)\*\*/g, '$1')
    .replace(/\*(.+?)\*/g, '$1')
    .replace(/- \[.\]\s/g, '')
    .replace(/^-\s/gm, '')
    .replace(/\n/g, ' ')
    .trim();
}

export function renderMarkdown(text) {
  return text
    .replace(/^### (.+)$/gm, '<h3>$1</h3>')
    .replace(/^## (.+)$/gm, '<h2>$1</h2>')
    .replace(/^# (.+)$/gm, '<h1>$1</h1>')
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.+?)\*/g, '<em>$1</em>')
    .replace(/^- \[x\] (.+)$/gm, '<div class="md-check done">✓ $1</div>')
    .replace(/^- \[ \] (.+)$/gm, '<div class="md-check">○ $1</div>')
    .replace(/^- (.+)$/gm, '<li>$1</li>')
    .replace(/(<li>.*<\/li>\n?)+/g, m => `<ul>${m}</ul>`)
    .replace(/\n/g, '<br>');
}

export function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

export function refreshIcons() {
  if (window.lucide) lucide.createIcons();
}
