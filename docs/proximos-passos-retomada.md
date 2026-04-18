# Proximos Passos para Retomada

## Estado atual (checkpoint)

- Schema MVP criado no Supabase:
  - `9` tabelas
  - `5` views
- Staging criado:
  - `sql/002_staging.sql` executado
- Carga de regioes pronta:
  - `sql/002b_load_stg_regioes.sql` disponivel
- Carga de fatos corrigida:
  - `sql/004_load_facts.sql` atualizado (sem erro de CTE)
- Documentacao de links TSE e guia operacional atualizada.
- Script de download automatico criado:
  - `scripts/006_download_tse.ps1`

## Proxima sessao - ordem recomendada

1. Baixar os arquivos TSE:
   - executar `.\scripts\006_download_tse.ps1`
2. Extrair os ZIPs baixados em `inputs/tse/`.
3. Popular staging:
   - rodar `sql/002b_load_stg_regioes.sql`
   - importar dados TSE para:
     - `staging.stg_candidatos`
     - `staging.stg_votacao_municipio`
     - `staging.stg_prestacao_contas`
     - `staging.stg_votacao_secao` (opcional no primeiro ciclo)
4. Carregar tabelas finais:
   - rodar `sql/003_load_dimensions.sql`
   - rodar `sql/004_load_facts.sql`
5. Validar resultados:
   - rodar `sql/005_validacoes_v2.sql`
   - revisar principalmente:
     - cobertura `staging.*`
     - `import_erros` por `fonte/tipo_erro`
     - `% rejeicao` por fonte

## Criterio de "pronto para dashboard"

- `stg_candidatos`, `stg_votacao_municipio` e `stg_prestacao_contas` com carga > 0
- `votacao_municipio` e `prestacao_contas` com carga > 0
- `import_erros` sem volume critico de `candidato_nao_encontrado` e `municipio_nao_encontrado`
- consultas de `sql/005_validacoes_v2.sql` sem inconsistencias graves

## Arquivos-chave para abrir primeiro na retomada

- `docs/guia-operacional-carga-sc-2022.md`
- `docs/links-download-tse-2022.md`
- `sql/003_load_dimensions.sql`
- `sql/004_load_facts.sql`
- `sql/005_validacoes_v2.sql`
