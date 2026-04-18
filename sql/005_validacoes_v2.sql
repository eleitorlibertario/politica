-- 005_validacoes_v2.sql
-- Validacoes mais acionaveis para o ciclo de carga atual.

-- 1) Cobertura geral (tabelas finais)
select 'regioes_sc' as objeto, count(*) as qtd from public.regioes_sc
union all select 'municipios_sc', count(*) from public.municipios_sc
union all select 'partidos', count(*) from public.partidos
union all select 'candidatos', count(*) from public.candidatos
union all select 'votacao_municipio', count(*) from public.votacao_municipio
union all select 'votacao_secao', count(*) from public.votacao_secao
union all select 'prestacao_contas', count(*) from public.prestacao_contas
union all select 'import_erros', count(*) from public.import_erros
order by 1;

-- 2) Cobertura staging (entradas brutas importadas)
select 'stg_regioes' as objeto, count(*) as qtd from staging.stg_regioes
union all select 'stg_candidatos', count(*) from staging.stg_candidatos
union all select 'stg_votacao_municipio', count(*) from staging.stg_votacao_municipio
union all select 'stg_votacao_secao', count(*) from staging.stg_votacao_secao
union all select 'stg_prestacao_contas', count(*) from staging.stg_prestacao_contas
order by 1;

-- 3) Municipios com regiao fallback (indicador de mismatch planilha x TSE)
select
  count(*) as municipios_em_sem_regiao
from public.municipios_sc m
join public.regioes_sc r on r.id = m.regiao_id
where r.nome = 'SEM REGIAO';

-- 4) Candidatos sem identificador_tse (pode prejudicar matching com fatos)
select
  count(*) as candidatos_sem_identificador_tse
from public.candidatos
where identificador_tse is null;

-- 5) Rejeicoes por fonte (import_erros)
select
  fonte,
  tipo_erro,
  count(*) as qtd
from public.import_erros
group by fonte, tipo_erro
order by qtd desc, fonte, tipo_erro;

-- 6) Taxa de rejeicao por fluxo (aproximada)
with base as (
  select 'stg_votacao_municipio'::text as fonte, count(*)::numeric as qtd_staging from staging.stg_votacao_municipio
  union all
  select 'stg_votacao_secao', count(*)::numeric from staging.stg_votacao_secao
  union all
  select 'stg_prestacao_contas', count(*)::numeric from staging.stg_prestacao_contas
),
err as (
  select fonte, count(*)::numeric as qtd_erros
  from public.import_erros
  where fonte in ('stg_votacao_municipio', 'stg_votacao_secao', 'stg_prestacao_contas')
  group by fonte
)
select
  b.fonte,
  b.qtd_staging,
  coalesce(e.qtd_erros, 0) as qtd_erros,
  case
    when b.qtd_staging > 0 then round((coalesce(e.qtd_erros, 0) / b.qtd_staging) * 100, 2)
    else null
  end as pct_rejeicao
from base b
left join err e on e.fonte = b.fonte
order by b.fonte;

-- 7) Votacao por municipio x secao (apenas quando secao estiver carregada)
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
order by abs(coalesce(m.votos_municipio, 0) - coalesce(s.votos_secao, 0)) desc
limit 200;

-- 8) Top 30 candidatos por votos (sanidade de dados carregados)
select
  c.cargo,
  c.numero,
  c.nome_urna,
  c.sigla_partido,
  sum(vm.votos)::bigint as total_votos
from public.votacao_municipio vm
join public.candidatos c on c.id = vm.candidato_id
group by c.cargo, c.numero, c.nome_urna, c.sigla_partido
order by total_votos desc
limit 30;

-- 9) Top 30 candidatos por custo_por_voto (com minimo de votos para evitar distorcao)
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
  c.cargo,
  c.numero,
  c.nome_urna,
  c.sigla_partido,
  v.total_votos,
  coalesce(d.total_despesas, 0) as total_despesas,
  case
    when v.total_votos > 0 then round(coalesce(d.total_despesas, 0) / v.total_votos, 6)
    else null
  end as custo_por_voto
from votos v
join public.candidatos c on c.id = v.candidato_id
left join despesas d on d.candidato_id = v.candidato_id
where v.total_votos >= 1000
order by custo_por_voto asc nulls last
limit 30;
