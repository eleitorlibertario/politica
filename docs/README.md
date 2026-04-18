# Documentacao do Projeto

## Projeto

Analise eleitoral de Santa Catarina nas eleicoes de 2022, com foco em deputado estadual e deputado federal.

O projeto e pessoal, exploratorio e voltado a analisar performance de candidatos e partidos, gasto declarado, custo por voto e forca regional usando uma classificacao propria de regioes.

## Ordem Recomendada de Leitura

1. [projeto-analise-eleitoral-sc-2022.md](projeto-analise-eleitoral-sc-2022.md)
2. [arquitetura.md](arquitetura.md)
3. [fontes-de-dados.md](fontes-de-dados.md)
4. [modelo-de-dados.md](modelo-de-dados.md)
5. [metricas.md](metricas.md)
6. [metodologia.md](metodologia.md)
7. [dashboard.md](dashboard.md)
8. [ingestao.md](ingestao.md)
9. [perguntas-analiticas.md](perguntas-analiticas.md)
10. [recomendacao-stack-dashboard.md](recomendacao-stack-dashboard.md)
11. [plano-implementacao.md](plano-implementacao.md)
12. [decisoes-pendentes.md](decisoes-pendentes.md)
13. [links-download-tse-2022.md](links-download-tse-2022.md)
14. [guia-operacional-carga-sc-2022.md](guia-operacional-carga-sc-2022.md)
15. [proximos-passos-retomada.md](proximos-passos-retomada.md)

## Conteudo

### Especificacao Geral

Arquivo:

```text
projeto-analise-eleitoral-sc-2022.md
```

Contem o resumo do projeto, escopo inicial, objetivos, infraestrutura planejada, modelo de dados proposto, metricas iniciais e decisoes ja tomadas.

### Arquitetura

Arquivo:

```text
arquitetura.md
```

Descreve o fluxo planejado entre fontes de dados, ingestao, Supabase, dashboard e possiveis MCPs.

### Fontes de Dados

Arquivo:

```text
fontes-de-dados.md
```

Lista as fontes necessarias: TSE, prestacao de contas e planilha propria de regioes.

### Modelo de Dados

Arquivo:

```text
modelo-de-dados.md
```

Define as tabelas planejadas, relacionamentos, origem dos dados e indices sugeridos.

### Metricas

Arquivo:

```text
metricas.md
```

Define metricas como votos totais, share regional, ranking municipal, custo por voto, concentracao territorial e dependencia regional.

### Metodologia

Arquivo:

```text
metodologia.md
```

Registra cuidados metodologicos para interpretar votos, gastos declarados, custo por voto e forca regional.

### Dashboard

Arquivo:

```text
dashboard.md
```

Define telas, filtros, cards, visualizacoes e perguntas que o dashboard deve responder.

### Ingestao

Arquivo:

```text
ingestao.md
```

Documenta a ordem de importacao, tratamentos esperados, validacoes e estrategia de reprocessamento.

### Perguntas Analiticas

Arquivo:

```text
perguntas-analiticas.md
```

Lista perguntas que o sistema deve responder sobre candidatos, partidos, regioes, cidades, urnas e financas.

### Recomendacao de Stack

Arquivo:

```text
recomendacao-stack-dashboard.md
```

Compara Metabase, Streamlit, Next.js e Supabase Studio, recomendando Metabase para o MVP e Next.js como possivel evolucao futura.

### Plano de Implementacao

Arquivo:

```text
plano-implementacao.md
```

Organiza a implementacao em fases, com objetivos, entregaveis, criterios de aceite, riscos e escopo do MVP.

### Decisoes Pendentes

Arquivo:

```text
decisoes-pendentes.md
```

Registra pontos ainda em aberto antes da implementacao.

### Links de Download TSE

Arquivo:

```text
links-download-tse-2022.md
```

Centraliza os links oficiais de download dos arquivos do TSE usados na ingestao.

### Guia Operacional de Carga

Arquivo:

```text
guia-operacional-carga-sc-2022.md
```

Guia pratico e direto com a sequencia completa: download, staging, carga e validacao.

### Proximos Passos para Retomada

Arquivo:

```text
proximos-passos-retomada.md
```

Checkpoint do estado atual e checklist objetivo para continuar o trabalho em outra sessao.

## Estado Atual

Somente documentacao foi criada.

Ainda nao foram criados:

- schema SQL;
- scripts de ingestao;
- conexao com Supabase;
- dashboard;
- MCP proprio;
- importacao da planilha de regioes;
- download de dados do TSE.
