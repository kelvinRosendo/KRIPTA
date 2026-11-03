const {test}=require('node:test'); const assert=require('node:assert/strict'); const vm=require('node:vm'); const fs=require('node:fs');
test('web maps credentials and user, registration does not create a session',async()=>{
 const calls=[]; const context={DEV_MODE:false,State:{},api:{post:async(p,b)=>{calls.push([p,b]);return p.endsWith('login')?{token:'jwt',id:1,nome:'Aluno',tipo:'ALUNO',email:b.email}:{id:1};},get:async()=>({id:1,nome:'Aluno',tipo:'ALUNO'})}};
 vm.createContext(context); vm.runInContext(fs.readFileSync('services/auth.js','utf8'),context);
 await context.registerUser({name:'Aluno',email:'a@b.com',password:'secret',role:'ALUNO',rm:'123'});
 assert.equal(context.State.token,undefined); assert.equal(calls[0][1].rm,'123'); assert.equal(calls[0][1].senha,'secret');
 await context.loginUser({email:'a@b.com',password:'secret'}); assert.equal(context.State.token,'jwt'); assert.equal(context.State.user.name,'Aluno'); assert.equal(calls[1][1].senha,'secret');
 context.logout(); assert.equal(context.State.token,null); assert.equal(context.State.user,null);
});