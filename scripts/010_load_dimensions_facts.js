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
  // Desabilita timeout no servidor (Supabase tem default que mata queries longas)
  await client.query('SET statement_timeout = 0');
  await client.query('SET lock_timeout = 0');
  console.log('Conectado.\n=== Carga dimensoes e fatos ===\n');

  // -------------------------------------------------------------------------
  // DIMENSOES
  // -------------------------------------------------------------------------

  // Passo 1: insere municipios com regiao fallback (query simples, sem normalize_txt em massa)
  await run('municipios_sc — insert base', `
    insert into public.municipios_sc (codigo_tse, codigo_ibge, nome, uf, regiao_id)
    select distinct
      nullif(trim(vm.codigo_municipio_tse),'')::integer as codigo_tse,
      null::integer,
      trim(vm.municipio) as nome,
      'SC',
      (select id from public.regioes_sc where nome = 'SEM REGIAO' limit 1)
    from staging.stg_votacao_municipio vm
    where coalesce(trim(vm.ano),'') = '2022'
      and upper(coalesce(trim(vm.uf),'')) = 'SC'
      and upper(coalesce(trim(vm.cargo),'')) in ('DEPUTADO ESTADUAL','DEPUTADO FEDERAL')
      and nullif(trim(vm.codigo_municipio_tse),'') is not null
    on conflict (codigo_tse) do update set nome = excluded.nome
  `);

  // Passo 2: atualiza regiao usando mapeamento da planilha (sobre poucos municipios)
  await run('municipios_sc — atualiza regioes', `
    update public.municipios_sc m
    set regiao_id = r.id
    from (
      select normalize_txt(cidade) as cidade_norm, min(trim(regiao)) as regiao
      from staging.stg_regioes
      where coalesce(trim(cidade),'') <> '' and coalesce(trim(regiao),'') <> ''
      group by normalize_txt(cidade)
    ) rm
    join public.regioes_sc r on r.nome = rm.regiao
    where normalize_txt(m.nome) = rm.cidade_norm
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
    select distinct on (ano, turno, cargo, numero, sigla_partido)
      nullif(trim(sc.ano),'')::integer                        as ano,
      coalesce(nullif(trim(sc.turno),'')::integer, 1)         as turno,
      upper(trim(sc.cargo))                                    as cargo,
      nullif(trim(sc.numero),'')::integer                     as numero,
      trim(sc.nome_urna)                                       as nome_urna,
      nullif(trim(sc.nome_completo),'')                        as nome_completo,
      p.id                                                     as partido_id,
      upper(trim(sc.sigla_partido))                            as sigla_partido,
      nullif(trim(sc.federacao_coligacao),'')                  as federacao_coligacao,
      nullif(trim(sc.situacao_candidatura),'')                 as situacao_candidatura,
      nullif(trim(sc.situacao_totalizacao),'')                 as situacao_totalizacao,
      nullif(trim(sc.identificador_tse),'')                    as identificador_tse
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
    order by ano, turno, cargo, numero, sigla_partido
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

  // Join direto por ID — evita normalize_txt em massa que trava o servidor
  await run('votacao_municipio', `
    insert into public.votacao_municipio (ano, turno, cargo, candidato_id, municipio_id, votos)
    select
      nullif(trim(vm.ano),'')::integer                                          as ano,
      coalesce(nullif(trim(vm.turno),'')::integer, 1)                           as turno,
      upper(trim(vm.cargo))                                                      as cargo,
      c.id                                                                       as candidato_id,
      m.id                                                                       as municipio_id,
      sum(nullif(regexp_replace(coalesce(vm.votos,''),'[^0-9-]+','','g'),'')::integer) as votos
    from staging.stg_votacao_municipio vm
    join public.municipios_sc m
      on m.codigo_tse = nullif(trim(vm.codigo_municipio_tse),'')::integer
    join public.candidatos c
      on c.identificador_tse = nullif(trim(vm.identificador_tse),'')
    where coalesce(trim(vm.ano),'') = '2022'
      and upper(coalesce(trim(vm.uf),'')) = 'SC'
      and upper(coalesce(trim(vm.cargo),'')) in ('DEPUTADO ESTADUAL','DEPUTADO FEDERAL')
    group by
      nullif(trim(vm.ano),'')::integer,
      coalesce(nullif(trim(vm.turno),'')::integer, 1),
      upper(trim(vm.cargo)),
      c.id, m.id
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
        case when nullif(trim(pc.data_lancamento),'') ~ E'^\\d{2}/\\d{2}/\\d{4}$'
             then to_date(trim(pc.data_lancamento), 'DD/MM/YYYY')
             else null end                                                        as data_lancamento,
        case when replace(replace(regexp_replace(coalesce(pc.valor,''),'[^0-9,.-]+','','g'),'.',''),',','.') ~ E'^-?[0-9]+(\\.[0-9]+)?$'
             then replace(replace(regexp_replace(coalesce(pc.valor,''),'[^0-9,.-]+','','g'),'.',''),',','.')::numeric(16,2)
             else null end                                                        as valor,
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
