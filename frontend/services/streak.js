/* ── Uso autenticado e sequência diária (RF09 / RN07 / UC07) ──
   Enquanto o aluno está autenticado e com a aba visível, o tempo de uso é
   enviado ao servidor (mock em dev). Ao acumular STREAK_MIN_SECONDS no dia,
   o streak avança no máximo uma vez (regra garantida no backend/mock). */

var STREAK_TICK_SECONDS = 15;
var streakTimer = null;
var streakAccumulated = 0;
var streakLastSent = 0;

function streakSupported() {
  return typeof State !== 'undefined' && State.token && typeof api !== 'undefined';
}

async function streakHeartbeat(payload) {
  try {
    var res = await api.post('/usage/heartbeat', { seconds: payload });
    applyStreakState(res);
    return res;
  } catch (e) {
    return null;
  }
}

function applyStreakState(res) {
  if (!res) return;
  var ring = document.getElementById('home-streak-ring');
  if (ring) {
    var circumference = 2 * Math.PI * 23; /* r = 23 */
    var offset = circumference * (1 - Math.min(1, (res.progress || 0) / 100));
    ring.setAttribute('stroke-dashoffset', String(offset));
  }
  var days = document.getElementById('home-streak-days');
  if (days && res.streak !== undefined) {
    days.textContent = res.streak + ' dia' + (res.streak === 1 ? '' : 's') + ' seguido' + (res.streak === 1 ? '' : 's') + '!';
  }
  var sub = document.getElementById('home-streak-sub');
  if (sub && res.threshold) {
    if (res.advanced) {
      sub.textContent = 'Sequência garantida hoje — continue estudando!';
    } else {
      var mins = Math.floor((res.seconds || 0) / 60);
      var need = Math.ceil((res.threshold - (res.seconds || 0)) / 60);
      sub.textContent = mins + ' min hoje · faltam ' + need + ' min para manter a sequência';
    }
  }
}

function startStreakTracking() {
  stopStreakTracking();
  /* Streak é exclusivo do aluno (RF09/RN07). */
  if (typeof isProfessor === 'function' && isProfessor()) return;
  if (!streakSupported()) return;
  streakLastSent = Date.now();
  streakTimer = setInterval(function () {
    if (document.hidden) { streakLastSent = Date.now(); return; }
    var now = Date.now();
    var elapsed = Math.floor((now - streakLastSent) / 1000);
    if (elapsed <= 0) return;
    streakLastSent = now;
    streakAccumulated += elapsed;
    if (streakAccumulated >= STREAK_TICK_SECONDS) {
      var chunk = streakAccumulated;
      streakAccumulated = 0;
      streakHeartbeat(chunk);
    }
  }, STREAK_TICK_SECONDS * 1000);
}

function stopStreakTracking() {
  if (streakTimer) clearInterval(streakTimer);
  streakTimer = null;
}

document.addEventListener('visibilitychange', function () {
  if (!document.hidden) streakLastSent = Date.now();
});
