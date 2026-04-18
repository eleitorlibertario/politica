/**
 * 008_inspect_headers.js
 * Le a primeira linha (header) de cada CSV extraido e mostra as colunas.
 * Uso: node scripts/008_inspect_headers.js
 */

const fs   = require('fs');
const path = require('path');
const readline = require('readline');

const extractedDir = path.join(__dirname, '..', 'inputs', 'tse_extracted');

function findCsvFiles(dir) {
  const results = [];
  if (!fs.existsSync(dir)) return results;
  for (const entry of fs.readdirSync(dir)) {
    const full = path.join(dir, entry);
    const stat = fs.statSync(full);
    if (stat.isDirectory()) {
      results.push(...findCsvFiles(full));
    } else if (/\.(csv|txt)$/i.test(entry)) {
      results.push(full);
    }
  }
  return results;
}

async function readFirstLine(filePath) {
  return new Promise((resolve, reject) => {
    const stream = fs.createReadStream(filePath, { encoding: 'latin1' });
    const rl = readline.createInterface({ input: stream, crlfDelay: Infinity });
    rl.once('line', (line) => {
      rl.close();
      stream.destroy();
      resolve(line);
    });
    rl.once('error', reject);
    stream.once('error', reject);
  });
}

async function main() {
  const files = findCsvFiles(extractedDir);

  if (files.length === 0) {
    console.log('Nenhum CSV/TXT encontrado em', extractedDir);
    console.log('Execute primeiro: powershell -File scripts/007_extract_zips.ps1');
    process.exit(1);
  }

  for (const file of files) {
    const rel = path.relative(extractedDir, file);
    const sizeMb = (fs.statSync(file).size / 1024 / 1024).toFixed(1);
    console.log(`\n=== ${rel} (${sizeMb} MB) ===`);
    try {
      const header = await readFirstLine(file);
      const cols = header.split(';');
      cols.forEach((col, i) => {
        console.log(`  [${String(i).padStart(2, '0')}] ${col.trim()}`);
      });
    } catch (e) {
      console.log(`  ERRO ao ler: ${e.message}`);
    }
  }
}

main();
