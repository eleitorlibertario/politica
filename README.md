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

O projeto ainda esta em fase de documentacao e planejamento.

Ainda nao foram implementados:

- schema SQL;
- scripts de ingestao;
- dashboard;
- conexao com Supabase;
- MCP proprio;
- importacao de dados do TSE.

## Escopo Inicial

- Estado: Santa Catarina
- Ano: 2022
- Cargos: deputado estadual e deputado federal
- Candidatos: todos os candidatos dos cargos definidos
- Banco planejado: Supabase/Postgres
- Dashboard recomendado para MVP: Metabase
- Regioes: classificacao propria a partir de planilha `cidade | regiao`
