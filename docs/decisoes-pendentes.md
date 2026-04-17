# Decisoes Pendentes

## Objetivo

Este documento registra decisoes que ainda precisam ser tomadas antes da implementacao.

## Dashboard

### Tecnologia

Decisao recomendada para o MVP:

```text
Metabase conectado ao Supabase/Postgres
```

Racional completo:

```text
docs/recomendacao-stack-dashboard.md
```

Ainda precisa ser confirmado pelo usuario antes da implementacao.

Opcoes possiveis:

- Next.js;
- React + Vite;
- Metabase;
- Supabase Studio + queries salvas;
- Streamlit;
- outro dashboard analitico.

Critérios:

- facilidade de desenvolvimento;
- qualidade da experiencia analitica;
- facilidade de conexao ao Supabase;
- facilidade de hospedagem no EasyPanel;
- capacidade de filtros e tabelas grandes.

### Hospedagem

Decidir onde o dashboard vai rodar.

Opcoes:

- local;
- EasyPanel;
- outro ambiente privado.

### Acesso

Decidir se havera protecao de acesso.

Opcoes:

- sem login, apenas ambiente privado;
- senha simples;
- autenticacao Supabase;
- proxy com protecao no EasyPanel.

## Ingestao

### Ferramenta

Decidir como a ingestao sera implementada.

Opcoes:

- scripts locais;
- job no servidor;
- ferramenta ETL;
- workflow automatizado;
- notebook controlado.

### Arquivos Brutos

Decidir onde guardar os arquivos originais.

Opcoes:

- pasta local `data/raw`;
- storage do Supabase;
- storage externo;
- nao armazenar, apenas registrar fonte e data de obtencao.

### Reprocessamento

Decidir como recarregar dados.

Opcoes:

- apagar e recarregar tudo;
- usar staging;
- usar upsert;
- versionar cargas.

## Dados

### Arquivos Exatos do TSE

Confirmar quais arquivos serao usados para:

- candidatos;
- votacao por municipio;
- votacao por secao;
- prestacao de contas;
- partidos.

### Chave de Candidato

Definir como relacionar candidatos entre bases.

Opcoes:

- identificador oficial do TSE;
- combinacao de ano, cargo, UF, numero e partido;
- outra chave composta.

### Documentos de Fornecedores ou Doadores

Definir se documentos serao:

- armazenados completos;
- mascarados;
- omitidos;
- mantidos apenas em tabela restrita.

## Regioes

### Importacao da Planilha

Decidir como a planilha `cidade | regiao` sera importada.

Opcoes:

- upload manual no Supabase;
- script de importacao;
- arquivo versionado no repositorio;
- planilha externa como fonte.

### Normalizacao de Cidades

Definir como lidar com divergencias de nomes.

Opcoes:

- normalizar nomes automaticamente;
- criar tabela de equivalencias;
- corrigir a planilha manualmente;
- usar codigo IBGE ou TSE na planilha.

## MCPs

### Papel no MVP

Decidir se o MVP tera MCP proprio.

Opcoes:

- nao usar MCP no MVP;
- usar `mcp-brasil` apenas como referencia/apoio;
- criar MCP proprio para consultar Supabase;
- criar MCP proprio depois do dashboard.

### Ferramentas Possiveis

Ferramentas futuras:

- `listar_candidatos`;
- `ranking_candidatos`;
- `ranking_partidos`;
- `buscar_candidato`;
- `forca_por_regiao`;
- `custo_por_voto`;
- `comparar_candidatos`;
- `comparar_partidos`.

## Priorizacao

Sequencia recomendada:

1. Confirmar arquivos do TSE.
2. Definir modelo de dados final.
3. Definir stack do dashboard.
4. Definir estrategia de ingestao.
5. Definir estrategia de seguranca/acesso.
6. Decidir papel dos MCPs no MVP.

Plano faseado detalhado:

```text
docs/plano-implementacao.md
```
