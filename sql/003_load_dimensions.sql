-- 003_load_dimensions.sql
-- Carrega dimensoes: regioes_sc, municipios_sc, partidos, candidatos.
-- Pre-requisitos:
-- 1) 001_mvp_schema.sql aplicado
-- 2) 002_staging.sql aplicado
-- 3) staging ja populado com CSVs

begin;

-- Garantir regiao fallback para casos sem mapeamento.
insert into public.regioes_sc (nome, descricao)
values ('SEM REGIAO', 'Fallback para municipios sem correspondencia na planilha')
on conflict (nome) do nothing;

-- 1) Regioes
insert into public.regioes_sc (nome)
select distinct trim(s.regiao)
from staging.stg_regioes s
where coalesce(trim(s.regiao), '') <> ''
on conflict (nome) do nothing;

-- 2) Municipios (a partir da votacao municipal + mapeamento da planilha)
with regiao_map as (
  select
    normalize_txt(cidade) as cidade_norm,
    min(trim(regiao)) as regiao
  from staging.stg_regioes
  where coalesce(trim(cidade), '') <> ''
    and coalesce(trim(regiao), '') <> ''
  group by normalize_txt(cidade)
),
base_municipios as (
  select
    nullif(trim(vm.codigo_municipio_tse), '')::integer as codigo_tse,
    min(trim(vm.municipio)) as municipio_nome,
    min(coalesce(rm.regiao, 'SEM REGIAO')) as regiao_nome
  from staging.stg_votacao_municipio vm
  left join regiao_map rm
    on rm.cidade_norm = normalize_txt(vm.municipio)
  where coalesce(trim(vm.ano), '') = '2022'
    and upper(coalesce(trim(vm.uf), '')) = 'SC'
    and upper(coalesce(trim(vm.cargo), '')) in ('DEPUTADO ESTADUAL', 'DEPUTADO FEDERAL')
    and nullif(trim(vm.codigo_municipio_tse), '') is not null
  group by nullif(trim(vm.codigo_municipio_tse), '')::integer
)
insert into public.municipios_sc (
  codigo_tse,
  codigo_ibge,
  nome,
  uf,
  regiao_id
)
select
  bm.codigo_tse,
  null::integer as codigo_ibge,
  bm.municipio_nome as nome,
  'SC' as uf,
  r.id as regiao_id
from base_municipios bm
join public.regioes_sc r
  on r.nome = bm.regiao_nome
on conflict (codigo_tse) do update
set
  nome = excluded.nome,
  regiao_id = excluded.regiao_id;

-- 3) Partidos
insert into public.partidos (ano, sigla, nome)
select distinct
  nullif(trim(sc.ano), '')::integer as ano,
  upper(trim(sc.sigla_partido)) as sigla,
  nullif(trim(sc.nome_partido), '') as nome
from staging.stg_candidatos sc
where coalesce(trim(sc.ano), '') = '2022'
  and upper(coalesce(trim(sc.uf), '')) = 'SC'
  and upper(coalesce(trim(sc.cargo), '')) in ('DEPUTADO ESTADUAL', 'DEPUTADO FEDERAL')
  and coalesce(trim(sc.sigla_partido), '') <> ''
on conflict (ano, sigla) do update
set nome = coalesce(excluded.nome, public.partidos.nome);

-- 4) Candidatos
insert into public.candidatos (
  ano,
  turno,
  cargo,
  numero,
  nome_urna,
  nome_completo,
  partido_id,
  sigla_partido,
  federacao_coligacao,
  situacao_candidatura,
  situacao_totalizacao,
  identificador_tse
)
select
  nullif(trim(sc.ano), '')::integer as ano,
  coalesce(nullif(trim(sc.turno), '')::integer, 1) as turno,
  upper(trim(sc.cargo)) as cargo,
  nullif(trim(sc.numero), '')::integer as numero,
  trim(sc.nome_urna) as nome_urna,
  nullif(trim(sc.nome_completo), '') as nome_completo,
  p.id as partido_id,
  upper(trim(sc.sigla_partido)) as sigla_partido,
  nullif(trim(sc.federacao_coligacao), '') as federacao_coligacao,
  nullif(trim(sc.situacao_candidatura), '') as situacao_candidatura,
  nullif(trim(sc.situacao_totalizacao), '') as situacao_totalizacao,
  nullif(trim(sc.identificador_tse), '') as identificador_tse
from staging.stg_candidatos sc
left join public.partidos p
  on p.ano = nullif(trim(sc.ano), '')::integer
 and p.sigla = upper(trim(sc.sigla_partido))
where coalesce(trim(sc.ano), '') = '2022'
  and upper(coalesce(trim(sc.uf), '')) = 'SC'
  and upper(coalesce(trim(sc.cargo), '')) in ('DEPUTADO ESTADUAL', 'DEPUTADO FEDERAL')
  and coalesce(trim(sc.numero), '') <> ''
  and coalesce(trim(sc.nome_urna), '') <> ''
  and coalesce(trim(sc.sigla_partido), '') <> ''
on conflict (ano, turno, cargo, numero, sigla_partido) do update
set
  nome_urna = excluded.nome_urna,
  nome_completo = coalesce(excluded.nome_completo, public.candidatos.nome_completo),
  partido_id = coalesce(excluded.partido_id, public.candidatos.partido_id),
  federacao_coligacao = coalesce(excluded.federacao_coligacao, public.candidatos.federacao_coligacao),
  situacao_candidatura = coalesce(excluded.situacao_candidatura, public.candidatos.situacao_candidatura),
  situacao_totalizacao = coalesce(excluded.situacao_totalizacao, public.candidatos.situacao_totalizacao),
  identificador_tse = coalesce(excluded.identificador_tse, public.candidatos.identificador_tse);

insert into public.import_logs (fonte, arquivo, status, mensagem)
values ('sql/003_load_dimensions.sql', null, 'ok', 'Dimensoes carregadas');

commit;
