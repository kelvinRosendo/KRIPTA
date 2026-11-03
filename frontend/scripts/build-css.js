/**
 * Compila o CSS do Tailwind (`src/input.css` -> `styles/output.css`).
 *
 * Usado pelo hook `postinstall` do package.json, para que um `npm install`
 * já deixe o CSS pronto e a página estilizada.
 *
 * Diferente do `npm run build` (que falha ruidosamente), este script tolera
 * a ausência do Tailwind — por exemplo, em installs com `--omit=dev` — e
 * apenas avisa, já que o `styles/output.css` versionado continua válido.
 */

const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const isWindows = process.platform === 'win32';
const bin = path.join(ROOT, 'node_modules', '.bin', isWindows ? 'tailwindcss.cmd' : 'tailwindcss');

if (!fs.existsSync(bin)) {
  console.log('');
  console.log('  [kripta] Tailwind CSS não encontrado — compilação pulada.');
  console.log('  [kripta] Rode "npm install" (sem --omit=dev) para recompilar o CSS.');
  console.log('  [kripta] O styles/output.css versionado no Git continua válido.');
  console.log('');
  process.exit(0);
}

const result = spawnSync(
  bin,
  ['-i', './src/input.css', '-o', './styles/output.css'],
  { cwd: ROOT, stdio: 'inherit', shell: isWindows }
);

if (result.error) {
  console.error('[kripta] Falha ao executar o Tailwind:', result.error.message);
  process.exit(1);
}

process.exit(result.status === null ? 1 : result.status);
