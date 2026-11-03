/* ── Materiais (Sprint 7) ── */
async function getMaterials(unitId) {
  return api.get('/unidades/' + unitId + '/materiais');
}

async function createMaterial(unitId, data) {
  return api.post('/unidades/' + unitId + '/materiais', data);
}

async function updateMaterial(id, data) {
  return api.put('/materiais/' + id, data);
}

async function deleteMaterial(id) {
  return api.del('/materiais/' + id);
}

async function completeMaterial(id) {
  return api.patch('/materiais/' + id + '/concluir');
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