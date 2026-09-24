/* ── Avisos (Sprint 15) ── */
async function getAnnouncements() {
  return api.get('/announcements');
}

function timeAgo(dateStr) {
  if (!dateStr) return '';
  var d = new Date(dateStr);
  var diff = Date.now() - d.getTime();
  var min = Math.floor(diff / 60000);
  if (min < 1) return 'agora';
  if (min < 60) return 'há ' + min + 'min';
  var h = Math.floor(min / 60);
  if (h < 24) return 'há ' + h + 'h';
  var days = Math.floor(h / 24);
  if (days === 1) return 'ontem';
  if (days < 7) return 'há ' + days + 'd';
  return formatDate(d);
}