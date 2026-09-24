/* ── Progresso e Gamificação (Sprints 12 e 13) ── */
async function getProgress() {
  return api.get('/progress');
}

async function getGamificationStats() {
  return api.get('/gamification/stats');
}

async function getAchievements() {
  return api.get('/gamification/achievements');
}

function levelTitle(level) {
  var titles = ['Iniciante', 'Estudante', 'Aprendiz', 'Curioso', 'Dedicado', 'Exploradora', 'Determinado', 'Mestrando', 'Referência', 'Lenda'];
  return titles[level - 1] || 'Exploradora';
}