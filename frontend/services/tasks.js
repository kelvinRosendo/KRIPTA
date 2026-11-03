/* ── Tarefas (Sprint 8 e Sprint 9) ── */
async function getTasks(params) {
  var query = '';
  if (params) {
    var parts = [];
    Object.keys(params).forEach(function (k) {
      if (params[k] !== undefined && params[k] !== null && params[k] !== '')
        parts.push(encodeURIComponent(k) + '=' + encodeURIComponent(params[k]));
    });
    if (parts.length) query = '?' + parts.join('&');
  }
  return api.get('/tasks' + query);
}

async function getTask(id) {
  return api.get('/tasks/' + id);
}

async function createTask(data) {
  return api.post('/tasks', data);
}

async function updateTask(id, data) {
  return api.put('/tasks/' + id, data);
}

async function deleteTask(id) {
  return api.del('/tasks/' + id);
}

async function completeTask(id) {
  return api.patch('/tasks/' + id + '/complete');
}

function taskRow(task, opts) {
  opts = opts || {};
  var accent = task.priority === 'HIGH' ? 'border-l-orange' : task.priority === 'MEDIUM' ? 'border-l-teal' : 'border-l-border';
  var done = task.completed || task.status === 'COMPLETED';
  var checkbox = done
    ? '<div class="w-[22px] h-[22px] rounded-[7px] bg-teal shrink-0 flex items-center justify-center"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="m5 13 4 4L19 7"/></svg></div>'
    : '<button type="button" data-action="complete" data-id="' + task.id + '" aria-label="Concluir tarefa" class="w-[22px] h-[22px] rounded-[7px] border-2 border-border shrink-0 cursor-pointer bg-transparent"></button>';
  var btnDel = opts.noDelete
    ? ''
    : '<button type="button" data-action="delete" data-id="' + task.id + '" data-name="' + esc(task.title) + '" class="icon-btn !w-8 !h-8" aria-label="Excluir">' +
      '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="#6B6F8E" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2m2 0-1 14a2 2 0 0 1-2 2H9a2 2 0 0 1-2-2L6 6"/></svg>' +
      '</button>';
  var meta =
    (task.subject ? esc(task.subject.name || '') : '') +
    (task.dueDate ? (task.subject ? ' · ' : '') + esc(formatDateTime(task.dueDate)) : '') +
    (task.priority && task.priority !== 'MEDIUM' ? ' · ' + esc(task.priority) : '');
  var row = (
    '<div class="card py-[13px] px-4 flex items-center gap-[11px] border-l-[3px] border-t-0 border-r-0 border-b-0 border border-border' +
    (opts.accentColor ? ' ' + opts.accentColor : ' ' + accent) +
    (opts.noDelete ? ' cursor-default' : ' cursor-pointer') +
    (done ? ' opacity-55' : '') + '" data-task="' + task.id + '"' +
    (typeof opts.onEdit === 'function' ? ' data-edit-task="' + task.id + '"' : '') +
    '>' +
    (opts.noCheck ? '' : checkbox) +
    '<div class="flex-1 min-w-0">' +
    '<div class="text-sm font-semibold' + (done ? ' line-through' : '') + '">' + esc(task.title) + '</div>' +
    '<div class="text-[11.5px] text-text-mid mt-0.5 truncate">' + esc(meta) + '</div>' +
    '</div>' +
    (opts.sideLabel ? opts.sideLabel(task) : '') +
    btnDel +
    '</div>'
  );
  return row;
}

function dueDateInputValue(dateStr) {
  if (!dateStr) return '';
  var s = String(dateStr);
  return s.slice(0, 16);
}

function taskFormPayload(form) {
  var fd = new FormData(form);
  var data = {
    title: fd.get('title'),
    description: fd.get('description') || null,
    dueDate: fd.get('dueDate') ? new Date(fd.get('dueDate')).toISOString() : null,
    priority: fd.get('priority') || 'MEDIUM',
  };
  var subjectId = fd.get('subjectId');
  if (subjectId) data.subjectId = parseInt(subjectId, 10);
  return data;
}