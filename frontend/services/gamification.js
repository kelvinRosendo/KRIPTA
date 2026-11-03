/* ── Progresso e Gamificação (Sprints 12 e 13) ── */

/* RN07: streak avança com pelo menos 10 minutos de uso autenticado no dia. */
var STREAK_MIN_SECONDS = 600;

async function getProgress() {
  return api.get('/progresso');
}

async function getGamificationStats() {
  return api.get('/gamificacao/estatisticas');
}

async function getAchievements() {
  return api.get('/gamificacao/conquistas');
}

function levelTitle(level) {
  var titles = ['Iniciante', 'Estudante', 'Aprendiz', 'Curioso', 'Dedicado', 'Exploradora', 'Determinado', 'Mestrando', 'Referência', 'Lenda'];
  return titles[level - 1] || 'Exploradora';
}