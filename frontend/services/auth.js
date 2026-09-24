/* ── Autenticação (Sprint 3) ── */
async function registerUser(data) {
  var res = await api.post('/auth/register', data);
  storeAuth(res);
  return res;
}

async function loginUser(data) {
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