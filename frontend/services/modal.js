/* ── Modal de exclusão (prevenção de erro) ── */
function openDeleteModal(name, kind, id) {
  window.__deleteState = { kind: kind || 'task', id: id };
  var modal = document.getElementById('delete-modal');
  var label = document.getElementById('delete-kind-label');
  var nameSpan = document.getElementById('delete-task-name');
  if (nameSpan) nameSpan.textContent = name || 'Este item';
  if (label) {
    var kindNames = { task: 'tarefa', subject: 'matéria', unit: 'unidade', material: 'material' };
    label.textContent = 'A ' + (kindNames[kind] || 'item') + ' "' + (name || '') + '" será removida e não poderá ser recuperada.';
  }
  modal.classList.remove('hidden');
  modal.classList.add('flex');
}

function closeDeleteModal() {
  var modal = document.getElementById('delete-modal');
  modal.classList.add('hidden');
  modal.classList.remove('flex');
}

async function confirmDelete() {
  var state = window.__deleteState;
  if (!state) { closeDeleteModal(); return; }
  var btn = document.querySelector('#delete-modal .confirm-delete');
  submitBtnLoading(btn, 'Excluindo…');
  try {
    if (state.kind === 'task') await deleteTask(state.id);
    else if (state.kind === 'subject') await deleteSubject(state.id);
    else if (state.kind === 'unit') await deleteUnit(state.id);
    else if (state.kind === 'material') await deleteMaterial(state.id);
    toast('Removido com sucesso');
    window.__deleteState = null;
    closeDeleteModal();
    if (state.kind === 'subject') renderSubjects();
    else if (state.kind === 'unit' || state.kind === 'material') switchTab(DETAIL_TAB);
    else renderTasks();
  } catch (e) {
    toast(cleanError(e), 'error');
  } finally {
    submitBtnReset(btn);
    window.__deleteState = null;
  }
}

/* ── Modal genérico de formulário ── */
function closeModal(id) {
  var modal = document.getElementById(id);
  if (modal) {
    modal.classList.add('hidden');
    modal.classList.remove('flex');
    window.__editingTask = null;
    window.__editingSubject = null;
    window.__editingUnit = null;
  }
}

function bindModalBackdrop() {
  document.querySelectorAll('.modal-backdrop').forEach(function (b) {
    b.addEventListener('click', function (e) {
      if (e.target === b) closeModal(b.id);
    });
  });
}

document.addEventListener('DOMContentLoaded', bindModalBackdrop);