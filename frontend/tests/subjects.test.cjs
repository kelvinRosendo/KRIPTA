const {test} = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
test('disciplinas maps list, create, update and delete contracts', async () => {
  const calls = [];
  const row = {id: 7, nome: 'Matemática', cor: '#123456'};
  const context = {api: Object.fromEntries(['get','post','put','del'].map(method => [method, async (path, body) => {
    calls.push({method, path, body});
    return method === 'get' && path === '/disciplinas' ? [row] : row;
  }]))};
  vm.createContext(context);
  vm.runInContext(fs.readFileSync('services/subjects.js','utf8'), context);
  assert.equal((await context.getSubjects())[0].name, 'Matemática');
  assert.equal((await context.getSubject(7)).color, '#123456');
  await context.createSubject({name:'Matemática',color:'#123456'});
  await context.updateSubject(7,{name:'Matemática',color:'#123456'});
  await context.deleteSubject(7);
  assert.equal(calls[2].body.nome,'Matemática');
  assert.equal(calls[3].body.cor,'#123456');
  assert.equal(calls[4].path,'/disciplinas/7');
  assert.equal(calls[4].method,'del');
});
