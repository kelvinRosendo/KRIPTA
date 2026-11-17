/* Seleção de turma e sincronização das matérias M-Tec da Etec São Mateus. */
var courseView = null;
var courseRequest = 0;

async function renderCourseSelection() {
  var card = document.getElementById('mtec-card');
  var labels = document.getElementById('mtec-status');
  var action = document.getElementById('mtec-open');
  var role = userRole();
  var request = ++courseRequest;
  var token = State.token;
  card.hidden = role !== 'ALUNO' && role !== 'USUARIO';
  courseView = null;
  if (card.hidden) return;
  labels.textContent = 'Carregando cursos…';
  action.disabled = true;

  try {
    var catalog = await api.get('/curso-mtec');
    if (request !== courseRequest || State.token !== token) return;
    courseView = catalog;
    var selected = catalog.selecao;
    var course = selected && catalog.cursos.find(function (item) { return item.id === selected.curso; });
    labels.textContent = course
      ? course.nome + ' · ' + selected.serie + 'ª série'
      : 'Escolha o curso e a série para carregar suas matérias.';
    action.textContent = course ? 'Trocar curso ou série' : 'Selecionar curso e série';
    refreshSubjectFilter();
  } catch (error) {
    if (request !== courseRequest || State.token !== token) return;
    labels.textContent = 'Não foi possível carregar os cursos.';
    action.textContent = 'Tentar novamente';
  } finally {
    if (request === courseRequest && State.token === token) action.disabled = false;
  }
}

function openCourseModal() {
  if (!courseView) {
    renderCourseSelection();
    return;
  }
  var form = document.getElementById('course-form');
  var course = form.elements.curso;
  var selected = courseView.selecao;
  course.replaceChildren(new Option('Escolha o curso', ''));
  courseView.cursos.forEach(function (item) { course.add(new Option(item.nome, item.id)); });
  course.value = selected ? selected.curso : '';
  form.elements.serie.value = selected ? selected.serie : '';
  document.getElementById('course-error').textContent = '';
  updateCourseNote(form);
  var modal = document.getElementById('course-modal');
  modal.classList.remove('hidden');
  modal.classList.add('flex');
  course.focus();
}

function updateCourseNote(form) {
  var name = form.elements.curso.value;
  var upperGrade = Number(form.elements.serie.value) > 1;
  var note = form.querySelector('[data-course-note]');
  note.textContent = upperGrade && name === 'nutricao-e-dietetica'
    ? 'Essa série usa o plano integrado de referência do CPS. Confirme com a secretaria se é o plano da sua turma.'
    : upperGrade && name === 'marketing'
      ? 'Essa série usa a matriz prevista no plano dos ingressantes de 2026.'
      : '';
  note.hidden = !note.textContent;
}

function bindLoginCourseFields() {
  var form = document.getElementById('login-form');
  var fields = document.getElementById('login-course-fields');
  var course = form.elements.curso;
  var retry = document.getElementById('login-courses-retry');

  async function load() {
    course.disabled = true;
    retry.hidden = true;
    course.replaceChildren(new Option('Carregando cursos…', ''));
    try {
      var options = await api.get('/curso-mtec/opcoes');
      course.replaceChildren(new Option('Escolha o curso', ''));
      options.forEach(function (item) { course.add(new Option(item.nome, item.id)); });
      course.disabled = false;
    } catch (error) {
      course.replaceChildren(new Option('Cursos indisponíveis', ''));
      retry.hidden = false;
    }
  }

  function updateRole() {
    fields.hidden = form.elements.role.value !== 'ALUNO';
    fields.disabled = fields.hidden;
  }
  form.elements.role.addEventListener('change', updateRole);
  fields.addEventListener('change', function () { updateCourseNote(form); });
  retry.addEventListener('click', load);
  updateRole();
  load();
}

function closeCourseModal() {
  var modal = document.getElementById('course-modal');
  modal.classList.add('hidden');
  modal.classList.remove('flex');
  document.getElementById('mtec-open').focus();
}

async function submitCourse(form) {
  var button = form.querySelector('button[type="submit"]');
  var error = document.getElementById('course-error');
  var token = State.token;
  error.textContent = '';
  submitBtnLoading(button, 'Carregando…');
  try {
    await api.put('/curso-mtec', { curso: form.elements.curso.value, serie: Number(form.elements.serie.value) });
    if (token !== State.token) return;
    closeCourseModal();
    toast('Turma selecionada. Confira suas matérias.');
    renderSubjects();
  } catch (failure) {
    if (token === State.token) error.textContent = cleanError(failure);
  } finally {
    submitBtnReset(button);
  }
}

document.addEventListener('DOMContentLoaded', function () {
  bindLoginCourseFields();
  var form = document.getElementById('course-form');
  var modal = document.getElementById('course-modal');
  form.addEventListener('change', function () { updateCourseNote(form); });
  form.addEventListener('submit', function (event) {
    event.preventDefault();
    submitCourse(form);
  });
  modal.addEventListener('keydown', function (event) {
    if (event.key === 'Escape') closeCourseModal();
  });
  modal.addEventListener('click', function (event) {
    if (event.target === modal) closeCourseModal();
  });
});
