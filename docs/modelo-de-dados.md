# Modelo de Dados

## Objetivo

Este documento define o modelo de dados planejado para o Supabase/Postgres.

O modelo ainda nao e uma migracao SQL. Ele serve como referencia para implementacao futura.

## Convencoes

- Usar `id` como chave primaria interna.
- Preservar codigos oficiais do TSE e IBGE quando disponiveis.
- Usar `created_at` para rastrear carga dos registros.
- Evitar armazenar dados pessoais sensiveis quando nao forem necessarios.
- Separar fatos eleitorais, dimensoes e views analiticas.

## Tabelas

### regioes_sc

Objetivo:

- armazenar a classificacao propria de regioes.

Campos:

```text
id
nome
descricao
created_at
```

Origem:

- planilha propria do usuario.

Regras:

- `nome` deve ser unico.
- uma regiao pode conter muitos municipios.

### municipios_sc

Objetivo:

- armazenar municipios de Santa Catarina e sua regiao propria.

Campos:

```text
id
codigo_tse
codigo_ibge
nome
uf
regiao_id
created_at
```

Origem:

- TSE;
- IBGE, se necessario;
- planilha propria de regioes.

Regras:

- `uf` deve ser `SC`.
- cada municipio deve ter uma `regiao_id`.
- `codigo_tse` deve ser usado para cruzar com votacao.
- `codigo_ibge` deve ser mantido para cruzamentos futuros.

### partidos

Objetivo:

- armazenar partidos presentes nas eleicoes analisadas.

Campos:

```text
id
ano
sigla
nome
created_at
```

Origem:

- cadastro de candidatos do TSE.

Regras:

- a combinacao `ano + sigla` deve ser unica.

### candidatos

Objetivo:

- armazenar todos os candidatos de SC em 2022 para deputado estadual e deputado federal.

Campos:

```text
id
ano
turno
cargo
numero
nome_urna
nome_completo
partido_id
sigla_partido
federacao_coligacao
situacao_candidatura
situacao_totalizacao
identificador_tse
created_at
```

Origem:

- cadastro de candidatos do TSE.

Regras:

- incluir todos os candidatos que concorreram aos cargos do escopo;
- manter `sigla_partido` mesmo com `partido_id`, para facilitar auditoria;
- usar identificador oficial do TSE quando disponivel;
- evitar armazenar CPF bruto.

### votacao_municipio

Objetivo:

- armazenar votos por candidato e municipio.

Campos:

```text
id
ano
turno
cargo
candidato_id
municipio_id
votos
created_at
```

Origem:

- dados de resultados/votacao do TSE.

Regras:

- cada linha representa votos de um candidato em um municipio para um cargo;
- `votos` deve ser inteiro nao negativo;
- o mesmo candidato pode aparecer em muitos municipios.

Indices sugeridos:

```text
ano, cargo
candidato_id
municipio_id
cargo, municipio_id
```

### votacao_secao

Objetivo:

- armazenar votos por candidato, municipio, zona e secao.

Campos:

```text
id
ano
turno
cargo
candidato_id
municipio_id
zona
secao
local_votacao
votos
created_at
```

Origem:

- dados de resultados por secao/urna do TSE, quando disponiveis.

Regras:

- cada linha representa votos de um candidato em uma secao;
- `zona` e `secao` devem ser mantidas como identificadores eleitorais;
- `local_votacao` pode ser nulo se nao existir na fonte.

Indices sugeridos:

```text
ano, cargo
municipio_id, zona, secao
candidato_id
cargo, municipio_id
```

### prestacao_contas

Objetivo:

- armazenar receitas e despesas declaradas na prestacao de contas.

Campos:

```text
id
ano
candidato_id
tipo_lancamento
categoria
descricao
fornecedor_ou_doador
documento_fornecedor_ou_doador
data_lancamento
valor
fonte_recurso
created_at
```

Origem:

- dados de prestacao de contas do TSE.

Regras:

- `valor` deve ser decimal;
- despesas e receitas devem ser distinguiveis por `tipo_lancamento`;
- dados de documento devem ser avaliados antes de exposicao no dashboard;
- registros sem candidato correspondente devem ser isolados para auditoria.

Indices sugeridos:

```text
ano
candidato_id
tipo_lancamento
categoria
```

## Views Planejadas

### vw_candidato_custo_voto

Objetivo:

- consolidar votos, despesas e custo por voto por candidato.

### vw_forca_candidato_regiao

Objetivo:

- medir forca de candidatos por regiao propria.

### vw_forca_partido_regiao

Objetivo:

- medir forca de partidos por regiao propria.

### vw_dominancia_municipal

Objetivo:

- identificar candidatos e partidos dominantes em cada municipio.

### vw_performance_secao

Objetivo:

- permitir analise granular por urna/secao.

## Relacionamentos

```text
regioes_sc 1:N municipios_sc
partidos 1:N candidatos
candidatos 1:N votacao_municipio
candidatos 1:N votacao_secao
candidatos 1:N prestacao_contas
municipios_sc 1:N votacao_municipio
municipios_sc 1:N votacao_secao
```

## Decisoes Pendentes

- Tipos SQL finais de cada campo.
- Chaves unicas definitivas.
- Estrategia para candidatos que aparecem em uma fonte e nao em outra.
- Se `zona` e `secao` serao texto ou numero.
- Se documentos de fornecedores/doadores serao armazenados completos, mascarados ou omitidos.
