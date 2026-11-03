/* ── Unidades (Sprint 6) ── */
async function getUnits(subjectId) {
  return api.get('/disciplinas/' + subjectId + '/unidades');
}

async function createUnit(subjectId, data) {
  return api.post('/disciplinas/' + subjectId + '/unidades', data);
}

async function updateUnit(id, data) {
  return api.put('/unidades/' + id, data);
}

async function deleteUnit(id) {
  return api.del('/unidades/' + id);
}