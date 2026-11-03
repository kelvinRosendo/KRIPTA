/* ── Notificações ligadas ao calendário (RF07 / RN05 / UC02) ── */

async function getNotifications() {
  return api.get('/notifications');
}

function notificationTypePill(type) {
  if (type === 'EXAM') return '<span class="pill bg-crimson-light text-crimson">Prova</span>';
  if (type === 'TASK') return '<span class="pill bg-indigo-light text-indigo">Tarefa</span>';
  return '<span class="pill bg-lilac-light text-lilac">Evento</span>';
}

function notificationCardHTML(n) {
  return (
    '<div class="card p-3.5 flex items-center gap-[11px]">' +
    '<div class="flex-1 min-w-0">' +
    '<div class="flex items-center gap-2">' + notificationTypePill(n.type) +
    '<span class="text-[11px] text-text-low">' + formatDate(n.date) + '</span></div>' +
    '<div class="text-sm font-bold mt-1.5 truncate">' + esc(n.title) + '</div>' +
    (n.message ? '<div class="text-[12px] text-text-mid mt-[3px]">' + esc(n.message) + '</div>' : '') +
    '</div></div>'
  );
}
