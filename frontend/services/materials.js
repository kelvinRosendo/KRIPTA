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
  var icons = { PDF: 'document', LINK: 'link', VIDEO: 'video', DOCUMENT: 'document', NOTE: 'note' };
  return uiIcon(icons[type] || 'attachment');
}