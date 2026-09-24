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

function spinner() {
  return '<div class="flex items-center justify-center py-10"><div class="w-8 h-8 border-2 border-border border-t-indigo rounded-full animate-spin"></div></div>';
}

function skeleton() {
  var blocks = '';
  for (var i = 0; i < 3; i++) {
    blocks += '<div class="card p-4 mb-2"><div class="h-4 w-2/3 bg-surface-2 rounded mb-2"></div><div class="h-3 w-1/3 bg-surface-2 rounded"></div></div>';
  }
  return '<div class="px-app mt-3">' + blocks + '</div>';
}

function emptyState(title, subtitle) {
  return (
    '<div class="px-app mt-6 flex flex-col items-center text-center py-10">' +
    '<div class="text-3xl mb-3">🍃</div>' +
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
  t.style.background = type === 'error' ? '#C0392B' : type === 'warn' ? '#FF6B35' : '#3D3DB4';
  t.textContent = message;
  document.body.appendChild(t);
  setTimeout(function () { t.remove(); }, 2600);
}

function errorView(message) {
  return (
    '<div class="px-app mt-6 flex flex-col items-center text-center py-10">' +
    '<div class="text-3xl mb-3">⚠️</div>' +
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
}

function submitBtnReset(btn) {
  if (!btn) return;
  btn.textContent = btn.dataset.label || btn.textContent;
  btn.disabled = false;
}