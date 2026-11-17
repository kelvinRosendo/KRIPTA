/* ── Navegação entre telas ── */
var PUBLIC_SCREENS = ['login', 'register'];

/* Papéis da plataforma (RN01/RN02): aluno e professor. */
function userRole() {
  return String((State.user && State.user.role) || 'ALUNO').toUpperCase();
}
function isProfessor() {
  return userRole() === 'PROFESSOR';
}
function isAuthorizedTeacher() {
  return isProfessor() && Boolean(State.user && State.user.authorized);
}

/* Professor e aluno têm áreas distintas: mostra/esconde itens do menu. */
function applyRoleNav() {
  var prof = typeof isProfessor === 'function' && isProfessor();
  var canApprove = typeof isAuthorizedTeacher === 'function' && isAuthorizedTeacher();
  document.querySelectorAll('.navitem[data-screen="professor"]').forEach(function (n) {
    n.style.display = prof ? '' : 'none';
  });
  /* UC06/FA02: só professor com autorização enxerga a área de aprovação. */
  document.querySelectorAll('.navitem[data-screen="aprovacoes"]').forEach(function (n) {
    n.style.display = (prof && canApprove) ? '' : 'none';
  });
  document.querySelectorAll('.navitem[data-screen="home"], .navitem[data-screen="tasks"], .navitem[data-screen="materias"], .navitem[data-screen="ia"], .navitem[data-screen="perfil"]').forEach(function (n) {
    n.style.display = prof ? 'none' : '';
  });
}

/* Telas exclusivas do aluno — professor é redirecionado para o painel. */
function defaultScreenForRole() {
  return isProfessor() ? 'professor' : 'home';
}

/*
 * Navega para uma tela.
 * - Telas protegidas sem token → redireciona para login e guarda o destino.
 * - Telas públicas: login/register (sem bottom nav).
 * - Após navegar para tela autenticada, dispara o render dinâmico.
 */
function goTo(screenName) {
  if (screenName === 'insignias' && isProfessor()) screenName = 'professor';
  /* Professor não tem acesso ao agente de IA (Kai). */
  if (typeof isProfessor === 'function' && isProfessor() && screenName === 'ia') screenName = 'professor';
  /* Área de aprovação exige professor autorizado (UC06/FA02). */
  if (screenName === 'aprovacoes' && typeof isAuthorizedTeacher === 'function' && !isAuthorizedTeacher()) {
    screenName = (typeof isProfessor === 'function' && isProfessor()) ? 'professor' : 'home';
  }
  var isPublic = PUBLIC_SCREENS.indexOf(screenName) !== -1;

  if (!isPublic && typeof isAuthenticated === 'function' && !isAuthenticated()) {
    window.__afterAuth = screenName;
    screenName = 'login';
    isPublic = true;
  }

  var active = document.querySelector('.screen.active');
  if (active && active.id === 'screen-' + screenName) return;
  applyScreen(screenName, isPublic);
}

/* Atualiza a tela e inicia seu carregamento sem bloquear a navegação. */
function applyScreen(screenName, isPublic) {
  document.querySelectorAll('.screen').forEach(function (s) {
    s.classList.remove('active');
  });
  var target = document.getElementById('screen-' + screenName);
  if (target) target.classList.add('active');

  document.querySelectorAll('.navitem').forEach(function (n) {
    var active = !isPublic && n.dataset.screen === (screenName === 'materia-detalhe' ? 'materias' : screenName);
    n.classList.toggle('active', active);
    if (active) n.setAttribute('aria-current', 'page');
    else n.removeAttribute('aria-current');
  });

  var nav = document.getElementById('bottomnav');
  var showNavigation = !isPublic && (typeof isAuthenticated !== 'function' || isAuthenticated());
  document.getElementById('app-header').hidden = !showNavigation;
  if (!showNavigation) {
    nav.classList.add('hidden');
    nav.style.display = 'none';
  } else {
    nav.classList.remove('hidden');
    nav.style.display = 'flex';
  }

  applyRoleNav();

  window.scrollTo(0, 0);

  if (!isPublic && typeof renderScreen === 'function') {
    renderScreen(screenName);
  }
}

/* Apenas para acesso explícito a telas públicas */
function goToAuth(screen) {
  if (typeof isAuthenticated === 'function' && isAuthenticated()) {
    goTo('home');
    return;
  }
  goTo(screen);
}

/* Depois do login/cadastro, volta para onde o usuário queria ir */
function resolvePostAuth(preferredScreen) {
  var dest = preferredScreen || window.__afterAuth || defaultScreenForRole();
  window.__afterAuth = null;
  if (isProfessor() && (dest === 'home' || dest === 'tasks' || dest === 'materias')) dest = 'professor';
  if (typeof updateStatusbarAvatar === 'function') updateStatusbarAvatar();
  goTo(dest);
}
