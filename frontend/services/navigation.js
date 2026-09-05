/* ── Navegação entre telas ── */
function goTo(screenName) {
  // esconde todas as telas
  document.querySelectorAll('.screen').forEach(function(s) {
    s.classList.remove('active');
  });

  // ativa a tela alvo
  var target = document.getElementById('screen-' + screenName);
  if (target) {
    target.classList.add('active');
  }

  // atualiza o estado ativo no nav
  document.querySelectorAll('.navitem').forEach(function(n) {
    n.classList.remove('active');
  });
  var navItem = document.querySelector('.navitem[data-screen="' + screenName + '"]');
  if (navItem) {
    navItem.classList.add('active');
  }

  // esconde nav no onboarding
  var nav = document.getElementById('bottomnav');
  if (screenName === 'onboarding') {
    nav.classList.add('hidden');
    nav.style.display = 'none';
  } else {
    nav.classList.remove('hidden');
    nav.style.display = 'flex';
  }

  window.scrollTo(0, 0);
}
