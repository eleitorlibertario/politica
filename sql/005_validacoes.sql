-- 005_validacoes.sql
-- Validacoes de qualidade apos carga de dimensoes e fatos.
-- Rode e confira os resultados das consultas.

-- 1) Cobertura geral
select 'regioes_sc' as objeto, count(*) as qtd from public.regioes_sc
union all
select 'municipios_sc', count(*) from public.municipios_sc
union all
select 'partidos', count(*) from public.partidos
union all
select 'candidatos', count(*) from public.candidatos
union all
select 'votacao_municipio', count(*) from public.votacao_municipio
union all
select 'votacao_secao', count(*) from public.votacao_secao
union all
select 'prestacao_contas', count(*) from public.prestacao_contas
union all
select 'import_erros', count(*) from public.import_erros
order by 1;

-- 2) Municipios de SC sem regiao
select m.*
from public.municipios_sc m
left join public.regioes_sc r on r.id = m.regiao_id
where r.id is null
   or r.nome is null;

-- 3) Candidatos sem partido associado
select c.id, c.ano, c.cargo, c.numero, c.nome_urna, c.sigla_partido
from public.candidatos c
where c.partido_id is null;

-- 4) Votacao municipio sem candidato/municipio valido (deveria ser zero)
select
  sum(case when vm.candidato_id is null then 1 else 0 end) as votos_sem_candidato,
  sum(case when vm.municipio_id is null then 1 else 0 end) as votos_sem_municipio
from public.votacao_municipio vm;

-- 5) Votacao secao sem candidato/municipio valido (deveria ser zero)
select
  sum(case when vs.candidato_id is null then 1 else 0 end) as secoes_sem_candidato,
  sum(case when vs.municipio_id is null then 1 else 0 end) as secoes_sem_municipio
from public.votacao_secao vs;

-- 6) Diferenca entre soma por secao e soma por municipio
with m as (
  select ano, turno, cargo, municipio_id, sum(votos)::bigint as votos_municipio
  from public.votacao_municipio
  group by ano, turno, cargo, municipio_id
),
s as (
  select ano, turno, cargo, municipio_id, sum(votos)::bigint as votos_secao
  from public.votacao_secao
  group by ano, turno, cargo, municipio_id
)
select
  coalesce(m.ano, s.ano) as ano,
  coalesce(m.turno, s.turno) as turno,
  coalesce(m.cargo, s.cargo) as cargo,
  coalesce(m.municipio_id, s.municipio_id) as municipio_id,
  coalesce(m.votos_municipio, 0) as votos_municipio,
  coalesce(s.votos_secao, 0) as votos_secao,
  coalesce(m.votos_municipio, 0) - coalesce(s.votos_secao, 0) as diferenca
from m
full outer join s
  on s.ano = m.ano
 and s.turno = m.turno
 and s.cargo = m.cargo
 and s.municipio_id = m.municipio_id
where coalesce(m.votos_municipio, 0) <> coalesce(s.votos_secao, 0)
order by abs(coalesce(m.votos_municipio, 0) - coalesce(s.votos_secao, 0)) desc;

-- 7) Candidatos com votos e sem despesa
with votos as (
  select candidato_id, sum(votos)::bigint as total_votos
  from public.votacao_municipio
  group by candidato_id
),
despesas as (
  select
    candidato_id,
    sum(case when upper(coalesce(tipo_lancamento, '')) like '%DESP%' then valor else 0 end)::numeric(16,2) as total_despesas
  from public.prestacao_contas
  where candidato_id is not null
  group by candidato_id
)
select
  c.id,
  c.cargo,
  c.numero,
  c.nome_urna,
  v.total_votos,
  coalesce(d.total_despesas, 0) as total_despesas
from votos v
join public.candidatos c on c.id = v.candidato_id
left join despesas d on d.candidato_id = v.candidato_id
where coalesce(d.total_despesas, 0) = 0
order by v.total_votos desc;

-- 8) Top erros de importacao
select fonte, tipo_erro, count(*) as qtd
from public.import_erros
group by fonte, tipo_erro
order by qtd desc, fonte, tipo_erro;
