# Arquitetura do Projeto

## Objetivo

Este documento descreve a arquitetura planejada para o projeto pessoal de analise eleitoral de Santa Catarina nas eleicoes de 2022.

O foco e organizar os dados em uma base Supabase e disponibilizar um dashboard exploratorio para analisar desempenho de candidatos e partidos por cidade, urna/secao e regiao propria.

## Visao Geral

```text
Fontes de dados
  - TSE
  - planilha propria de regioes - documento inputs/cidade_regiao.csv


Camada de ingestao
  - baixar ou receber arquivos
  - padronizar campos
  - validar dados
  - carregar no Supabase

Supabase / Postgres
  - tabelas normalizadas
  - views analiticas
  - indices para consulta

Dashboard
  - filtros
  - rankings
  - comparacoes
  - analise territorial
  - visualizacao de dados
  - analise de custo por voto
  - analises temporais

MCP / agente
  - consultas assistidas
  - perguntas recorrentes
  - apoio exploratorio
```

## Componentes

### Fontes de Dados

As fontes iniciais sao:

- dados eleitorais do TSE;
- dados de prestacao de contas do TSE;
- planilha propria de regioes com as colunas `cidade` e `regiao`.

### Camada de Ingestao

A camada de ingestao sera responsavel por transformar arquivos brutos em dados consistentes no Supabase.

Responsabilidades:

- importar a planilha de regioes;
- normalizar nomes de cidades;
- relacionar cidades da planilha com municipios do TSE;
- carregar candidatos;
- carregar votacao por municipio;
- carregar votacao por urna/secao;
- carregar prestacao de contas;
- validar totais contra fontes oficiais;
- registrar problemas de compatibilidade ou dados ausentes.

### Supabase

O Supabase sera a base persistente do projeto.

Responsabilidades:

- armazenar tabelas normalizadas;
- armazenar dados de apoio;
- disponibilizar views analiticas;
- servir dados para o dashboard;
- permitir consultas SQL exploratorias.

O projeto Supabase ja existe no EasyPanel.

### Dashboard

O dashboard sera a interface principal de analise visual.

Responsabilidades:

- permitir filtros por cargo, partido, candidato, cidade e regiao;
- exibir rankings;
- comparar candidatos e partidos;
- visualizar custo por voto;
- explorar votacao por cidade e urna/secao;
- identificar forca politica por regiao propria.

### MCPs

MCPs podem ser usados como camada complementar, nao como substituto da base analitica.

Usos possiveis:

- consultar dados do TSE via `mcp-brasil`;
- criar ferramentas proprias para perguntas recorrentes;
- consultar views do Supabase por linguagem natural;
- apoiar investigacoes exploratorias.

Repositorio de referencia:

```text
https://github.com/jxnxts/mcp-brasil
```

## Fluxo de Dados

1. Dados brutos sao obtidos do TSE e da planilha de regioes.
2. Arquivos sao armazenados ou referenciados como entrada.
3. A ingestao padroniza nomes, codigos e tipos.
4. Os dados sao carregados no Supabase.
5. Views analiticas consolidam metricas.
6. O dashboard consome tabelas e views.
7. Consultas MCP ou agente podem usar as mesmas views para responder perguntas.

## Principios

- Preservar dados brutos sempre que possivel.
- Separar dados brutos, dados normalizados e metricas derivadas.
- Usar codigos oficiais sempre que existirem.
- Evitar conclusoes causais sem base metodologica.
- Documentar todas as transformacoes relevantes.
- Manter o MVP focado no recorte SC 2022.

## Pontos Pendentes

- Definir a tecnologia do dashboard.
- Definir como os arquivos brutos serao armazenados.
- Definir se havera backend proprio ou consulta direta ao Supabase.
- Definir se o MCP proprio sera construido no MVP ou em fase posterior.
