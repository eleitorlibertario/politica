/**
 * 010_load_dimensions_facts.js
 * Carrega dimensoes e fatos a partir do staging.
 * Uso: node --env-file=.env scripts/010_load_dimensions_facts.js
 */
'use strict';

const { Client } = require('pg');

const client = new Client({
  host:     process.env.PG_HOST,
  port:     Number(process.env.PG_PORT),
  database: process.env.PG_DATABASE,
  user:     process.env.PG_USER,
  password: process.env.PG_PASSWORD,
  ssl:      { rejectUnauthorized: false },
  statement_timeout: 0,
  query_timeout:     0,
});

async function run(label, sql) {
  process.stdout.write('[RUN] ' + label + '... ');
  const t = Date.now();
  const res = await client.query(sql);
  const rows = res.rowCount ?? (res.rows && res.rows[0] ? JSON.stringify(res.rows[0]) : '');
  console.log('OK (' + ((Date.now()-t)/1000).toFixed(1) + 's)' + (rows ? ' ' + rows : ''));
}

async function main() {
  await client.connect();
  console.log('Conectado.\n=== Carga dimensoes e fatos ===\n');

  // -------------------------------------------------------------------------
  // DIMENSOES
  // -------------------------------------------------------------------------

  await run('municipios_sc', `
    with regiao_map as (
      select normalize_txt(cidade) as cidade_norm, min(trim(regiao)) as regiao
      from staging.stg_regioes
      where coalesce(trim(cidade),'') <> '' and coalesce(trim(regiao),'') <> ''
      group by normalize_txt(cidade)
    ),
    base as (
      select
        nullif(trim(vm.codigo_municipio_tse),'')::integer as codigo_tse,
        min(trim(vm.municipio)) as nome,
        min(coalesce(rm.regiao,'SEM REGIAO')) as regiao_nome
      from staging.stg_votacao_municipio vm
      left join regiao_map rm on rm.cidade_norm = normalize_txt(vm.municipio)
      where coalesce(trim(vm.ano),'') = '2022'
        and upper(coalesce(trim(vm.uf),'')) = 'SC'
        and upper(coalesce(trim(vm.cargo),'')) in ('DEPUTADO ESTADUAL','DEPUTADO FEDERAL')
        and nullif(trim(vm.codigo_municipio_tse),'') is not null
      group by nullif(trim(vm.codigo_municipio_tse),'')::integer
    )
    insert into public.municipios_sc (codigo_tse, codigo_ibge, nome, uf, regiao_id)
    select b.codigo_tse, null::integer, b.nome, 'SC', r.id
    from base b
    join public.regioes_sc r on r.nome = b.regiao_nome
    on conflict (codigo_tse) do update set nome = excluded.nome, regiao_id = excluded.regiao_id
  `);

  await run('partidos', `
    insert into public.partidos (ano, sigla, nome)
    select distinct
      nullif(trim(sc.ano),'')::integer,
      upper(trim(sc.sigla_partido)),
      nullif(trim(sc.nome_partido),'')
    from staging.stg_candidatos sc
    where coalesce(trim(sc.ano),'') = '2022'
      and upper(coalesce(trim(sc.uf),'')) = 'SC'
      and upper(coalesce(trim(sc.cargo),'')) in ('DEPUTADO ESTADUAL','DEPUTADO FEDERAL')
      and coalesce(trim(sc.sigla_partido),'') <> ''
    on conflict (ano, sigla) do update set nome = coalesce(excluded.nome, public.partidos.nome)
  `);

  await run('candidatos', `
    insert into public.candidatos (
      ano, turno, cargo, numero, nome_urna, nome_completo,
      partido_id, sigla_partido, federacao_coligacao,
      situacao_candidatura, situacao_totalizacao, identificador_tse
    )
    select
      nullif(trim(sc.ano),'')::integer,
      coalesce(nullif(trim(sc.turno),'')::integer, 1),
      upper(trim(sc.cargo)),
      nullif(trim(sc.numero),'')::integer,
      trim(sc.nome_urna),
      nullif(trim(sc.nome_completo),''),
      p.id,
      upper(trim(sc.sigla_partido)),
      nullif(trim(sc.federacao_coligacao),''),
      nullif(trim(sc.situacao_candidatura),''),
      nullif(trim(sc.situacao_totalizacao),''),
      nullif(trim(sc.identificador_tse),'')
    from staging.stg_candidatos sc
    left join public.partidos p
      on p.ano = nullif(trim(sc.ano),'')::integer
     and p.sigla = upper(trim(sc.sigla_partido))
    where coalesce(trim(sc.ano),'') = '2022'
      and upper(coalesce(trim(sc.uf),'')) = 'SC'
      and upper(coalesce(trim(sc.cargo),'')) in ('DEPUTADO ESTADUAL','DEPUTADO FEDERAL')
      and coalesce(trim(sc.numero),'') <> ''
      and coalesce(trim(sc.nome_urna),'') <> ''
      and coalesce(trim(sc.sigla_partido),'') <> ''
    on conflict (ano, turno, cargo, numero, sigla_partido) do update set
      nome_urna           = excluded.nome_urna,
      nome_completo       = coalesce(excluded.nome_completo, public.candidatos.nome_completo),
      partido_id          = coalesce(excluded.partido_id, public.candidatos.partido_id),
      federacao_coligacao = coalesce(excluded.federacao_coligacao, public.candidatos.federacao_coligacao),
      situacao_candidatura= coalesce(excluded.situacao_candidatura, public.candidatos.situacao_candidatura),
      situacao_totalizacao= coalesce(excluded.situacao_totalizacao, public.candidatos.situacao_totalizacao),
      identificador_tse   = coalesce(excluded.identificador_tse, public.candidatos.identificador_tse)
  `);

  // -------------------------------------------------------------------------
  // FATOS
  // -------------------------------------------------------------------------

  await run('votacao_municipio (resolve + agrega por municipio)', `
    insert into public.votacao_municipio (ano, turno, cargo, candidato_id, municipio_id, votos)
    with base as (
      select
        nullif(trim(vm.ano),'')::integer                                         as ano,
        coalesce(nullif(trim(vm.turno),'')::integer, 1)                          as turno,
        upper(trim(vm.cargo))                                                     as cargo,
        nullif(trim(vm.codigo_municipio_tse),'')::integer                        as codigo_tse,
        vm.municipio                                                              as municipio_nome,
        nullif(trim(vm.numero_candidato),'')::integer                            as numero_candidato,
        upper(trim(vm.sigla_partido))                                             as sigla_partido,
        nullif(trim(vm.identificador_tse),'')                                    as identificador_tse,
        nullif(regexp_replace(coalesce(vm.votos,''),'[^0-9-]+','','g'),'')::integer as votos
      from staging.stg_votacao_municipio vm
      where coalesce(trim(vm.ano),'') = '2022'
        and upper(coalesce(trim(vm.uf),'')) = 'SC'
        and upper(coalesce(trim(vm.cargo),'')) in ('DEPUTADO ESTADUAL','DEPUTADO FEDERAL')
    ),
    resolved as (
      select
        b.ano, b.turno, b.cargo, b.votos,
        m.id as municipio_id,
        c.id as candidato_id
      from base b
      left join public.municipios_sc m
        on m.codigo_tse = b.codigo_tse
        or normalize_txt(m.nome) = normalize_txt(b.municipio_nome)
      left join public.candidatos c
        on c.identificador_tse = b.identificador_tse
        or (b.identificador_tse is null
            and c.ano = b.ano and c.turno = b.turno and c.cargo = b.cargo
            and c.numero = b.numero_candidato and c.sigla_partido = b.sigla_partido)
      where m.id is not null and c.id is not null and b.votos is not null
    )
    select ano, turno, cargo, candidato_id, municipio_id, sum(votos)::integer as votos
    from resolved
    group by ano, turno, cargo, candidato_id, municipio_id
    on conflict (ano, turno, cargo, candidato_id, municipio_id) do update set votos = excluded.votos
  `);

  await run('prestacao_contas', `
    insert into public.prestacao_contas (
      ano, candidato_id, tipo_lancamento, categoria, descricao,
      fornecedor_ou_doador, documento_fornecedor_ou_doador,
      data_lancamento, valor, fonte_recurso
    )
    with base as (
      select
        nullif(trim(pc.ano),'')::integer                                        as ano,
        upper(trim(pc.cargo))                                                    as cargo,
        nullif(trim(pc.numero_candidato),'')::integer                           as numero_candidato,
        upper(trim(pc.sigla_partido))                                            as sigla_partido,
        nullif(trim(pc.identificador_tse),'')                                   as identificador_tse,
        nullif(trim(pc.tipo_lancamento),'')                                      as tipo_lancamento,
        nullif(trim(pc.categoria),'')                                            as categoria,
        nullif(trim(pc.descricao),'')                                            as descricao,
        nullif(trim(pc.fornecedor_ou_doador),'')                                 as fornecedor_ou_doador,
        nullif(trim(pc.documento_fornecedor_ou_doador),'')                       as documento_fornecedor_ou_doador,
        nullif(trim(pc.data_lancamento),'')::date                                as data_lancamento,
        nullif(replace(replace(regexp_replace(coalesce(pc.valor,''),'[^0-9,.-]+','','g'),'.',''),',','.'),'')::numeric(16,2) as valor,
        nullif(trim(pc.fonte_recurso),'')                                        as fonte_recurso
      from staging.stg_prestacao_contas pc
      where coalesce(trim(pc.ano),'') = '2022'
        and upper(coalesce(trim(pc.uf),'')) = 'SC'
        and upper(coalesce(trim(pc.cargo),'')) in ('DEPUTADO ESTADUAL','DEPUTADO FEDERAL')
    ),
    resolved as (
      select b.*, c.id as candidato_id
      from base b
      left join public.candidatos c
        on c.identificador_tse = b.identificador_tse
        or (b.identificador_tse is null and c.ano = b.ano and c.turno = 1
            and c.cargo = b.cargo and c.numero = b.numero_candidato
            and c.sigla_partido = b.sigla_partido)
      where b.valor is not null
    )
    select ano, candidato_id, tipo_lancamento, categoria, descricao,
           fornecedor_ou_doador, documento_fornecedor_ou_doador,
           data_lancamento, valor, fonte_recurso
    from resolved
  `);

  await run('import_log', `
    insert into public.import_logs (fonte, arquivo, status, mensagem)
    values ('scripts/010_load_dimensions_facts.js', null, 'ok', 'Dimensoes e fatos carregados')
  `);

  console.log('\n=== Verificando totais ===');
  const totais = await client.query(`
    select 'municipios_sc'    as tabela, count(*) as linhas from public.municipios_sc
    union all select 'partidos',        count(*) from public.partidos
    union all select 'candidatos',      count(*) from public.candidatos
    union all select 'votacao_municipio', count(*) from public.votacao_municipio
    union all select 'prestacao_contas', count(*) from public.prestacao_contas
  `);
  totais.rows.forEach(r => console.log('  ' + r.tabela.padEnd(22) + r.linhas));
}

main()
  .catch(e => { console.error('\nERRO FATAL:', e.message); process.exit(1); })
  .finally(() => client.end());
