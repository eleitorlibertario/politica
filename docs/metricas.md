# Metricas Analiticas

## Objetivo

Este documento define as metricas iniciais para analisar candidatos, partidos, cidades, regioes e urnas/secoes.

## Principios

- Toda metrica deve ter formula clara.
- Toda metrica deve declarar seu nivel de agregacao.
- Metricas financeiras devem distinguir gasto declarado de gasto territorial.
- Rankings devem sempre indicar cargo e recorte territorial.

## Metricas de Candidato

### total_votos_candidato

Definicao:

- soma dos votos recebidos por um candidato no recorte selecionado.

Formula:

```text
sum(votos)
```

Niveis:

- estadual;
- regiao;
- municipio;
- secao.

### share_municipal_candidato

Definicao:

- percentual dos votos de um candidato dentro de um municipio para um cargo.

Formula:

```text
votos_do_candidato_no_municipio / total_votos_do_cargo_no_municipio
```

Uso:

- comparar forca local entre candidatos.

### share_regional_candidato

Definicao:

- percentual dos votos de um candidato dentro de uma regiao propria para um cargo.

Formula:

```text
votos_do_candidato_na_regiao / total_votos_do_cargo_na_regiao
```

Uso:

- identificar candidatos fortes em cada regiao.

### ranking_municipal_candidato

Definicao:

- posicao do candidato dentro de um municipio, considerando votos para o mesmo cargo.

Uso:

- identificar candidatos top 1, top 3 ou top 10 em cada cidade.

### ranking_regional_candidato

Definicao:

- posicao do candidato dentro de uma regiao propria, considerando votos para o mesmo cargo.

Uso:

- identificar liderancas regionais.

### total_despesas_candidato

Definicao:

- soma das despesas declaradas pelo candidato.

Formula:

```text
sum(valor) where tipo_lancamento representa despesa
```

Uso:

- base para custo por voto.

### custo_por_voto_candidato

Definicao:

- despesa declarada dividida pelo total de votos do candidato.

Formula:

```text
total_despesas_candidato / total_votos_candidato
```

Interpretacao:

- quanto o candidato declarou gastar para cada voto obtido, em media.

Limitacao:

- nao indica gasto por cidade, urna ou regiao.

### concentracao_top_5_municipios

Definicao:

- percentual dos votos do candidato concentrado nos 5 municipios onde ele teve mais votos.

Formula:

```text
votos_nos_5_maiores_municipios / total_votos_candidato
```

Uso:

- medir dependencia de poucas cidades.

### concentracao_top_10_municipios

Definicao:

- percentual dos votos do candidato concentrado nos 10 municipios onde ele teve mais votos.

Formula:

```text
votos_nos_10_maiores_municipios / total_votos_candidato
```

### presenca_territorial

Definicao:

- quantidade de municipios onde o candidato recebeu votos.

Formula:

```text
count(distinct municipio_id) where votos > 0
```

Uso:

- diferenciar candidatos concentrados de candidatos espalhados.

### dependencia_regional

Definicao:

- percentual dos votos do candidato vindo de sua principal regiao.

Formula:

```text
votos_na_melhor_regiao / total_votos_candidato
```

Uso:

- identificar candidatos fortemente regionais.

## Metricas de Partido

### total_votos_partido

Definicao:

- soma dos votos de todos os candidatos do partido em um cargo e recorte.

Formula:

```text
sum(votos_dos_candidatos_do_partido)
```

### share_regional_partido

Definicao:

- percentual dos votos de um partido dentro de uma regiao para um cargo.

Formula:

```text
votos_do_partido_na_regiao / total_votos_do_cargo_na_regiao
```

### custo_por_voto_partido

Definicao:

- soma das despesas dos candidatos do partido dividida pela soma dos votos dos candidatos do partido.

Formula:

```text
total_despesas_partido / total_votos_partido
```

### votos_por_candidato_medio

Definicao:

- media de votos dos candidatos de um partido em um cargo e recorte.

Formula:

```text
total_votos_partido / numero_candidatos_partido
```

### concentracao_interna_partido

Definicao:

- percentual dos votos do partido concentrado nos seus candidatos mais votados.

Exemplo:

```text
votos_top_3_candidatos_do_partido / total_votos_partido
```

Uso:

- identificar se a forca do partido vem de muitos candidatos ou de poucos nomes.

## Metricas de Municipio e Regiao

### candidato_top_1

Definicao:

- candidato mais votado em um municipio ou regiao para um cargo.

### partido_top_1

Definicao:

- partido mais votado em um municipio ou regiao para um cargo.

### fragmentacao_municipal

Definicao:

- indicador de dispersao dos votos entre candidatos em um municipio.

Possiveis formulas:

```text
1 - share_do_candidato_mais_votado
```

ou

```text
indice baseado em distribuicao dos votos entre candidatos
```

Decisao pendente:

- escolher a formula final apos ver os dados.

### municipios_decisivos

Definicao:

- municipios que mais contribuem para a votacao total de um candidato ou partido.

Formula:

```text
votos_no_municipio / total_votos_candidato_ou_partido
```

## Metricas de Urna/Secao

### share_secao_candidato

Definicao:

- percentual dos votos de um candidato dentro de uma secao para um cargo.

Formula:

```text
votos_do_candidato_na_secao / total_votos_do_cargo_na_secao
```

### ranking_secao_candidato

Definicao:

- posicao do candidato na secao, considerando votos para o mesmo cargo.

## Cuidados

- Sempre filtrar por cargo ao comparar candidatos.
- Nao comparar diretamente deputado estadual e deputado federal sem deixar claro o contexto.
- Candidatos com poucos votos podem distorcer metricas de custo por voto.
- Despesas declaradas podem sofrer retificacao.
- Custo por voto regional nao deve ser tratado como gasto efetivo naquela regiao.
