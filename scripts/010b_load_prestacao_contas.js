'use strict';
const { Client } = require('pg');
const client = new Client({
  host: process.env.PG_HOST, port: Number(process.env.PG_PORT),
  database: process.env.PG_DATABASE, user: process.env.PG_USER,
  password: process.env.PG_PASSWORD, ssl: { rejectUnauthorized: false },
  statement_timeout: 0, query_timeout: 0,
});

async function run(label, sql) {
  process.stdout.write('[RUN] ' + label + '... ');
  const t = Date.now();
  const res = await client.query(sql);
  const rows = res.rowCount ?? '';
  console.log('OK (' + ((Date.now()-t)/1000).toFixed(1) + 's)' + (rows ? ' ' + rows : ''));
}

async function main() {
  await client.connect();
  await client.query('SET statement_timeout = 0');
  await client.query('SET lock_timeout = 0');
  console.log('Conectado.');

  await run('prestacao_contas', `
    insert into public.prestacao_contas (
      ano, candidato_id, tipo_lancamento, categoria, descricao,
      fornecedor_ou_doador, documento_fornecedor_ou_doador,
      data_lancamento, valor, fonte_recurso
    )
    -- Passo 1: limpeza basica e filtro de uf/ano/cargo
    with raw as (
      select
        nullif(trim(pc.ano),'')::integer                                as ano,
        upper(trim(pc.cargo))                                            as cargo,
        nullif(trim(pc.numero_candidato),'')::integer                   as numero_candidato,
        upper(trim(pc.sigla_partido))                                    as sigla_partido,
        nullif(trim(pc.identificador_tse),'')                           as identificador_tse,
        nullif(trim(pc.tipo_lancamento),'')                              as tipo_lancamento,
        nullif(trim(pc.categoria),'')                                    as categoria,
        nullif(trim(pc.descricao),'')                                    as descricao,
        nullif(trim(pc.fornecedor_ou_doador),'')                         as fornecedor_ou_doador,
        nullif(trim(pc.documento_fornecedor_ou_doador),'')               as documento_fornecedor_ou_doador,
        case when nullif(trim(pc.data_lancamento),'') ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
             then to_date(trim(pc.data_lancamento), 'DD/MM/YYYY')
             else null end                                               as data_lancamento,
        -- limpa valor: remove chars invalidos, guarda string intermed
        replace(replace(
          regexp_replace(coalesce(pc.valor,''), '[^0-9,.-]+', '', 'g'),
        '.', ''), ',', '.')                                              as valor_clean,
        nullif(trim(pc.fonte_recurso),'')                                as fonte_recurso
      from staging.stg_prestacao_contas pc
      where coalesce(trim(pc.ano),'') = '2022'
        and upper(coalesce(trim(pc.uf),'')) = 'SC'
        and upper(coalesce(trim(pc.cargo),'')) in ('DEPUTADO ESTADUAL','DEPUTADO FEDERAL')
    ),
    -- Passo 2: filtra apenas linhas onde valor_clean e um numero valido
    --          (separa WHERE do cast para evitar avaliacao eager pelo planner)
    valid as (
      select * from raw
      where valor_clean ~ '^-?[0-9]+([.][0-9]+)?$'
    ),
    -- Passo 3: cast seguro (valor_clean ja validado)
    base as (
      select
        ano, cargo, numero_candidato, sigla_partido, identificador_tse,
        tipo_lancamento, categoria, descricao,
        fornecedor_ou_doador, documento_fornecedor_ou_doador,
        data_lancamento,
        valor_clean::numeric(16,2) as valor,
        fonte_recurso
      from valid
    ),
    -- Passo 4: resolve candidato_id
    resolved as (
      select b.*, c.id as candidato_id
      from base b
      left join public.candidatos c
        on c.identificador_tse = b.identificador_tse
        or (b.identificador_tse is null and c.ano = b.ano and c.turno = 1
            and c.cargo = b.cargo and c.numero = b.numero_candidato
            and c.sigla_partido = b.sigla_partido)
    )
    select ano, candidato_id, tipo_lancamento, categoria, descricao,
           fornecedor_ou_doador, documento_fornecedor_ou_doador,
           data_lancamento, valor, fonte_recurso
    from resolved
  `);

  await run('import_log', `
    insert into public.import_logs (fonte, arquivo, status, mensagem)
    values ('scripts/010b_load_prestacao_contas.js', null, 'ok', 'Prestacao de contas carregada')
  `);

  console.log('\n=== Totais finais ===');
  const totais = await client.query(`
    select 'municipios_sc'      as tabela, count(*) as linhas from public.municipios_sc
    union all select 'partidos',           count(*) from public.partidos
    union all select 'candidatos',         count(*) from public.candidatos
    union all select 'votacao_municipio',  count(*) from public.votacao_municipio
    union all select 'prestacao_contas',   count(*) from public.prestacao_contas
  `);
  totais.rows.forEach(r => console.log('  ' + r.tabela.padEnd(22) + r.linhas));
}

main()
  .catch(e => { console.error('\nERRO FATAL:', e.message); process.exit(1); })
  .finally(() => client.end());
