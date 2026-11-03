const assert = require('node:assert/strict');
const base = 'http://localhost:8080/api';
const account = {nome: 'Aluno CI', email: 'auth-ci@example.com', senha: 'ci-test-password', tipo: 'ALUNO', rm: '12345'};
async function request(path, status, body, token, method) {
  const response = await fetch(base + path, {
    method: method || (body ? 'POST' : 'GET'),
    headers: {'Content-Type': 'application/json', ...(token ? {Authorization: 'Bearer ' + token} : {})},
    body: body ? JSON.stringify(body) : undefined
  });
  assert.equal(response.status, status, path);
  return response.status === 204 ? null : response.json();
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
    await request('/auth/register', 400, {...account, tipo: 'USUARIO'});
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
  assert.equal(user.rm, '12345');
  assert.equal(user.podeAprovar, false);
  await request('/conteudos/1/aprovar', 403, {}, session.token, 'PATCH');
  if (!process.argv.includes('--existing')) {
    const subject = await request('/disciplinas', 201, {nome:'Matemática CI', cor:'#123456'}, session.token);
    await request('/disciplinas/' + subject.id, 200, {nome:'Matemática atualizada', cor:'#654321'}, session.token, 'PUT');
    const other = {...account, email:'other-ci@example.com', rm:'67890'};
    await request('/auth/register', 201, other);
    const otherSession = await request('/auth/login', 200, other);
    assert.equal((await request('/disciplinas', 200, undefined, otherSession.token)).length, 0);
    await request('/disciplinas/' + subject.id, 404, undefined, otherSession.token);
    await request('/disciplinas/' + subject.id, 404, {nome:'Invasão'}, otherSession.token, 'PUT');
    await request('/disciplinas/' + subject.id, 404, undefined, otherSession.token, 'DELETE');
  } else {
    const subjects = await request('/disciplinas', 200, undefined, session.token);
    const subject = subjects.find(item => item.nome === 'Matemática atualizada');
    assert.ok(subject, 'Subject must survive backend restart');
    assert.equal(subject.cor, '#654321');
    await request('/disciplinas/' + subject.id, 204, undefined, session.token, 'DELETE');
    await request('/disciplinas/' + subject.id, 404, undefined, session.token);
  }
  const cors = await fetch(base + '/auth/login', {method: 'OPTIONS', headers: {
    Origin: 'http://localhost:5173', 'Access-Control-Request-Method': 'POST',
    'Access-Control-Request-Headers': 'content-type'
  }});
  assert.equal(cors.headers.get('access-control-allow-origin'), 'http://localhost:5173');
  console.log('Authentication HTTP checks passed' + (process.argv.includes('--existing') ? ' after restart' : ''));
})().catch(error => { console.error(error); process.exitCode = 1; });
