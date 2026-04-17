# Projeto de Analise Eleitoral de Santa Catarina - 2022

## Resumo

Este projeto pessoal tem como objetivo analisar a performance eleitoral de candidatos e partidos em Santa Catarina nas eleicoes de 2022, com foco nos cargos de deputado estadual e deputado federal.

A primeira fase sera exploratoria: organizar os dados eleitorais e financeiros em uma base Supabase, criar consultas analiticas e disponibilizar um dashboard para investigar padroes territoriais, custo por voto e forca politica por regiao.

## Objetivos

- Analisar a performance de todos os candidatos que concorreram aos cargos de deputado estadual e deputado federal em Santa Catarina em 2022.
- Comparar desempenho eleitoral por cidade, urna/secao e regiao propria.
- Medir votos, participacao relativa, ranking territorial e concentracao geografica de candidatos e partidos.
- Cruzar votacao com gasto declarado de campanha.
- Calcular custo por voto de candidatos e partidos.
- Identificar quem e mais forte em cada regiao do estado.
- Criar uma base reutilizavel para novas analises eleitorais no futuro.

## Escopo Inicial

### Estado

- Santa Catarina

### Eleicao

- Eleicoes gerais de 2022

### Cargos

- Deputado estadual
- Deputado federal

### Candidatos

- Todos os candidatos que concorreram aos cargos definidos no escopo.

### Granularidade

- Cidade/municipio
- Urna/secao, quando disponivel nos dados do TSE
- Regiao propria definida pelo usuario

### Regioes

O usuario possui uma classificacao propria de regioes em uma planilha com duas colunas:

```text
cidade | regiao
```

Essa planilha sera importada para o banco e usada como referencia para agregacoes regionais.

## Fora do Escopo Inicial

- Eleicoes de outros anos.
- Cargos diferentes de deputado estadual e deputado federal.
- Analise de outros estados.
- Sistema publico multiusuario.
- Autenticacao de usuarios finais.
- Analise causal sobre impacto de gasto em cada cidade, salvo se houver dados que sustentem essa inferencia.

## Fontes de Dados

### TSE

Fonte principal para:

- resultados eleitorais;
- candidatos;
- partidos;
- votacao por municipio;
- votacao por zona/secao/urna, quando disponivel;
- prestacao de contas;
- despesas declaradas;
- situacao dos candidatos.

### Planilha de Regioes

Fonte local fornecida pelo usuario contendo:

- cidade;
- regiao propria.

Essa tabela sera usada para classificar os municipios catarinenses conforme o criterio do usuario.

## Infraestrutura

### Banco de Dados

- Supabase
- Postgres
- Projeto ja existente no EasyPanel

O Supabase sera usado como base persistente para ingestao, normalizacao e consulta dos dados.

### Dashboard

O projeto deve incluir um dashboard para analise visual e interativa dos dados.

O dashboard deve permitir, no minimo:

- filtrar por cargo;
- filtrar por partido;
- filtrar por candidato;
- filtrar por cidade;
- filtrar por regiao;
- comparar candidatos;
- comparar partidos;
- visualizar rankings;
- visualizar custo por voto;
- navegar de regiao para cidade e, quando possivel, para urna/secao.

### MCPs

O projeto pode usar a pasta/repo `mcp-brasil` como referencia ou apoio para consultas a dados brasileiros, especialmente dados do TSE.

Repositorio informado:

```text
https://github.com/jxnxts/mcp-brasil
```

No entanto, para analise pesada e comparacoes territoriais, os dados devem ser carregados em Supabase em vez de depender apenas de chamadas MCP em tempo real.

## Modelo de Dados Proposto

### regioes_sc

Tabela com a classificacao propria das regioes.

```text
id
nome
descricao
created_at
```

### municipios_sc

Tabela de municipios de Santa Catarina.

```text
id
codigo_tse
codigo_ibge
nome
uf
regiao_id
created_at
```

### candidatos

Tabela com candidatos a deputado estadual e deputado federal em SC em 2022.

```text
id
ano
turno
cargo
numero
nome_urna
nome_completo
partido
sigla_partido
federacao_coligacao
situacao_candidatura
situacao_totalizacao
cpf_hash_ou_id_tse
created_at
```

Observacao: dados pessoais sensiveis devem ser evitados quando nao forem necessarios para a analise.

### votacao_municipio

Tabela de votos por candidato e municipio.

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

### votacao_secao

Tabela de votos por candidato e zona/secao.

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

### prestacao_contas

Tabela com dados declarados de receitas e despesas eleitorais.

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

### partidos

Tabela auxiliar para consolidacao por partido.

```text
id
ano
sigla
nome
created_at
```

## Views Analiticas Propostas

### vw_candidato_custo_voto

Mostra o desempenho financeiro-eleitoral por candidato.

Campos esperados:

```text
cargo
candidato
partido
total_votos
total_despesas
custo_por_voto
ranking_votos
ranking_eficiencia
```

Formula principal:

```text
custo_por_voto = total_despesas / total_votos
```

### vw_forca_candidato_regiao

Mostra onde cada candidato e mais forte.

Campos esperados:

```text
regiao
cargo
candidato
partido
votos
share_regional
ranking_na_regiao
percentual_dos_votos_do_candidato_na_regiao
```

### vw_forca_partido_regiao

Mostra a forca de cada partido por regiao e cargo.

Campos esperados:

```text
regiao
cargo
partido
votos
share_regional
ranking_partido_na_regiao
numero_candidatos
votos_por_candidato_medio
```

### vw_dominancia_municipal

Mostra os principais candidatos em cada municipio.

Campos esperados:

```text
municipio
regiao
cargo
candidato_top_1
partido_top_1
votos_top_1
share_top_1
top_3_candidatos
fragmentacao
```

### vw_performance_secao

Permite investigacao em nivel de urna/secao.

Campos esperados:

```text
municipio
regiao
zona
secao
cargo
candidato
partido
votos
ranking_na_secao
share_na_secao
```

## Metricas Iniciais

### Candidatos

- votos totais;
- votos por municipio;
- votos por regiao;
- votos por zona/secao;
- share de votos no municipio;
- share de votos na regiao;
- ranking por municipio;
- ranking por regiao;
- municipios onde foi top 1, top 3 ou top 10;
- regioes onde foi top 1, top 3 ou top 10;
- concentracao dos votos nos principais municipios;
- total de despesas declaradas;
- custo por voto.

### Partidos

- votos totais por cargo;
- votos por municipio;
- votos por regiao;
- share regional;
- ranking regional;
- numero de candidatos;
- votos medios por candidato;
- custo agregado por voto;
- concentracao dos votos entre candidatos do partido.

### Regioes

- candidato mais votado por cargo;
- partido mais votado por cargo;
- candidatos com melhor custo por voto;
- candidatos com maior concentracao regional;
- partidos dominantes;
- municipios decisivos dentro da regiao.

## Cuidado Metodologico

O gasto declarado de campanha normalmente e informado no nivel do candidato, partido, fornecedor, categoria ou lancamento financeiro. Ele nao necessariamente indica quanto foi gasto em uma cidade, urna ou regiao especifica.

Por isso, o custo por voto mais defensavel no MVP e:

```text
custo_por_voto_candidato = total_despesas_declaradas_do_candidato / total_votos_do_candidato
```

Analises regionais devem ser interpretadas como desempenho territorial dado o custo total declarado, e nao como prova de quanto foi investido diretamente naquela regiao.

## Dashboard Inicial

O dashboard deve priorizar exploracao, nao apresentacao institucional.

Telas sugeridas:

### Visao Geral

- total de votos por cargo;
- total de candidatos;
- total de partidos;
- total de despesas declaradas;
- custo medio por voto;
- rankings gerais.

### Candidatos

- busca por candidato;
- votos totais;
- gasto declarado;
- custo por voto;
- mapa/tabela por regiao;
- ranking por cidade;
- evolucao de detalhe ate secao/urna, quando disponivel.

### Partidos

- votos por partido;
- custo agregado por voto;
- distribuicao regional;
- candidatos mais relevantes dentro do partido;
- comparacao entre deputado estadual e deputado federal.

### Regioes

- ranking de candidatos por regiao;
- ranking de partidos por regiao;
- cidades mais relevantes da regiao;
- candidatos com maior dependencia daquela regiao.

### Cidades e Urnas

- ranking de candidatos por cidade;
- ranking de partidos por cidade;
- detalhe por zona/secao;
- comparacao entre cidades da mesma regiao.

## Perguntas Analiticas Iniciais

- Quem teve melhor custo por voto em SC?
- Quem teve maior votacao total por cargo?
- Quais candidatos foram mais fortes em cada regiao propria?
- Quais partidos foram mais fortes em cada regiao propria?
- Quais candidatos tiveram votacao muito concentrada em poucas cidades?
- Quais candidatos tiveram presenca territorial mais ampla?
- Existem partidos fortes em uma regiao, mas fracos no resto do estado?
- Quais municipios foram decisivos para os candidatos mais votados?
- Onde candidatos a deputado estadual e deputado federal do mesmo partido performaram de forma parecida?
- Onde houve diferenca relevante entre a forca do partido para estadual e federal?

## Proximos Passos

1. Importar a planilha de regioes para o projeto.
2. Definir o formato final dos nomes de cidades para compatibilizar planilha, TSE e possivelmente IBGE.
3. Baixar ou consultar os arquivos do TSE para candidatos, resultados e prestacao de contas de 2022.
4. Criar scripts de ingestao para Supabase.
5. Criar tabelas e views analiticas no Postgres.
6. Validar amostras de dados contra resultados oficiais.
7. Criar o primeiro dashboard exploratorio.
8. Adicionar consultas via MCP ou agente para perguntas recorrentes.

## Decisoes Ja Tomadas

- O projeto sera pessoal.
- O estado inicial sera Santa Catarina.
- O ano inicial sera 2022.
- Os cargos iniciais serao deputado estadual e deputado federal.
- Todos os candidatos desses cargos serao analisados.
- A analise deve incluir candidatos e partidos.
- A analise deve incluir gasto declarado e custo por voto.
- A classificacao regional sera propria, vinda de planilha com `cidade` e `regiao`.
- O banco sera Supabase em projeto ja existente no EasyPanel.
- O projeto tera dashboard para analise.

## Decisoes Pendentes

- Tecnologia do dashboard.
- Formato da ingestao dos dados: scripts locais, jobs agendados ou funcoes no servidor.
- Estrategia de importacao da planilha de regioes.
- Estrutura final de armazenamento dos arquivos brutos.
- Se o projeto tera repositorio proprio separado ou sera organizado dentro da pasta atual.
- Se as consultas MCP serao criadas como servidor proprio ou apenas usando o `mcp-brasil` como apoio.
