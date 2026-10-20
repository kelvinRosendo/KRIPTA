/* ── Preferências do usuário (acessibilidade / notificações) ── */

var PREFS_KEY = 'kripta_prefs';

function getPrefs() {
  var parsed = {};
  try {
    parsed = JSON.parse(localStorage.getItem(PREFS_KEY) || '{}') || {};
  } catch (e) {
    parsed = {};
  }
  return {
    a11y: parsed.a11y === true,
    notifications: parsed.notifications !== false,
  };
}

function savePrefs(prefs) {
  try {
    localStorage.setItem(PREFS_KEY, JSON.stringify(prefs));
  } catch (e) { /* armazenamento indisponível */ }
}

function setPref(key, value) {
  var prefs = getPrefs();
  prefs[key] = value;
  savePrefs(prefs);
  applyPrefs();
}

function applyPrefs() {
  var prefs = getPrefs();
  document.documentElement.classList.toggle('a11y-mode', prefs.a11y);

  var section = document.getElementById('notifications-section');
  if (section) section.style.display = prefs.notifications ? '' : 'none';

  var a11yToggle = document.getElementById('pref-a11y');
  if (a11yToggle) a11yToggle.checked = prefs.a11y;
  var notifToggle = document.getElementById('pref-notifications');
  if (notifToggle) notifToggle.checked = prefs.notifications;
}

document.addEventListener('DOMContentLoaded', applyPrefs);
