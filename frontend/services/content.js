/* ── Conteúdo acadêmico e aprovação (RF03, RF04, RF05 / UC03, UC05, UC06) ── */

/* Professor cadastra conteúdo associado ao componente curricular (RF03/UC05). */
async function createContent(data) {
  return api.post('/contents', data);
}

/* Meus conteúdos (professor). */
async function getMyContents() {
  return api.get('/contents/mine');
}

/* Conteúdos aguardando aprovação (professor autorizado, RF04/UC06). */
async function getPendingContents() {
  return api.get('/contents/pending');
}

/* Conteúdos aprovados de um componente curricular (consulta do aluno, RF05). */
async function getApprovedContents(subjectId) {
  return api.get('/contents?status=APROVADO' + (subjectId ? '&subjectId=' + subjectId : ''));
}

async function approveContent(id) {
  return api.patch('/contents/' + id + '/approve');
}

async function rejectContent(id, reason) {
  return api.patch('/contents/' + id + '/reject', { reason: reason || null });
}

const CONTENT_STATUS = {
  PENDENTE: { label: 'Aguardando aprovação', cls: 'bg-orange-light text-orange' },
  APROVADO: { label: 'Aprovado', cls: 'bg-teal-light text-teal' },
  REJEITADO: { label: 'Rejeitado', cls: 'bg-crimson-light text-crimson' },
};

function contentStatusPill(status) {
  var meta = CONTENT_STATUS[status] || CONTENT_STATUS.PENDENTE;
  return '<span class="pill ' + meta.cls + '">' + meta.label + '</span>';
}

/* Card de conteúdo aprovado visto pelo aluno (aba Conteúdos da matéria). */
function contentCardHTML(c) {
  return (
    '<div class="card p-3.5">' +
    '<div class="flex items-start justify-between gap-2">' +
    '<div class="flex-1 min-w-0">' +
    '<div class="text-[13.5px] font-bold">' + materialIcon(c.type) + ' ' + esc(c.title) + '</div>' +
    (c.description ? '<div class="text-[12px] text-text-mid mt-1 leading-snug">' + esc(c.description) + '</div>' : '') +
    '<div class="text-[11px] text-text-low mt-1">Por ' + esc(c.authorName || 'professor') + '</div>' +
    '</div>' +
    (c.url ? '<a href="' + esc(c.url) + '" target="_blank" rel="noopener" class="text-xs text-indigo font-bold shrink-0">abrir</a>' : '') +
    '</div></div>'
  );
}

/* Card usado no painel do professor e na fila de aprovação. */
function professorContentCardHTML(c, reviewable) {
  var actions = '';
  if (reviewable) {
    actions =
      '<div class="flex gap-2 mt-3">' +
      '<button type="button" class="flex-1 py-2 bg-teal border-none rounded-md text-white font-bold text-[12.5px] cursor-pointer" data-action="approve-content" data-id="' + c.id + '">Aprovar</button>' +
      '<button type="button" class="flex-1 py-2 bg-crimson border-none rounded-md text-white font-bold text-[12.5px] cursor-pointer" data-action="reject-content" data-id="' + c.id + '">Rejeitar</button>' +
      '</div>';
  }
  return (
    '<div class="card p-3.5">' +
    '<div class="flex items-start justify-between gap-2">' +
    '<div class="flex-1 min-w-0">' +
    '<div class="text-[13.5px] font-bold">' + materialIcon(c.type) + ' ' + esc(c.title) + '</div>' +
    '<div class="text-[11.5px] text-text-mid mt-1">' + esc(c.subjectName || ('Matéria #' + (c.subjectId || '—'))) + ' · por ' + esc(c.authorName || '—') + '</div>' +
    (c.description ? '<div class="text-[12px] text-text-mid mt-1 leading-snug">' + esc(c.description) + '</div>' : '') +
    (c.status === 'REJEITADO' && c.rejectReason ? '<div class="text-[11.5px] text-crimson mt-1">Motivo: ' + esc(c.rejectReason) + '</div>' : '') +
    '</div>' +
    contentStatusPill(c.status) +
    '</div>' +
    actions +
    '</div>'
  );
}
