# Plano de Ingestao

## Objetivo

Este documento descreve o processo planejado para carregar dados no Supabase.

Nao e um script de execucao. E uma especificacao para implementacao futura.

## Ordem Recomendada

1. Importar regioes proprias.
2. Importar municipios de Santa Catarina.
3. Associar municipios as regioes.
4. Importar partidos.
5. Importar candidatos.
6. Importar votacao por municipio.
7. Importar votacao por secao/urna.
8. Importar prestacao de contas.
9. Criar ou atualizar views analiticas.
10. Validar totais e relacionamentos.

## Entrada: Planilha de Regioes

Formato informado:

```text
cidade | regiao
```

Tratamentos necessarios:

- remover espacos extras;
- padronizar maiusculas/minusculas;
- normalizar acentos, se necessario;
- conferir duplicidades;
- verificar cidades sem regiao;
- verificar regioes vazias;
- reconciliar nomes com municipios oficiais.

Saida esperada:

- `regioes_sc`;
- `municipios_sc.regiao_id`.

## Entrada: Candidatos

Tratamentos necessarios:

- filtrar ano 2022;
- filtrar UF SC;
- filtrar cargos deputado estadual e deputado federal;
- normalizar nome de cargo;
- normalizar sigla de partido;
- preservar identificador oficial quando existir;
- evitar armazenar CPF bruto.

Saida esperada:

- `partidos`;
- `candidatos`.

## Entrada: Votacao por Municipio

Tratamentos necessarios:

- filtrar ano 2022;
- filtrar UF SC;
- filtrar cargos do escopo;
- associar municipio por codigo TSE;
- associar candidato por identificador, numero/cargo/partido ou regra definida;
- validar votos como inteiros.

Saida esperada:

- `votacao_municipio`.

Validacoes:

- total por candidato deve bater com total oficial esperado;
- municipios sem regiao devem ser listados;
- candidatos sem cadastro devem ser listados.

## Entrada: Votacao por Secao/Urna

Tratamentos necessarios:

- filtrar ano 2022;
- filtrar UF SC;
- filtrar cargos do escopo;
- associar municipio por codigo TSE;
- manter zona e secao;
- associar candidato;
- tratar local de votacao como opcional.

Saida esperada:

- `votacao_secao`.

Validacoes:

- soma por municipio deve ser comparada com `votacao_municipio`;
- secoes sem votos devem ser avaliadas;
- divergencias devem ser registradas.

## Entrada: Prestacao de Contas

Tratamentos necessarios:

- filtrar ano 2022;
- filtrar UF SC;
- filtrar cargos do escopo;
- separar receitas e despesas;
- converter valores para decimal;
- associar lancamentos a candidatos;
- classificar categorias de despesa;
- decidir tratamento de documentos de fornecedores/doadores.

Saida esperada:

- `prestacao_contas`.

Validacoes:

- total de despesas por candidato deve ser auditavel;
- candidatos sem despesa devem permanecer na analise;
- lancamentos sem candidato correspondente devem ser registrados.

## Estrategia de Reprocessamento

O processo deve permitir recarregar dados sem duplicar registros.

Opcoes:

- apagar e recarregar tabelas de staging;
- usar chaves unicas e upsert;
- manter arquivos brutos versionados;
- registrar data de carga.

Decisao pendente:

- escolher a estrategia antes da implementacao.

## Tabelas de Auditoria Sugeridas

### import_logs

Finalidade:

- registrar quando uma carga ocorreu.

Campos possiveis:

```text
id
fonte
arquivo
status
linhas_lidas
linhas_importadas
linhas_com_erro
mensagem
created_at
```

### import_erros

Finalidade:

- registrar problemas de compatibilidade.

Campos possiveis:

```text
id
fonte
linha_origem
tipo_erro
descricao
dados_originais
created_at
```

## Regras de Qualidade

- Nenhuma cidade de SC com votos deve ficar sem regiao.
- Nenhum candidato com votos deve ficar fora de `candidatos`.
- Valores financeiros devem ser convertidos sem perda de precisao.
- Totais devem ser comparados antes de considerar carga concluida.
- Dados problematicos devem ser registrados, nao descartados silenciosamente.

## Decisoes Pendentes

- Ferramenta de ingestao.
- Formato de staging.
- Local dos arquivos brutos.
- Politica de sobrescrita.
- Campos exatos usados para associar candidatos entre bases.
