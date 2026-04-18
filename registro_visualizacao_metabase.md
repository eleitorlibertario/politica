# Registro - Proposta de Visualizacao e Fontes Utilizadas

Data: 2026-04-18
Projeto: mcp_br

## 1) Fontes usadas para embasar a proposta

Arquivos consultados na pasta `docs/`:

- `docs/guia-operacional-carga-sc-2022.md`
- `docs/projeto-analise-eleitoral-sc-2022.md`
- `docs/README.md`
- `docs/ingestao.md`
- `docs/plano-implementacao.md`

Arquivo consultado na raiz:

- `README.md`

Validacao complementar de aderencia tecnica:

- Estrutura SQL e views em `sql/` (especialmente cargas e views analiticas) para garantir que os cards propostos batem com o modelo real.

## 2) Proposta de visualizacao (MVP no Metabase)

### Objetivo

Entregar visualizacao analitica rapida para SC 2022 com foco em:

- votos
- candidatos
- partidos
- forca regional
- custo por voto
- qualidade da carga

### Filtros globais recomendados

- `cargo`
- `partido`
- `regiao`
- `municipio`

### Ordem de montagem recomendada

1. Conectar Supabase/Postgres no Metabase.
2. Sincronizar schema `public`.
3. Criar filtros globais.
4. Montar dashboard de Visao Geral.
5. Montar dashboards tematicos (Candidatos, Partidos, Territorio).
6. Padronizar formatacao (percentual, moeda, ranking).
7. Validar resultados com card de erros e consistencia dos filtros.

## 3) Dashboards e cards sugeridos

### Dashboard 1 - Visao Geral

- Total de votos
- Total de candidatos (com votos)
- Top candidatos por votos
- Custo por voto
- Erros de importacao

### Dashboard 2 - Candidatos

- Ranking de candidatos por votos
- Ranking por custo por voto
- Forca de candidato por regiao

### Dashboard 3 - Partidos

- Forca de partido por regiao
- Despesas totais por partido

### Dashboard 4 - Territorio

- Dominancia municipal (top 1 por municipio)
- Opcional: barras por `share_top_1`

## 4) Mapeamento de filtros

- `cargo` -> `candidatos.cargo` ou `views.cargo`
- `partido` -> `candidatos.sigla_partido` ou `views.partido`
- `regiao` -> `regioes_sc.nome` ou `views.regiao`
- `municipio` -> `municipios_sc.nome` ou `vw_dominancia_municipal.municipio`

## 5) Checklist de pronto (MVP)

- Filtros aplicam sem erro em todos os cards relevantes.
- Nao existem cards vazios sem justificativa.
- Rankings de votos e custo por voto estao coerentes.
- Card de erros de importacao disponivel para auditoria.
- Formatos numéricos padronizados (milhar, percentual, moeda).

## 6) Observacao importante

A proposta foi construída com base no estado atual do repositorio e na documentacao existente. Caso o pipeline/SQL mude, os cards e mapeamentos de filtro devem ser revisados.
