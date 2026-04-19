# Politica

Projeto pessoal de analise eleitoral de Santa Catarina nas eleicoes de 2022.

O objetivo inicial e analisar a performance de candidatos e partidos nos cargos de deputado estadual e deputado federal, cruzando resultados eleitorais, gasto declarado de campanha, custo por voto e forca por regioes proprias.

## Documentacao

A documentacao principal esta em:

```text
docs/
```

Comece por:

- [docs/README.md](docs/README.md)
- [docs/projeto-analise-eleitoral-sc-2022.md](docs/projeto-analise-eleitoral-sc-2022.md)
- [docs/plano-implementacao.md](docs/plano-implementacao.md)
- [docs/links-download-tse-2022.md](docs/links-download-tse-2022.md)
- [docs/guia-operacional-carga-sc-2022.md](docs/guia-operacional-carga-sc-2022.md)

## Estado Atual

Pipeline de carga completo. Dados SC 2022 carregados no Supabase.

Implementado:

- schema SQL (staging + publico);
- scripts de ingestao (download, extracao, staging, dimensoes, fatos);
- conexao com Supabase/Postgres via Node.js + pg;
- importacao de dados do TSE (candidatos, votacao por municipio, prestacao de contas);
- validacao de dados (005_validacoes_v2.sql);
- dashboards Metabase Cloud (Visao Geral, Candidatos, Partidos, Territorio);
- filtros globais nos dashboards (cargo, partido, regiao, municipio).

Pendente:

- MCP proprio.

## Escopo Inicial

- Estado: Santa Catarina
- Ano: 2022
- Cargos: deputado estadual e deputado federal
- Candidatos: todos os candidatos dos cargos definidos
- Banco planejado: Supabase/Postgres
- Dashboard recomendado para MVP: Metabase
- Regioes: classificacao propria a partir de planilha `cidade | regiao`
