# Fontes de Dados

## Objetivo

Este documento lista as fontes necessarias para alimentar a analise eleitoral de Santa Catarina em 2022.

## Fontes Principais

### TSE

O Tribunal Superior Eleitoral sera a fonte principal dos dados eleitorais e financeiros.

Dados necessarios:

- candidatos;
- partidos;
- resultados por municipio;
- resultados por zona/secao/urna, quando disponivel;
- prestacao de contas;
- despesas declaradas;
- situacao dos candidatos;
- situacao de totalizacao.

Links oficiais do portal:

- https://dadosabertos.tse.jus.br/dataset/candidatos-2022
- https://dadosabertos.tse.jus.br/dataset/resultados-2022
- https://dadosabertos.tse.jus.br/dataset/dadosabertos-tse-jus-br-dataset-prestacao-de-contas-eleitorais-2022

Links diretos de download usados no projeto:

- `consulta_cand_2022.zip`:
  - https://cdn.tse.jus.br/estatistica/sead/odsele/consulta_cand/consulta_cand_2022.zip
- `votacao_candidato_munzona_2022.zip`:
  - https://cdn.tse.jus.br/estatistica/sead/odsele/votacao_candidato_munzona/votacao_candidato_munzona_2022.zip
- `votacao_secao_2022_SC.zip`:
  - https://cdn.tse.jus.br/estatistica/sead/odsele/votacao_secao/votacao_secao_2022_SC.zip
- `prestacao_de_contas_eleitorais_candidatos_2022.zip`:
  - https://cdn.tse.jus.br/estatistica/sead/odsele/prestacao_contas/prestacao_de_contas_eleitorais_candidatos_2022.zip

## Bases Necessarias

### Cadastro de Candidatos

Finalidade:

- identificar todos os candidatos de SC em 2022 para deputado estadual e deputado federal;
- obter numero, nome de urna, nome completo, partido e situacao;
- criar a dimensao de candidatos.

Campos esperados:

```text
ano
uf
cargo
numero
nome_urna
nome_completo
sigla_partido
nome_partido
situacao_candidatura
situacao_totalizacao
identificador_tse
```

Uso no projeto:

- preencher `candidatos`;
- preencher `partidos`;
- relacionar votacao e prestacao de contas.

### Votacao por Municipio

Finalidade:

- analisar desempenho dos candidatos por cidade;
- calcular ranking municipal;
- agregar votos por regiao propria;
- calcular share por municipio e regiao.

Campos esperados:

```text
ano
turno
uf
municipio
codigo_municipio_tse
cargo
numero_candidato
nome_candidato
sigla_partido
votos
```

Uso no projeto:

- preencher `votacao_municipio`;
- criar views de forca regional;
- criar rankings municipais.

### Votacao por Secao ou Urna

Finalidade:

- permitir analise granular por zona/secao;
- investigar concentracao localizada;
- comparar candidatos em urnas ou locais de votacao.

Campos esperados:

```text
ano
turno
uf
municipio
codigo_municipio_tse
zona
secao
local_votacao
cargo
numero_candidato
nome_candidato
sigla_partido
votos
```

Uso no projeto:

- preencher `votacao_secao`;
- permitir drill-down no dashboard;
- apoiar investigacoes pontuais.

### Prestacao de Contas

Finalidade:

- obter despesas declaradas de campanha;
- calcular custo por voto;
- comparar eficiencia financeira entre candidatos e partidos.

Campos esperados:

```text
ano
uf
cargo
candidato
numero_candidato
sigla_partido
tipo_lancamento
categoria
descricao
fornecedor_ou_doador
documento_fornecedor_ou_doador
data_lancamento
valor
fonte_recurso
```

Uso no projeto:

- preencher `prestacao_contas`;
- somar despesas por candidato;
- somar despesas por partido;
- calcular custo por voto.

## Fonte Local

### Planilha de Regioes

Fonte fornecida pelo usuario.

Formato informado:

```text
cidade | regiao
```

Finalidade:

- classificar municipios de Santa Catarina em regioes proprias;
- permitir analise territorial conforme criterio politico/estrategico do usuario.

Regras esperadas:

- cada cidade deve pertencer a uma unica regiao;
- os nomes das cidades devem ser reconciliados com os nomes/codigos do TSE;
- divergencias de grafia devem ser registradas e corrigidas em uma tabela de equivalencias, se necessario.

## Validacoes Necessarias

- Todos os municipios de SC presentes na votacao devem ter uma regiao associada.
- Todos os candidatos com votos devem existir na tabela `candidatos`.
- Todas as linhas de prestacao de contas devem ser associadas a um candidato quando possivel.
- Totais de votos por cargo devem bater com totais oficiais ou com arquivos de referencia do TSE.
- Valores financeiros devem ser tratados como numericos com precisao decimal.

## Riscos

- Divergencia entre nome de cidade na planilha e nome oficial do TSE.
- Candidato com nome diferente entre base de votacao e prestacao de contas.
- Candidato com numero/partido alterado ou situacao especial.
- Dados financeiros com retificacoes.
- Campos de local de votacao ausentes ou inconsistentes.
- Custo por voto interpretado incorretamente como gasto local.

## Decisoes Pendentes

- Confirmar os nomes exatos dos arquivos do TSE que serao usados.
- Definir se os arquivos brutos ficarao no repositorio, em storage externo ou apenas documentados.
- Definir se a planilha de regioes sera importada manualmente ou por fluxo automatizado.
