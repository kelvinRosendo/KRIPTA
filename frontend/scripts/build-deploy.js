const { cpSync, mkdirSync, readFileSync, writeFileSync } = require('node:fs');
const path = require('node:path');

let api;
try {
  api = new URL(process.env.KRIPTA_API_URL);
} catch {
  throw new Error('Configure KRIPTA_API_URL com a URL HTTPS da API do KRIPTA no Render.');
}
if (api.protocol !== 'https:' || api.username || api.password || api.search || api.hash ||
    !['/api', '/api/'].includes(api.pathname)) {
  throw new Error('KRIPTA_API_URL deve usar HTTPS e terminar em /api, sem credenciais ou parâmetros.');
}

const root = path.resolve(__dirname, '..');
const out = path.join(root, 'dist');
mkdirSync(out, { recursive: true });
for (const item of ['index.html', 'assets', 'services', 'styles']) {
  cpSync(path.join(root, item), path.join(out, item), { recursive: true });
}

const configFile = path.join(out, 'services', 'config.js');
const config = readFileSync(configFile, 'utf8');
writeFileSync(configFile,
  'globalThis.KRIPTA_API_URL = ' + JSON.stringify(api.origin + '/api') + ';\n' + config);
