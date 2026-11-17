var salaRequest = 0;

async function renderSalas() {
  var list = document.getElementById('salas-list');
  var form = document.getElementById('sala-form');
  var token = State.token;
  var request = ++salaRequest;
  var professor = isProfessor();
  document.getElementById('salas-heading').textContent = professor ? 'Minhas salas' : 'Minha sala';
  form.hidden = true;
  showLoading(list);
  try {
    var salas = await api.get('/salas');
    if (State.token !== token || request !== salaRequest) return;
    form.hidden = !professor && salas.length > 0;
    form.querySelector('label span').textContent = professor ? 'Nome da sala' : 'Código da sala';
    var input = form.elements.sala;
    input.maxLength = professor ? 80 : 12;
    input.pattern = professor ? '' : '[A-Fa-f0-9]{12}';
    if (professor) input.removeAttribute('pattern');
    form.querySelector('button').textContent = professor ? 'Criar sala' : 'Entrar na sala';
    list.innerHTML = salas.length ? salas.map(salaCard).join('') :
      emptyState(professor ? 'Nenhuma sala criada' : 'Você ainda não tem uma sala',
        professor ? 'Crie uma sala e compartilhe o código com a turma.' : 'Peça o código da sala ao professor.');
  } catch (error) {
    if (State.token === token && request === salaRequest) list.innerHTML = errorView(cleanError(error));
  }
}

function salaCard(sala) {
  var activities = sala.atividades.map(function (item) {
    return '<li class="room-activity"><strong>' + esc(item.titulo) + '</strong><time datetime="' +
      esc(item.prazo) + '">' + esc(formatDateTime(item.prazo)) + '</time>' +
      (item.descricao ? '<p>' + esc(item.descricao) + '</p>' : '') + '</li>';
  }).join('');
  return '<article class="card room-card"><div class="room-card-header"><div><h2>' + esc(sala.nome) + '</h2><p>' +
    sala.alunos + ' de ' + sala.limite + ' alunos</p></div>' +
    (isProfessor() ? '<div class="room-code"><small>Código da sala</small><strong>' + esc(sala.codigo) + '</strong></div>' : '') +
    '</div><h3>Atividades da sala</h3>' +
    (activities ? '<ul>' + activities + '</ul>' : emptyState('Sem atividades publicadas')) +
    (isProfessor() ? '<details class="room-compose"><summary>Nova atividade</summary>' +
      '<form class="room-form" data-sala-id="' + sala.id + '">' +
      '<label>Título<input name="titulo" maxlength="200" required></label>' +
      '<label>Descrição<textarea name="descricao" maxlength="4000" rows="3"></textarea></label>' +
      '<label>Prazo<input type="datetime-local" name="prazo" required></label>' +
      '<button class="btn-primary" type="submit">Publicar atividade</button></form></details>' :
      '<button type="button" class="btn-ghost" onclick="goTo(\'tasks\')">Ver minhas tarefas</button>') +
    '</article>';
}

document.addEventListener('DOMContentLoaded', function () {
  var screen = document.getElementById('screen-salas');
  screen.addEventListener('submit', async function (event) {
    var form = event.target;
    event.preventDefault();
    var button = form.querySelector('button[type="submit"]');
    if (button.disabled || !form.reportValidity()) return;
    var token = State.token;
    submitBtnLoading(button);
    try {
      if (form.dataset.salaId) {
        await api.post('/salas/' + form.dataset.salaId + '/atividades', {
          titulo: form.elements.titulo.value.trim(),
          descricao: form.elements.descricao.value.trim() || null,
          prazo: new Date(form.elements.prazo.value).toISOString(),
        });
        if (State.token === token) toast('Atividade publicada para a sala.');
      } else {
        var valor = form.elements.sala.value.trim();
        if (!valor) throw new Error('Preencha o campo da sala.');
        if (isProfessor()) await api.post('/salas', { nome: valor });
        else await api.post('/salas/entrar', { codigo: valor });
        if (State.token === token) toast(isProfessor() ? 'Sala criada.' : 'Você entrou na sala.');
      }
      if (State.token === token) {
        form.reset();
        renderSalas();
      }
    } catch (error) {
      if (State.token === token) toast(cleanError(error), 'error');
    } finally {
      submitBtnReset(button);
    }
  });
});
