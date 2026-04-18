/**
 * 009_load_staging.js
 * Le os CSVs do TSE e carrega nas tabelas staging.* do Supabase.
 * Filtra: UF = SC, CARGO in (DEPUTADO ESTADUAL, DEPUTADO FEDERAL)
 * votacao_secao excluida do MVP para economizar espaco no banco.
 *
 * Uso: node --env-file=.env scripts/009_load_staging.js
 */

'use strict';

const fs       = require('fs');
const path     = require('path');
const readline = require('readline');
const { Pool } = require('pg');

const EXTRACTED_DIR = path.join(__dirname, '..', 'inputs', 'tse_extracted');
const BATCH_SIZE    = 200;

const pool = new Pool({
  host:     process.env.PG_HOST,
  port:     Number(process.env.PG_PORT),
  database: process.env.PG_DATABASE,
  user:     process.env.PG_USER,
  password: process.env.PG_PASSWORD,
  ssl:      { rejectUnauthorized: false },
  max:      3,
});

function cargoMatch(cargo) {
  if (!cargo) return false;
  const u = cargo.toUpperCase();
  return u === 'DEPUTADO ESTADUAL' || u === 'DEPUTADO FEDERAL';
}

function parseRow(raw) {
  const cols = [];
  let field = '';
  let inQuotes = false;
  for (let i = 0; i < raw.length; i++) {
    const ch = raw[i];
    if (inQuotes) {
      if (ch === '"' && raw[i + 1] === '"') { field += '"'; i++; }
      else if (ch === '"') { inQuotes = false; }
      else { field += ch; }
    } else {
      if (ch === '"') { inQuotes = true; }
      else if (ch === ';') { cols.push(field.trim()); field = ''; }
      else { field += ch; }
    }
  }
  cols.push(field.trim());
  return cols;
}

function col(headers, cols, name) {
  const idx = headers.indexOf(name);
  if (idx === -1) return null;
  const v = cols[idx];
  return (v === '' || v === '#NULO#' || v === '#NE#') ? null : v;
}

// Cria um gerador assincrono de linhas com backpressure natural
async function* csvLines(filePath) {
  const stream = fs.createReadStream(filePath, { encoding: 'latin1' });
  const rl = readline.createInterface({ input: stream, crlfDelay: Infinity });
  try {
    for await (const line of rl) {
      yield line;
    }
  } finally {
    rl.close();
    stream.destroy();
  }
}

async function batchInsert(client, table, rows) {
  if (rows.length === 0) return;
  const keys   = Object.keys(rows[0]);
  const colStr = keys.map(k => `"${k}"`).join(', ');
  const values = [];
  const params = [];
  let   p      = 1;
  for (const row of rows) {
    const placeholders = keys.map(() => `$${p++}`).join(', ');
    values.push(`(${placeholders})`);
    for (const k of keys) params.push(row[k]);
  }
  await client.query(
    `INSERT INTO ${table} (${colStr}) VALUES ${values.join(', ')} ON CONFLICT DO NOTHING`,
    params
  );
}

// ---------------------------------------------------------------------------
// Loaders
// ---------------------------------------------------------------------------

async function loadCandidatos() {
  const file = path.join(EXTRACTED_DIR, 'consulta_cand_2022', 'consulta_cand_2022_SC.csv');
  if (!fs.existsSync(file)) { console.log('[SKIP] consulta_cand_2022_SC.csv'); return; }
  console.log('\n[LOAD] stg_candidatos <- ' + path.basename(file));

  const client = await pool.connect();
  let batch = [], inserted = 0, skipped = 0, headers = null;

  try {
    for await (const raw of csvLines(file)) {
      const cols = parseRow(raw);
      if (!headers) { headers = cols; continue; }
      if (cols.length < 2) continue;

      const uf    = col(headers, cols, 'SG_UF');
      const cargo = col(headers, cols, 'DS_CARGO');
      if (uf !== 'SC' || !cargoMatch(cargo)) { skipped++; continue; }

      batch.push({
        ano:                  col(headers, cols, 'ANO_ELEICAO'),
        turno:                col(headers, cols, 'NR_TURNO'),
        uf, cargo,
        numero:               col(headers, cols, 'NR_CANDIDATO'),
        nome_urna:            col(headers, cols, 'NM_URNA_CANDIDATO'),
        nome_completo:        col(headers, cols, 'NM_CANDIDATO'),
        sigla_partido:        col(headers, cols, 'SG_PARTIDO'),
        nome_partido:         col(headers, cols, 'NM_PARTIDO'),
        federacao_coligacao:  col(headers, cols, 'DS_COMPOSICAO_FEDERACAO'),
        situacao_candidatura: col(headers, cols, 'DS_SITUACAO_CANDIDATURA'),
        situacao_totalizacao: col(headers, cols, 'DS_SIT_TOT_TURNO'),
        identificador_tse:    col(headers, cols, 'SQ_CANDIDATO'),
        source_file:          path.basename(file),
      });

      if (batch.length >= BATCH_SIZE) {
        await batchInsert(client, 'staging.stg_candidatos', batch);
        inserted += batch.length;
        batch = [];
        process.stdout.write('\r  inserido: ' + inserted);
      }
    }
    if (batch.length > 0) {
      await batchInsert(client, 'staging.stg_candidatos', batch);
      inserted += batch.length;
    }
  } finally { client.release(); }

  console.log('\r  inserido: ' + inserted + ' | ignorado: ' + skipped);
}

async function loadVotacaoMunicipio() {
  const file = path.join(EXTRACTED_DIR, 'votacao_candidato_munzona_2022', 'votacao_candidato_munzona_2022_SC.csv');
  if (!fs.existsSync(file)) { console.log('[SKIP] votacao_candidato_munzona_2022_SC.csv'); return; }
  console.log('\n[LOAD] stg_votacao_municipio <- ' + path.basename(file));

  const client = await pool.connect();
  let batch = [], inserted = 0, skipped = 0, headers = null;

  try {
    for await (const raw of csvLines(file)) {
      const cols = parseRow(raw);
      if (!headers) { headers = cols; continue; }
      if (cols.length < 2) continue;

      const uf    = col(headers, cols, 'SG_UF');
      const cargo = col(headers, cols, 'DS_CARGO');
      if (uf !== 'SC' || !cargoMatch(cargo)) { skipped++; continue; }

      batch.push({
        ano:                  col(headers, cols, 'ANO_ELEICAO'),
        turno:                col(headers, cols, 'NR_TURNO'),
        uf, cargo,
        codigo_municipio_tse: col(headers, cols, 'CD_MUNICIPIO'),
        municipio:            col(headers, cols, 'NM_MUNICIPIO'),
        numero_candidato:     col(headers, cols, 'NR_CANDIDATO'),
        nome_candidato:       col(headers, cols, 'NM_URNA_CANDIDATO'),
        sigla_partido:        col(headers, cols, 'SG_PARTIDO'),
        identificador_tse:    col(headers, cols, 'SQ_CANDIDATO'),
        votos:                col(headers, cols, 'QT_VOTOS_NOMINAIS'),
        source_file:          path.basename(file),
      });

      if (batch.length >= BATCH_SIZE) {
        await batchInsert(client, 'staging.stg_votacao_municipio', batch);
        inserted += batch.length;
        batch = [];
        process.stdout.write('\r  inserido: ' + inserted);
      }
    }
    if (batch.length > 0) {
      await batchInsert(client, 'staging.stg_votacao_municipio', batch);
      inserted += batch.length;
    }
  } finally { client.release(); }

  console.log('\r  inserido: ' + inserted + ' | ignorado: ' + skipped);
}

async function loadPrestacaoContas(tipo) {
  const prefix = tipo === 'DESPESA' ? 'despesas_contratadas' : 'receitas';
  const srcDir = path.join(EXTRACTED_DIR, 'prestacao_de_contas_eleitorais_candidatos_2022');
  const file   = path.join(srcDir, prefix + '_candidatos_2022_SC.csv');
  if (!fs.existsSync(file)) { console.log('[SKIP] ' + path.basename(file)); return; }
  console.log('\n[LOAD] stg_prestacao_contas (' + tipo + ') <- ' + path.basename(file));

  const client = await pool.connect();
  let batch = [], inserted = 0, skipped = 0, headers = null;

  try {
    for await (const raw of csvLines(file)) {
      const cols = parseRow(raw);
      if (!headers) { headers = cols; continue; }
      if (cols.length < 2) continue;

      const uf    = col(headers, cols, 'SG_UF');
      const cargo = col(headers, cols, 'DS_CARGO');
      if (uf !== 'SC' || !cargoMatch(cargo)) { skipped++; continue; }

      const row = tipo === 'DESPESA' ? {
        ano:                            col(headers, cols, 'AA_ELEICAO'),
        uf, cargo,
        numero_candidato:               col(headers, cols, 'NR_CANDIDATO'),
        nome_candidato:                 col(headers, cols, 'NM_CANDIDATO'),
        sigla_partido:                  col(headers, cols, 'SG_PARTIDO'),
        identificador_tse:              col(headers, cols, 'SQ_CANDIDATO'),
        tipo_lancamento:                'DESPESA',
        categoria:                      col(headers, cols, 'DS_ORIGEM_DESPESA'),
        descricao:                      col(headers, cols, 'DS_DESPESA'),
        fornecedor_ou_doador:           col(headers, cols, 'NM_FORNECEDOR'),
        documento_fornecedor_ou_doador: col(headers, cols, 'NR_CPF_CNPJ_FORNECEDOR'),
        data_lancamento:                col(headers, cols, 'DT_DESPESA'),
        valor:                          col(headers, cols, 'VR_DESPESA_CONTRATADA'),
        fonte_recurso:                  null,
        source_file:                    path.basename(file),
      } : {
        ano:                            col(headers, cols, 'AA_ELEICAO'),
        uf, cargo,
        numero_candidato:               col(headers, cols, 'NR_CANDIDATO'),
        nome_candidato:                 col(headers, cols, 'NM_CANDIDATO'),
        sigla_partido:                  col(headers, cols, 'SG_PARTIDO'),
        identificador_tse:              col(headers, cols, 'SQ_CANDIDATO'),
        tipo_lancamento:                'RECEITA',
        categoria:                      col(headers, cols, 'DS_ORIGEM_RECEITA'),
        descricao:                      col(headers, cols, 'DS_RECEITA'),
        fornecedor_ou_doador:           col(headers, cols, 'NM_DOADOR'),
        documento_fornecedor_ou_doador: col(headers, cols, 'NR_CPF_CNPJ_DOADOR'),
        data_lancamento:                col(headers, cols, 'DT_RECEITA'),
        valor:                          col(headers, cols, 'VR_RECEITA'),
        fonte_recurso:                  col(headers, cols, 'DS_FONTE_RECEITA'),
        source_file:                    path.basename(file),
      };

      batch.push(row);

      if (batch.length >= BATCH_SIZE) {
        await batchInsert(client, 'staging.stg_prestacao_contas', batch);
        inserted += batch.length;
        batch = [];
        process.stdout.write('\r  inserido: ' + inserted);
      }
    }
    if (batch.length > 0) {
      await batchInsert(client, 'staging.stg_prestacao_contas', batch);
      inserted += batch.length;
    }
  } finally { client.release(); }

  console.log('\r  inserido: ' + inserted + ' | ignorado: ' + skipped);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
async function main() {
  console.log('=== Carga staging TSE 2022 SC ===');
  console.log('Filtro: UF=SC, CARGO in (DEPUTADO ESTADUAL, DEPUTADO FEDERAL)');
  console.log('Excluido: votacao_secao (economizar espaco no banco)\n');

  const t0 = Date.now();
  try {
    await loadCandidatos();
    await loadVotacaoMunicipio();
    await loadPrestacaoContas('DESPESA');
    await loadPrestacaoContas('RECEITA');
  } finally {
    await pool.end();
  }

  const elapsed = ((Date.now() - t0) / 1000).toFixed(1);
  console.log('\n=== Concluido em ' + elapsed + 's ===');
}

main().catch(e => {
  console.error('ERRO FATAL:', e.message);
  process.exit(1);
});
