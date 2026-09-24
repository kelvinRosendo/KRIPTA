/* ── Unidades (Sprint 6) ── */
async function getUnits(subjectId) {
  return api.get('/subjects/' + subjectId + '/units');
}

async function createUnit(subjectId, data) {
  return api.post('/subjects/' + subjectId + '/units', data);
}

async function updateUnit(id, data) {
  return api.put('/units/' + id, data);
}

async function deleteUnit(id) {
  return api.del('/units/' + id);
}