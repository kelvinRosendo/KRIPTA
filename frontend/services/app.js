/* ── App principal: init, rotas, renderização dinâmica ── */

document.addEventListener('DOMContentLoaded', init);

function init() {
  updateTopbarDate();
  bindGlobalEvents();
  bindSubjectFilter();
  updateStatusbarAvatar();
  applyPrefs();

  bindRegisterRole();

  if (isAuthenticated()) {
    fetchMe().then(function () { updateStatusbarAvatar(); goTo(defaultScreenForRole()); startStreakTracking(); }).catch(function () { logout(); goTo('login'); });
  } else { goTo('login'); }

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
      case 'insignias': renderBadgeCollection(); break;
      case 'avisos': renderAnnouncements(); break;
      case 'professor': renderProfessor(); break;
      case 'salas': renderSalas(); break;
      case 'aprovacoes': renderApprovals(); break;
      case 'ia': initKai(); break;
    }
  } catch (e) {
    console.error('Erro ao renderizar tela', screenName, e);
  }
}

function handleSessionExpired() {
  logout();
  closeProfileDrawer(true);
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
  var token = State.token;
  var greeting = document.getElementById('home-greeting');
  if (State.user && State.user.name) greeting.textContent = 'Olá, ' + State.user.name.split(' ')[0];
  document.getElementById('home-highlight').hidden = true;
  renderHomeAgenda();
  renderHomeSubjects();

  try {
    var dash = await getDashboard();
    if (State.token !== token) return;
    fillHomeStats(dash);
    fillHomeTasks(dash);
    fillHomeHighlight(dash);
  } catch (e) {
    if (State.token === token) document.getElementById('home-tasks').innerHTML = errorView(e && e.message);
  }
}

async function renderHomeSubjects() {
  var panel = document.getElementById('home-subjects');
  var token = State.token;
  showLoading(panel);
  try {
    var subjects = await getSubjects();
    if (State.token !== token) return;
    panel.replaceChildren();
    subjects.slice(0, 3).forEach(function (subject) {
      var item = document.createElement('button');
      item.type = 'button';
      item.className = 'card home-subject';
      item.dataset.openSubject = subject.id;
      var appearance = subjectAppearance(subject);
      item.style.setProperty('--subject-color', appearance.color);
      item.style.setProperty('--subject-ink', appearance.ink);
      item.textContent = subject.name;
      panel.append(item);
    });
    if (!subjects.length) panel.innerHTML = emptyState('Nenhuma matéria cadastrada', '', 'book');
  } catch (error) {
    if (State.token === token) panel.textContent = 'Não foi possível carregar as matérias.';
  }
}

function fillHomeHighlight(dash) {
  var next = dash.tasksToday.concat(dash.tasksTomorrow, dash.upcomingTasks || []).reduce(function (earliest, task) {
    return !earliest || new Date(task.dueDate) < new Date(earliest.dueDate) ? task : earliest;
  }, null);
  if (!next) return;

  document.getElementById('home-highlight-title').textContent = next.title;
  document.getElementById('home-highlight-date').textContent = 'Próxima entrega · ' + formatDateTime(next.dueDate);
  document.getElementById('home-highlight').hidden = false;
}

async function renderHomeAgenda() {
  var panel = document.getElementById('home-agenda');
  var token = State.token;
  var today = new Date();
  showLoading(panel);
  try {
    var events = await getCalendar(toLocalDateStr(today), toLocalDateStr(calAddDays(today, 7)));
    if (State.token !== token) return;
    panel.replaceChildren();
    events.sort(function (a, b) {
      return (a.date + (a.time || '')).localeCompare(b.date + (b.time || ''));
    }).slice(0, 3).forEach(function (event) {
      var row = document.createElement('div');
      row.className = 'home-event';
      var date = document.createElement('time');
      date.dateTime = event.date;
      date.textContent = formatDate(calParseDay(event.date));
      var details = document.createElement('div');
      var title = document.createElement('strong');
      title.textContent = event.title;
      var meta = document.createElement('p');
      meta.textContent = (event.scope === 'PESSOAL' ? 'Pessoal' : 'Escolar') +
        (event.time ? ' · ' + event.time.slice(0, 5) : '');
      details.append(title, meta);
      row.append(date, details);
      panel.append(row);
    });
    if (!events.length) panel.innerHTML = emptyState('Nenhum evento nos próximos sete dias', '', 'calendar');
  } catch (error) {
    if (State.token === token) panel.textContent = 'Não foi possível carregar a agenda.';
  }
}

function fillHomeStats(dash) {
  var stats = (dash && dash.stats) || {};
  var xp = stats.xp !== undefined ? stats.xp : dash.xp;
  var level = stats.level !== undefined ? stats.level : dash.level;
  var streak = stats.streak !== undefined ? stats.streak : dash.streak;
  var badges = (dash.badgesCount !== undefined) ? dash.badgesCount : (dash.achievements ? dash.achievements.length : null);
  if (badges !== null && level) badges += badgeDefinitions.filter(function (badge) {
    return badge.level && badge.level <= level;
  }).length;

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
  (dash.upcomingTasks || []).forEach(function (t) { tasks.push({ task: t, label: taskSideLabel(t), color: 'border-l-border' }); });
  (dash.overdueTasks || []).forEach(function (t) { tasks.push({ task: t, label: '<span class="pill bg-crimson-light text-crimson" style="flex:0 0 auto">atrasada</span>', color: 'border-l-crimson' }); });

  if (!tasks.length) {
    container.innerHTML = emptyState('Nada por aqui', 'Você não tem atividades pendentes nos próximos sete dias.', 'tasks');
    return;
  }

  tasks.slice(0, 6).forEach(function (item) {
    container.insertAdjacentHTML('beforeend', taskRow(item.task, { accentColor: item.color, sideLabel: function () { return item.label; }, noDelete: true }));
  });
}

/* ══════════════════════ MATÉRIAS (Etapa 5) ══════════════════════ */
var SUBJECT_STYLES = [
  [/program|sistemas|banco de dados|internet|tecnologia|informati|comput/, 'code', '#625add'],
  [/matemat|estatistica|calculo/, 'calc', '#42ddd7'],
  [/quimica|fisica|laborat/, 'flask', '#ff6b35'],
  [/biologia|nutri|ambiente|saude|alimento/, 'leaf', '#30d5a0'],
  [/geografia|historia|filosofia|sociologia/, 'globe', '#b28fff'],
  [/marketing|gestao|administr|negocio|financ|contab/, 'chart', '#ffad47'],
  [/arte|design/, 'palette', '#f47cb6']
];

function subjectGroupHTML(label) {
  return '<div class="subject-group-label text-[11px] font-bold uppercase tracking-wide text-text-low mt-2 mb-0.5 px-0.5">' + esc(label) + '</div>';
}

function subjectAppearance(s) {
  var name = s.name.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');
  var style = SUBJECT_STYLES.find(function (entry) { return entry[0].test(name); });
  var icon = style ? style[1] : 'book';
  var color = style ? style[2] : '#b28fff';
  var ink = color === '#625add' ? '#ffffff' : '#171329';
  return { icon: icon, color: color, ink: ink };
}

function subjectCardHTML(s) {
  var appearance = subjectAppearance(s);
  var meta = subjectMeta(s);
  var pending = (s.pendingCount && s.pendingCount > 0)
    ? '<span class="pill bg-crimson-light text-crimson">' + s.pendingCount + ' pendência' + (s.pendingCount === 1 ? '' : 's') + '</span>'
    : '<span class="pill bg-teal-light text-teal">em dia</span>';
  return (
    '<div class="card subject-color-card" style="--subject-color:' + appearance.color + ';--subject-ink:' + appearance.ink + '">' +
    '<button type="button" class="subject-open" data-open-subject="' + s.id + '">' +
    '<span class="subject-emblem">' + uiIcon(appearance.icon) + '</span>' +
    '<span class="subject-text"><strong>' + esc(s.name) + '</strong>' +
    (meta ? '<small>' + esc(meta) + '</small>' : '') +
    '</span>' + pending + '</button>' +
    '<button type="button" class="icon-btn !w-8 !h-8" data-action="delete" data-kind="subject" data-id="' + s.id + '" data-name="' + esc(s.name) + '" aria-label="Excluir matéria">' +
    '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#6B6F8E" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2m2 0-1 14a2 2 0 0 1-2 2H9a2 2 0 0 1-2-2L6 6"/></svg>' +
    '</button>' +
    '</div>'
  );
}

var subjectsView = null;

async function renderSubjects() {
  var token = State.token;
  subjectsView = null;
  renderCourseSelection();
  var list = document.getElementById('subjects-list');
  var countEl = document.getElementById('subjects-count');
  showLoading(list);
  try {
    var subjects = await getSubjects();
    var arr = Array.isArray(subjects) ? subjects : (subjects && subjects.content ? subjects.content : []);
    if (State.token !== token) return;
    subjectsView = { token: token, items: arr };
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
  var query = normalizeSubjectSearch(document.getElementById('subject-search').value);
  var filtered = subjects.filter(function (subject) {
    return (filter === 'all' || String(subject[filter] || '').toLowerCase() === 'true') &&
      normalizeSubjectSearch(subject.name || '').includes(query);
  });

  empty(list);
  if (!filtered.length) {
    var hasCriteria = query || filter !== 'all';
    list.innerHTML = '<div class="subjects-empty" role="status">' +
      crystalIllustration('book') +
      '<h2>' + (hasCriteria ? 'Nenhuma matéria encontrada' : 'Nenhuma matéria cadastrada') + '</h2>' +
      '<p>' + (hasCriteria ? 'Tente outro nome ou mude o filtro.' : 'Adicione sua primeira matéria para organizar unidades e materiais.') + '</p></div>';
  } else if (courseView && courseView.selecao) {
    var courseIds = new Set(courseView.selecao.disciplinaIds);
    var current = filtered.filter(function (subject) { return courseIds.has(subject.id); });
    var other = filtered.filter(function (subject) { return !courseIds.has(subject.id); });
    if (current.length) {
      list.insertAdjacentHTML('beforeend', subjectGroupHTML('Matérias da minha turma'));
      current.forEach(function (subject) { list.insertAdjacentHTML('beforeend', subjectCardHTML(subject)); });
    }
    if (other.length) {
      list.insertAdjacentHTML('beforeend', subjectGroupHTML('Outras matérias'));
      other.forEach(function (subject) { list.insertAdjacentHTML('beforeend', subjectCardHTML(subject)); });
    }
  } else {
    var GROUPS = [
      { key: 'CURSO', label: 'Matérias do curso' },
      { key: 'BASE', label: 'Matérias da Base Comum Curricular' },
    ];
    var byGroup = { CURSO: [], BASE: [], OUTROS: [] };
    filtered.forEach(function (s) {
      var g = (s.group === 'CURSO' || s.group === 'BASE') ? s.group : 'OUTROS';
      byGroup[g].push(s);
    });
    GROUPS.forEach(function (group) {
      if (!byGroup[group.key].length) return;
      list.insertAdjacentHTML('beforeend', subjectGroupHTML(group.label));
      byGroup[group.key].forEach(function (s) { list.insertAdjacentHTML('beforeend', subjectCardHTML(s)); });
    });
    if (byGroup.OUTROS.length) {
      list.insertAdjacentHTML('beforeend', subjectGroupHTML('Outras matérias'));
      byGroup.OUTROS.forEach(function (s) { list.insertAdjacentHTML('beforeend', subjectCardHTML(s)); });
    }
  }
}

function normalizeSubjectSearch(value) {
  return value.trim().toLocaleLowerCase('pt-BR').normalize('NFD').replace(/\p{M}/gu, '');
}

function refreshSubjectFilter() {
  if (subjectsView && subjectsView.token === State.token) applySubjectFilter(subjectsView.items);
}

function bindSubjectFilter() {
  document.getElementById('subject-search').addEventListener('input', refreshSubjectFilter);
  document.querySelectorAll('[data-subject-filter]').forEach(function (pill) {
    pill.addEventListener('click', function () {
      window.__subjectFilter = pill.getAttribute('data-subject-filter');
      document.querySelectorAll('[data-subject-filter]').forEach(function (p) {
        p.setAttribute('aria-pressed', String(p === pill));
      });
      refreshSubjectFilter();
    });
  });
}

/* ── Formulário de matéria ── */
async function openSubjectModal(subject) {
  var form = document.getElementById('subject-form');
  window.__editingSubject = subject || null;
  var components = await api.get('/componentes');
  var select = form.elements['componentId'];
  select.innerHTML = '<option value="">Sem vínculo acadêmico</option>';
  components.forEach(function(c) { var option = document.createElement('option'); option.value = c.id; option.textContent = c.name; select.appendChild(option); });
  select.value = subject && subject.componentId || '';
  form.reset();
  document.getElementById('subject-modal-title').textContent = subject ? 'Editar matéria' : 'Nova matéria';
  if (subject) {
    form.elements['name'].value = subject.name || '';
    form.elements['color'].value = subject.color || '#6366F1';
  }
  document.getElementById('subject-modal').classList.remove('hidden');
  document.getElementById('subject-modal').classList.add('flex');
}

async function submitSubjectForm(form) {
  var btn = form.querySelector('button[type="submit"]');
  submitBtnLoading(btn);
  var data = { name: form.elements['name'].value, color: form.elements['color'].value, componentId: form.elements['componentId'].value ? Number(form.elements['componentId'].value) : null };
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
  else if (tab === 'atividades') renderSubjectTasks();
  else renderSubjectAvisos();
}

async function renderSubjectTasks() {
  var body = document.getElementById('subject-body');
  var subject = State.currentSubject;
  var token = State.token;
  showLoading(body);
  try {
    var tasks = await getTasks({ subjectId: subject.id });
    if (State.token !== token || State.currentSubject !== subject || DETAIL_TAB !== 'atividades') return;
    var wrap = el('section', 'px-app subject-tasks');
    var action = el('button', 'btn-primary subjects-add', 'Nova atividade');
    action.type = 'button';
    action.addEventListener('click', function () { openTaskModal(subject.id); });
    wrap.appendChild(action);
    if (!tasks.length) {
      wrap.insertAdjacentHTML('beforeend', emptyState('Nenhuma atividade nesta matéria', 'Adicione uma atividade com prazo para ver o lembrete na agenda.', 'tasks'));
    }
    tasks.forEach(function (task) {
      wrap.insertAdjacentHTML('beforeend', taskRow(task, { onEdit: true, sideLabel: taskSideLabel }));
    });
    body.replaceChildren(wrap);
  } catch (error) {
    if (State.token === token && State.currentSubject === subject && DETAIL_TAB === 'atividades') {
      body.innerHTML = errorView(error && error.message);
    }
  }
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
    '<div class="text-[14.5px] font-bold">' + uiIcon('folder') + ' ' + esc(unit.name) + '</div>' +
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
  showLoading(detail);
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
    var values = await Promise.all([getTasks(params), getSubjects().catch(function () { return []; })]);
    var tasks = values[0];
    var names = new Map(values[1].map(function (subject) { return [subject.id, subject.name]; }));
    var arr = Array.isArray(tasks) ? tasks : (tasks && tasks.content ? tasks.content : []);
    arr.forEach(function (task) { task.subjectName = names.get(task.subjectId); });
    if (countEl) countEl.textContent = arr.length + ' tarefa' + (arr.length === 1 ? '' : 's');
    renderTaskGroups(arr);
  } catch (e) {
    list.innerHTML = errorView(e && e.message);
  }
}

function setTasksFilter(filter) {
  TASKS_FILTER = filter;
  document.querySelectorAll('[data-task-filter]').forEach(function (p) {
    var active = p.dataset.taskFilter === filter;
    p.setAttribute('aria-pressed', String(active));
    if (active) {
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
var taskFormRequest = 0;

async function prepareTaskForm(form, subjectId) {
  var request = ++taskFormRequest;
  var token = State.token;
  var subjectSel = form.elements['subjectId'];
  var submit = form.querySelector('button[type="submit"]');
  subjectSel.replaceChildren(new Option('Carregando matérias…', ''));
  subjectSel.disabled = true;
  submit.disabled = true;
  try {
    var subjects = await getSubjects();
    if (request !== taskFormRequest || State.token !== token) return;
    subjectSel.replaceChildren(new Option('Sem matéria', ''));
    subjects.forEach(function (subject) { subjectSel.add(new Option(subject.name, subject.id)); });
    subjectSel.value = subjectId || '';
    submit.disabled = false;
  } catch (error) {
    if (request !== taskFormRequest || State.token !== token) return;
    subjectSel.replaceChildren(new Option('Não foi possível carregar as matérias', ''));
    toast('Não foi possível carregar as matérias. Feche o formulário e tente novamente.', 'error');
  } finally {
    if (request === taskFormRequest && State.token === token) subjectSel.disabled = false;
  }
}

function openTaskModal(subjectId) {
  var form = document.getElementById('task-form');
  window.__editingTask = null;
  form.reset();
  document.getElementById('task-modal-title').textContent = subjectId ? 'Nova atividade' : 'Nova tarefa';
  form.elements['dueDate'].required = Boolean(subjectId);
  form.elements['subjectId'].required = Boolean(subjectId);
  form.elements['priority'].value = 'MEDIUM';
  prepareTaskForm(form, subjectId);
  document.getElementById('task-modal').classList.remove('hidden');
  document.getElementById('task-modal').classList.add('flex');
}

function openTaskEditModal(id) {
  getTask(id)
    .then(function (t) {
      if (t.salaAtividadeId) {
        document.getElementById('room-task-title').textContent = t.title;
        var due = document.getElementById('room-task-due');
        due.dateTime = t.dueDate;
        due.textContent = formatDateTime(t.dueDate);
        document.getElementById('room-task-description').textContent = t.description || '';
        document.getElementById('room-task-dialog').showModal();
        return;
      }
      var form = document.getElementById('task-form');
      window.__editingTask = t;
      document.getElementById('task-modal-title').textContent = 'Editar tarefa';
      form.reset();
      form.elements['title'].value = t.title || '';
      form.elements['description'].value = t.description || '';
      form.elements['dueDate'].value = dueDateInputValue(t.dueDate);
      form.elements['priority'].value = t.priority || 'MEDIUM';
      form.elements['dueDate'].required = false;
      form.elements['subjectId'].required = false;
      prepareTaskForm(form, t.subjectId || (t.subject && t.subject.id));
      document.getElementById('task-modal').classList.remove('hidden');
      document.getElementById('task-modal').classList.add('flex');
    })
    .catch(function (e) { toast(cleanError(e), 'error'); });
}

async function submitTaskForm(form) {
  var btn = form.querySelector('button[type="submit"]');
  if (btn.disabled || !form.reportValidity()) return;
  submitBtnLoading(btn);
  try {
    var data = taskFormPayload(form);
    if (window.__editingTask) {
      await updateTask(window.__editingTask.id, data);
      toast('Tarefa atualizada');
    } else {
      await createTask(data);
      toast('Tarefa criada');
    }
    window.__editingTask = null;
    closeModal('task-modal');
    refreshTaskScreen();
  } catch (e) {
    toast(cleanError(e), 'error');
  } finally {
    submitBtnReset(btn);
  }
}

function refreshTaskScreen() {
  var active = document.querySelector('.screen.active');
  if (active && active.id === 'screen-materia-detalhe' && DETAIL_TAB === 'atividades') renderSubjectTasks();
  else if (active && active.id === 'screen-home') renderHome();
  else if (active && active.id === 'screen-calendario') renderCalendar();
  else renderTasks();
}

async function doCompleteTask(id, btn) {
  if (btn.disabled) return;
  var token = State.token;
  btn.disabled = true;
  btn.setAttribute('aria-busy', 'true');
  try {
    var res = await completeTask(id);
    if (State.token !== token) return;
    if (res && res.gamification) celebrateProgress(res.gamification);
    else toast('Tarefa concluída');
    refreshTaskScreen();
  } catch (e) {
    if (State.token === token) toast(cleanError(e), 'error');
  } finally {
    btn.disabled = false;
    btn.removeAttribute('aria-busy');
  }
}

/* ══════════════════════ CALENDÁRIO (Etapa 9) ══════════════════════
   Estado e renderização (dia/semana/mês) ficam em services/calendar.js. */
function openPersonalEventModal() {
  window.__editingEvent = null;
  var form = document.getElementById('personal-event-form');
  form.reset();
  form.elements['date'].value = toLocalDateStr(new Date());
  form.elements['scope'].querySelector('[value=ESCOLAR]').disabled = !isProfessor();
  document.getElementById('personal-event-modal').classList.remove('hidden');
  document.getElementById('personal-event-modal').classList.add('flex');
}

async function submitPersonalEventForm(form) {
  var btn = form.querySelector('button[type="submit"]');
  submitBtnLoading(btn);
  try {
    var eventPayload = {
      title: form.elements['title'].value,
      date: form.elements['date'].value,
      note: form.elements['note'].value || null,
      time: form.elements['time'].value || null,
      scope: form.elements['scope'].value,
      type: form.elements['type'].value,
    };
    if (window.__editingEvent) await api.put('/calendario/eventos/' + window.__editingEvent, eventPayload);
    else await createPersonalEvent(eventPayload);
    toast('Evento pessoal salvo');
    closeModal('personal-event-modal');
    CAL_SELECTED = calParseDay(form.elements['date'].value);
    CAL_CURSOR = new Date(CAL_SELECTED);
    if (CAL_SCOPE !== eventPayload.scope) setCalendarScope(eventPayload.scope);
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

    renderBadges(badgesEl, await getAchievements(), g && g.level);
  } catch (e) {
    badgesEl.innerHTML = errorView(e && e.message);
  }
}

var crystalGroups = [
  { name: 'Jasper', tone: 'orange', shape: 'M12 2 21 8 20 17 11 22 3 16 4 7Z', facets: 'm4 7 8 3 9-2m-9 2-1 12m-8-6 9-6 8 7' },
  { name: 'Lapiz-lazuli', tone: 'indigo', shape: 'M6 3h12l4 8-4 10H6L2 11Z', facets: 'm6 3 3 8-3 10m12-18-3 8 3 10M2 11h20' },
  { name: 'Ametista', tone: 'lilac', shape: 'm12 1 8 6v10l-8 6-8-6V7Z', facets: 'm4 7 8 3 8-3m-8-6v22m-8-6 8-7 8 7' },
  { name: 'Diamante', tone: 'teal', shape: 'M6 4h12l5 6-11 12L1 10Z', facets: 'M1 10h22M6 4l2 6 4 12 4-12 2-6M8 10l4-6 4 6' }
];

var badgeDefinitions = [
  { code: 'FIRST_TASK', name: 'Primeira tarefa', description: 'Concluiu a primeira tarefa.', group: 0 },
  { code: 'LEVEL_2', name: 'Estudante', level: 2, group: 0 },
  { code: 'FIRST_STREAK', name: 'Primeiro dia', description: 'Estudou por dez minutos em um dia.', group: 1 },
  { code: 'LEVEL_5', name: 'Dedicado', level: 5, group: 1 },
  { code: 'TEN_TASKS', name: 'Dez tarefas', description: 'Concluiu dez tarefas.', group: 2 },
  { code: 'LEVEL_10', name: 'Lenda', level: 10, group: 2 },
  { code: 'WEEK_STREAK', name: 'Semana de estudos', description: 'Manteve uma sequência por sete dias.', group: 3 },
  { code: 'LEVEL_20', name: 'Diamante', level: 20, group: 3 }
];

function earnedBadge(badge, codes, level) {
  return badge.level ? level >= badge.level : codes.has(badge.code);
}

function badgeCard(badge, unlocked) {
  var crystal = crystalGroups[badge.group];
  var label = unlocked ? badge.name : (badge.level ? 'Bloqueado. Atinja o nível ' + badge.level + ' para desbloquear.' : 'Bloqueado');
  var description = badge.description || ('Nível ' + badge.level + ' alcançado.');
  return '<article class="card badge-card' + (unlocked ? '' : ' badge-locked') + '">' +
    '<div class="badge-emblem badge-' + crystal.tone + '"><svg viewBox="0 0 24 24" aria-hidden="true">' +
    '<path d="' + crystal.shape + '" fill="currentColor" fill-opacity=".28" stroke="currentColor"/>' +
    '<path d="' + crystal.facets + '" fill="none" stroke="currentColor"/></svg></div>' +
    '<div><h3>' + esc(label) + '</h3>' + (unlocked ? '<p>' + esc(description) + '</p>' : '') +
    '</div></article>';
}

function renderBadges(container, achievements, level) {
  var codes = new Set(achievements.filter(function (badge) { return badge.earned !== false; }).map(function (badge) { return badge.code; }));
  var earned = badgeDefinitions.filter(function (badge) { return earnedBadge(badge, codes, level); });
  container.innerHTML = earned.length ? earned.map(function (badge) { return badgeCard(badge, true); }).join('') :
    emptyState('Nenhuma insígnia conquistada', 'Conclua uma tarefa para desbloquear sua primeira.', 'medal');
}

async function renderBadgeCollection() {
  var container = document.getElementById('crystal-collection');
  var token = State.token;
  showLoading(container);
  try {
    var result = await Promise.all([getAchievements(), getGamificationStats()]);
    if (State.token !== token) return;
    var codes = new Set(result[0].filter(function (badge) { return badge.earned !== false; }).map(function (badge) { return badge.code; }));
    container.innerHTML = crystalGroups.map(function (group, index) {
      return '<section><h2 class="crystal-section-title tone-' + group.tone + '">Insígnia ' + esc(group.name) +
        '</h2><div class="badges-grid">' + badgeDefinitions.filter(function (badge) { return badge.group === index; })
          .map(function (badge) { return badgeCard(badge, earnedBadge(badge, codes, result[1].level)); }).join('') +
        '</div></section>';
    }).join('');
  } catch (error) {
    if (State.token === token) container.innerHTML = errorView(cleanError(error));
  }
}

function celebrateProgress(progress) {
  var unlocked = progress.unlocked || [];
  var messages = [];
  if (progress.xpEarned) messages.push('+' + progress.xpEarned + ' XP');
  if (progress.levelUp) messages.push('Nível ' + progress.levelUp + ' alcançado!');
  if (unlocked.length) messages.push(unlocked.length === 1 ? 'Insígnia desbloqueada!' : 'Insígnias desbloqueadas!');
  if (!messages.length) return;
  toast(messages.join(' · '));
  var message = document.getElementById('toast');
  message.classList.add(progress.levelUp ? 'level-celebration' : 'xp-celebration');
  if ((!unlocked.length && !progress.xpEarned) || matchMedia('(prefers-reduced-motion: reduce)').matches ||
      document.documentElement.classList.contains('a11y-mode')) return;
  var confetti = el('div', 'badge-confetti');
  confetti.setAttribute('aria-hidden', 'true');
  for (var i = 0; i < 28; i++) {
    var piece = el('span');
    piece.style.setProperty('--x', (i * 23 % 101) + '%');
    piece.style.setProperty('--delay', (i % 7) * 45 + 'ms');
    piece.style.setProperty('--piece', ['#ff6b35', '#625add', '#b28fff', '#42ddd7'][i % 4]);
    confetti.appendChild(piece);
  }
  document.body.appendChild(confetti);
  setTimeout(function () { confetti.remove(); }, 1800);
}

function logoutAndGoLogin() {
  stopStreakTracking();
  logout();
  closeProfileDrawer(true);
  goTo('login');
  toast('Você saiu da sua conta.');
}

function updateStatusbarAvatar() {
  var user = State.user;
  var initial = user && user.name ? String(user.name).charAt(0).toUpperCase() : 'A';
  document.getElementById('header-avatar-initial').textContent = initial;
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
  drawer.setAttribute('aria-hidden', 'false');
  requestAnimationFrame(function () {
    if (drawer.getAttribute('aria-hidden') === 'false') drawer.classList.add('open');
  });
}

function closeProfileDrawer(immediately) {
  var drawer = document.getElementById('profile-drawer');
  if (!drawer) return;
  drawer.classList.remove('open');
  drawer.setAttribute('aria-hidden', 'true');
  if (PROFILE_DRAWER_TIMER) {
    clearTimeout(PROFILE_DRAWER_TIMER);
    PROFILE_DRAWER_TIMER = null;
  }
  if (immediately) {
    drawer.style.display = 'none';
    return;
  }
  PROFILE_DRAWER_TIMER = setTimeout(function () {
    if (!drawer.classList.contains('open')) drawer.style.display = 'none';
  }, 300);
}

function openSettingsFromDrawer() {
  closeProfileDrawer();
  goTo('configuracoes');
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
  document.getElementById('professor-approvals').style.display = isAuthorizedTeacher() ? '' : 'none';
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
    var subjects = await api.get('/componentes');
    if (!subjects.length) { var name = window.prompt('Nome do componente curricular:'); if (name) { await api.post('/componentes', {name:name}); subjects = await api.get('/componentes'); } }
    var arr = Array.isArray(subjects) ? subjects : (subjects && subjects.content ? subjects.content : []);
    arr.forEach(function (s) { var o = el('option', null, s.name); o.value = s.id; subjectSel.appendChild(o); });

    if (arr.length && State.currentSubject) subjectSel.value = State.currentSubject.id;
  } catch (e) { /* sem matérias */ }

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
function kaiTimestamp() {
  var now = new Date();
  return '<time class="kai-time" datetime="' + now.toISOString() + '">' +
    esc(now.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })) + '</time>';
}

function kaiAvatar() {
  return '<span class="kai-avatar">' + uiIcon('kai') + '</span>';
}

function initKai() {
  var container = document.getElementById('kai-chat');
  if (container.dataset.ready === String(State.user.id)) {
    bindKaiSend();
    return;
  }
  var name = State.user.name.split(' ')[0];
  container.innerHTML = '<div class="kai-reply">' + kaiAvatar() + '<div class="chat-bubble-kai">' +
    '<div>Oi, ' + esc(name) + '! Posso te ajudar com matérias, tarefas e prazos. O que precisa hoje?</div>' +
    kaiTimestamp() + '</div></div>';
  container.dataset.ready = String(State.user.id);
  container.removeAttribute('aria-busy');
  document.getElementById('kai-input').value = '';
  document.getElementById('kai-send').disabled = false;
  bindKaiSend();
}

async function sendKai() {
  var input = document.getElementById('kai-input');
  var container = document.getElementById('kai-chat');
  var button = document.getElementById('kai-send');
  var message = (input.value || '').trim();
  if (!message || button.disabled) return;
  var token = State.token;

  container.insertAdjacentHTML('beforeend',
    '<div class="flex justify-end"><div class="chat-bubble-user"><div>' + esc(message) + '</div>' +
    kaiTimestamp() + '</div></div>');
  input.value = '';
  button.disabled = true;
  button.setAttribute('aria-busy', 'true');

  var reply = el('div', 'kai-reply');
  reply.innerHTML = kaiAvatar() + '<div class="chat-bubble-kai"><span class="kai-typing" role="status">' +
    '<span class="sr-only">Kai está digitando</span><i></i><i></i><i></i></span></div>';
  container.appendChild(reply);
  container.scrollTop = container.scrollHeight;

  var text;
  try {
    var result = await kaiChat(message);
    text = (result && (result.reply || result.response || result.message)) || 'Não consegui processar sua pergunta agora.';
  } catch (error) {
    text = 'Não consegui responder agora: ' + cleanError(error);
  } finally {
    if (State.token === token) {
      var bubble = reply.querySelector('.chat-bubble-kai');
      bubble.innerHTML = '<div>' + esc(text) + '</div>' + kaiTimestamp();
      button.disabled = false;
      button.removeAttribute('aria-busy');
      container.scrollTop = container.scrollHeight;
    }
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
  errEl.textContent = '';
  var student = form.elements.role.value === 'ALUNO';
  if (student && form.elements.curso.disabled) {
    errEl.textContent = 'Aguarde o carregamento dos cursos ou tente novamente.';
    return;
  }
  if (btn.disabled || !form.reportValidity()) return;
  submitBtnLoading(btn);
  try {
    await loginUser({
      email: form.elements['email'].value,
      password: form.elements['password'].value,
      role: form.elements['role'] ? form.elements['role'].value : 'ALUNO',
      course: student ? form.elements.curso.value : null,
      grade: student ? Number(form.elements.serie.value) : null,
      roomCode: student ? form.elements.codigoSala.value.trim() : null,
    });
    if (!student && !isProfessor()) {
      logout();
      form.elements.role.value = 'ALUNO';
      form.elements.role.dispatchEvent(new Event('change'));
      errEl.textContent = 'Entre com o perfil Aluno e selecione sua turma.';
      return;
    }
    resolvePostAuth(student ? 'materias' : null);
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
    if (authWrap) authWrap.style.display = 'none';
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
    await registerUser(payload); logout(); goTo('login'); toast('Cadastro concluído. Entre com seu e-mail e senha.');
    return;
  }

  if (confirm !== null && password !== confirm) {
    if (errEl) errEl.textContent = 'As senhas não coincidem.';
    toast('As senhas não coincidem.', 'error');
    return;
  }
  submitBtnLoading(btn);
  try {
    await registerUser(payload); logout(); goTo('login'); toast('Cadastro concluído. Entre com seu e-mail e senha.');
  } catch (e) {
    if (errEl) errEl.textContent = cleanError(e);
    toast(cleanError(e), 'error');
  } finally {
    submitBtnReset(btn);
  }
}
