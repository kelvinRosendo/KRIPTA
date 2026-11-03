const assert = require('node:assert/strict');
const base = 'http://localhost:8080/api';
const account = {nome: 'Aluno CI', email: 'auth-ci@example.com', senha: 'ci-test-password', tipo: 'ALUNO', rm: '12345'};
async function request(path, status, body, token) {
  const response = await fetch(base + path, {
    method: body ? 'POST' : 'GET',
    headers: {'Content-Type': 'application/json', ...(token ? {Authorization: 'Bearer ' + token} : {})},
    body: body ? JSON.stringify(body) : undefined
  });
  assert.equal(response.status, status, path);
  return response.json();
}
(async () => {
  let ready = false;
  for (let attempt = 0; attempt < 90; attempt++) {
    try { ready = (await fetch(base + '/health')).ok; } catch {}
    if (ready) break;
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
  assert.ok(ready, 'Backend did not start');
  if (!process.argv.includes('--existing')) {
    await request('/auth/register', 400, {...account, rm: ''});
    await request('/auth/register', 400, {...account, tipo: 'ADMIN'});
    await request('/auth/register', 201, account);
    await request('/auth/register', 409, account);
  }
  await request('/users/me', 401);
  await request('/users/me', 401, undefined, 'invalid-token');
  await request('/auth/login', 401, {email: account.email, senha: 'incorrect'});
  const session = await request('/auth/login', 200, account);
  assert.ok(session.token);
  const user = await request('/users/me', 200, undefined, session.token);
  assert.equal(user.email, account.email);
  assert.equal(user.tipo, 'ALUNO');
  const cors = await fetch(base + '/auth/login', {method: 'OPTIONS', headers: {
    Origin: 'http://localhost:5173', 'Access-Control-Request-Method': 'POST',
    'Access-Control-Request-Headers': 'content-type'
  }});
  assert.equal(cors.headers.get('access-control-allow-origin'), 'http://localhost:5173');
  console.log('Authentication HTTP checks passed' + (process.argv.includes('--existing') ? ' after restart' : ''));
})().catch(error => { console.error(error); process.exitCode = 1; });
