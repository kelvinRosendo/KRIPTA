/* ── Completar tarefa com feedback visual (Norman — seção 2.5.1) ── */
function completeTask(checkbox) {
    checkbox.style.background = 'var(--teal)';
    checkbox.style.border = 'none';
    checkbox.innerHTML = '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round" style="display:block;margin:5px;"><path d="m5 13 4 4L19 7"/><\/svg>';
    var row = checkbox.closest('.card');
    var title = row ? row.querySelector('[style*="font-weight:600"]') : null;
    if (title) title.style.textDecoration = 'line-through';
    if (row) {
      row.style.transition = 'opacity .4s ease';
      setTimeout(function() { row.style.opacity = '0.5'; }, 400);
    }
}