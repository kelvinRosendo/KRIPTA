/* ── Autenticação (Sprint 3) ── */
async function registerUser(data) {
  if (isDevAccess(data)) return enterDevMode(data);
  var res = await api.post('/auth/register', data);
  storeAuth(res);
  return res;
}

async function loginUser(data) {
  if (isDevAccess(data)) return enterDevMode(data);
  var res = await api.post('/auth/login', data);
  storeAuth(res);
  return res;
}

function storeAuth(res) {
  if (res && res.token) {
    State.token = res.token;
    State.user = res.user || null;
  }
}

async function fetchMe() {
  var user = await api.get('/users/me');
  State.user = user;
  return user;
}

function logout() {
  State.token = null;
  State.user = null;
  State.currentSubject = null;
  State.currentUnit = null;
}

function isAuthenticated() {
  return Boolean(State.token);
}

/* ══════════════════════════════════════════════════════════════
   ENTRADA DE DEV (bypass)
   Com DEV_MODE ligado, digitar a chave (DEV_ACCESS_KEY) no e-mail
   E na senha dispensa o cadastro e entra direto na Home.

   Dependência INTENCIONAL e unidirecional com DEV_MODE:
   a chave só é aceita quando o interruptor está ligado. O bypass
   emite um token fictício (dev-bypass-token), que não tem valor
   contra a API real — se ele funcionasse com DEV_MODE desligado,
   entraria com token inválido e derrubaria a sessão no 401.
   Desligado, a validação E2E fica limpa: a chave é inerte.
   ══════════════════════════════════════════════════════════════ */

function normalizeDevKey(value) {
  return String(value === null || value === undefined ? '' : value).trim().toLowerCase();
}

function isDevAccess(data) {
  if (!DEV_MODE) return false;
  if (!DEV_ACCESS_KEY || !data) return false;
  return normalizeDevKey(data.email) === normalizeDevKey(DEV_ACCESS_KEY)
    && normalizeDevKey(data.password) === normalizeDevKey(DEV_ACCESS_KEY);
}

function enterDevMode(data) {
  var raw = data || {};
  var typedEmail = String(raw.email === undefined || raw.email === null ? '' : raw.email).trim();
  var isKeyAsEmail = normalizeDevKey(typedEmail) === normalizeDevKey(DEV_ACCESS_KEY);
  var user = {
    id: 0,
    name: (raw.name && String(raw.name).trim()) || 'Dev',
    email: (!typedEmail || isKeyAsEmail) ? DEV_ACCESS_KEY : typedEmail,
    dev: true,
  };
  var res = { token: 'dev-bypass-token', user: user, dev: true };

  if (typeof devReset === 'function') devReset();
  storeAuth(res);
  if (typeof toast === 'function') toast('Modo dev ativado — dados de demonstração', 'warn');
  return res;
}
