/* ── Loader de transição entre telas ──
   Anima o logo KRIPTA (4 peças) enquanto troca de tela.
   Portado do protótipo Ktestes e adaptado aos nomes do projeto. */

var LOADER_CYCLE_MS = 640;
var LOADER_QUADRANT_MS = 160;
var LOADER_FINISH_MS = 640;
var LOADER_SWITCH_MS = 720;
var LOADER_HIDE_MS = 950;
var LOADER_PIECE_ORDER = ['.piece-orange', '.piece-indigo', '.piece-purple', '.piece-teal'];

var LOADER = {
  timers: [],
  logoTimeout: null,
  logoInterval: null,
};

function loaderOverlay() {
  return document.getElementById('loader-overlay');
}

function loaderShowQuadrant(index) {
  var overlay = loaderOverlay();
  if (!overlay) return;
  overlay.querySelectorAll('.piece').forEach(function (piece) {
    piece.classList.remove('active');
  });
  var active = overlay.querySelector(LOADER_PIECE_ORDER[index % LOADER_PIECE_ORDER.length]);
  if (active) active.classList.add('active');
}

function loaderStartCycle() {
  var overlay = loaderOverlay();
  if (!overlay) return;
  var logo = overlay.querySelector('.kripta-logo');
  clearTimeout(LOADER.logoTimeout);
  clearInterval(LOADER.logoInterval);
  if (logo) logo.classList.remove('complete');

  var time = performance.now() % LOADER_CYCLE_MS;
  var index = Math.floor(time / LOADER_QUADRANT_MS);
  loaderShowQuadrant(index);

  LOADER.logoTimeout = setTimeout(function () {
    loaderShowQuadrant(index + 1);
    LOADER.logoInterval = setInterval(function () {
      loaderShowQuadrant(Math.floor((performance.now() % LOADER_CYCLE_MS) / LOADER_QUADRANT_MS));
    }, LOADER_QUADRANT_MS);
  }, LOADER_QUADRANT_MS - (time % LOADER_QUADRANT_MS));
}

function loaderFinishCycle() {
  var overlay = loaderOverlay();
  clearTimeout(LOADER.logoTimeout);
  clearInterval(LOADER.logoInterval);
  if (!overlay) return;
  overlay.querySelectorAll('.piece').forEach(function (piece) {
    piece.classList.remove('active');
  });
  var logo = overlay.querySelector('.kripta-logo');
  if (logo) logo.classList.add('complete');
}

function loaderClearTimers() {
  LOADER.timers.forEach(clearTimeout);
  LOADER.timers = [];
}

/*
 * Executa a transição animada e chama switchFn no momento da troca de tela.
 * Sem o overlay no DOM, a troca acontece imediatamente.
 */
function playPageTransition(switchFn) {
  var overlay = loaderOverlay();
  if (!overlay) { switchFn(); return; }

  loaderClearTimers();

  overlay.classList.remove('hidden');
  loaderStartCycle();

  LOADER.timers.push(setTimeout(function () { loaderFinishCycle(); }, LOADER_FINISH_MS));
  LOADER.timers.push(setTimeout(function () { switchFn(); }, LOADER_SWITCH_MS));
  LOADER.timers.push(setTimeout(function () {
    overlay.classList.add('hidden');
  }, LOADER_HIDE_MS));
}
