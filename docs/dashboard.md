# Dashboard

## Objetivo

Este documento define o dashboard planejado para analise eleitoral de Santa Catarina em 2022.

O dashboard sera uma ferramenta pessoal de exploracao, nao uma pagina publica institucional.

## Objetivos do Dashboard

- Explorar votos por candidato, partido, cidade, regiao e urna/secao.
- Comparar desempenho de candidatos.
- Comparar desempenho de partidos.
- Identificar forca regional.
- Analisar custo por voto.
- Encontrar concentracao territorial e padroes incomuns.

## Filtros Globais

Filtros esperados:

- cargo;
- partido;
- candidato;
- regiao;
- cidade;
- zona;
- secao;
- faixa de votos;
- faixa de custo por voto;
- situacao do candidato, se disponivel.

## Tela: Visao Geral

Objetivo:

- dar uma leitura rapida do estado da eleicao analisada.

Cards:

- total de votos analisados;
- total de candidatos;
- total de partidos;
- total de despesas declaradas;
- custo medio por voto;
- numero de municipios;
- numero de regioes.

Visualizacoes:

- ranking geral de candidatos por votos;
- ranking geral de partidos por votos;
- ranking de custo por voto;
- distribuicao de votos por regiao;
- distribuicao de despesas por partido.

Perguntas respondidas:

- quem foi mais votado em SC?
- quais partidos tiveram maior votacao?
- quais campanhas tiveram melhor custo por voto?

## Tela: Candidatos

Objetivo:

- analisar um candidato ou comparar candidatos.

Filtros:

- cargo;
- candidato;
- partido;
- regiao;
- cidade.

Cards:

- votos totais;
- total de despesas;
- custo por voto;
- melhor regiao;
- melhor cidade;
- municipios com votos;
- concentracao nos top 10 municipios.

Visualizacoes:

- tabela de votos por regiao;
- tabela de votos por cidade;
- ranking do candidato em cada regiao;
- ranking do candidato em cada cidade;
- distribuicao de votos;
- despesas por categoria.

Perguntas respondidas:

- onde o candidato foi mais forte?
- em quais cidades ele teve melhor desempenho?
- o voto foi concentrado ou espalhado?
- qual foi seu custo por voto?

## Tela: Partidos

Objetivo:

- analisar desempenho partidario por cargo e territorio.

Filtros:

- cargo;
- partido;
- regiao;
- cidade.

Cards:

- votos totais do partido;
- total de candidatos;
- despesas totais dos candidatos do partido;
- custo por voto agregado;
- melhor regiao;
- melhor municipio.

Visualizacoes:

- votos por regiao;
- votos por cidade;
- ranking dos candidatos do partido;
- concentracao dos votos entre candidatos;
- comparacao entre deputado estadual e deputado federal.

Perguntas respondidas:

- qual partido foi mais forte em cada regiao?
- o partido dependeu de poucos candidatos?
- onde o partido performou melhor para estadual e federal?

## Tela: Regioes

Objetivo:

- entender a forca politica dentro das regioes proprias.

Filtros:

- cargo;
- regiao;
- partido;
- candidato.

Cards:

- total de votos da regiao;
- partido mais votado;
- candidato mais votado;
- quantidade de municipios;
- custo medio por voto dos candidatos filtrados.

Visualizacoes:

- ranking de candidatos na regiao;
- ranking de partidos na regiao;
- cidades mais relevantes da regiao;
- candidatos mais dependentes da regiao;
- comparacao da regiao contra o estado.

Perguntas respondidas:

- quem e mais forte em cada regiao?
- quais partidos dominam cada regiao?
- quais cidades explicam o resultado regional?

## Tela: Cidades

Objetivo:

- analisar municipios individualmente.

Filtros:

- cargo;
- cidade;
- regiao;
- partido;
- candidato.

Cards:

- total de votos do cargo na cidade;
- candidato mais votado;
- partido mais votado;
- share do candidato top 1;
- fragmentacao.

Visualizacoes:

- ranking de candidatos na cidade;
- ranking de partidos na cidade;
- comparacao com a regiao;
- detalhe por zona/secao, quando disponivel.

Perguntas respondidas:

- quem ganhou a disputa proporcional naquela cidade?
- a cidade foi concentrada ou fragmentada?
- quais candidatos dependem dessa cidade?

## Tela: Urnas e Secoes

Objetivo:

- permitir investigacao granular.

Filtros:

- cargo;
- cidade;
- zona;
- secao;
- candidato;
- partido.

Visualizacoes:

- ranking de candidatos por secao;
- ranking de partidos por secao;
- comparacao entre secoes de uma cidade;
- secoes onde um candidato teve desempenho acima da media municipal.

Perguntas respondidas:

- onde dentro da cidade o candidato foi mais forte?
- existem secoes com comportamento muito diferente da media?

## Tela: Comparador

Objetivo:

- comparar candidatos ou partidos lado a lado.

Comparacoes:

- candidato vs candidato;
- partido vs partido;
- estadual vs federal dentro do mesmo partido;
- regiao vs regiao;
- cidade vs cidade.

Indicadores:

- votos totais;
- share;
- ranking;
- custo por voto;
- concentracao territorial;
- melhor regiao;
- melhor municipio.

## Requisitos de UX

- Dashboard deve priorizar tabelas, filtros e graficos objetivos.
- Deve ser facil alternar entre cargo estadual e federal.
- Deve permitir drill-down de regiao para cidade e de cidade para secao.
- Deve deixar claro quando um dado financeiro e declarado e nao territorial.
- Deve permitir exportar tabelas ou copiar resultados, se possivel.

## Decisoes Pendentes

- Tecnologia do dashboard.
- Se o dashboard sera local ou hospedado no EasyPanel.
- Se havera senha ou protecao de acesso.
- Quais graficos entram no MVP.
- Se havera mapa geografico ou apenas tabelas por regiao/cidade no inicio.
