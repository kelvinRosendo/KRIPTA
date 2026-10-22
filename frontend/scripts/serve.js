/**
 * Servidor estático local do protótipo KRIPTA.
 *
 * Substitui o `start index.html` (exclusivo do Windows) por uma solução
 * multiplataforma e sem dependências externas, usando apenas o módulo `http`
 * do Node.js.
 *
 * Uso:  npm run serve  [-- porta]
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const PORT = Number(process.argv[2]) || 5173;

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

const server = http.createServer((req, res) => {
  const pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
  const relative = pathname === '/' ? 'index.html' : pathname.replace(/^\/+/, '');
  const filePath = path.resolve(ROOT, relative);

  // Impede que o servidor exponha arquivos fora da pasta do frontend.
  if (!filePath.startsWith(ROOT + path.sep)) {
    res.writeHead(403, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('403 — acesso negado');
    return;
  }

  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('404 — não encontrado: ' + pathname);
      return;
    }

    const type = MIME[path.extname(filePath).toLowerCase()] || 'application/octet-stream';
    res.writeHead(200, { 'Content-Type': type, 'Cache-Control': 'no-cache' });
    fs.createReadStream(filePath).pipe(res);
  });
});

server.listen(PORT, () => {
  console.log('');
  console.log('  KRIPTA — protótipo rodando em:');
  console.log('  ->  http://localhost:' + PORT);
  console.log('');
  console.log('  API (Spring Boot) esperada em: http://localhost:8080/api');
  console.log('  Para recompilar o CSS durante o desenvolvimento,');
  console.log('  abra outro terminal e rode:  npm run dev');
  console.log('');
  console.log('  Ctrl+C para encerrar.');
  console.log('');
});
