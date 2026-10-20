/* ── App principal: init, rotas, renderização dinâmica ── */

document.addEventListener('DOMContentLoaded', init);

function init() {
  updateTopbarDate();
  bindGlobalEvents();
  bindSubjectFilter();
  mountStatusbarAvatars();
  updateStatusbarAvatar();
  applyPrefs();

  bindRegisterRole();

  if (isAuthenticated()) {
    if (State.user) {
      goTo(defaultScreenForRole());
      startStreakTracking();
    } else {
      fetchMe()
        .then(function () { updateStatusbarAvatar(); goTo(defaultScreenForRole()); startStreakTracking(); })
        .catch(function () { goTo('login'); });
    }
  } else {
    goTo('login');
  }

  healthCheck();
}

function updateTopbarDate() {
  var el = document.getElementById('home-date');
  if (!el) return;
  var dias = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
  var meses = ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'];
  var d = new Date();
  el.textContent = dias[d.getDay()] + ', ' + d.getDate() + ' de ' + meses[d.getMonth()];
}

function firstEqualizer() {
  window.scrollTo(0, 0);
}

/* ── Roteamento com gate de autenticação (Sprint 3 / Sprint 18) ── */
function renderScreen(screenName) {
  firstEqualizer();
  if (['login', 'register'].indexOf(screenName) !== -1) return;

  if (!isAuthenticated()) {
    goTo('login');
    toast('Sessão encerrada. Faça login para continuar.', 'warn');
    return;
  }

  try {
    switch (screenName) {
      case 'home': renderHome(); break;
      case 'materias': renderSubjects(); break;
      case 'materia-detalhe': renderSubjectDetail(); break;
      case 'tasks': renderTasks(); break;
      case 'calendario': renderCalendar(); break;
      case 'perfil': renderProfile(); break;
      case 'avisos': renderAnnouncements(); break;
      case 'professor': renderProfessor(); break;
      case 'aprovacoes': renderApprovals(); break;
      case 'ia': initKai(); break;
    }
  } catch (e) {
    console.error('Erro ao renderizar tela', screenName, e);
  }
}

function handleSessionExpired() {
  logout();
  goTo('login');
  toast('Sua sessão expirou. Entre novamente.', 'warn');
}

/* ── Health check (Sprint 2) ── */
async function healthCheck() {
  var pill = document.getElementById('conn-banner');
  var statusEl = document.getElementById('conn-status');

  function apply(ok, message) {
    if (!pill) { if (statusEl) statusEl.textContent = message; return; }
    pill.classList.remove('hidden');
    pill.style.background = ok ? '#E6F9F8' : '#FDECEA';
    pill.style.color = ok ? '#0E7A72' : '#C0392B';
    pill.textContent = message || (ok ? 'Online' : 'Offline');
    pill.title = message || '';
  }

  if (statusEl) statusEl.textContent = 'Verificando conexão…';

  /* Mock ligado (interruptor global DEV_MODE): o health check real não é
     consultado, porque nenhum request real está indo para a API. A pill
     no canto superior direito deixa o estado explícito. */
  if (DEV_MODE) {
    if (pill) {
      pill.classList.remove('hidden');
      pill.style.background = '#FFF3E0';
      pill.style.color = '#B85C00';
      pill.textContent = 'dev';
      pill.title = 'Modo dev — dados de demonstração, latência ' + (Number(DEV_LATENCY) || 0) + ' ms (?mock=off para a API real)';
    }
    console.warn('[KRIPTA] DEV_MODE ligado: devMock/devFallback ativos, latência ' + (Number(DEV_LATENCY) || 0) + ' ms. Nenhum request real é usado. Use ?mock=off para validar E2E.');
    return;
  }

  try {
    var res = await api.get('/health');
    apply(true, (res && res.status) ? String(res.status) : 'Online');
  } catch (e) {
    apply(false, 'Offline');
  }
}

/* ── Eventos globais delegados ── */
function bindGlobalEvents() {
  document.addEventListener('submit', function (e) {
    var form = e.target;
    if (form.id === 'login-form') { e.preventDefault(); submitLogin(form); }
    else if (form.id === 'register-form') { e.preventDefault(); submitRegister(form); }
    else if (form.id === 'subject-form') { e.preventDefault(); submitSubjectForm(form); }
    else if (form.id === 'unit-form') { e.preventDefault(); submitUnitForm(form); }
    else if (form.id === 'material-form') { e.preventDefault(); submitMaterialForm(form); }
    else if (form.id === 'task-form') { e.preventDefault(); submitTaskForm(form); }
    else if (form.id === 'content-form') { e.preventDefault(); submitContentForm(form); }
    else if (form.id === 'personal-event-form') { e.preventDefault(); submitPersonalEventForm(form); }
  });

  document.addEventListener('click', function (e) {
    var btn = e.target.closest('[data-action]');
    if (btn) {
      var action = btn.getAttribute('data-action');
      var id = btn.getAttribute('data-id');
      var kind = btn.getAttribute('data-kind');
      if (action === 'complete' && kind === 'task') { e.preventDefault(); doCompleteTask(id, btn); }
      else if (action === 'complete' && kind === 'material') { e.preventDefault(); doCompleteMaterial(id, btn); }
      else if (action === 'delete' && kind === 'task') { e.preventDefault(); openDeleteModal(btn.getAttribute('data-name'), 'task', id); }
      else if (action === 'delete' && kind === 'subject') { e.preventDefault(); openDeleteModal(btn.getAttribute('data-name'), 'subject', id); }
      else if (action === 'delete' && kind === 'unit') { e.preventDefault(); openDeleteModal(btn.getAttribute('data-name'), 'unit', id); }
      else if (action === 'delete' && kind === 'material') { e.preventDefault(); openDeleteModal(btn.getAttribute('data-name'), 'material', id); }
      else if (action === 'approve-content') { e.preventDefault(); doApproveContent(id, btn); }
      else if (action === 'reject-content') { e.preventDefault(); doRejectContent(id, btn); }
      return;
    }

    var editRow = e.target.closest('[data-edit-task]');
    if (editRow) { e.preventDefault(); openTaskEditModal(editRow.getAttribute('data-edit-task')); return; }

    var toggle = e.target.closest('[data-toggle-unit]');
    if (toggle) { e.preventDefault(); toggleUnitMaterials(toggle.getAttribute('data-toggle-unit')); return; }

    var subjectCard = e.target.closest('[data-open-subject]');
    if (subjectCard) { e.preventDefault(); openSubject(subjectCard.getAttribute('data-open-subject')); return; }
  });

  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') closeProfileDrawer();
  });
}

/* ══════════════════════ HOME (Etapa 4) ══════════════════════ */
async function renderHome() {
  var greeting = document.getElementById('home-greeting');
  if (State.user && State.user.name) greeting.textContent = 'Olá, ' + State.user.name.split(' ')[0];

  try {
    var dash = await getDashboard();
    fillHomeStats(dash);
    fillHomeTasks(dash);
  } catch (e) {
    document.getElementById('home-tasks').innerHTML = errorView(e && e.message);
  }
}

function fillHomeStats(dash) {
  var stats = (dash && dash.stats) || {};
  var xp = stats.xp !== undefined ? stats.xp : dash.xp;
  var level = stats.level !== undefined ? stats.level : dash.level;
  var streak = stats.streak !== undefined ? stats.streak : dash.streak;
  var badges = (dash.badgesCount !== undefined) ? dash.badgesCount : (dash.achievements ? dash.achievements.length : null);

  var streakCard = document.getElementById('home-streak-card');
  if (streak) {
    streakCard.classList.remove('hidden');
    document.getElementById('home-streak-days').textContent = streak + ' dia' + (streak === 1 ? '' : 's') + ' seguido' + (streak === 1 ? '' : 's') + '!';
    document.getElementById('home-streak-sub').textContent = 'Continue assim para manter a sequência';
  } else {
    streakCard.classList.add('hidden');
  }

  if (xp !== undefined) document.getElementById('home-stat-xp').textContent = Number(xp).toLocaleString('pt-BR');
  if (level !== undefined) document.getElementById('home-stat-level').textContent = 'Nível ' + level;
  if (badges !== null && badges !== undefined) document.getElementById('home-stat-badges').textContent = badges;
}

function fillHomeTasks(dash) {
  var container = document.getElementById('home-tasks');
  empty(container);
  if (!container) return;

  var tasks = [];
  (dash.tasksToday || []).forEach(function (t) { tasks.push({ task: t, label: '<span class="pill bg-orange-light text-orange" style="flex:0 0 auto">hoje</span>', color: 'border-l-orange' }); });
  (dash.tasksTomorrow || []).forEach(function (t) { tasks.push({ task: t, label: '<span class="pill bg-teal-light text-teal" style="flex:0 0 auto">amanhã</span>', color: 'border-l-teal' }); });
  (dash.overdueTasks || []).forEach(function (t) { tasks.push({ task: t, label: '<span class="pill bg-crimson-light text-crimson" style="flex:0 0 auto">atrasada</span>', color: 'border-l-crimson' }); });

  if (!tasks.length) {
    container.innerHTML = emptyState('Nada por aqui', 'Você não tem tarefas para hoje e amanhã.');
    return;
  }

  tasks.slice(0, 6).forEach(function (item) {
    container.insertAdjacentHTML('beforeend', taskRow(item.task, { accentColor: item.color, sideLabel: function () { return item.label; }, noDelete: true }));
  });
}

/* ══════════════════════ MATÉRIAS (Etapa 5) ══════════════════════ */
var SUBJECT_COLORS = ['bg-indigo-light', 'bg-teal-light', 'bg-orange-light', 'bg-lilac-light', 'bg-surface-2'];

function subjectCardHTML(s) {
  var c = SUBJECT_COLORS[Math.abs(s.id || 1) % SUBJECT_COLORS.length];
  var icon = s.icon || '📚';
  var meta = subjectMeta(s);
  var pending = (s.pendingCount && s.pendingCount > 0)
    ? '<span class="pill bg-crimson-light text-crimson">' + s.pendingCount + ' pendência' + (s.pendingCount === 1 ? '' : 's') + '</span>'
    : '<span class="pill bg-teal-light text-teal">em dia</span>';
  return (
    '<div class="card p-3.5 flex items-center gap-3 cursor-pointer" data-open-subject="' + s.id + '">' +
    '<div class="w-[44px] h-[44px] rounded-[13px] ' + c + ' flex items-center justify-center text-xl shrink-0">' + esc(icon) + '</div>' +
    '<div class="flex-1 min-w-0">' +
    '<div class="text-[14.5px] font-bold truncate">' + esc(s.name) + '</div>' +
    (meta ? '<div class="text-xs text-text-mid mt-px truncate">' + esc(meta) + '</div>' : '') +
    '</div>' +
    pending +
    '<button type="button" class="icon-btn !w-8 !h-8" data-action="delete" data-kind="subject" data-id="' + s.id + '" data-name="' + esc(s.name) + '" aria-label="Excluir matéria">' +
    '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#6B6F8E" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2m2 0-1 14a2 2 0 0 1-2 2H9a2 2 0 0 1-2-2L6 6"/></svg>' +
    '</button>' +
    '</div>'
  );
}

async function renderSubjects() {
  var list = document.getElementById('subjects-list');
  var countEl = document.getElementById('subjects-count');
  showLoading(list);
  try {
    var subjects = await getSubjects();
    var arr = Array.isArray(subjects) ? subjects : (subjects && subjects.content ? subjects.content : []);
    fillSubjectFilter(countEl, arr);
    applySubjectFilter(arr);
  } catch (e) {
    list.innerHTML = errorView(e && e.message);
  }
}

function fillSubjectFilter(countEl, subjects) {
  if (countEl) countEl.textContent = subjects.length + ' matéria' + (subjects.length === 1 ? '' : 's') + ' este semestre';
}

function applySubjectFilter(subjects) {
  var list = document.getElementById('subjects-list');
  var filter = window.__subjectFilter || 'all';
  var filtered = (filter === 'all')
    ? subjects
    : subjects.filter(function (s) { return String(s[filter] || '').toLowerCase() === 'true'; });

  empty(list);
  if (!filtered.length) {
    list.innerHTML = emptyState('Nenhuma matéria aqui', 'Toque em "Adicionar matéria" para começar.');
    return;
  }
  filtered.forEach(function (s) { list.insertAdjacentHTML('beforeend', subjectCardHTML(s)); });
  list.insertAdjacentHTML('beforeend',
    '<button type="button" class="btn-ghost flex items-center justify-center gap-2 mt-1" onclick="openSubjectModal()">' +
    '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg> Adicionar matéria</button>');
}

function bindSubjectFilter() {
  document.querySelectorAll('[data-subject-filter]').forEach(function (pill) {
    pill.addEventListener('click', function () {
      window.__subjectFilter = pill.getAttribute('data-subject-filter');
      document.querySelectorAll('[data-subject-filter]').forEach(function (p) {
        if (p === pill) {
          p.className = 'pill bg-indigo text-white cursor-pointer';
        } else {
          p.className = 'pill bg-surface text-text-mid border border-border cursor-pointer';
        }
      });
      getSubjects()
        .then(function (subjects) {
          var arr = Array.isArray(subjects) ? subjects : (subjects && subjects.content ? subjects.content : []);
          applySubjectFilter(arr);
        })
        .catch(function (e) { document.getElementById('subjects-list').innerHTML = errorView(e && e.message); });
    });
  });
}

/* ── Formulário de matéria ── */
function openSubjectModal(subject) {
  var form = document.getElementById('subject-form');
  window.__editingSubject = subject || null;
  form.reset();
  document.getElementById('subject-modal-title').textContent = subject ? 'Editar matéria' : 'Nova matéria';
  if (subject) {
    form.elements['name'].value = subject.name || '';
    form.elements['description'].value = subject.description || '';
  }
  document.getElementById('subject-modal').classList.remove('hidden');
  document.getElementById('subject-modal').classList.add('flex');
}

async function submitSubjectForm(form) {
  var btn = form.querySelector('button[type="submit"]');
  submitBtnLoading(btn);
  var data = { name: form.elements['name'].value, description: form.elements['description'].value };
  try {
    if (window.__editingSubject) {
      await updateSubject(window.__editingSubject.id, data);
      toast('Matéria atualizada');
    } else {
      await createSubject(data);
      toast('Matéria criada');
    }
    window.__editingSubject = null;
    closeModal('subject-modal');
    renderSubjects();
  } catch (e) {
    toast(cleanError(e), 'error');
  } finally {
    submitBtnReset(btn);
  }
}

/* ══════════════════════ DETALHE DA MATÉRIA (Etapas 6 e 7) ══════════════════════ */
function openSubject(id) {
  getSubject(id)
    .then(function (s) {
      State.currentSubject = s;
      goTo('materia-detalhe');
    })
    .catch(function (e) { toast(cleanError(e), 'error'); });
}

var DETAIL_TAB = 'units';

async function renderSubjectDetail() {
  var subject = State.currentSubject;
  if (!subject) { goTo('materias'); return; }

  document.getElementById('subject-name').textContent = subject.name;
  document.getElementById('subject-teacher').textContent = subject.teacher || '';
  document.getElementById('subject-desc').textContent = subject.description || '';

  switchTab('units');
}

function switchTab(tab) {
  DETAIL_TAB = tab;
  document.querySelectorAll('[data-detail-tab]').forEach(function (t) {
    var active = t.getAttribute('data-detail-tab') === tab;
    t.className = 'py-2.5 px-1 text-[13px] cursor-pointer mr-[18px] ' +
      (active ? 'font-bold text-indigo border-b-[2.5px] border-indigo mb-[-1.5px]' : 'font-semibold text-text-mid');
  });
  var body = document.getElementById('subject-body');
  if (tab === 'units') renderUnits(0);
  else if (tab === 'contents') renderSubjectContents();
  else if (tab === 'materials') renderAllMaterials();
  else renderSubjectAvisos();
}

/* Conteúdos aprovados do componente curricular (RF05 — consulta do aluno) */
async function renderSubjectContents() {
  var body = document.getElementById('subject-body');
  var subject = State.currentSubject;
  showLoading(body);
  try {
    var list = await getApprovedContents(subject.id);
    var arr = Array.isArray(list) ? list : (list && list.content ? list.content : []);
    empty(body);
    if (!arr.length) { body.innerHTML = emptyState('Sem conteúdos', 'Conteúdos aprovados deste componente aparecem aqui.'); return; }
    var wrap = el('div', 'px-app flex flex-col gap-[9px] mt-4');
    arr.forEach(function (c) { wrap.insertAdjacentHTML('beforeend', contentCardHTML(c)); });
    body.appendChild(wrap);
  } catch (e) {
    body.innerHTML = errorView(e && e.message);
  }
}

async function renderUnits(openUnitId) {
  var body = document.getElementById('subject-body');
  var subject = State.currentSubject;
  showLoading(body);
  try {
    var units = await getUnits(subject.id);
    var arr = Array.isArray(units) ? units : (units && units.content ? units.content : []);
    empty(body);

    var addBtn = '<button type="button" class="btn-ghost flex items-center justify-center gap-2 mt-1" onclick="openUnitModal()">' +
      '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg> Adicionar unidade</button>';
    var addWrap = el('div', 'px-app flex flex-col gap-[9px] mt-4');
    if (!arr.length) {
      addWrap.innerHTML = emptyState('Nenhuma unidade ainda', 'Crie a primeira unidade desta matéria.') + addBtn;
      body.appendChild(addWrap);
      return;
    }
    arr.forEach(function (u) {
      addWrap.insertAdjacentHTML('beforeend', unitCardHTML(u, openUnitId === u.id));
    });
    addWrap.insertAdjacentHTML('beforeend', addBtn);
    body.appendChild(addWrap);
  } catch (e) {
    body.innerHTML = errorView(e && e.message);
  }
}

function unitCardHTML(unit) {
  return (
    '<div class="card p-[15px]">' +
    '<div class="flex justify-between items-center cursor-pointer" data-toggle-unit="' + unit.id + '">' +
    '<div class="text-[14.5px] font-bold">📂 ' + esc(unit.name) + '</div>' +
    '<span class="text-[11.5px] text-text-mid font-semibold">' + (unit.materialsCount || unit.materialCount || 0) + ' materiais</span>' +
    '</div>' +
    '</div>'
  );
}

async function toggleUnitMaterials(unitId) {
  var existing = document.querySelector('[data-unit-materials="' + unitId + '"]');
  if (existing) { existing.remove(); return; }

  document.querySelectorAll('[data-unit-materials]').forEach(function (c) { c.remove(); });

  var toggle = document.querySelector('[data-toggle-unit="' + unitId + '"]');
  if (!toggle) return;
  var card = toggle.closest('.card');
  if (!card) return;

  State.currentUnit = { id: unitId };
  var detail = el('div', 'unit-detail mt-3 flex flex-col gap-2');
  detail.dataset.unitMaterials = unitId;
  detail.innerHTML = spinner();
  card.appendChild(detail);

  try {
    var materials = await getMaterials(unitId);
    var arr = Array.isArray(materials) ? materials : [];
    empty(detail);
    if (!arr.length) {
      detail.innerHTML = emptyState('Sem materiais', 'Adicione PDFs, links, vídeos e anotações.');
    }
    arr.forEach(function (m) { detail.insertAdjacentHTML('beforeend', materialRowHTML(m, unitId)); });
    detail.insertAdjacentHTML('beforeend',
      '<button type="button" class="btn-ghost !py-2.5 !text-[12.5px] flex items-center justify-center gap-2 !mt-1" onclick="openMaterialModal(' + unitId + ')">' +
      '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg> Adicionar material</button>');
  } catch (e) {
    detail.innerHTML = errorView(e && e.message);
  }
}

function materialRowHTML(m, unitId) {
  var done = m.completed;
  var checkbox = done
    ? '<div class="w-[19px] h-[19px] rounded-md bg-teal shrink-0 flex items-center justify-center"><svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="m5 13 4 4L19 7"/></svg></div>'
    : '<button type="button" class="w-[19px] h-[19px] rounded-md border-2 border-border shrink-0 bg-transparent cursor-pointer" data-action="complete" data-kind="material" data-id="' + m.id + '" aria-label="Concluir material"></button>';
  return (
    '<div class="flex items-center gap-2.5" data-material="' + m.id + '">' + checkbox +
    '<span class="text-[13px] flex-1 min-w-0 ' + (done ? 'line-through text-text-mid' : 'font-semibold') + '">' + materialIcon(m.type) + ' ' + esc(m.title) + '</span>' +
    (m.url ? '<a href="' + esc(m.url) + '" target="_blank" rel="noopener" class="text-xs text-indigo font-bold shrink-0">abrir</a>' : '') +
    '<button type="button" class="icon-btn !w-7 !h-7 shrink-0" data-action="delete" data-kind="material" data-id="' + m.id + '" data-name="' + esc(m.title) + '" aria-label="Excluir material">' +
    '<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#6B6F8E" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2m2 0-1 14a2 2 0 0 1-2 2H9a2 2 0 0 1-2-2L6 6"/></svg>' +
    '</button></div>'
  );
}

async function renderAllMaterials() {
  var body = document.getElementById('subject-body');
  var subject = State.currentSubject;
  showLoading(body);
  try {
    var units = await getUnits(subject.id);
    var arr = Array.isArray(units) ? units : (units && units.content ? units.content : []);
    empty(body);
    if (!arr.length) { body.innerHTML = emptyState('Nenhum material', 'Este filtro agrupa os materiais de todas as unidades.'); return; }
    var wrap = el('div', 'px-app flex flex-col gap-[9px] mt-4');
    for (var i = 0; i < arr.length; i++) {
      var u = arr[i];
      try {
        var materials = await getMaterials(u.id);
        var mArr = Array.isArray(materials) ? materials : [];
        if (!mArr.length) continue;
        wrap.insertAdjacentHTML('beforeend', '<div class="section-label !mb-1 mt-1">' + esc(u.name) + '</div>');
        mArr.forEach(function (m) { wrap.insertAdjacentHTML('beforeend', materialRowHTML(m, u.id)); });
      } catch (e2) { /* ignora unidade com erro */ }
    }
    body.appendChild(wrap);
  } catch (e) {
    body.innerHTML = errorView(e && e.message);
  }
}

async function renderSubjectAvisos() {
  var body = document.getElementById('subject-body');
  showLoading(body);
  try {
    var announcements = await getAnnouncements();
    var arr = Array.isArray(announcements) ? announcements : [];
    empty(body);
    if (!arr.length) { body.innerHTML = emptyState('Sem avisos', 'Avisos de ' + esc(State.currentSubject.name) + ' aparecem aqui.'); return; }
    var wrap = el('div', 'px-app flex flex-col gap-[9px] mt-4');
    arr.forEach(function (a) { wrap.insertAdjacentHTML('beforeend', announcementCardHTML(a)); });
    body.appendChild(wrap);
  } catch (e) {
    body.innerHTML = errorView(e && e.message);
  }
}

/* ── Formulário de unidade ── */
function openUnitModal() {
  var form = document.getElementById('unit-form');
  window.__editingUnit = null;
  form.reset();
  document.getElementById('unit-modal-title').textContent = 'Nova unidade';
  document.getElementById('unit-modal').classList.remove('hidden');
  document.getElementById('unit-modal').classList.add('flex');
}

async function submitUnitForm(form) {
  var btn = form.querySelector('button[type="submit"]');
  submitBtnLoading(btn);
  var data = { name: form.elements['name'].value, description: form.elements['description'].value };
  try {
    await createUnit(State.currentSubject.id, data);
    toast('Unidade criada');
    closeModal('unit-modal');
    switchTab('units');
  } catch (e) {
    toast(cleanError(e), 'error');
  } finally {
    submitBtnReset(btn);
  }
}

/* ── Formulário de material ── */
function openMaterialModal(unitId) {
  var form = document.getElementById('material-form');
  window.__materialUnitId = unitId;
  form.reset();
  document.getElementById('material-modal-title').textContent = 'Novo material';
  var sel = form.elements['type'];
  sel.innerHTML = '';
  MATERIAL_TYPES.forEach(function (t) {
    var opt = el('option', null, t);
    opt.value = t;
    sel.appendChild(opt);
  });
  document.getElementById('material-modal').classList.remove('hidden');
  document.getElementById('material-modal').classList.add('flex');
}

async function submitMaterialForm(form) {
  var btn = form.querySelector('button[type="submit"]');
  submitBtnLoading(btn);
  var data = {
    title: form.elements['title'].value,
    type: form.elements['type'].value,
    url: form.elements['url'].value || null,
    description: form.elements['description'].value || null,
  };
  try {
    await createMaterial(window.__materialUnitId, data);
    toast('Material adicionado');
    closeModal('material-modal');
    switchTab(DETAIL_TAB);
  } catch (e) {
    toast(cleanError(e), 'error');
  } finally {
    submitBtnReset(btn);
  }
}

/* ── Concluir material ── */
async function doCompleteMaterial(id, btn) {
  try {
    await completeMaterial(id);
    toast('Material concluído');
    switchTab(DETAIL_TAB);
  } catch (e) {
    toast(cleanError(e), 'error');
  }
}

/* ══════════════════════ TAREFAS (Etapa 8) ══════════════════════ */
var TASKS_FILTER = 'PENDING';

async function renderTasks() {
  var list = document.getElementById('tasks-list');
  var countEl = document.getElementById('tasks-count');
  showLoading(list);
  if (countEl) countEl.textContent = 'Carregando…';
  try {
    var params = {};
    if (TASKS_FILTER === 'COMPLETED') params.status = 'COMPLETED';
    else if (TASKS_FILTER === 'PENDING') params.status = 'PENDING';
    var tasks = await getTasks(params);
    var arr = Array.isArray(tasks) ? tasks : (tasks && tasks.content ? tasks.content : []);
    if (countEl) countEl.textContent = arr.length + ' tarefa' + (arr.length === 1 ? '' : 's');
    renderTaskGroups(arr);
  } catch (e) {
    list.innerHTML = errorView(e && e.message);
  }
}

function setTasksFilter(filter) {
  TASKS_FILTER = filter;
  document.querySelectorAll('[data-task-filter]').forEach(function (p) {
    if (p.getAttribute('data-task-filter') === filter) {
      p.className = 'pill bg-indigo text-white cursor-pointer';
    } else {
      p.className = 'pill bg-surface text-text-mid border border-border cursor-pointer';
    }
  });
  renderTasks();
}

function taskDayGroup(task) {
  if (!task.dueDate) return 'depois';
  var due = new Date(task.dueDate);
  var today = new Date(); today.setHours(0, 0, 0, 0);
  var d = new Date(due); d.setHours(0, 0, 0, 0);
  var diff = Math.round((d - today) / 86400000);
  if (diff < 0) return 'atrasadas';
  if (diff === 0) return 'hoje';
  if (diff === 1) return 'amanha';
  if (diff < 7) return 'semana';
  return 'depois';
}

function renderTaskGroups(arr) {
  var container = document.getElementById('tasks-list');
  empty(container);
  if (!arr.length) {
    container.innerHTML = emptyState(TASKS_FILTER === 'COMPLETED' ? 'Nenhuma concluída' : 'Nenhuma tarefa pendente', 'Toque no botão + para criar uma tarefa.');
    return;
  }
  var groups = { atrasadas: 'Atrasadas', hoje: 'Hoje', amanha: 'Amanhã', semana: 'Esta semana', depois: 'Depois' };
  var g = { atrasadas: [], hoje: [], amanha: [], semana: [], depois: [] };
  arr.forEach(function (t) { g[taskDayGroup(t)].push(t); });
  Object.keys(groups).forEach(function (key) {
    if (!g[key].length) return;
    var label = el('div', 'section-label mt-2.5 first:mt-0');
    label.textContent = groups[key];
    container.appendChild(label);
    g[key].forEach(function (t) {
      container.insertAdjacentHTML('beforeend', taskRow(t, { sideLabel: taskSideLabel, onEdit: true }));
    });
  });
}

/* ── Formulário de tarefa ── */
async function prepareTaskForm(form, editingId) {
  var subjectSel = form.elements['subjectId'];
  subjectSel.innerHTML = '';
  try {
    var subjects = await getSubjects();
    var arr = Array.isArray(subjects) ? subjects : (subjects && subjects.content ? subjects.content : []);
    var placeholder = el('option', null, 'Sem matéria');
    placeholder.value = '';
    subjectSel.appendChild(placeholder);
    arr.forEach(function (s) {
      var opt = el('option', null, s.name);
      opt.value = s.id;
      subjectSel.appendChild(opt);
    });
    if (editingId && window.__editingTask && window.__editingTask.subject) {
      subjectSel.value = window.__editingTask.subject.id;
    }
  } catch (e) { /* sem matérias */ }
}

function openTaskModal() {
  var form = document.getElementById('task-form');
  window.__editingTask = null;
  form.reset();
  document.getElementById('task-modal-title').textContent = 'Nova tarefa';
  form.elements['priority'].value = 'MEDIUM';
  prepareTaskForm(form, null);
  document.getElementById('task-modal').classList.remove('hidden');
  document.getElementById('task-modal').classList.add('flex');
}

function openTaskEditModal(id) {
  getTask(id)
    .then(function (t) {
      var form = document.getElementById('task-form');
      window.__editingTask = t;
      document.getElementById('task-modal-title').textContent = 'Editar tarefa';
      form.reset();
      form.elements['title'].value = t.title || '';
      form.elements['description'].value = t.description || '';
      form.elements['dueDate'].value = dueDateInputValue(t.dueDate);
      form.elements['priority'].value = t.priority || 'MEDIUM';
      prepareTaskForm(form, id);
      document.getElementById('task-modal').classList.remove('hidden');
      document.getElementById('task-modal').classList.add('flex');
    })
    .catch(function (e) { toast(cleanError(e), 'error'); });
}

async function submitTaskForm(form) {
  var btn = form.querySelector('button[type="submit"]');
  submitBtnLoading(btn);
  var data = taskFormPayload(form);
  try {
    if (window.__editingTask) {
      await updateTask(window.__editingTask.id, data);
      toast('Tarefa atualizada');
    } else {
      await createTask(data);
      toast('Tarefa criada');
    }
    window.__editingTask = null;
    closeModal('task-modal');
    renderTasks();
  } catch (e) {
    toast(cleanError(e), 'error');
  } finally {
    submitBtnReset(btn);
  }
}

async function doCompleteTask(id, btn) {
  try {
    var res = await completeTask(id);
    var earned = res && res.gamification && res.gamification.xpEarned;
    toast(earned ? '+' + earned + ' XP' : '+20 XP', earned ? 'success' : 'success');
    var row = document.querySelector('[data-task="' + id + '"]');
    if (row) row.classList.add('opacity-55');
    setTimeout(function () { renderTasks(); }, 700);
  } catch (e) {
    toast(cleanError(e), 'error');
  }
}

/* ══════════════════════ CALENDÁRIO (Etapa 9) ══════════════════════
   Estado e renderização (dia/semana/mês) ficam em services/calendar.js. */
function openPersonalEventModal() {
  var form = document.getElementById('personal-event-form');
  form.reset();
  form.elements['date'].value = toLocalDateStr(new Date());
  document.getElementById('personal-event-modal').classList.remove('hidden');
  document.getElementById('personal-event-modal').classList.add('flex');
}

async function submitPersonalEventForm(form) {
  var btn = form.querySelector('button[type="submit"]');
  submitBtnLoading(btn);
  try {
    await createPersonalEvent({
      title: form.elements['title'].value,
      date: form.elements['date'].value,
      note: form.elements['note'].value || null,
    });
    toast('Evento pessoal salvo');
    closeModal('personal-event-modal');
    CAL_SELECTED = calParseDay(form.elements['date'].value);
    CAL_CURSOR = new Date(CAL_SELECTED);
    if (CAL_SCOPE !== 'PESSOAL') setCalendarScope('PESSOAL');
    else renderCalendar();
  } catch (e) {
    toast(cleanError(e), 'error');
  } finally {
    submitBtnReset(btn);
  }
}

/* ══════════════════════ PERFIL (Etapa 10) ══════════════════════ */
async function renderProfile() {
  var nameEl = document.getElementById('profile-name');
  var subEl = document.getElementById('profile-sub');
  var nextEl = document.getElementById('profile-next');
  var initialEl = document.getElementById('profile-initial');
  var badgesEl = document.getElementById('badges-grid');
  var prof = typeof isProfessor === 'function' && isProfessor();

  /* Professor não participa de gamificação: sem insígnias, nível ou Kai. */
  var barWrap = document.getElementById('profile-bar-wrap');
  var badgesSection = document.getElementById('profile-badges-section');
  var kaiRow = document.getElementById('profile-kai-row');
  if (barWrap) barWrap.style.display = prof ? 'none' : '';
  if (nextEl) nextEl.style.display = prof ? 'none' : '';
  if (badgesSection) badgesSection.style.display = prof ? 'none' : '';
  if (kaiRow) kaiRow.style.display = prof ? 'none' : '';

  if (!prof) showLoading(badgesEl);
  try {
    var user = State.user || await fetchMe();
    if (nameEl) nameEl.textContent = user.name;
    if (initialEl) initialEl.textContent = (user.name || '?').trim().charAt(0).toUpperCase();

    if (prof) {
      if (subEl) subEl.textContent = ['Professor' + (user.authorized ? ' responsável' : ''), user.email].filter(Boolean).join(' · ');
      empty(badgesEl);
      return;
    }

    var g = null, p = null;
    try { g = await getGamificationStats(); } catch (e) {}
    try { p = await getProgress(); } catch (e) {}

    if (subEl) {
      var parts = [];
      if (isProfessor()) {
        parts.push('Professor' + (user.authorized ? ' responsável' : ''));
      } else {
        if (g && g.level) parts.push('Nível ' + g.level + ' · ' + levelTitle(g.level));
        if (g && g.xp !== undefined) parts.push(g.xp + ' XP');
        if (user.rm) parts.push('RM ' + user.rm);
      }
      subEl.textContent = parts.join(' · ') || user.email;
    }
    if (nextEl) {
      if (g && g.xpToNextLevel) nextEl.textContent = g.xpToNextLevel + ' para o próximo nível';
      else if (g && g.levelProgress !== undefined) nextEl.textContent = g.levelProgress + '% para o próximo nível';
      else if (p && p.overallProgress !== undefined) nextEl.textContent = 'Progresso geral: ' + p.overallProgress + '%';
      else nextEl.textContent = '';
    }
    var bar = document.getElementById('profile-bar');
    if (bar) {
      if (g && g.levelProgress !== undefined) bar.style.width = g.levelProgress + '%';
      else if (g && g.xp && g.xpToNextLevel) bar.style.width = Math.min(100, Math.round((g.xp / (g.xp + g.xpToNextLevel)) * 100)) + '%';
      else if (p && p.overallProgress !== undefined) bar.style.width = p.overallProgress + '%';
    }

    var achievements = null;
    try { achievements = await getAchievements(); } catch (e) {}
    empty(badgesEl);
    if (achievements && Array.isArray(achievements) && achievements.length) {
      var open = achievements.filter(function (a) { return a.earned !== false; });
      (open.length ? open : achievements).forEach(function (a) {
        badgesEl.insertAdjacentHTML('beforeend',
          '<div class="card aspect-square flex flex-col items-center justify-center gap-[5px]">' +
          '<span class="text-xl">' + esc(a.icon || '🏅') + '</span>' +
          '<span class="text-[9px] text-text-mid font-bold">' + esc(a.name || a.title || '') + '</span></div>');
      });
    } else {
      badgesEl.innerHTML =
        '<div class="card aspect-square flex flex-col items-center justify-center gap-[5px] opacity-[.28] border-dashed"><span class="text-xl">🔒</span><span class="text-[9px] text-text-low font-bold">VOCÊ DESBLOQUEIA</span></div>';
    }
  } catch (e) {
    badgesEl.innerHTML = errorView(e && e.message);
  }
}

function logoutAndGoLogin() {
  stopStreakTracking();
  logout();
  closeProfileDrawer();
  goTo('login');
  toast('Você saiu da sua conta.');
}

/* ── Avatar do usuário no statusbar (abre o drawer de perfil) ── */
function mountStatusbarAvatars() {
  document.querySelectorAll('.statusbar').forEach(function (bar) {
    if (bar.querySelector('.statusbar-avatar')) return;
    var first = bar.querySelector('span');
    if (!first) return;
    var btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'statusbar-avatar';
    btn.setAttribute('aria-label', 'Abrir perfil');
    btn.innerHTML = '<span class="statusbar-avatar-initial">A</span>';
    btn.addEventListener('click', openProfileDrawer);
    bar.replaceChild(btn, first);
  });
}

function updateStatusbarAvatar() {
  var user = State.user;
  var initial = user && user.name ? String(user.name).charAt(0).toUpperCase() : 'A';
  document.querySelectorAll('.statusbar-avatar-initial').forEach(function (el) {
    el.textContent = initial;
  });
}

/* ── Drawer de perfil + configurações ── */
var PROFILE_DRAWER_TIMER = null;

function openProfileDrawer() {
  renderProfileDrawer();
  updateStatusbarAvatar();
  var drawer = document.getElementById('profile-drawer');
  if (!drawer) return;
  if (PROFILE_DRAWER_TIMER) { clearTimeout(PROFILE_DRAWER_TIMER); PROFILE_DRAWER_TIMER = null; }
  drawer.style.display = 'flex';
  requestAnimationFrame(function () { drawer.classList.add('open'); });
  drawer.setAttribute('aria-hidden', 'false');
}

function closeProfileDrawer() {
  var drawer = document.getElementById('profile-drawer');
  if (!drawer) return;
  drawer.classList.remove('open');
  drawer.setAttribute('aria-hidden', 'true');
  if (PROFILE_DRAWER_TIMER) clearTimeout(PROFILE_DRAWER_TIMER);
  PROFILE_DRAWER_TIMER = setTimeout(function () {
    if (!drawer.classList.contains('open')) drawer.style.display = 'none';
  }, 300);
}

function toggleDrawerSettings() {
  var panel = document.getElementById('drawer-settings');
  var trigger = document.querySelector('[aria-controls="drawer-settings"]');
  if (!panel) return;
  var open = panel.classList.toggle('open');
  if (trigger) trigger.setAttribute('aria-expanded', open ? 'true' : 'false');
}

function renderProfileDrawer() {
  var user = State.user || {};
  var name = user.name || 'Aluno';
  var isTeacher = (user.role || '').toUpperCase() === 'PROFESSOR';
  var sub = isTeacher
    ? (user.authorized === false ? 'Professor — aprovação pendente' : 'Professor autorizado')
    : ('RM ' + (user.rm || '—') + (user.email ? ' · ' + user.email : ''));
  var avatar = document.getElementById('drawer-avatar');
  var nameEl = document.getElementById('drawer-name');
  var subEl = document.getElementById('drawer-sub');
  var progressRow = document.getElementById('drawer-progress-row');
  if (avatar) avatar.textContent = String(name).charAt(0).toUpperCase();
  if (nameEl) nameEl.textContent = name;
  if (subEl) subEl.textContent = sub;
  if (progressRow) progressRow.style.display = isTeacher ? 'none' : '';
  applyPrefs();
}

/* UC08/RF12: perfil com nível, XP, conquistas e insígnias. */
function openProfileFromDrawer() {
  closeProfileDrawer();
  goTo('perfil');
}

/* ══════════════════════ AVISOS (Etapa 9) ══════════════════════ */
function announcementCardHTML(a) {
  var subject = (a.subject && a.subject.name) || (a.subjectName) || 'KRIPTA';
  return (
    '<div class="card p-3.5">' +
    '<div class="flex justify-between">' +
    '<span class="text-[11px] font-bold text-indigo tracking-wider">' + esc(subject.toUpperCase()) + '</span>' +
    '<span class="text-[11px] text-text-low">' + timeAgo(a.createdAt || a.date) + '</span>' +
    '</div>' +
    '<div class="text-sm font-bold mt-1.5">' + esc(a.title) + '</div>' +
    (a.message ? '<div class="text-[12.5px] text-text-mid mt-[3px] leading-[1.5]">' + esc(a.message) + '</div>' : '') +
    (a.description && !a.message ? '<div class="text-[12.5px] text-text-mid mt-[3px] leading-[1.5]">' + esc(a.description) + '</div>' : '') +
    '</div>'
  );
}

async function renderAnnouncements() {
  var container = document.getElementById('announcements-list');
  showLoading(container);
  renderNotifications();
  try {
    var list = await getAnnouncements();
    var arr = Array.isArray(list) ? list : (list && list.content ? list.content : []);
    empty(container);
    if (!arr.length) {
      container.innerHTML = emptyState('Nenhum aviso ainda', 'Avisos das matérias aparecem aqui.');
    } else {
      arr.forEach(function (a) { container.insertAdjacentHTML('beforeend', announcementCardHTML(a)); });
    }
  } catch (e) {
    container.innerHTML = errorView(e && e.message);
  }
}

/* Notificações derivadas do calendário (RF07 / RN05) */
async function renderNotifications() {
  var container = document.getElementById('notifications-list');
  if (!container) return;
  showLoading(container);
  try {
    var list = await getNotifications();
    var arr = Array.isArray(list) ? list : (list && list.content ? list.content : []);
    empty(container);
    if (!arr.length) {
      container.innerHTML = '<div class="text-[12.5px] text-text-mid py-2">Sem notificações no momento.</div>';
      return;
    }
    arr.forEach(function (n) { container.insertAdjacentHTML('beforeend', notificationCardHTML(n)); });
  } catch (e) {
    container.innerHTML = errorView(e && e.message);
  }
}

/* ══════════════════════ PROFESSOR (RF03/RF04 — UC05/UC06) ══════════════════════ */
async function renderProfessor() {
  var subEl = document.getElementById('professor-sub');
  var container = document.getElementById('professor-contents');
  if (subEl && State.user) subEl.textContent = (State.user.name || 'Professor') + (State.user.authorized ? ' · autorizado a aprovar' : ' · sem permissão de aprovação');
  showLoading(container);
  try {
    var list = await getMyContents();
    var arr = Array.isArray(list) ? list : (list && list.content ? list.content : []);
    empty(container);
    if (!arr.length) {
      container.innerHTML = emptyState('Nenhum conteúdo cadastrado', 'Use "Cadastrar conteúdo" para enviar material ao seu componente curricular.');
      return;
    }
    arr.forEach(function (c) { container.insertAdjacentHTML('beforeend', professorContentCardHTML(c, false)); });
  } catch (e) {
    container.innerHTML = errorView(e && e.message);
  }
}

async function renderApprovals() {
  var subEl = document.getElementById('approvals-sub');
  var container = document.getElementById('approvals-list');
  if (subEl) subEl.textContent = isAuthorizedTeacher() ? 'Aguardando sua revisão' : 'Somente professores responsáveis podem aprovar';
  showLoading(container);
  if (!isAuthorizedTeacher()) {
    empty(container);
    container.innerHTML = emptyState('Acesso restrito', 'Apenas professores autorizados podem aprovar ou rejeitar conteúdos (RN04).');
    return;
  }
  try {
    var list = await getPendingContents();
    var arr = Array.isArray(list) ? list : (list && list.content ? list.content : []);
    empty(container);
    if (!arr.length) {
      container.innerHTML = emptyState('Nada para aprovar', 'Novos conteúdos enviados por professores aparecem aqui.');
      return;
    }
    var wrap = el('div', 'flex flex-col gap-[9px]');
    arr.forEach(function (c) { wrap.insertAdjacentHTML('beforeend', professorContentCardHTML(c, true)); });
    container.appendChild(wrap);
  } catch (e) {
    container.innerHTML = errorView(e && e.message);
  }
}

async function doApproveContent(id, btn) {
  if (!isAuthorizedTeacher()) { toast('Apenas professores autorizados podem aprovar conteúdos.', 'error'); return; }
  if (btn) submitBtnLoading(btn, 'Aprovando…');
  try {
    await approveContent(id);
    toast('Conteúdo aprovado');
    renderApprovals();
  } catch (e) {
    toast(cleanError(e), 'error');
    if (btn) submitBtnReset(btn);
  }
}

async function doRejectContent(id, btn) {
  if (!isAuthorizedTeacher()) { toast('Apenas professores autorizados podem rejeitar conteúdos.', 'error'); return; }
  var reason = window.prompt('Motivo da rejeição (opcional):') || null;
  if (btn) submitBtnLoading(btn, 'Rejeitando…');
  try {
    await rejectContent(id, reason);
    toast('Conteúdo rejeitado');
    renderApprovals();
  } catch (e) {
    toast(cleanError(e), 'error');
    if (btn) submitBtnReset(btn);
  }
}

/* ── Modal de cadastro de conteúdo ── */
var CONTENT_TYPES = ['PDF', 'VIDEO', 'LINK', 'DOCUMENT', 'SLIDE', 'OTHER'];

async function openContentModal() {
  var form = document.getElementById('content-form');
  form.reset();
  var subjectSel = form.elements['subjectId'];
  var unitSel = form.elements['unitId'];
  var typeSel = form.elements['type'];
  subjectSel.innerHTML = '';
  typeSel.innerHTML = '';
  unitSel.innerHTML = '';
  CONTENT_TYPES.forEach(function (t) { var o = el('option', null, t); o.value = t; typeSel.appendChild(o); });
  var noUnit = el('option', null, 'Sem unidade'); noUnit.value = ''; unitSel.appendChild(noUnit);
  try {
    var subjects = await getSubjects();
    var arr = Array.isArray(subjects) ? subjects : (subjects && subjects.content ? subjects.content : []);
    arr.forEach(function (s) { var o = el('option', null, s.name); o.value = s.id; subjectSel.appendChild(o); });
    subjectSel.addEventListener('change', function () { fillContentUnits(subjectSel.value); });
    if (arr.length && State.currentSubject) subjectSel.value = State.currentSubject.id;
  } catch (e) { /* sem matérias */ }
  fillContentUnits(subjectSel.value);
  document.getElementById('content-modal').classList.remove('hidden');
  document.getElementById('content-modal').classList.add('flex');
}

async function fillContentUnits(subjectId) {
  var form = document.getElementById('content-form');
  var unitSel = form.elements['unitId'];
  unitSel.innerHTML = '';
  var noUnit = el('option', null, 'Sem unidade'); noUnit.value = ''; unitSel.appendChild(noUnit);
  if (!subjectId) return;
  try {
    var units = await getUnits(subjectId);
    var arr = Array.isArray(units) ? units : (units && units.content ? units.content : []);
    arr.forEach(function (u) { var o = el('option', null, u.name); o.value = u.id; unitSel.appendChild(o); });
  } catch (e) { /* sem unidades */ }
}

async function submitContentForm(form) {
  var btn = form.querySelector('button[type="submit"]');
  submitBtnLoading(btn);
  var data = {
    subjectId: form.elements['subjectId'].value,
    unitId: form.elements['unitId'].value || null,
    title: form.elements['title'].value,
    type: form.elements['type'].value,
    url: form.elements['url'].value || null,
    description: form.elements['description'].value || null,
  };
  if (!data.subjectId) { toast('Selecione o componente curricular', 'error'); submitBtnReset(btn); return; }
  try {
    await createContent(data);
    toast('Conteúdo enviado para aprovação');
    closeModal('content-modal');
    renderProfessor();
  } catch (e) {
    toast(cleanError(e), 'error');
  } finally {
    submitBtnReset(btn);
  }
}

/* ══════════════════════ KAI (Etapa 11) ══════════════════════ */
function initKai() {
  var container = document.getElementById('kai-chat');
  if (container.dataset.ready) {
    bindKaiSend();
    return;
  }
  empty(container);
  var name = State.user ? State.user.name.split(' ')[0] : 'humano';
  container.innerHTML =
    '<div class="flex gap-2 max-w-[90%]">' +
    '<div class="w-7 h-7 rounded-[9px] bg-lilac shrink-0 flex items-center justify-center text-[13px]">🤖</div>' +
    '<div class="chat-bubble-kai"><div class="text-[13px] leading-[1.55] text-text-hi">Oi, ' + esc(name) + '! Posso te ajudar com matérias, tarefas e prazos. O que precisa hoje?</div></div>' +
    '</div>';
  container.dataset.ready = '1';
  window.__kaiTyping = false;
  bindKaiSend();
}

async function sendKai() {
  var input = document.getElementById('kai-input');
  var container = document.getElementById('kai-chat');
  var message = (input.value || '').trim();
  if (!message || window.__kaiTyping) return;

  container.insertAdjacentHTML('beforeend',
    '<div class="flex justify-end"><div class="chat-bubble-user"><div class="text-[13px] leading-[1.55] text-white">' + esc(message) + '</div></div></div>');
  input.value = '';
  window.__kaiTyping = true;
  container.scrollTop = container.scrollHeight;

  var typingId = 'kai-typing';
  container.insertAdjacentHTML('beforeend',
    '<div class="flex gap-2 max-w-[90%]"><div class="w-7 h-7 rounded-[9px] bg-lilac shrink-0 flex items-center justify-center text-[13px]">🤖</div>' +
    '<div class="chat-bubble-kai"><div class="text-[13px]" id="' + typingId + '">…</div></div></div>');

  try {
    var res = await kaiChat(message);
    var reply = (res && (res.reply || res.response || res.message)) || 'Não consegui processar sua pergunta agora.';
    var typing = document.getElementById(typingId);
    if (typing) typing.textContent = reply;
  } catch (e) {
    var typing = document.getElementById(typingId);
    if (typing) typing.textContent = 'Ops, não consegui responder agora: ' + cleanError(e);
  } finally {
    window.__kaiTyping = false;
    container.scrollTop = container.scrollHeight;
  }
}

function bindKaiSend() {
  var btn = document.getElementById('kai-send');
  var input = document.getElementById('kai-input');
  if (btn && btn.dataset.bound) return;
  if (!btn || !input) return;
  btn.dataset.bound = '1';
  btn.addEventListener('click', sendKai);
  input.addEventListener('keydown', function (e) {
    if (e.key === 'Enter') sendKai();
  });
}

/* ══════════════════════ AUTH (Etapa 3) ══════════════════════ */
async function submitLogin(form) {
  var btn = form.querySelector('button[type="submit"]');
  var errEl = document.getElementById('login-error');
  submitBtnLoading(btn);
  try {
    await loginUser({
      email: form.elements['email'].value,
      password: form.elements['password'].value,
      role: form.elements['role'] ? form.elements['role'].value : 'ALUNO',
    });
    resolvePostAuth();
    startStreakTracking();
    healthCheck();
  } catch (e) {
    if (errEl) errEl.textContent = cleanError(e);
    toast(cleanError(e), 'error');
  } finally {
    submitBtnReset(btn);
  }
}

/* Mostra RM para aluno e autorização para professor (RN01/RN02). */
function bindRegisterRole() {
  var sel = document.getElementById('register-role');
  if (!sel) return;
  var apply = function () {
    var prof = sel.value === 'PROFESSOR';
    var rmWrap = document.getElementById('register-rm-wrap');
    var authWrap = document.getElementById('register-auth-wrap');
    var rmInput = document.querySelector('#register-form [name="rm"]');
    if (rmWrap) rmWrap.style.display = prof ? 'none' : '';
    if (authWrap) authWrap.style.display = prof ? '' : 'none';
    if (rmInput) rmInput.required = !prof;
  };
  sel.addEventListener('change', apply);
  apply();
}

function registerPayload(form) {
  var role = (form.elements['role'] && form.elements['role'].value) || 'ALUNO';
  return {
    name: form.elements['name'].value,
    email: form.elements['email'].value,
    password: form.elements['password'].value,
    role: role,
    rm: form.elements['rm'] ? form.elements['rm'].value : null,
    authorized: form.elements['authorized'] ? form.elements['authorized'].checked : false,
  };
}

async function submitRegister(form) {
  var btn = form.querySelector('button[type="submit"]');
  var errEl = document.getElementById('register-error');
  var payload = registerPayload(form);
  var name = payload.name;
  var email = payload.email;
  var password = payload.password;
  var confirm = form.elements['confirmPassword'] ? form.elements['confirmPassword'].value : null;

  /* RN01: o aluno precisa do RM para ser identificado pela instituição. */
  if (!isDevAccess(payload) && payload.role === 'ALUNO' && !String(payload.rm || '').trim()) {
    var rmMsg = 'Informe o RM (registro de matrícula) para cadastro de aluno.';
    if (errEl) errEl.textContent = rmMsg;
    toast(rmMsg, 'error');
    return;
  }

  /* Entrada de dev: dispensa validações e vai direto para a Home */
  if (isDevAccess(payload)) {
    await registerUser(payload);
    resolvePostAuth();
    startStreakTracking();
    healthCheck();
    return;
  }

  if (confirm !== null && password !== confirm) {
    if (errEl) errEl.textContent = 'As senhas não coincidem.';
    toast('As senhas não coincidem.', 'error');
    return;
  }
  submitBtnLoading(btn);
  try {
    await registerUser(payload);
    resolvePostAuth();
    startStreakTracking();
    healthCheck();
  } catch (e) {
    if (errEl) errEl.textContent = cleanError(e);
    toast(cleanError(e), 'error');
  } finally {
    submitBtnReset(btn);
  }
}