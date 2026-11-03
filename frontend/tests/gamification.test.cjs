const {test}=require('node:test');
const assert=require('node:assert/strict');
const vm=require('node:vm');
const fs=require('node:fs');
test('gamification reads persisted routes and heartbeat never reports client time',async()=>{
  const calls=[];
  const c={document:{addEventListener:()=>{},getElementById:()=>null},api:{get:async p=>{calls.push([p]);return {};},post:async(p,b)=>{calls.push([p,b]);return {};}}};
  vm.createContext(c);
  for(const name of ['gamification','streak'])vm.runInContext(fs.readFileSync('services/'+name+'.js','utf8'),c);
  await c.getProgress();await c.getGamificationStats();await c.getAchievements();await c.streakHeartbeat(999999);
  assert.equal(calls[0][0],'/progresso');
  assert.equal(calls[1][0],'/gamificacao/estatisticas');
  assert.equal(calls[2][0],'/gamificacao/conquistas');
  assert.equal(calls[3][0],'/usage/heartbeat');
  assert.equal(Object.keys(calls[3][1]).length,0);
});
