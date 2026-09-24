/* ── Materiais (Sprint 7) ── */
async function getMaterials(unitId) {
  return api.get('/units/' + unitId + '/materials');
}

async function createMaterial(unitId, data) {
  return api.post('/units/' + unitId + '/materials', data);
}

async function updateMaterial(id, data) {
  return api.put('/materials/' + id, data);
}

async function deleteMaterial(id) {
  return api.del('/materials/' + id);
}

async function completeMaterial(id) {
  return api.patch('/materials/' + id + '/complete');
}

const MATERIAL_TYPES = ['PDF', 'LINK', 'VIDEO', 'DOCUMENT', 'NOTE', 'OTHER'];

function materialIcon(type) {
  switch (type) {
    case 'PDF': return '📄';
    case 'LINK': return '🔗';
    case 'VIDEO': return '🎬';
    case 'DOCUMENT': return '📃';
    case 'NOTE': return '📝';
    default: return '📎';
  }
}