/* ── Camada central de comunicação com o backend (Sprint 1) ──
   Todas as chamadas HTTP passam por aqui.
   - envia/recebe JSON
   - injeta JWT no header Authorization
   - interpreta erros padrão do Spring Boot (Sprint 10)
   - detecta 401 (Sessão expirada, Sprint 18)
   - trata erros de rede/timeout (Sprint 19)
*/

function normalizeError(status, payload) {
  var err = new Error((payload && payload.message) || 'Erro inesperado');
  err.status = status;
  err.code = (payload && payload.error) || 'ERROR';
  err.fields = (payload && payload.fields) || null;
  return err;
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
    if (!isAuthEndpoint) {
      handleSessionExpired();
    }
    throw normalizeError(401, payload);
  }

  if (!res.ok) {
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