function uiIcon(name) {
  return '<svg class="ui-icon" aria-hidden="true" focusable="false"><use href="#icon-' + name + '"></use></svg>';
}

/* ── Helpers de UI compartilhados ── */

function esc(str) {
  if (str === null || str === undefined) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function el(tag, className, text) {
  var node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
}

function empty(container) {
  if (!container) return;
  while (container.firstChild) container.removeChild(container.firstChild);
}

function skeleton() {
  var blocks = '';
  for (var i = 0; i < 3; i++) {
    blocks += '<div class="card p-4 mb-2"><div class="h-4 w-2/3 bg-surface-2 rounded mb-2"></div><div class="h-3 w-1/3 bg-surface-2 rounded"></div></div>';
  }
  return '<div class="loading-skeleton" role="status"><span class="sr-only">Carregando…</span><div aria-hidden="true">' + blocks + '</div></div>';
}

function crystalIllustration(icon) {
  return '<div class="crystal-illustration" aria-hidden="true"><svg viewBox="0 0 112 83" focusable="false">' +
    '<path fill="#ff6b35" d="m17 27 4 7 7 4-7 4-4 8-4-8-7-4 7-4Z"/>' +
    '<path fill="#42ddd7" d="m95 11 3 5 5 3-5 3-3 5-3-5-5-3 5-3Z"/>' +
    '<path fill="#b28fff" d="m89 30 13 14-7 26-20-6 2-23Z"/>' +
    '<path fill="#625add" d="m55 5 23 19 6 33-29 22-28-22 5-33Z"/>' +
    '<path fill="#fff" opacity=".22" d="m55 5 23 19-23 10-23-10Zm0 29 23-10 6 33-29 22Z"/>' +
    '<path fill="#171432" opacity=".25" d="m55 34-23-10-5 33 28 22Z"/></svg>' + uiIcon(icon || 'book') + '</div>';
}

function emptyState(title, subtitle, icon) {
  return (
    '<div class="px-app mt-6 flex flex-col items-center text-center py-10">' +
    crystalIllustration(icon) +
    '<div class="font-display text-sm font-bold text-text-hi">' + esc(title) + '</div>' +
    (subtitle ? '<div class="text-xs text-text-mid mt-1 leading-relaxed max-w-[240px]">' + esc(subtitle) + '</div>' : '') +
    '</div>'
  );
}

function toast(message, type) {
  var existing = document.getElementById('toast');
  if (existing) existing.remove();
  var t = el('div', 'fixed bottom-[120px] left-1/2 -translate-x-1/2 z-[200] rounded-md px-4 py-3 text-[12.5px] font-bold text-white shadow-lg');
  t.id = 'toast';
  /* RNF03: leitores de tela anunciam mudanças de estado. */
  t.setAttribute('role', type === 'error' ? 'alert' : 'status');
  t.setAttribute('aria-live', type === 'error' ? 'assertive' : 'polite');
  t.style.background = type === 'error' ? '#a52a2a' : type === 'warn' ? '#984000' : '#3D3DB4';
  t.textContent = message;
  document.body.appendChild(t);
  setTimeout(function () {
    t.classList.add('toast-exit');
    t.addEventListener('animationend', function () { t.remove(); }, { once: true });
    setTimeout(function () { t.remove(); }, 300);
  }, 2600);
}

function motionAllowed() {
  return !matchMedia('(prefers-reduced-motion: reduce)').matches &&
    !document.documentElement.classList.contains('a11y-mode');
}

async function dissolveTask(id) {
  var screen = document.querySelector('.screen.active');
  var card = screen && screen.querySelector('[data-task="' + CSS.escape(String(id)) + '"]');
  if (!card || !motionAllowed()) return;
  var bounds = card.getBoundingClientRect();
  var dust = el('div', 'task-dust');
  dust.setAttribute('aria-hidden', 'true');
  dust.style.left = bounds.left + 'px';
  dust.style.top = bounds.top + 'px';
  dust.style.width = bounds.width + 'px';
  dust.style.height = bounds.height + 'px';
  for (var i = 0; i < 36; i++) {
    var piece = el('span');
    piece.style.left = (i * 37 % 100) + '%';
    piece.style.top = (i * 19 % 100) + '%';
    piece.style.setProperty('--drift', (i % 2 ? 1 : -1) * (12 + i % 17) + 'px');
    piece.style.setProperty('--delay', i % 6 * 18 + 'ms');
    dust.appendChild(piece);
  }
  document.body.appendChild(dust);
  try {
    await card.animate([
      { opacity: 1, filter: 'blur(0px)', transform: 'translateY(0)' },
      { opacity: 0, filter: 'blur(6px)', transform: 'translateY(-14px)' }
    ], { duration: 480, easing: 'ease-in', fill: 'forwards' }).finished;
  } finally {
    dust.remove();
  }
}

function errorView(message) {
  return (
    '<div class="px-app mt-6 flex flex-col items-center text-center py-10">' +
    '<div class="state-icon state-icon-error">' + uiIcon('alert') + '</div>' +
    '<div class="font-display text-sm font-bold text-text-hi">' + esc(message || 'Algo deu errado') + '</div>' +
    '<button class="btn-ghost !mt-4 !w-auto !py-2.5 !px-6" onclick="window.location.reload()">Tentar novamente</button>' +
    '</div>'
  );
}

function showLoading(container) {
  if (!container) return;
  container.innerHTML = skeleton();
}

function cleanError(err) {
  if (err.fields) {
    var first = Object.keys(err.fields)[0];
    return err.fields[first];
  }
  return err.message || 'Erro inesperado';
}

function submitBtnLoading(btn, text) {
  if (!btn) return;
  btn.dataset.label = btn.textContent;
  btn.textContent = text || 'Aguarde…';
  btn.disabled = true;
  btn.setAttribute('aria-busy', 'true');
}

function submitBtnReset(btn) {
  if (!btn) return;
  btn.textContent = btn.dataset.label || btn.textContent;
  btn.disabled = false;
  btn.removeAttribute('aria-busy');
}
