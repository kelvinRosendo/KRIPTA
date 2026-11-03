/* ── Dashboard (Sprint 11) ── */
async function getDashboard() {
  var values = await Promise.all([getGamificationStats(), getTasks()]);
  var stats = values[0], tasks = values[1];
  var today = toLocalDateStr(new Date());
  var tomorrow = toLocalDateStr(calAddDays(new Date(),1));
  var pending = tasks.filter(function(t){return !t.completed && t.dueDate;});
  function day(t) {return toLocalDateStr(new Date(t.dueDate));}
  return {stats:stats, xp:stats.xp, level:stats.level, streak:stats.streak,
    tasksToday:pending.filter(function(t){return day(t)===today;}), tasksTomorrow:pending.filter(function(t){return day(t)===tomorrow;}), overdueTasks:pending.filter(function(t){return day(t)<today;}), achievements:await getAchievements()};
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