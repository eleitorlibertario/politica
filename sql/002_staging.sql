-- 002_staging.sql
-- Cria tabelas de staging para receber CSVs brutos antes da carga final.
-- Rode este arquivo antes de importar qualquer CSV no Supabase.

begin;

create schema if not exists staging;

-- Normalizador simples para matching por texto (cidade, nomes etc.).
create or replace function public.normalize_txt(v text)
returns text
language sql
immutable
as $$
  select nullif(regexp_replace(upper(unaccent(trim(coalesce(v, '')))), '[^A-Z0-9]+', '', 'g'), '');
$$;

-- Cidade | regiao (arquivo local)
create table if not exists staging.stg_regioes (
  id bigserial primary key,
  cidade text,
  regiao text,
  qtde_eleitores_2022 text,
  qtde_eleitores_2024 text,
  source_file text,
  loaded_at timestamptz not null default now()
);

-- Cadastro de candidatos TSE (SC 2022)
create table if not exists staging.stg_candidatos (
  id bigserial primary key,
  ano text,
  turno text,
  uf text,
  cargo text,
  numero text,
  nome_urna text,
  nome_completo text,
  sigla_partido text,
  nome_partido text,
  federacao_coligacao text,
  situacao_candidatura text,
  situacao_totalizacao text,
  identificador_tse text,
  source_file text,
  loaded_at timestamptz not null default now()
);

-- Votacao por municipio
create table if not exists staging.stg_votacao_municipio (
  id bigserial primary key,
  ano text,
  turno text,
  uf text,
  codigo_municipio_tse text,
  municipio text,
  cargo text,
  numero_candidato text,
  nome_candidato text,
  sigla_partido text,
  identificador_tse text,
  votos text,
  source_file text,
  loaded_at timestamptz not null default now()
);

-- Votacao por secao/urna
create table if not exists staging.stg_votacao_secao (
  id bigserial primary key,
  ano text,
  turno text,
  uf text,
  codigo_municipio_tse text,
  municipio text,
  zona text,
  secao text,
  local_votacao text,
  cargo text,
  numero_candidato text,
  nome_candidato text,
  sigla_partido text,
  identificador_tse text,
  votos text,
  source_file text,
  loaded_at timestamptz not null default now()
);

-- Prestacao de contas
create table if not exists staging.stg_prestacao_contas (
  id bigserial primary key,
  ano text,
  uf text,
  cargo text,
  numero_candidato text,
  nome_candidato text,
  sigla_partido text,
  identificador_tse text,
  tipo_lancamento text,
  categoria text,
  descricao text,
  fornecedor_ou_doador text,
  documento_fornecedor_ou_doador text,
  data_lancamento text,
  valor text,
  fonte_recurso text,
  source_file text,
  loaded_at timestamptz not null default now()
);

commit;
