-- 004_load_facts.sql
-- Carrega fatos: votacao_municipio, votacao_secao, prestacao_contas.
-- Resolve candidatos por:
-- 1) identificador_tse
-- 2) fallback por ano+turno+cargo+numero+sigla_partido

begin;

-- =========================
-- 1) VOTACAO MUNICIPIO
-- =========================
drop table if exists tmp_resolved_votacao_municipio;

create temporary table tmp_resolved_votacao_municipio as
with base as (
  select
    vm.id as stg_id,
    nullif(trim(vm.ano), '')::integer as ano,
    coalesce(nullif(trim(vm.turno), '')::integer, 1) as turno,
    upper(trim(vm.cargo)) as cargo,
    nullif(trim(vm.codigo_municipio_tse), '')::integer as codigo_tse,
    vm.municipio as municipio_nome,
    nullif(trim(vm.numero_candidato), '')::integer as numero_candidato,
    upper(trim(vm.sigla_partido)) as sigla_partido,
    nullif(trim(vm.identificador_tse), '') as identificador_tse,
    nullif(regexp_replace(coalesce(vm.votos, ''), '[^0-9-]+', '', 'g'), '')::integer as votos
  from staging.stg_votacao_municipio vm
  where coalesce(trim(vm.ano), '') = '2022'
    and upper(coalesce(trim(vm.uf), '')) = 'SC'
    and upper(coalesce(trim(vm.cargo), '')) in ('DEPUTADO ESTADUAL', 'DEPUTADO FEDERAL')
),
resolved as (
  select
    b.*,
    m.id as municipio_id,
    c.id as candidato_id
  from base b
  left join public.municipios_sc m
    on m.codigo_tse = b.codigo_tse
    or normalize_txt(m.nome) = normalize_txt(b.municipio_nome)
  left join public.candidatos c
    on c.identificador_tse = b.identificador_tse
    or (
      b.identificador_tse is null
      and c.ano = b.ano
      and c.turno = b.turno
      and c.cargo = b.cargo
      and c.numero = b.numero_candidato
      and c.sigla_partido = b.sigla_partido
    )
)
select * from resolved;

insert into public.votacao_municipio (
  ano,
  turno,
  cargo,
  candidato_id,
  municipio_id,
  votos
)
select
  r.ano,
  r.turno,
  r.cargo,
  r.candidato_id,
  r.municipio_id,
  r.votos
from tmp_resolved_votacao_municipio r
where r.candidato_id is not null
  and r.municipio_id is not null
  and r.votos is not null
on conflict (ano, turno, cargo, candidato_id, municipio_id) do update
set votos = excluded.votos;

insert into public.import_erros (fonte, linha_origem, tipo_erro, descricao, dados_originais)
select
  'stg_votacao_municipio' as fonte,
  r.stg_id as linha_origem,
  case
    when r.candidato_id is null and r.municipio_id is null then 'cand_e_municipio_nao_encontrados'
    when r.candidato_id is null then 'candidato_nao_encontrado'
    when r.municipio_id is null then 'municipio_nao_encontrado'
    else 'erro_desconhecido'
  end as tipo_erro,
  'Linha ignorada na carga de votacao_municipio' as descricao,
  jsonb_build_object(
    'ano', r.ano,
    'turno', r.turno,
    'cargo', r.cargo,
    'codigo_tse', r.codigo_tse,
    'municipio', r.municipio_nome,
    'numero_candidato', r.numero_candidato,
    'sigla_partido', r.sigla_partido,
    'identificador_tse', r.identificador_tse,
    'votos', r.votos
  ) as dados_originais
from tmp_resolved_votacao_municipio r
where r.candidato_id is null
   or r.municipio_id is null;

-- =========================
-- 2) VOTACAO SECAO
-- =========================
drop table if exists tmp_resolved_votacao_secao;

create temporary table tmp_resolved_votacao_secao as
with base as (
  select
    vs.id as stg_id,
    nullif(trim(vs.ano), '')::integer as ano,
    coalesce(nullif(trim(vs.turno), '')::integer, 1) as turno,
    upper(trim(vs.cargo)) as cargo,
    nullif(trim(vs.codigo_municipio_tse), '')::integer as codigo_tse,
    vs.municipio as municipio_nome,
    trim(vs.zona) as zona,
    trim(vs.secao) as secao,
    nullif(trim(vs.local_votacao), '') as local_votacao,
    nullif(trim(vs.numero_candidato), '')::integer as numero_candidato,
    upper(trim(vs.sigla_partido)) as sigla_partido,
    nullif(trim(vs.identificador_tse), '') as identificador_tse,
    nullif(regexp_replace(coalesce(vs.votos, ''), '[^0-9-]+', '', 'g'), '')::integer as votos
  from staging.stg_votacao_secao vs
  where coalesce(trim(vs.ano), '') = '2022'
    and upper(coalesce(trim(vs.uf), '')) = 'SC'
    and upper(coalesce(trim(vs.cargo), '')) in ('DEPUTADO ESTADUAL', 'DEPUTADO FEDERAL')
),
resolved as (
  select
    b.*,
    m.id as municipio_id,
    c.id as candidato_id
  from base b
  left join public.municipios_sc m
    on m.codigo_tse = b.codigo_tse
    or normalize_txt(m.nome) = normalize_txt(b.municipio_nome)
  left join public.candidatos c
    on c.identificador_tse = b.identificador_tse
    or (
      b.identificador_tse is null
      and c.ano = b.ano
      and c.turno = b.turno
      and c.cargo = b.cargo
      and c.numero = b.numero_candidato
      and c.sigla_partido = b.sigla_partido
    )
)
select * from resolved;

insert into public.votacao_secao (
  ano,
  turno,
  cargo,
  candidato_id,
  municipio_id,
  zona,
  secao,
  local_votacao,
  votos
)
select
  r.ano,
  r.turno,
  r.cargo,
  r.candidato_id,
  r.municipio_id,
  r.zona,
  r.secao,
  r.local_votacao,
  r.votos
from tmp_resolved_votacao_secao r
where r.candidato_id is not null
  and r.municipio_id is not null
  and coalesce(r.zona, '') <> ''
  and coalesce(r.secao, '') <> ''
  and r.votos is not null
on conflict (ano, turno, cargo, candidato_id, municipio_id, zona, secao) do update
set
  local_votacao = excluded.local_votacao,
  votos = excluded.votos;

insert into public.import_erros (fonte, linha_origem, tipo_erro, descricao, dados_originais)
select
  'stg_votacao_secao' as fonte,
  r.stg_id as linha_origem,
  case
    when r.candidato_id is null and r.municipio_id is null then 'cand_e_municipio_nao_encontrados'
    when r.candidato_id is null then 'candidato_nao_encontrado'
    when r.municipio_id is null then 'municipio_nao_encontrado'
    when coalesce(r.zona, '') = '' or coalesce(r.secao, '') = '' then 'zona_ou_secao_ausente'
    else 'erro_desconhecido'
  end as tipo_erro,
  'Linha ignorada na carga de votacao_secao' as descricao,
  jsonb_build_object(
    'ano', r.ano,
    'turno', r.turno,
    'cargo', r.cargo,
    'codigo_tse', r.codigo_tse,
    'municipio', r.municipio_nome,
    'zona', r.zona,
    'secao', r.secao,
    'numero_candidato', r.numero_candidato,
    'sigla_partido', r.sigla_partido,
    'identificador_tse', r.identificador_tse,
    'votos', r.votos
  ) as dados_originais
from tmp_resolved_votacao_secao r
where r.candidato_id is null
   or r.municipio_id is null
   or coalesce(r.zona, '') = ''
   or coalesce(r.secao, '') = '';

-- =========================
-- 3) PRESTACAO DE CONTAS
-- =========================
drop table if exists tmp_resolved_prestacao_contas;

create temporary table tmp_resolved_prestacao_contas as
with base as (
  select
    pc.id as stg_id,
    nullif(trim(pc.ano), '')::integer as ano,
    upper(trim(pc.cargo)) as cargo,
    nullif(trim(pc.numero_candidato), '')::integer as numero_candidato,
    upper(trim(pc.sigla_partido)) as sigla_partido,
    nullif(trim(pc.identificador_tse), '') as identificador_tse,
    nullif(trim(pc.tipo_lancamento), '') as tipo_lancamento,
    nullif(trim(pc.categoria), '') as categoria,
    nullif(trim(pc.descricao), '') as descricao,
    nullif(trim(pc.fornecedor_ou_doador), '') as fornecedor_ou_doador,
    nullif(trim(pc.documento_fornecedor_ou_doador), '') as documento_fornecedor_ou_doador,
    nullif(trim(pc.data_lancamento), '')::date as data_lancamento,
    nullif(
      replace(
        replace(
          regexp_replace(coalesce(pc.valor, ''), '[^0-9,.-]+', '', 'g'),
          '.',
          ''
        ),
        ',',
        '.'
      ),
      ''
    )::numeric(16,2) as valor,
    nullif(trim(pc.fonte_recurso), '') as fonte_recurso
  from staging.stg_prestacao_contas pc
  where coalesce(trim(pc.ano), '') = '2022'
    and upper(coalesce(trim(pc.uf), '')) = 'SC'
    and upper(coalesce(trim(pc.cargo), '')) in ('DEPUTADO ESTADUAL', 'DEPUTADO FEDERAL')
),
resolved as (
  select
    b.*,
    c.id as candidato_id
  from base b
  left join public.candidatos c
    on c.identificador_tse = b.identificador_tse
    or (
      b.identificador_tse is null
      and c.ano = b.ano
      and c.turno = 1
      and c.cargo = b.cargo
      and c.numero = b.numero_candidato
      and c.sigla_partido = b.sigla_partido
    )
)
select * from resolved;

insert into public.prestacao_contas (
  ano,
  candidato_id,
  tipo_lancamento,
  categoria,
  descricao,
  fornecedor_ou_doador,
  documento_fornecedor_ou_doador,
  data_lancamento,
  valor,
  fonte_recurso
)
select
  r.ano,
  r.candidato_id,
  r.tipo_lancamento,
  r.categoria,
  r.descricao,
  r.fornecedor_ou_doador,
  r.documento_fornecedor_ou_doador,
  r.data_lancamento,
  r.valor,
  r.fonte_recurso
from tmp_resolved_prestacao_contas r
where r.valor is not null;

insert into public.import_erros (fonte, linha_origem, tipo_erro, descricao, dados_originais)
select
  'stg_prestacao_contas' as fonte,
  r.stg_id as linha_origem,
  case
    when r.candidato_id is null and r.valor is null then 'candidato_nao_encontrado_e_valor_invalido'
    when r.candidato_id is null then 'candidato_nao_encontrado'
    when r.valor is null then 'valor_invalido'
    else 'erro_desconhecido'
  end as tipo_erro,
  'Linha carregada parcial ou ignorada na prestacao de contas' as descricao,
  jsonb_build_object(
    'ano', r.ano,
    'cargo', r.cargo,
    'numero_candidato', r.numero_candidato,
    'sigla_partido', r.sigla_partido,
    'identificador_tse', r.identificador_tse,
    'tipo_lancamento', r.tipo_lancamento,
    'valor_raw', (select pc.valor from staging.stg_prestacao_contas pc where pc.id = r.stg_id)
  ) as dados_originais
from tmp_resolved_prestacao_contas r
where r.candidato_id is null
   or r.valor is null;

insert into public.import_logs (fonte, arquivo, status, mensagem)
values ('sql/004_load_facts.sql', null, 'ok', 'Fatos carregados');

commit;
