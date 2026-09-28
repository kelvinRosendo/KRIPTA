/* ══════════════════════════════════════════════════════════════
   DADOS DE DEMONSTRAÇÃO (somente entrada de dev)
   Quando o modo dev está ativo e o backend não responde (offline,
   401 pelo token fictício, etc.), o frontend serve dados locais
   para que o app continue navegável. Nada aqui roda fora do dev.
   ══════════════════════════════════════════════════════════════ */

var DEV_STORE = null;

function devShiftDate(days, hour) {
  var d = new Date();
  d.setDate(d.getDate() + days);
  d.setHours(hour === undefined ? 18 : hour, 0, 0, 0);
  return d.toISOString();
}

function devSeed() {
  var subjectA = { id: 1, name: 'Algoritmos e Estruturas de Dados', teacher: 'Prof. Camila Nunes', icon: '📐', description: 'Lógica de programação, complexidade e estruturas lineares.', pendingCount: 2, hasExam: true, isProject: true, isFavorite: true };
  var subjectB = { id: 2, name: 'Banco de Dados', teacher: 'Prof. Ricardo Lima', icon: '🗄️', description: 'Modelagem relacional, SQL e normalização.', pendingCount: 2, hasExam: true, isProject: false, isFavorite: false };
  var subjectC = { id: 3, name: 'Redes de Computadores', teacher: 'Prof. Marina Alves', icon: '🌐', description: 'Camadas do modelo OSI, protocolos e segurança.', pendingCount: 2, hasExam: false, isProject: true, isFavorite: true };

  var unitA1 = { id: 11, subjectId: 1, name: 'Unidade 1 — Revisão e análise de algoritmos', description: 'Complexidade assintótica e notação Big-O.', materialsCount: 3 };
  var unitA2 = { id: 12, subjectId: 1, name: 'Unidade 2 — Listas e pilhas', description: 'Estruturas lineares e operações básicas.', materialsCount: 2 };
  var unitB1 = { id: 21, subjectId: 2, name: 'Unidade 1 — Modelo relacional', description: 'Chaves, relacionamentos e cardinalidade.', materialsCount: 2 };
  var unitC1 = { id: 31, subjectId: 3, name: 'Unidade 1 — Camadas do modelo OSI', description: 'Protocolos de cada camada.', materialsCount: 1 };

  var materialList = [
    { id: 101, unitId: 11, title: 'Slides — Introdução à análise de algoritmos', type: 'PDF', url: 'https://example.com/slides-big-o', description: 'Aula 1', completed: true },
    { id: 102, unitId: 11, title: 'Lista 1 de exercícios', type: 'DOCUMENT', url: 'https://example.com/lista1', description: 'Entrega na próxima semana', completed: false },
    { id: 103, unitId: 11, title: 'Vídeo-aula — Big-O na prática', type: 'VIDEO', url: 'https://example.com/video', description: null, completed: false },
    { id: 104, unitId: 12, title: 'Anotações — Pilhas e filas', type: 'NOTE', url: null, description: 'Resumo das estruturas lineares.', completed: false },
    { id: 105, unitId: 12, title: 'Exercícios resolvidos — L1', type: 'PDF', url: 'https://example.com/exercicios-l1', description: null, completed: true },
    { id: 201, unitId: 21, title: 'Apostila — SQL básico', type: 'PDF', url: 'https://example.com/sql', description: null, completed: false },
    { id: 202, unitId: 21, title: 'Script de criação do banco', type: 'DOCUMENT', url: 'https://example.com/script', description: 'Schema do trabalho', completed: false },
    { id: 301, unitId: 31, title: 'Mapa das 7 camadas', type: 'LINK', url: 'https://example.com/osi', description: null, completed: false },
  ];

  var taskList = [
    { id: 201, title: 'Revisar exercício 4 da Lista 1', description: 'Ordenação por contagem', dueDate: devShiftDate(0, 20), priority: 'HIGH', completed: false, subjectId: 1 },
    { id: 202, title: 'Entregar resumo da Unidade 1', description: 'Até 20h', dueDate: devShiftDate(0, 23), priority: 'MEDIUM', completed: false, subjectId: 2 },
    { id: 203, title: 'Ler capítulo 3 — Protocolos', description: null, dueDate: devShiftDate(1, 9), priority: 'MEDIUM', completed: false, subjectId: 3 },
    { id: 204, title: 'Implementar pilha com array', description: 'Projeto da disciplina', dueDate: devShiftDate(3, 21), priority: 'HIGH', completed: false, subjectId: 1 },
    { id: 205, title: 'Exercícios de normalização', description: null, dueDate: devShiftDate(-2, 19), priority: 'LOW', completed: false, subjectId: 2 },
    { id: 206, title: 'Apresentação do seminário', description: 'Grupo 3', dueDate: devShiftDate(5, 10), priority: 'HIGH', completed: false, subjectId: 3 },
    { id: 207, title: 'Assistir à aula de gossip', description: null, dueDate: devShiftDate(-1, 18), priority: 'LOW', completed: true, subjectId: 1 },
    { id: 208, title: 'Resolver lista 2', description: null, dueDate: devShiftDate(8, 22), priority: 'MEDIUM', completed: true, subjectId: 2 },
  ];

  var announcementList = [
    { id: 301, title: 'Prova da Unidade 1 agendada', message: 'A prova de Banco de Dados acontece na próxima quarta-feira, às 19h.', createdAt: devShiftDate(-1, 12), subject: { id: 2, name: 'Banco de Dados' } },
    { id: 302, title: 'Material novo disponível', message: 'Slides da aula de hoje já estão na unidade correspondente.', createdAt: devShiftDate(-3, 9), subject: { id: 1, name: 'Algoritmos e Estruturas de Dados' } },
    { id: 303, title: 'Mudança de sala', message: 'O seminário de Redes passa para a sala 204.', createdAt: devShiftDate(-6, 15), subject: { id: 3, name: 'Redes de Computadores' } },
  ];

  var achievementList = [
    { id: 401, icon: '🔥', title: 'Primeiro passo', description: 'Concluiu a primeira tarefa', earned: true },
    { id: 402, icon: '📚', title: 'Estudante dedicado', description: '7 dias seguidos de estudo', earned: true },
    { id: 403, icon: '🏆', title: 'Maratonista', description: 'Concluiu 10 tarefas', earned: true },
    { id: 404, icon: '🌟', title: 'Rota completa', description: 'Finalizou todas as unidades', earned: false },
  ];

  return {
    user: { id: 0, name: 'Dev', email: 'kripta08', dev: true },
    xp: 1240,
    level: 4,
    streak: 7,
    completedCount: 1,
    subjects: [subjectA, subjectB, subjectC],
    units: [unitA1, unitA2, unitB1, unitC1],
    materials: materialList,
    tasks: taskList,
    announcements: announcementList,
    achievements: achievementList,
  };
}

function devStore() {
  if (!DEV_STORE) DEV_STORE = devSeed();
  return DEV_STORE;
}

function devReset() {
  DEV_STORE = null;
}

function devNextId(list) {
  var max = 0;
  list.forEach(function (item) { if (item.id > max) max = item.id; });
  return max + 1;
}

function devQuery(path) {
  var out = {};
  var qs = String(path).split('?')[1];
  if (!qs) return out;
  qs.split('&').forEach(function (pair) {
    if (!pair) return;
    var parts = pair.split('=');
    out[decodeURIComponent(parts[0])] = decodeURIComponent(parts.slice(1).join('=') || '');
  });
  return out;
}

function devDayDiff(dateStr) {
  if (!dateStr) return null;
  var today = new Date();
  today.setHours(0, 0, 0, 0);
  var d = new Date(dateStr);
  d.setHours(0, 0, 0, 0);
  return Math.round((d - today) / 86400000);
}

function devMatch(path, pattern) {
  var m = String(path).match(pattern);
  return m ? m[1] : null;
}

function devSubjectName(id) {
  var s = devStore().subjects.filter(function (x) { return x.id === id; })[0];
  return s ? s.name : 'KRIPTA';
}

function devDecorateTask(task) {
  var copy = {};
  Object.keys(task).forEach(function (k) { copy[k] = task[k]; });
  if (task.subjectId) copy.subject = { id: task.subjectId, name: devSubjectName(task.subjectId) };
  return copy;
}

function devRecountSubject(subjectId) {
  var s = devStore();
  var pending = s.tasks.filter(function (t) { return t.subjectId === subjectId && !t.completed; }).length;
  var target = s.subjects.filter(function (x) { return x.id === subjectId; })[0];
  if (target) target.pendingCount = pending;
}

function devAddXP(amount) {
  var s = devStore();
  s.xp += amount;
  s.level = Math.floor(s.xp / 300) + 1;
}

function devCalendarEvents() {
  var s = devStore();
  var events = s.tasks
    .filter(function (t) { return !t.completed && t.dueDate; })
    .map(function (t) {
      return { date: String(t.dueDate).slice(0, 10), title: t.title, type: 'TASK' };
    });
  events.push({ date: devShiftDate(2, 19).slice(0, 10), title: 'Prova — Banco de Dados', type: 'EXAM' });
  events.push({ date: devShiftDate(6, 10).slice(0, 10), title: 'Seminário de Redes', type: 'EVENT' });
  events.push({ date: devShiftDate(9, 8).slice(0, 10), title: 'Prova — Algoritmos', type: 'EXAM' });
  return events;
}

/* Responde ao mock da rota pedida. Devolve undefined quando não há mock. */
function devMock(method, path, body) {
  var s = devStore();
  var verb = String(method).toUpperCase();
  var route = String(path).split('?')[0];
  var query = devQuery(path);
  var data = body || {};
  var id;

  /* Usuário */
  if (verb === 'GET' && route === '/users/me') return s.user;

  /* Dashboard */
  if (verb === 'GET' && route === '/dashboard') {
    var pendingTasks = s.tasks.filter(function (t) { return !t.completed; });
    return {
      stats: { xp: s.xp, level: s.level, streak: s.streak },
      badgesCount: s.achievements.filter(function (a) { return a.earned; }).length,
      tasksToday: pendingTasks.filter(function (t) { return devDayDiff(t.dueDate) === 0; }).map(devDecorateTask),
      tasksTomorrow: pendingTasks.filter(function (t) { return devDayDiff(t.dueDate) === 1; }).map(devDecorateTask),
      overdueTasks: pendingTasks.filter(function (t) { var d = devDayDiff(t.dueDate); return d !== null && d < 0; }).map(devDecorateTask),
    };
  }

  /* Matérias */
  if (route === '/subjects') {
    if (verb === 'GET') return s.subjects;
    if (verb === 'POST') {
      var created = {
        id: devNextId(s.subjects),
        name: data.name || 'Nova matéria',
        teacher: data.teacher || '',
        description: data.description || '',
        icon: data.icon || '📚',
        pendingCount: 0,
        hasExam: false,
        isProject: false,
        isFavorite: false,
      };
      s.subjects.push(created);
      return created;
    }
  }
  if ((id = devMatch(route, /^\/subjects\/(\d+)$/))) {
    var subject = s.subjects.filter(function (x) { return x.id === Number(id); })[0];
    if (verb === 'GET') return subject;
    if (verb === 'PUT' && subject) {
      Object.keys(data).forEach(function (k) { subject[k] = data[k]; });
      return subject;
    }
    if (verb === 'DELETE' && subject) {
      s.subjects = s.subjects.filter(function (x) { return x.id !== Number(id); });
      s.units = s.units.filter(function (u) { return u.subjectId !== Number(id); });
      s.tasks = s.tasks.filter(function (t) { return t.subjectId !== Number(id); });
      return {};
    }
  }

  /* Unidades */
  if ((id = devMatch(route, /^\/subjects\/(\d+)\/units$/))) {
    if (verb === 'GET') return s.units.filter(function (u) { return u.subjectId === Number(id); });
    if (verb === 'POST') {
      var unit = { id: devNextId(s.units), subjectId: Number(id), name: data.name || 'Nova unidade', description: data.description || '', materialsCount: 0 };
      s.units.push(unit);
      return unit;
    }
  }
  if ((id = devMatch(route, /^\/units\/(\d+)$/))) {
    var unitTarget = s.units.filter(function (x) { return x.id === Number(id); })[0];
    if (verb === 'PUT' && unitTarget) {
      Object.keys(data).forEach(function (k) { unitTarget[k] = data[k]; });
      return unitTarget;
    }
    if (verb === 'DELETE' && unitTarget) {
      s.units = s.units.filter(function (x) { return x.id !== Number(id); });
      s.materials = s.materials.filter(function (m) { return m.unitId !== Number(id); });
      return {};
    }
  }

  /* Materiais */
  if ((id = devMatch(route, /^\/units\/(\d+)\/materials$/))) {
    var unitId = Number(id);
    if (verb === 'GET') return s.materials.filter(function (m) { return m.unitId === unitId; });
    if (verb === 'POST') {
      var material = {
        id: devNextId(s.materials),
        unitId: unitId,
        title: data.title || 'Novo material',
        type: data.type || 'OTHER',
        url: data.url || null,
        description: data.description || null,
        completed: false,
      };
      s.materials.push(material);
      devRecountMaterials(unitId);
      return material;
    }
  }
  if ((id = devMatch(route, /^\/materials\/(\d+)\/complete$/))) {
    if (verb === 'PATCH') return devToggleMaterial(Number(id));
  }
  if ((id = devMatch(route, /^\/materials\/(\d+)$/))) {
    var materialTarget = s.materials.filter(function (x) { return x.id === Number(id); })[0];
    if (verb === 'PUT' && materialTarget) {
      Object.keys(data).forEach(function (k) { materialTarget[k] = data[k]; });
      return materialTarget;
    }
    if (verb === 'DELETE' && materialTarget) {
      s.materials = s.materials.filter(function (x) { return x.id !== Number(id); });
      devRecountMaterials(materialTarget.unitId);
      return {};
    }
  }

  /* Tarefas */
  if (route === '/tasks') {
    if (verb === 'GET') {
      var list = s.tasks;
      if (query.status === 'COMPLETED') list = list.filter(function (t) { return t.completed; });
      else if (query.status === 'PENDING') list = list.filter(function (t) { return !t.completed; });
      return list.map(devDecorateTask);
    }
    if (verb === 'POST') {
      var task = {
        id: devNextId(s.tasks),
        title: data.title || 'Nova tarefa',
        description: data.description || null,
        dueDate: data.dueDate || null,
        priority: data.priority || 'MEDIUM',
        completed: false,
        subjectId: data.subjectId || null,
      };
      s.tasks.push(task);
      devRecountSubject(task.subjectId);
      return devDecorateTask(task);
    }
  }
  if (id = devMatch(route, /^\/tasks\/(\d+)\/complete$/)) {
    if (verb === 'PATCH') return devToggleTask(Number(id));
  }
  if ((id = devMatch(route, /^\/tasks\/(\d+)$/))) {
    var taskTarget = s.tasks.filter(function (x) { return x.id === Number(id); })[0];
    if (verb === 'GET') return taskTarget ? devDecorateTask(taskTarget) : undefined;
    if (verb === 'PUT' && taskTarget) {
      Object.keys(data).forEach(function (k) { taskTarget[k] = data[k]; });
      devRecountSubject(taskTarget.subjectId);
      return devDecorateTask(taskTarget);
    }
    if (verb === 'DELETE' && taskTarget) {
      s.tasks = s.tasks.filter(function (x) { return x.id !== Number(id); });
      devRecountSubject(taskTarget.subjectId);
      return {};
    }
  }

  /* Avisos */
  if (verb === 'GET' && route === '/announcements') return s.announcements;

  /* Calendário */
  if (verb === 'GET' && route === '/calendar') {
    return devCalendarEvents().filter(function (e) {
      if (query.startDate && e.date < query.startDate) return false;
      if (query.endDate && e.date > query.endDate) return false;
      return true;
    });
  }

  /* Gamificação */
  if (verb === 'GET' && route === '/progress') {
    return { overallProgress: Math.min(100, Math.round((s.completedCount / Math.max(1, s.tasks.length)) * 100)) };
  }
  if (verb === 'GET' && route === '/gamification/stats') {
    var base = (s.level - 1) * 300;
    return { level: s.level, xp: s.xp, xpToNextLevel: (s.level * 300) - s.xp, levelProgress: Math.round(((s.xp - base) / 300) * 100) };
  }
  if (verb === 'GET' && route === '/gamification/achievements') return s.achievements;

  /* Kai */
  if (verb === 'POST' && route === '/ai/chat') {
    return { reply: 'Modo dev: sou a Kai em modo demonstração. Suas tarefas e matérias são dados locais de exemplo.' };
  }

  return undefined;
}

function devRecountMaterials(unitId) {
  var s = devStore();
  var unit = s.units.filter(function (x) { return x.id === unitId; })[0];
  if (unit) unit.materialsCount = s.materials.filter(function (m) { return m.unitId === unitId; }).length;
}

function devToggleTask(id) {
  var s = devStore();
  var task = s.tasks.filter(function (x) { return x.id === id; })[0];
  if (!task) return undefined;
  task.completed = !task.completed;
  var earned = 0;
  if (task.completed) {
    s.completedCount += 1;
    devAddXP(20);
    earned = 20;
  }
  devRecountSubject(task.subjectId);
  var result = devDecorateTask(task);
  result.gamification = { xpEarned: earned };
  return result;
}

function devToggleMaterial(id) {
  var s = devStore();
  var material = s.materials.filter(function (x) { return x.id === id; })[0];
  if (!material) return undefined;
  material.completed = !material.completed;
  return material;
}
