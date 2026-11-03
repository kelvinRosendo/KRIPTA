/* ── Matérias (Sprint 5) ── */
async function getSubjects() {
  return (await api.get('/disciplinas')).map(mapSubject);
}

async function getSubject(id) {
  return mapSubject(await api.get('/disciplinas/' + encodeURIComponent(id)));
}

async function createSubject(data) {
  return mapSubject(await api.post('/disciplinas', { nome: data.name, cor: data.color || null, componenteId: data.componentId || null }));
}

async function updateSubject(id, data) {
  return mapSubject(await api.put('/disciplinas/' + encodeURIComponent(id), { nome: data.name, cor: data.color || null, componenteId: data.componentId || null }));
}

async function deleteSubject(id) {
  return api.del('/disciplinas/' + encodeURIComponent(id));
}

function mapSubject(data) {
  return { id: data.id, name: data.nome, color: data.cor, componentId: data.componenteId };
}

function subjectMeta(subject) {
  var parts = [];
  if (subject && subject.pendingCount !== undefined) {
    parts.push((subject.pendingCount === 1 ? '1 pendência' : subject.pendingCount + ' pendências'));
  }
  if (subject && subject.teacher) parts.push(subject.teacher);
  return parts.join(' · ');
}
