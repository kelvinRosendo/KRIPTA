/* ── Dashboard (Sprint 11) ── */
async function getDashboard() {
  return api.get('/dashboard');
}

function taskSideLabel(t) {
  if (!t || !t.dueDate) return '';
  var due = new Date(t.dueDate);
  var today = new Date();
  today.setHours(0, 0, 0, 0);
  var tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);
  var d = new Date(due);
  d.setHours(0, 0, 0, 0);
  var diff = Math.round((d - today) / 86400000);
  if (diff === 0) return '<span class="pill bg-orange-light text-orange" style="flex:0 0 auto">hoje</span>';
  if (diff === 1) return '<span class="pill bg-teal-light text-teal" style="flex:0 0 auto">amanhã</span>';
  if (diff < 0) return '<span class="pill bg-crimson-light text-crimson" style="flex:0 0 auto">atrasada</span>';
  return '<span class="pill bg-surface-2 text-text-mid" style="flex:0 0 auto">' + esc(formatDate(due)) + '</span>';
}

function formatDate(date) {
  if (!date) return '';
  var d = new Date(date);
  function p(n) { return n < 10 ? '0' + n : n; }
  return p(d.getDate()) + '/' + p(d.getMonth() + 1);
}

function formatDateTime(date) {
  if (!date) return '';
  var d = new Date(date);
  function p(n) { return n < 10 ? '0' + n : n; }
  return formatDate(d) + ', ' + p(d.getHours()) + 'h' + p(d.getMinutes());
}