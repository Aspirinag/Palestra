// Prepara la cartella www/ che Capacitor mette dentro l'app: la pagina, le librerie e le icone
import { cpSync, existsSync, mkdirSync, readdirSync, rmSync } from 'node:fs';

rmSync('www', { recursive: true, force: true });
mkdirSync('www');
cpSync('index.html', 'www/index.html');
if (existsSync('vendor')) cpSync('vendor', 'www/vendor', { recursive: true });
for (const f of readdirSync('.')) if (f.endsWith('.png')) cpSync(f, `www/${f}`);
console.log('www/ pronta');
