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
  /* Login (sem papel explícito) reaproveita o último perfil de dev persistido. */
  var saved = typeof devRestoreUser === 'function' ? devRestoreUser() : null;
  if (saved && !raw.role && !raw.name) raw = { email: raw.email, password: raw.password, role: saved.role, name: saved.name, rm: saved.rm, authorized: saved.authorized };
  var role = String(raw.role || 'ALUNO').toUpperCase();
  if (role !== 'PROFESSOR') role = 'ALUNO';
  var user = {
    id: role === 'PROFESSOR' ? 900 : 0,
    name: (raw.name && String(raw.name).trim()) || (role === 'PROFESSOR' ? 'Professor' : 'Aluno'),
    email: (!typedEmail || isKeyAsEmail) ? DEV_ACCESS_KEY : typedEmail,
    role: role,
    rm: role === 'ALUNO' ? String(raw.rm || '').trim() || null : null,
    authorized: role === 'PROFESSOR'
      ? Boolean(raw.authorized !== undefined ? raw.authorized : (saved && saved.role === 'PROFESSOR' ? saved.authorized : true))
      : false,
    dev: true,
  };
  var res = { token: 'dev-bypass-token', user: user, dev: true };

  if (typeof devReset === 'function') devReset();
  if (typeof devPersistUser === 'function') devPersistUser(user);
  storeAuth(res);
  if (typeof toast === 'function') toast('Modo dev ativado — dados de demonstração', 'warn');
  return res;
}
