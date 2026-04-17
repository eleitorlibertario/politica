# Recomendacao de Stack do Dashboard

## Objetivo

Este documento recomenda uma stack para o dashboard do projeto de analise eleitoral de Santa Catarina em 2022.

A recomendacao considera:

- uso pessoal;
- Supabase/Postgres ja existente no EasyPanel;
- necessidade de filtros, tabelas, rankings e comparacoes;
- analise exploratoria;
- baixa necessidade inicial de design publico ou experiencia multiusuario;
- facilidade de evoluir depois para uma aplicacao propria.

## Contexto

O projeto precisa de um dashboard para analisar:

- candidatos;
- partidos;
- regioes proprias;
- cidades;
- urnas/secoes;
- votos;
- despesas declaradas;
- custo por voto;
- concentracao territorial.

O dashboard deve consumir dados ja tratados no Supabase, preferencialmente a partir de views analiticas.

## Opcoes Avaliadas

### Metabase

Descricao:

- ferramenta pronta de BI/dashboard;
- conecta em bancos SQL como Postgres;
- permite criar perguntas, graficos, tabelas e filtros;
- boa para dashboards internos e exploracao rapida.

Pontos fortes:

- menor tempo para ter um dashboard funcional;
- filtros e parametros de dashboard ja existem;
- bom para tabelas, rankings e graficos simples;
- nao exige construir interface do zero;
- combina bem com uso pessoal e analise exploratoria.

Pontos fracos:

- menor controle fino de UX;
- comparadores muito especificos podem ficar limitados;
- experiencia menos customizada;
- pode ficar menos elegante para drill-downs complexos.

Quando usar:

- melhor escolha para MVP analitico rapido.

### Streamlit

Descricao:

- framework Python para criar apps de dados;
- bom para analise exploratoria e prototipos;
- conecta com Supabase/Postgres.

Pontos fortes:

- muito bom para analise de dados;
- rapido para criar filtros, tabelas e graficos;
- facilita misturar dashboard e analises Python;
- bom se a ingestao tambem for feita em Python.

Pontos fracos:

- UX menos refinada que uma aplicacao web propria;
- pode exigir cuidado com performance em tabelas grandes;
- estado da interface pode ficar limitado em fluxos mais complexos.

Quando usar:

- boa escolha se o projeto priorizar investigacao analitica em Python.

### Next.js

Descricao:

- framework web React;
- integra bem com Supabase;
- permite criar dashboard customizado e mais refinado.

Pontos fortes:

- maior controle da interface;
- bom para construir experiencia rica e especifica;
- facilita evoluir para app privado mais completo;
- boa integracao com Supabase;
- melhor para comparadores e drill-downs personalizados.

Pontos fracos:

- maior tempo de implementacao;
- exige construir componentes, filtros e tabelas;
- precisa de mais decisoes de UI, estado e arquitetura.

Quando usar:

- melhor escolha para versao mais madura do dashboard.

### Supabase Studio e SQL

Descricao:

- uso direto do Supabase para consultas, tabelas e views.

Pontos fortes:

- nenhum dashboard adicional no inicio;
- bom para validacao de dados;
- util durante ingestao e auditoria.

Pontos fracos:

- nao e uma experiencia analitica final;
- ruim para comparacoes visuais recorrentes;
- nao resolve bem a exploracao por filtros.

Quando usar:

- apoio tecnico, nao dashboard principal.

## Recomendacao

### Recomendacao Principal: Metabase no MVP

Para o MVP, a recomendacao e usar:

```text
Supabase/Postgres + Metabase
```

Motivo:

- o objetivo inicial e explorar dados, nao criar produto publico;
- Metabase entrega filtros, rankings, tabelas e graficos rapidamente;
- o projeto ja tera views analiticas no Postgres;
- reduz o tempo entre ingestao dos dados e primeiras descobertas;
- evita gastar energia inicial construindo componentes de dashboard.

## Stack Recomendada para o MVP

```text
Banco:
  Supabase/Postgres no EasyPanel

Camada analitica:
  Views SQL no Postgres

Dashboard:
  Metabase

Ingestao:
  Scripts documentados e executados separadamente em fase futura

MCP:
  Fora do MVP ou apenas como apoio posterior
```

## Arquitetura Recomendada para o Dashboard MVP

```text
Tabelas normalizadas no Supabase
  -> views analiticas no Postgres
  -> Metabase conectado ao Postgres
  -> dashboards com filtros
```

Views importantes para o Metabase:

- `vw_candidato_custo_voto`;
- `vw_forca_candidato_regiao`;
- `vw_forca_partido_regiao`;
- `vw_dominancia_municipal`;
- `vw_performance_secao`.

## Por que nao Next.js no MVP

Next.js e uma boa escolha para uma versao mais madura, mas nao deve ser a primeira escolha se o objetivo imediato for exploracao.

Motivos:

- exige mais tempo para construir filtros, tabelas e visualizacoes;
- aumenta a quantidade de decisoes tecnicas cedo demais;
- atrasa o primeiro contato real com os dados;
- o valor inicial esta mais nas perguntas analiticas do que na interface customizada.

## Por que nao Streamlit como primeira escolha

Streamlit tambem e viavel, principalmente se a analise for fortemente baseada em Python.

No entanto, para este projeto, Metabase parece mais adequado no MVP porque:

- o banco ja sera Postgres/Supabase;
- as metricas podem viver em views SQL;
- a experiencia de dashboards com filtros e compartilhamento privado e mais direta;
- reduz dependencia de codigo Python para navegar nos dados.

## Evolucao Recomendada

### Fase 1: Supabase + SQL

Objetivo:

- estruturar dados e validar consultas.

Interface:

- Supabase Studio;
- queries SQL;
- views.

### Fase 2: Metabase

Objetivo:

- criar dashboard exploratorio rapido.

Interface:

- filtros por cargo, partido, candidato, cidade e regiao;
- tabelas;
- rankings;
- graficos simples.

### Fase 3: Next.js

Objetivo:

- criar uma experiencia propria se o Metabase ficar limitado.

Quando considerar:

- necessidade de comparador mais sofisticado;
- necessidade de navegação customizada;
- necessidade de design mais refinado;
- necessidade de incorporar consultas assistidas por agente/MCP.

## Requisitos do Metabase no MVP

O dashboard em Metabase deve ter:

- filtros globais por cargo, partido, candidato, cidade e regiao;
- cards de total de votos, total de despesas e custo por voto;
- ranking de candidatos;
- ranking de partidos;
- ranking regional;
- ranking municipal;
- tabela de custo por voto;
- comparacao entre deputado estadual e deputado federal;
- visualizacao de detalhe por urna/secao quando os dados estiverem carregados.

## Criterios de Aceite

O dashboard MVP sera considerado suficiente quando permitir responder:

1. Quem foi mais forte em cada regiao?
2. Quem teve melhor custo por voto por cargo?
3. Qual partido foi mais forte em cada regiao?
4. Quais candidatos tiveram voto mais concentrado?
5. Quais cidades foram decisivas para os principais candidatos?
6. Onde deputado estadual e deputado federal diferem dentro do mesmo partido?

## Referencias Consultadas

- Supabase Docs: uso de Supabase com Next.js.
- Metabase Docs: filtros e parametros em dashboards.
- Streamlit Docs: conexao com Supabase e Postgres.

## Decisao Recomendada

Adotar Metabase como dashboard do MVP e manter Next.js como opcao futura caso o projeto precise de uma interface mais customizada.
