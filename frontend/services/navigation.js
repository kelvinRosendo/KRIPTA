/* ── Navegação entre telas ── */
var PUBLIC_SCREENS = ['login', 'register'];
var __appBooted = false;

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
  document.querySelectorAll('.navitem[data-screen="home"], .navitem[data-screen="tasks"], .navitem[data-screen="materias"], .navitem[data-screen="ia"]').forEach(function (n) {
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
 * - A partir da segunda navegação, roda a transição animada do loader.
 */
function goTo(screenName) {
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

  var apply = function () { applyScreen(screenName, isPublic); };

  if (!__appBooted) {
    __appBooted = true;
    apply();
    return;
  }

  if (typeof playPageTransition === 'function') {
    playPageTransition(apply);
  } else {
    apply();
  }
}

/* Aplica a troca de tela em si (usada pelo goTo e pela transição). */
function applyScreen(screenName, isPublic) {
  document.querySelectorAll('.screen').forEach(function (s) {
    s.classList.remove('active');
  });
  var target = document.getElementById('screen-' + screenName);
  if (target) target.classList.add('active');

  document.querySelectorAll('.navitem').forEach(function (n) {
    n.classList.remove('active');
  });
  var navItem = document.querySelector('.navitem[data-screen="' + screenName + '"]');
  if (navItem && !isPublic) navItem.classList.add('active');

  var nav = document.getElementById('bottomnav');
  if (isPublic || (typeof isAuthenticated === 'function' && !isAuthenticated())) {
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
function resolvePostAuth() {
  var dest = window.__afterAuth || defaultScreenForRole();
  window.__afterAuth = null;
  if (isProfessor() && (dest === 'home' || dest === 'tasks' || dest === 'materias')) dest = 'professor';
  if (typeof updateStatusbarAvatar === 'function') updateStatusbarAvatar();
  goTo(dest);
}