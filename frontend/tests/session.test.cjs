const {test} = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
test('401 clears session, validation fields survive and auth never falls back to mock', async () => {
  let expired = 0;
  const context = {API_URL:'http://localhost:8080/api', State:{token:'expired'}, DEV_MODE:true, DEV_LATENCY:0,
    handleSessionExpired:()=>{expired++; context.State.token=null;},
    devMock:()=>({token:'fake'}),
    fetch:async()=>({status:401,ok:false,text:async()=>'{"message":"Sessão inválida"}'})};
  vm.createContext(context);
  vm.runInContext(fs.readFileSync('services/api.js','utf8'),context);
  await assert.rejects(context.api.get('/users/me'), {status:401});
  assert.equal(expired,1);
  assert.equal(context.State.token,null);
  await assert.rejects(context.api.post('/auth/login',{}), {status:401});
  assert.equal(expired,1);
  context.fetch = async()=>{throw new Error('offline');};
  await assert.rejects(context.api.post('/auth/register',{}), {code:'NETWORK_ERROR'});
  assert.equal(context.normalizeError(400,{errors:{rm:'Obrigatório'}}).fields.rm,'Obrigatório');
});
