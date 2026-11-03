/* ── Camada central de comunicação com o backend (Sprint 1) ──
   Todas as chamadas HTTP passam por aqui.
   - envia/recebe JSON
   - injeta JWT no header Authorization
   - interpreta erros padrão do Spring Boot (Sprint 10)
   - detecta 401 (Sessão expirada, Sprint 18)
   - trata erros de rede/timeout (Sprint 19)
   - com DEV_MODE ligado, cai em dados de demonstração (ver config.js);
     com DEV_MODE desligado, nenhum mock: os erros reais propagam
*/

function normalizeError(status, payload) {
  var err = new Error((payload && payload.message) || 'Erro inesperado');
  err.status = status;
  err.code = (payload && payload.error) || 'ERROR';
  err.fields = (payload && payload.fields) || null;
  return err;
}

/* Interruptor global. Fora dele, devFallback é inerte por completo. */
function devMockEnabled() {
  return Boolean(DEV_MODE);
}

/* Piso de latência do mock: segura a resposta o suficiente para o navegador
   pintar o skeleton entre o showLoading() e a renderização do conteúdo.
   Só roda quando existe mock de resposta; rota sem mock não ganha atraso. */
function devDelay() {
  var ms = Number(DEV_LATENCY) || 0;
  if (ms <= 0) return Promise.resolve();
  return new Promise(function (resolve) { setTimeout(resolve, ms); });
}

async function devFallback(method, path, body) {
  if (!devMockEnabled()) return undefined;
  if (typeof devMock !== 'function') return undefined;
  var value;
  try {
    value = devMock(method, path, body);
  } catch (e) {
    console.warn('Mock de dev falhou para', path, e);
    return undefined;
  }
  if (value === undefined) return undefined;
  await devDelay();
  return value;
}

async function apiRequest(method, path, body) {
  var headers = { 'Content-Type': 'application/json' };
  if (State.token) {
    headers['Authorization'] = 'Bearer ' + State.token;
  }

  var res;
  try {
    res = await fetch(API_URL + path, {
      method: method,
      headers: headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
  } catch (e) {
    var mock = await devFallback(method, path, body);
    if (mock !== undefined) return mock;
    var netErr = new Error('Não foi possível conectar ao servidor. Verifique sua conexão.');
    netErr.status = 0;
    netErr.code = 'NETWORK_ERROR';
    throw netErr;
  }

  var payload = null;
  var text = await res.text();
  if (text) {
    try {
      payload = JSON.parse(text);
    } catch (e) {
      payload = null;
    }
  }

  if (res.status === 401) {
    var isAuthEndpoint = path.indexOf('/auth/login') !== -1 || path.indexOf('/auth/register') !== -1;
    /* Sem mock, o 401 é a resposta real do servidor: encerra a sessão. */
    if (!isAuthEndpoint && !devMockEnabled()) {
      handleSessionExpired();
    }
    var mock401 = await devFallback(method, path, body);
    if (mock401 !== undefined) return mock401;
    throw normalizeError(401, payload);
  }

  if (!res.ok) {
    var mockErr = await devFallback(method, path, body);
    if (mockErr !== undefined) return mockErr;
    throw normalizeError(res.status, payload);
  }

  return payload;
}

var api = {
  get: function (path) {
    return apiRequest('GET', path);
  },
  post: function (path, body) {
    return apiRequest('POST', path, body);
  },
  put: function (path, body) {
    return apiRequest('PUT', path, body);
  },
  patch: function (path, body) {
    return apiRequest('PATCH', path, body);
  },
  del: function (path) {
    return apiRequest('DELETE', path);
  },
  request: apiRequest,
};