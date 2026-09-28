/* ── Configuração de ambiente (Sprint 20) ──
   ─────────────────────────────────────────────────────────────
   DEV_MODE é o interruptor global do modo de demonstração.
   Ferramenta temporária: some quando o backend entrar.

   DEV_MODE = true
     · devMock responde no lugar da API
     · devFallback substitui falha de rede, 401, 404 e 500
     · DEV_LATENCY (ms) segura a resposta para o skeleton ser pintado

   DEV_MODE = false  (padrão)
     · nenhum mock, nenhum fallback
     · 401, 404, 500 e falha de rede chegam ao fluxo de erro real
     · é este estado que permite validar E2E contra o Spring Boot

   Precedência:
     1) ?mock=on | ?mock=off na URL  (temporário, só nesta aba)
     2) DEV_MODE abaixo             (permanente, manual)
   ─────────────────────────────────────────────────────────────
*/
const ENV = 'dev';

const CONFIG = {
  dev: {
    API_URL: 'http://localhost:8080/api',
    /* Entrada de dev: chave liberada em e-mail OU senha (vazio = desativado) */
    DEV_ACCESS_KEY: 'kripta08',
    /* Interruptor do mock. true = demonstração; false = API real. */
    DEV_MODE: false,
    /* Piso de latência do mock, em ms. Simula o servidor para o skeleton aparecer. */
    DEV_LATENCY: 400,
  },
  prod: {
    API_URL: 'https://api.kripta.app/api',
    DEV_ACCESS_KEY: '',
    DEV_MODE: false,
    DEV_LATENCY: 0,
  },
};

function resolveDevMode() {
  var override = null;
  try {
    var pairs = String(window.location.search || '').replace(/^\?/, '').toLowerCase().split('&');
    for (var i = 0; i < pairs.length; i++) {
      var kv = pairs[i].split('=');
      if (kv[0] !== 'mock') continue;
      if (kv[1] === 'on' || kv[1] === 'true' || kv[1] === '1') override = true;
      if (kv[1] === 'off' || kv[1] === 'false' || kv[1] === '0') override = false;
    }
  } catch (e) {
    override = null;
  }
  if (override !== null) return override;
  return Boolean(CONFIG[ENV].DEV_MODE);
}

const API_URL = CONFIG[ENV].API_URL;
const DEV_ACCESS_KEY = CONFIG[ENV].DEV_ACCESS_KEY;
const DEV_LATENCY = CONFIG[ENV].DEV_LATENCY;
const DEV_MODE = resolveDevMode();

const APP_NAME = 'KRIPTA';