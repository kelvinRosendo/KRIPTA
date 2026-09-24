/* ── Navegação entre telas ── */
var PUBLIC_SCREENS = ['login', 'register'];

/*
 * Navega para uma tela.
 * - Telas protegidas sem token → redireciona para login e guarda o destino.
 * - Telas públicas: login/register (sem bottom nav).
 * - Após navegar para tela autenticada, dispara o render dinâmico.
 */
function goTo(screenName) {
  var isPublic = PUBLIC_SCREENS.indexOf(screenName) !== -1;

  if (!isPublic && typeof isAuthenticated === 'function' && !isAuthenticated()) {
    window.__afterAuth = screenName;
    screenName = 'login';
    isPublic = true;
  }

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
  var dest = window.__afterAuth || 'home';
  window.__afterAuth = null;
  goTo(dest);
}