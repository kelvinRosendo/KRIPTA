/* ── Kai / IA (Sprint 16) ──
   Frontend nunca chama a API de IA direto. Tudo passa por /api/ai/chat.
*/
async function kaiChat(message) {
  return api.post('/ai/chat', { message: message });
}