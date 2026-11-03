/* ── Calendário (Sprint 14 / RF06) ──
   Visões dia, semana e mês, com escopo escolar ou pessoal. */

var CAL_VIEW = 'month';
var CAL_SCOPE = 'ESCOLAR';
var CAL_CURSOR = new Date();
var CAL_SELECTED = new Date();
var CAL_EVENTS = [];

var CAL_MONTHS = ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'];
var CAL_WEEKDAYS = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
var CAL_WEEKDAYS_FULL = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];

async function getCalendar(startDate, endDate, scope) {
  var qs = '?startDate=' + encodeURIComponent(startDate) + '&endDate=' + encodeURIComponent(endDate);
  if (scope && scope !== 'ALL') qs += '&scope=' + encodeURIComponent(scope);
  return api.get('/calendar' + qs);
}

async function getPersonalEvents() {
  return api.get('/calendar/events');
}

async function createPersonalEvent(data) {
  return api.post('/calendar/events', data);
}

function toLocalDateStr(d) {
  function p(n) { return n < 10 ? '0' + n : n; }
  return d.getFullYear() + '-' + p(d.getMonth() + 1) + '-' + p(d.getDate());
}

function calParseDay(key) {
  var parts = String(key).split('-');
  return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
}

function calAddDays(d, n) {
  var x = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  x.setDate(x.getDate() + n);
  return x;
}

function calStartOfWeek(d) {
  return calAddDays(d, -d.getDay());
}

function calSameDay(a, b) {
  return toLocalDateStr(a) === toLocalDateStr(b);
}

function calEventsOn(date) {
  var key = toLocalDateStr(date);
  return CAL_EVENTS.filter(function (e) { return e.date && String(e.date).slice(0, 10) === key; });
}

/* Intervalo visível conforme a visão atual (mês inclui dias vizinhos do grid). */
function calendarRange() {
  if (CAL_VIEW === 'day') {
    return { start: CAL_CURSOR, end: CAL_CURSOR };
  }
  if (CAL_VIEW === 'week') {
    var start = calStartOfWeek(CAL_CURSOR);
    return { start: start, end: calAddDays(start, 6) };
  }
  var first = new Date(CAL_CURSOR.getFullYear(), CAL_CURSOR.getMonth(), 1);
  var gridStart = calAddDays(first, -first.getDay());
  return { start: gridStart, end: calAddDays(gridStart, 41) };
}

function calendarTitleText() {
  if (CAL_VIEW === 'day') {
    return CAL_WEEKDAYS_FULL[CAL_CURSOR.getDay()] + ', ' + CAL_CURSOR.getDate() + ' de ' + CAL_MONTHS[CAL_CURSOR.getMonth()];
  }
  if (CAL_VIEW === 'week') {
    var start = calStartOfWeek(CAL_CURSOR);
    var end = calAddDays(start, 6);
    if (start.getMonth() === end.getMonth()) {
      return start.getDate() + ' – ' + end.getDate() + ' de ' + CAL_MONTHS[start.getMonth()];
    }
    return start.getDate() + ' ' + CAL_MONTHS[start.getMonth()].slice(0, 3) + ' – ' + end.getDate() + ' ' + CAL_MONTHS[end.getMonth()].slice(0, 3);
  }
  return CAL_MONTHS[CAL_CURSOR.getMonth()].toUpperCase() + ' ' + CAL_CURSOR.getFullYear();
}

function setCalendarScope(scope) {
  CAL_SCOPE = scope;
  document.querySelectorAll('[data-cal-scope]').forEach(function (p) {
    if (p.getAttribute('data-cal-scope') === scope) {
      p.className = 'pill bg-indigo text-white cursor-pointer';
    } else {
      p.className = 'pill bg-surface text-text-mid border border-border cursor-pointer';
    }
  });
  renderCalendar();
}

function setCalendarView(view) {
  CAL_VIEW = view;
  CAL_SELECTED = new Date(CAL_CURSOR);
  document.querySelectorAll('[data-cal-view]').forEach(function (b) {
    if (b.getAttribute('data-cal-view') === view) {
      b.className = 'flex-1 py-1.5 rounded-sm bg-white text-indigo font-bold text-[12px] shadow-sm border-none cursor-pointer';
    } else {
      b.className = 'flex-1 py-1.5 rounded-sm bg-transparent text-text-mid font-semibold text-[12px] border-none cursor-pointer';
    }
  });
  renderCalendar();
}

async function renderCalendar() {
  var body = document.getElementById('calendar-body');
  if (!body) return;
  showLoading(body);
  var range = calendarRange();
  try {
    var events = await getCalendar(toLocalDateStr(range.start), toLocalDateStr(range.end), CAL_SCOPE);
    CAL_EVENTS = Array.isArray(events) ? events : (events && events.content ? events.content : []);
    body.innerHTML = calendarShellHTML();
    bindCalendarNav();
    renderCalendarView();
  } catch (e) {
    body.innerHTML = errorView(e && e.message);
  }
}

function calendarShellHTML() {
  return (
    '<div class="card p-4">' +
    '<div class="flex items-center justify-between mb-3">' +
    '<button type="button" class="icon-btn !w-8 !h-8" data-cal-prev aria-label="Anterior">' +
    '<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m15 18-6-6 6-6"/></svg></button>' +
    '<span class="font-display font-bold text-[13px]" data-cal-title>' + calendarTitleText() + '</span>' +
    '<button type="button" class="icon-btn !w-8 !h-8" data-cal-next aria-label="Próximo">' +
    '<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m9 18 6-6-6-6"/></svg></button>' +
    '</div>' +
    '<div id="cal-view-body"></div>' +
    '</div>' +
    '<div id="cal-day-events" class="mt-3"></div>'
  );
}

function renderCalendarView() {
  var vb = document.getElementById('cal-view-body');
  var agenda = document.getElementById('cal-day-events');
  if (!vb) return;
  if (CAL_VIEW === 'day') vb.innerHTML = dayHeaderHTML();
  else if (CAL_VIEW === 'week') vb.innerHTML = weekStripHTML();
  else vb.innerHTML = monthGridHTML();
  bindCalendarDays();
  if (agenda) agenda.innerHTML = agendaHTML(CAL_SELECTED);
}

function weekdayHeaderHTML() {
  var out = '<div class="cal-grid">';
  for (var i = 0; i < 7; i++) {
    out += '<span class="text-center text-[10px] font-bold text-text-low py-1">' + CAL_WEEKDAYS[i] + '</span>';
  }
  return out + '</div>';
}

function dayCellHTML(date, otherMonth) {
  var count = calEventsOn(date).length;
  var cls = 'cal-cell' +
    (otherMonth ? ' other' : '') +
    (calSameDay(date, new Date()) ? ' today' : '') +
    (calSameDay(date, CAL_SELECTED) ? ' selected' : '');
  var dots = '';
  for (var i = 0; i < Math.min(count, 3); i++) dots += '<span class="cal-dot"></span>';
  return (
    '<button type="button" class="' + cls + '" data-cal-day="' + toLocalDateStr(date) + '">' +
    '<span class="cal-daynum">' + date.getDate() + '</span>' +
    '<span class="cal-dots">' + dots + '</span>' +
    '</button>'
  );
}

function monthGridHTML() {
  var first = new Date(CAL_CURSOR.getFullYear(), CAL_CURSOR.getMonth(), 1);
  var gridStart = calAddDays(first, -first.getDay());
  var out = weekdayHeaderHTML() + '<div class="cal-grid mt-1">';
  for (var i = 0; i < 42; i++) {
    var d = calAddDays(gridStart, i);
    out += dayCellHTML(d, d.getMonth() !== CAL_CURSOR.getMonth());
  }
  return out + '</div>';
}

function weekStripHTML() {
  var start = calStartOfWeek(CAL_CURSOR);
  var out = '<div class="cal-grid">';
  for (var i = 0; i < 7; i++) {
    var d = calAddDays(start, i);
    var count = calEventsOn(d).length;
    var cls = 'cal-cell' +
      (calSameDay(d, new Date()) ? ' today' : '') +
      (calSameDay(d, CAL_SELECTED) ? ' selected' : '');
    var dots = '';
    for (var j = 0; j < Math.min(count, 3); j++) dots += '<span class="cal-dot"></span>';
    out +=
      '<button type="button" class="' + cls + '" data-cal-day="' + toLocalDateStr(d) + '">' +
      '<span class="cal-weekday">' + CAL_WEEKDAYS[d.getDay()] + '</span>' +
      '<span class="cal-daynum">' + d.getDate() + '</span>' +
      '<span class="cal-dots">' + dots + '</span>' +
      '</button>';
  }
  return out + '</div>';
}

function dayHeaderHTML() {
  var d = CAL_CURSOR;
  return (
    '<div class="flex items-center justify-between">' +
    '<div>' +
    '<div class="font-display text-[15px] font-bold">' + CAL_WEEKDAYS_FULL[d.getDay()] + ', ' + d.getDate() + '</div>' +
    '<div class="text-[11.5px] text-text-mid">' + CAL_MONTHS[d.getMonth()] + ' de ' + d.getFullYear() + '</div>' +
    '</div>' +
    (calSameDay(d, new Date()) ? '<span class="pill bg-indigo-light text-indigo">Hoje</span>' : '') +
    '</div>'
  );
}

function eventTypeMeta(type) {
  if (type === 'EXAM') return { label: 'Prova', cls: 'bg-crimson-light text-crimson' };
  if (type === 'TASK') return { label: 'Tarefa', cls: 'bg-indigo-light text-indigo' };
  return { label: 'Evento', cls: 'bg-lilac-light text-lilac' };
}

function agendaHTML(date) {
  var events = calEventsOn(date);
  if (!events.length) {
    return '<div class="card p-4 text-center text-[12.5px] text-text-mid">Nenhum evento neste dia.</div>';
  }
  return events.map(function (e) {
    var meta = eventTypeMeta(e.type);
    var scope = e.scope === 'PESSOAL' ? 'Pessoal' : 'Escolar';
    return (
      '<div class="card p-3.5 mb-2 flex items-center gap-3">' +
      '<span class="pill ' + meta.cls + '">' + meta.label + '</span>' +
      '<div class="flex-1 min-w-0">' +
      '<div class="text-[13px] font-semibold truncate">' + esc(e.title) + '</div>' +
      (e.note ? '<div class="text-[11.5px] text-text-mid mt-0.5 truncate">' + esc(e.note) + '</div>' : '') +
      '</div>' +
      '<span class="pill bg-surface-2 text-text-mid">' + scope + '</span>' +
      '</div>'
    );
  }).join('');
}

function bindCalendarDays() {
  document.querySelectorAll('[data-cal-day]').forEach(function (cell) {
    cell.addEventListener('click', function () {
      CAL_SELECTED = calParseDay(cell.getAttribute('data-cal-day'));
      if (CAL_VIEW === 'day') CAL_CURSOR = new Date(CAL_SELECTED);
      renderCalendarView();
    });
  });
}

function bindCalendarNav() {
  var prev = document.querySelector('[data-cal-prev]');
  var next = document.querySelector('[data-cal-next]');
  if (prev) prev.addEventListener('click', function () { shiftCalendar(-1); });
  if (next) next.addEventListener('click', function () { shiftCalendar(1); });
}

function shiftCalendar(dir) {
  if (CAL_VIEW === 'day') {
    CAL_CURSOR = calAddDays(CAL_CURSOR, dir);
  } else if (CAL_VIEW === 'week') {
    CAL_CURSOR = calAddDays(CAL_CURSOR, 7 * dir);
  } else {
    CAL_CURSOR = new Date(CAL_CURSOR.getFullYear(), CAL_CURSOR.getMonth() + dir, 1);
  }
  CAL_SELECTED = new Date(CAL_CURSOR);
  renderCalendar();
}
