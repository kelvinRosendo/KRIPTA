/* ── Matérias (Sprint 5) ── */
async function getSubjects() {
  return api.get('/subjects');
}

async function getSubject(id) {
  return api.get('/subjects/' + id);
}

async function createSubject(data) {
  return api.post('/subjects', data);
}

async function updateSubject(id, data) {
  return api.put('/subjects/' + id, data);
}

async function deleteSubject(id) {
  return api.del('/subjects/' + id);
}

function subjectMeta(subject) {
  var parts = [];
  if (subject && subject.pendingCount !== undefined) {
    parts.push((subject.pendingCount === 1 ? '1 pendência' : subject.pendingCount + ' pendências'));
  }
  if (subject && subject.teacher) parts.push(subject.teacher);
  return parts.join(' · ');
}