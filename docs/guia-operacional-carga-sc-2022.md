# Guia Operacional - Carga SC 2022

## Para que serve este guia

Este guia descreve, em ordem simples, como sair de "repositorio pronto" para "dados carregados no Supabase".

Ele foi escrito para evitar duvidas sobre:

- quais arquivos baixar;
- em que ordem executar os SQLs;
- como validar se a carga deu certo.

## Visao rapida do fluxo

1. Baixar arquivos oficiais do TSE.
2. Preparar staging no Supabase.
3. Carregar dados brutos nas tabelas `staging.*`.
4. Carregar dimensoes e fatos.
5. Validar qualidade da carga.

## Passo 1 - Baixar arquivos do TSE

Executar na raiz do projeto:

```powershell
.\scripts\006_download_tse.ps1
```

Arquivos baixados em:

- `inputs/tse/`

Arquivos esperados:

- `consulta_cand_2022.zip`
- `votacao_candidato_munzona_2022.zip`
- `votacao_secao_2022_SC.zip`
- `prestacao_de_contas_eleitorais_candidatos_2022.zip`

Se precisar baixar novamente:

```powershell
.\scripts\006_download_tse.ps1 -Force
```

## Passo 2 - Criar staging no Supabase

No SQL Editor, rodar:

1. `sql/001_mvp_schema.sql` (caso ainda nao tenha rodado)
2. `sql/002_staging.sql`

## Passo 3 - Popular staging

### Regioes proprias

Rodar:

- `sql/002b_load_stg_regioes.sql`

Isso carrega `inputs/regiao/cidade_regiao.csv` em `staging.stg_regioes`.

### Arquivos do TSE

Importar os CSV/TXT extraidos dos ZIPs nas tabelas:

- `staging.stg_candidatos`
- `staging.stg_votacao_municipio`
- `staging.stg_votacao_secao` (opcional no primeiro ciclo)
- `staging.stg_prestacao_contas`

Observacao:

- foco de filtro do projeto: `ANO 2022`, `UF SC`, cargos `DEPUTADO ESTADUAL` e `DEPUTADO FEDERAL`.

## Passo 4 - Carga para tabelas finais

Rodar, nessa ordem:

1. `sql/003_load_dimensions.sql`
2. `sql/004_load_facts.sql`

## Passo 5 - Validar resultado

Rodar:

- `sql/005_validacoes_v2.sql`

Itens principais para olhar:

- contagem de `staging.*` e tabelas finais;
- `import_erros` por `fonte` e `tipo_erro`;
- `% rejeicao` por fonte;
- top candidatos por votos.

## Como interpretar rapido

- `qtd_staging = 0`: voce ainda nao importou os arquivos brutos na staging.
- `qtd_erros = 0` e tabelas finais vazias: carga ainda nao aconteceu.
- `qtd_erros > 0`: revisar `import_erros` para ajustar mapeamento/chaves.
- `municipios_em_sem_regiao > 0`: ajustar reconciliacao cidade x regiao.

## Referencias

- Links oficiais de download:
  - `docs/links-download-tse-2022.md`
- Modelo e metodologia:
  - `docs/modelo-de-dados.md`
  - `docs/metodologia.md`
