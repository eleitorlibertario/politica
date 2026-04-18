# Links de Download TSE - SC 2022

## Objetivo

Este documento centraliza os links oficiais necessarios para baixar os arquivos do TSE usados na ingestao do projeto.

Fonte principal dos datasets:

- https://dadosabertos.tse.jus.br/

## Datasets de referencia no portal

- Candidatos - 2022:
  - https://dadosabertos.tse.jus.br/dataset/candidatos-2022
- Resultados - 2022:
  - https://dadosabertos.tse.jus.br/dataset/resultados-2022
- Prestacao de Contas Eleitorais - 2022:
  - https://dadosabertos.tse.jus.br/dataset/dadosabertos-tse-jus-br-dataset-prestacao-de-contas-eleitorais-2022

## Links diretos para download (ZIP)

### 1) Candidatos (todas as UFs)

- https://cdn.tse.jus.br/estatistica/sead/odsele/consulta_cand/consulta_cand_2022.zip

Uso no projeto:

- alimentar `staging.stg_candidatos` (filtrando SC e cargos do escopo).

### 2) Votacao por municipio/zona (todas as UFs)

- https://cdn.tse.jus.br/estatistica/sead/odsele/votacao_candidato_munzona/votacao_candidato_munzona_2022.zip

Uso no projeto:

- alimentar `staging.stg_votacao_municipio` (filtrando SC e cargos do escopo).

### 3) Votacao por secao (SC)

- https://cdn.tse.jus.br/estatistica/sead/odsele/votacao_secao/votacao_secao_2022_SC.zip

Uso no projeto:

- alimentar `staging.stg_votacao_secao`.

### 4) Prestacao de contas de candidatos (todas as UFs)

- https://cdn.tse.jus.br/estatistica/sead/odsele/prestacao_contas/prestacao_de_contas_eleitorais_candidatos_2022.zip

Uso no projeto:

- alimentar `staging.stg_prestacao_contas` (filtrando SC e cargos do escopo).

## Download automatico (recomendado)

Script do projeto:

- `scripts/006_download_tse.ps1`

Executar na raiz do repositorio:

```powershell
.\scripts\006_download_tse.ps1
```

Forcar novo download (sobrescrever arquivos existentes):

```powershell
.\scripts\006_download_tse.ps1 -Force
```

Destino dos arquivos:

- `inputs/tse/`

## Observacoes operacionais

- Os arquivos do TSE costumam usar `;` como separador e codificacao Latin-1.
- Nao abrir arquivos grandes no Excel para "validar tudo"; priorizar banco, Power Query, DuckDB, Python ou BI.
- Sempre registrar nome do arquivo e data de download em `import_logs`.
- Quando houver revisao/retificacao do TSE, repetir carga com a estrategia de reprocessamento definida.

## Sequencia recomendada apos o download

1. Rodar `sql/002_staging.sql` (se ainda nao foi rodado).
2. Popular tabelas `staging.*` com os arquivos extraidos.
3. Rodar `sql/003_load_dimensions.sql`.
4. Rodar `sql/004_load_facts.sql`.
5. Rodar `sql/005_validacoes_v2.sql`.
