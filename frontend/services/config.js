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

   O modo final não aceita ativação de mocks pela URL.
   ─────────────────────────────────────────────────────────────
*/
const ENV = 'dev';

const CONFIG = {
  dev: {
    API_URL: 'http://localhost:8080/api',
    /* Entrada de dev: chave liberada em e-mail OU senha (vazio = desativado) */
    DEV_ACCESS_KEY: '',
    /* Interruptor do mock. true = demonstração; false = API real. */
    DEV_MODE: false,
    /* Piso de latência do mock, em ms. Simula o servidor para o skeleton aparecer. */
    DEV_LATENCY: 150,
  },
  prod: {
    API_URL: 'https://api.kripta.app/api',
    DEV_ACCESS_KEY: '',
    DEV_MODE: false,
    DEV_LATENCY: 0,
  },
};

function resolveDevMode() {
  return Boolean(CONFIG[ENV].DEV_MODE);
}

const API_URL = CONFIG[ENV].API_URL;
const DEV_ACCESS_KEY = CONFIG[ENV].DEV_ACCESS_KEY;
const DEV_LATENCY = CONFIG[ENV].DEV_LATENCY;
const DEV_MODE = resolveDevMode();

const APP_NAME = 'KRIPTA';