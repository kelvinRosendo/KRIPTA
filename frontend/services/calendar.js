/* ── Calendário (Sprint 14) ── */
async function getCalendar(startDate, endDate) {
  var qs = '?startDate=' + encodeURIComponent(startDate) + '&endDate=' + encodeURIComponent(endDate);
  return api.get('/calendar' + qs);
}

function toLocalDateStr(d) {
  function p(n) { return n < 10 ? '0' + n : n; }
  return d.getFullYear() + '-' + p(d.getMonth() + 1) + '-' + p(d.getDate());
}

function calendarGrid(events, baseDate) {
  var start = new Date(baseDate.getFullYear(), baseDate.getMonth(), 1);
  var year = baseDate.getFullYear();
  var month = baseDate.getMonth();
  var byDate = {};
  events.forEach(function (e) {
    if (!e.date) return;
    var key = String(e.date).slice(0, 10);
    (byDate[key] = byDate[key] || []).push(e);
  });
  var weekday = start.getDay(); // 0 = domingo
  var blocks = '';
  if (weekday > 0) {
    for (var i = 0; i < start.getDay(); i++) blocks += '<div class="flex-1 text-center py-2"></div>';
  }
  var total = new Date(year, month + 1, 0).getDate();
  var monthNames = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];
  for (var d = 1; d <= total; d++) {
    var key = year + '-' + (month < 9 ? '0' + (month + 1) : month + 1) + '-' + (d < 10 ? '0' + d : d);
    var dayEvents = byDate[key] || [];
    blocks +=
      '<div class="flex-1 flex flex-col items-center py-1.5 gap-0.5' + (dayEvents.length ? ' cursor-pointer' : '') + '" data-day="' + key + '">' +
      '<span class="text-[12px] font-bold' + (dayEvents.length ? ' text-indigo' : ' text-text-mid') + '">' + d + '</span>' +
      (dayEvents.length ? '<span class="w-1.5 h-1.5 bg-indigo rounded-full"></span>' : '<span class="w-1.5 h-1.5">&nbsp;</span>') +
      '</div>';
  }
  var monthName = monthNames[month].toUpperCase();
  return (
    '<div class="card p-4">' +
    '<div class="flex justify-between items-center mb-2">' +
    '<button type="button" class="icon-btn !w-8 !h-8" data-cal-prev aria-label="Mês anterior"><svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m15 18-6-6 6-6"/></svg></button>' +
    '<span class="font-display font-bold text-[13px]" data-cal-title>' + monthName + ' ' + year + '</span>' +
    '<button type="button" class="icon-btn !w-8 !h-8" data-cal-next aria-label="Próximo mês"><svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m9 18 6-6-6-6"/></svg></button>' +
    '</div>' +
    '<div class="flex"><span class="flex-1 text-center text-[10px] font-bold text-text-low">D</span><span class="flex-1 text-center text-[10px] font-bold text-text-low">S</span><span class="flex-1 text-center text-[10px] font-bold text-text-low">T</span><span class="flex-1 text-center text-[10px] font-bold text-text-low">Q</span><span class="flex-1 text-center text-[10px] font-bold text-text-low">Q</span><span class="flex-1 text-center text-[10px] font-bold text-text-low">S</span><span class="flex-1 text-center text-[10px] font-bold text-text-low">S</span></div>' +
    '<div class="flex flex-wrap">' + blocks + '</div>' +
    '</div>' +
    '<div id="cal-day-events" class="mt-2"></div>'
  );
}