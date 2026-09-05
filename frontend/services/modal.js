/* ── Modal de exclusão (prevenção de erro — seção 2.5.3) ── */
function openDeleteModal(taskName) {
  var modal = document.getElementById('delete-modal');
  document.getElementById('delete-task-name').textContent = taskName;
  modal.classList.remove('hidden');
  modal.classList.add('flex');
}
function closeDeleteModal() {
  var modal = document.getElementById('delete-modal');
  modal.classList.add('hidden');
  modal.classList.remove('flex');
}
