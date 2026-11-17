const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
test('calendar range and notification services use real API routes', async () => {
  const calls=[];
  const context={Date,api:{get:async p=>{calls.push(p);return [];},post:async(p,b)=>{calls.push(p);return b;}}};
  vm.createContext(context);
  for(const file of ['calendar','notifications','announcements'])vm.runInContext(fs.readFileSync('services/'+file+'.js','utf8'),context);
  await context.getCalendar('2026-11-03','2026-11-03','PESSOAL');
  assert.equal(calls[0],'/calendario?inicio=2026-11-03&fim=2026-11-03&scope=PESSOAL');
  await context.createPersonalEvent({title:'Teste',date:'2026-11-03'});
  assert.equal(calls[1],'/calendario/eventos');
  await context.getNotifications();
  await context.getAnnouncements();
  assert.equal(calls[2],'/notificacoes');
  assert.equal(calls[3],'/notificacoes');
  context.CAL_EVENTS=[{date:'2026-11-03',title:'No dia'},{date:'2026-11-04',title:'Outro dia'}];
  assert.equal(context.calEventsOn(new Date(2026,10,3)).length,1);
});

test('pending task deadlines appear once on the local day and only in personal or combined views', async () => {
  const start = '2026-11-20';
  const localDue = new Date(2026, 10, 20, 23, 15).toISOString();
  let taskRequests = 0;
  const context = vm.createContext({
    Date,
    api: { get: async () => [{ id: 6, title: 'Evento existente', date: start }] },
    isProfessor: () => false,
    getTasks: async () => {
      taskRequests++;
      return [
        { id: 11, title: 'Trabalho', dueDate: localDue, completed: false },
        { id: 12, title: 'Concluída', dueDate: localDue, completed: true },
        { id: 13, title: 'Sem prazo', dueDate: null },
        { id: 14, title: 'Outro dia', dueDate: new Date(2026, 10, 21, 12).toISOString() },
      ];
    },
  });
  vm.runInContext(fs.readFileSync('services/calendar.js', 'utf8'), context);
  const events = await context.getCalendarWithDeadlines(start, start, 'ALL');
  assert.equal(events.length, 2);
  assert.equal(events[1].taskId, 11);
  assert.equal(events[1].date, start);
  assert.equal(events[1].time, '23:15');
  assert.equal((await context.getCalendarWithDeadlines(start, start, 'ESCOLAR')).length, 1);
  assert.equal(taskRequests, 1);
});
