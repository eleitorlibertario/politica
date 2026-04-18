-- MVP schema for SC 2022 electoral analysis
-- Target: Supabase Postgres (public schema)

begin;

create extension if not exists unaccent;

create table if not exists public.regioes_sc (
  id bigserial primary key,
  nome text not null,
  descricao text,
  created_at timestamptz not null default now(),
  constraint uq_regioes_sc_nome unique (nome)
);

create table if not exists public.municipios_sc (
  id bigserial primary key,
  codigo_tse integer not null,
  codigo_ibge integer,
  nome text not null,
  uf char(2) not null default 'SC',
  regiao_id bigint not null references public.regioes_sc(id) on update cascade on delete restrict,
  created_at timestamptz not null default now(),
  constraint ck_municipios_sc_uf check (uf = 'SC'),
  constraint uq_municipios_sc_codigo_tse unique (codigo_tse),
  constraint uq_municipios_sc_codigo_ibge unique (codigo_ibge)
);

create table if not exists public.partidos (
  id bigserial primary key,
  ano integer not null,
  sigla text not null,
  nome text,
  created_at timestamptz not null default now(),
  constraint uq_partidos_ano_sigla unique (ano, sigla)
);

create table if not exists public.candidatos (
  id bigserial primary key,
  ano integer not null,
  turno integer not null default 1,
  cargo text not null,
  numero integer not null,
  nome_urna text not null,
  nome_completo text,
  partido_id bigint references public.partidos(id) on update cascade on delete set null,
  sigla_partido text not null,
  federacao_coligacao text,
  situacao_candidatura text,
  situacao_totalizacao text,
  identificador_tse text,
  created_at timestamptz not null default now(),
  constraint ck_candidatos_cargo check (
    cargo in ('DEPUTADO ESTADUAL', 'DEPUTADO FEDERAL')
  ),
  constraint uq_candidatos_recorte unique (ano, turno, cargo, numero, sigla_partido)
);

create unique index if not exists uq_candidatos_identificador_tse
  on public.candidatos (identificador_tse)
  where identificador_tse is not null;

create table if not exists public.votacao_municipio (
  id bigserial primary key,
  ano integer not null,
  turno integer not null,
  cargo text not null,
  candidato_id bigint not null references public.candidatos(id) on update cascade on delete restrict,
  municipio_id bigint not null references public.municipios_sc(id) on update cascade on delete restrict,
  votos integer not null,
  created_at timestamptz not null default now(),
  constraint ck_votacao_municipio_votos_nonneg check (votos >= 0),
  constraint ck_votacao_municipio_cargo check (
    cargo in ('DEPUTADO ESTADUAL', 'DEPUTADO FEDERAL')
  ),
  constraint uq_votacao_municipio unique (ano, turno, cargo, candidato_id, municipio_id)
);

create index if not exists idx_votacao_municipio_ano_cargo on public.votacao_municipio (ano, cargo);
create index if not exists idx_votacao_municipio_candidato on public.votacao_municipio (candidato_id);
create index if not exists idx_votacao_municipio_municipio on public.votacao_municipio (municipio_id);
create index if not exists idx_votacao_municipio_cargo_municipio on public.votacao_municipio (cargo, municipio_id);

create table if not exists public.votacao_secao (
  id bigserial primary key,
  ano integer not null,
  turno integer not null,
  cargo text not null,
  candidato_id bigint not null references public.candidatos(id) on update cascade on delete restrict,
  municipio_id bigint not null references public.municipios_sc(id) on update cascade on delete restrict,
  zona text not null,
  secao text not null,
  local_votacao text,
  votos integer not null,
  created_at timestamptz not null default now(),
  constraint ck_votacao_secao_votos_nonneg check (votos >= 0),
  constraint ck_votacao_secao_cargo check (
    cargo in ('DEPUTADO ESTADUAL', 'DEPUTADO FEDERAL')
  ),
  constraint uq_votacao_secao unique (ano, turno, cargo, candidato_id, municipio_id, zona, secao)
);

create index if not exists idx_votacao_secao_ano_cargo on public.votacao_secao (ano, cargo);
create index if not exists idx_votacao_secao_municipio_zona_secao on public.votacao_secao (municipio_id, zona, secao);
create index if not exists idx_votacao_secao_candidato on public.votacao_secao (candidato_id);
create index if not exists idx_votacao_secao_cargo_municipio on public.votacao_secao (cargo, municipio_id);

create table if not exists public.prestacao_contas (
  id bigserial primary key,
  ano integer not null,
  candidato_id bigint references public.candidatos(id) on update cascade on delete set null,
  tipo_lancamento text not null,
  categoria text,
  descricao text,
  fornecedor_ou_doador text,
  documento_fornecedor_ou_doador text,
  data_lancamento date,
  valor numeric(16,2) not null,
  fonte_recurso text,
  created_at timestamptz not null default now()
);

create index if not exists idx_prestacao_contas_ano on public.prestacao_contas (ano);
create index if not exists idx_prestacao_contas_candidato on public.prestacao_contas (candidato_id);
create index if not exists idx_prestacao_contas_tipo on public.prestacao_contas (tipo_lancamento);
create index if not exists idx_prestacao_contas_categoria on public.prestacao_contas (categoria);

create table if not exists public.import_logs (
  id bigserial primary key,
  fonte text not null,
  arquivo text,
  status text not null,
  linhas_lidas integer,
  linhas_importadas integer,
  linhas_com_erro integer,
  mensagem text,
  created_at timestamptz not null default now()
);

create table if not exists public.import_erros (
  id bigserial primary key,
  fonte text not null,
  linha_origem bigint,
  tipo_erro text not null,
  descricao text,
  dados_originais jsonb,
  created_at timestamptz not null default now()
);

create or replace view public.vw_candidato_custo_voto as
with votos as (
  select
    vm.candidato_id,
    vm.cargo,
    sum(vm.votos)::bigint as total_votos
  from public.votacao_municipio vm
  group by vm.candidato_id, vm.cargo
),
despesas as (
  select
    pc.candidato_id,
    sum(
      case
        when upper(coalesce(pc.tipo_lancamento, '')) like '%DESP%' then pc.valor
        else 0
      end
    )::numeric(16,2) as total_despesas
  from public.prestacao_contas pc
  where pc.candidato_id is not null
    and pc.valor > 0
  group by pc.candidato_id
)
select
  c.cargo,
  c.nome_urna as candidato,
  c.sigla_partido as partido,
  coalesce(v.total_votos, 0)::bigint as total_votos,
  coalesce(d.total_despesas, 0)::numeric(16,2) as total_despesas,
  case
    when coalesce(v.total_votos, 0) > 0
      then round(coalesce(d.total_despesas, 0) / v.total_votos, 6)
    else null
  end as custo_por_voto,
  dense_rank() over (
    partition by c.cargo
    order by coalesce(v.total_votos, 0) desc
  ) as ranking_votos,
  dense_rank() over (
    partition by c.cargo
    order by
      case
        when coalesce(v.total_votos, 0) > 0
          then coalesce(d.total_despesas, 0) / v.total_votos
        else null
      end asc nulls last
  ) as ranking_eficiencia
from public.candidatos c
left join votos v on v.candidato_id = c.id and v.cargo = c.cargo
left join despesas d on d.candidato_id = c.id;

create or replace view public.vw_forca_candidato_regiao as
with base as (
  select
    r.nome as regiao,
    vm.cargo,
    c.id as candidato_id,
    c.nome_urna as candidato,
    c.sigla_partido as partido,
    sum(vm.votos)::bigint as votos
  from public.votacao_municipio vm
  join public.candidatos c on c.id = vm.candidato_id
  join public.municipios_sc m on m.id = vm.municipio_id
  join public.regioes_sc r on r.id = m.regiao_id
  group by r.nome, vm.cargo, c.id, c.nome_urna, c.sigla_partido
),
totais_regiao as (
  select regiao, cargo, sum(votos)::bigint as total_votos_regiao
  from base
  group by regiao, cargo
),
totais_candidato as (
  select candidato_id, cargo, sum(votos)::bigint as total_votos_candidato
  from base
  group by candidato_id, cargo
)
select
  b.regiao,
  b.cargo,
  b.candidato,
  b.partido,
  b.votos,
  case
    when tr.total_votos_regiao > 0
      then round((b.votos::numeric / tr.total_votos_regiao), 6)
    else null
  end as share_regional,
  dense_rank() over (partition by b.regiao, b.cargo order by b.votos desc) as ranking_na_regiao,
  case
    when tc.total_votos_candidato > 0
      then round((b.votos::numeric / tc.total_votos_candidato), 6)
    else null
  end as percentual_dos_votos_do_candidato_na_regiao
from base b
join totais_regiao tr on tr.regiao = b.regiao and tr.cargo = b.cargo
join totais_candidato tc on tc.candidato_id = b.candidato_id and tc.cargo = b.cargo;

create or replace view public.vw_forca_partido_regiao as
with base as (
  select
    r.nome as regiao,
    vm.cargo,
    c.sigla_partido as partido,
    c.id as candidato_id,
    sum(vm.votos)::bigint as votos
  from public.votacao_municipio vm
  join public.candidatos c on c.id = vm.candidato_id
  join public.municipios_sc m on m.id = vm.municipio_id
  join public.regioes_sc r on r.id = m.regiao_id
  group by r.nome, vm.cargo, c.sigla_partido, c.id
),
partido_agg as (
  select
    regiao,
    cargo,
    partido,
    count(distinct candidato_id)::integer as numero_candidatos,
    sum(votos)::bigint as votos
  from base
  group by regiao, cargo, partido
),
totais_regiao as (
  select regiao, cargo, sum(votos)::bigint as total_votos_regiao
  from partido_agg
  group by regiao, cargo
)
select
  p.regiao,
  p.cargo,
  p.partido,
  p.votos,
  case
    when t.total_votos_regiao > 0
      then round((p.votos::numeric / t.total_votos_regiao), 6)
    else null
  end as share_regional,
  dense_rank() over (partition by p.regiao, p.cargo order by p.votos desc) as ranking_partido_na_regiao,
  p.numero_candidatos,
  case
    when p.numero_candidatos > 0 then round((p.votos::numeric / p.numero_candidatos), 2)
    else null
  end as votos_por_candidato_medio
from partido_agg p
join totais_regiao t on t.regiao = p.regiao and t.cargo = p.cargo;

create or replace view public.vw_dominancia_municipal as
with base as (
  select
    m.nome as municipio,
    r.nome as regiao,
    vm.cargo,
    c.nome_urna as candidato,
    c.sigla_partido as partido,
    sum(vm.votos)::bigint as votos
  from public.votacao_municipio vm
  join public.candidatos c on c.id = vm.candidato_id
  join public.municipios_sc m on m.id = vm.municipio_id
  join public.regioes_sc r on r.id = m.regiao_id
  group by m.nome, r.nome, vm.cargo, c.nome_urna, c.sigla_partido
),
ranked as (
  select
    b.*,
    row_number() over (partition by b.municipio, b.cargo order by b.votos desc) as pos,
    sum(b.votos) over (partition by b.municipio, b.cargo) as total_votos_municipio
  from base b
)
select
  r1.municipio,
  r1.regiao,
  r1.cargo,
  r1.candidato as candidato_top_1,
  r1.partido as partido_top_1,
  r1.votos as votos_top_1,
  case
    when r1.total_votos_municipio > 0
      then round((r1.votos::numeric / r1.total_votos_municipio), 6)
    else null
  end as share_top_1,
  (
    select string_agg(r2.candidato, ' | ' order by r2.votos desc)
    from ranked r2
    where r2.municipio = r1.municipio
      and r2.cargo = r1.cargo
      and r2.pos <= 3
  ) as top_3_candidatos,
  case
    when r1.total_votos_municipio > 0
      then round(1 - (r1.votos::numeric / r1.total_votos_municipio), 6)
    else null
  end as fragmentacao
from ranked r1
where r1.pos = 1;

create or replace view public.vw_performance_secao as
with base as (
  select
    m.nome as municipio,
    r.nome as regiao,
    vs.zona,
    vs.secao,
    vs.cargo,
    c.nome_urna as candidato,
    c.sigla_partido as partido,
    sum(vs.votos)::bigint as votos
  from public.votacao_secao vs
  join public.candidatos c on c.id = vs.candidato_id
  join public.municipios_sc m on m.id = vs.municipio_id
  join public.regioes_sc r on r.id = m.regiao_id
  group by m.nome, r.nome, vs.zona, vs.secao, vs.cargo, c.nome_urna, c.sigla_partido
),
totais_secao as (
  select
    municipio,
    zona,
    secao,
    cargo,
    sum(votos)::bigint as total_votos_secao
  from base
  group by municipio, zona, secao, cargo
)
select
  b.municipio,
  b.regiao,
  b.zona,
  b.secao,
  b.cargo,
  b.candidato,
  b.partido,
  b.votos,
  dense_rank() over (
    partition by b.municipio, b.zona, b.secao, b.cargo
    order by b.votos desc
  ) as ranking_na_secao,
  case
    when t.total_votos_secao > 0
      then round((b.votos::numeric / t.total_votos_secao), 6)
    else null
  end as share_na_secao
from base b
join totais_secao t
  on t.municipio = b.municipio
 and t.zona = b.zona
 and t.secao = b.secao
 and t.cargo = b.cargo;

commit;
