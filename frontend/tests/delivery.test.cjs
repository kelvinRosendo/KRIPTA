const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
test('delivery mode cannot be changed to mocks through a URL',()=>{
 const ctx=vm.createContext({window:{location:{search:'?mock=on'}}});
 vm.runInContext(fs.readFileSync('services/config.js','utf8'),ctx);
 assert.equal(vm.runInContext('DEV_MODE',ctx),false);
 assert.equal(vm.runInContext('DEV_ACCESS_KEY',ctx),'');
});
