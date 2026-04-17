# Plano de Implementacao

## Objetivo

Este documento descreve uma sequencia faseada para implementar o projeto.

Ele nao executa nenhuma acao e nao substitui os documentos tecnicos detalhados. Serve como guia de prioridades, entregaveis e criterios de aceite.

## Principios de Implementacao

- Comecar pelo menor recorte que gere analise real.
- Validar dados antes de construir visualizacoes complexas.
- Separar ingestao, modelo de dados, metricas e dashboard.
- Manter rastreabilidade entre dado bruto, dado tratado e metrica.
- Evitar automacao prematura.
- Priorizar perguntas analiticas sobre acabamento visual no MVP.

## Fase 0: Preparacao Documental

Status:

- em andamento.

Objetivo:

- consolidar escopo, decisoes e plano antes de implementar.

Entregaveis:

- especificacao geral;
- arquitetura;
- fontes de dados;
- modelo de dados;
- metricas;
- metodologia;
- dashboard;
- ingestao;
- perguntas analiticas;
- decisoes pendentes;
- recomendacao de stack;
- plano de implementacao.

Criterios de aceite:

- escopo inicial documentado;
- decisoes tomadas registradas;
- decisoes pendentes visiveis;
- fase de MVP definida.

## Fase 1: Confirmacao das Fontes do TSE

Objetivo:

- identificar exatamente quais arquivos do TSE serao usados.

Atividades:

- localizar base de candidatos de 2022;
- localizar base de votacao por municipio de 2022;
- localizar base de votacao por secao/urna de 2022;
- localizar base de prestacao de contas de 2022;
- confirmar campos disponiveis;
- confirmar chaves de relacionamento entre bases.

Entregaveis:

- lista dos arquivos oficiais;
- dicionario preliminar de campos;
- observacoes sobre campos ausentes ou problematicos;
- decisao sobre chave de candidato.

Criterios de aceite:

- cada tabela planejada tem fonte identificada;
- votacao e prestacao de contas podem ser relacionadas a candidatos;
- municipios podem ser relacionados a codigos oficiais.

Riscos:

- nomes ou identificadores de candidatos divergentes entre bases;
- campos de secao/urna diferentes do esperado;
- necessidade de tratar arquivos grandes.

## Fase 2: Preparacao da Planilha de Regioes

Objetivo:

- transformar a planilha `cidade | regiao` em referencia confiavel para agregacoes.

Atividades:

- validar se todas as cidades possuem regiao;
- verificar duplicidades;
- padronizar nomes de cidades;
- mapear cidades para codigos TSE e/ou IBGE;
- registrar divergencias.

Entregaveis:

- lista final de regioes;
- tabela de municipios com regiao;
- lista de cidades com divergencia de nome;
- regra de normalizacao documentada.

Criterios de aceite:

- todos os municipios de SC usados na votacao possuem regiao;
- nenhuma cidade da planilha fica sem correspondencia sem justificativa;
- divergencias ficam documentadas.

## Fase 3: Modelo de Dados Final

Objetivo:

- transformar o modelo conceitual em estrutura pronta para criacao no Supabase.

Atividades:

- definir tipos SQL;
- definir chaves primarias;
- definir chaves estrangeiras;
- definir chaves unicas;
- definir indices;
- decidir tratamento de documentos sensiveis;
- definir tabelas de auditoria de importacao.

Entregaveis:

- schema SQL documentado;
- dicionario de dados;
- regras de integridade;
- plano de indices.

Criterios de aceite:

- todas as tabelas possuem campos e tipos definidos;
- relacionamentos estao claros;
- campos sensiveis tem regra de tratamento;
- modelo suporta as perguntas do MVP.

## Fase 4: Ingestao Inicial

Objetivo:

- carregar os dados essenciais no Supabase.

Atividades:

- carregar regioes;
- carregar municipios;
- carregar partidos;
- carregar candidatos;
- carregar votacao por municipio;
- carregar prestacao de contas;
- carregar votacao por secao/urna, se o volume e o formato estiverem controlados.

Entregaveis:

- tabelas populadas no Supabase;
- log de importacao;
- relatorio de erros;
- amostras validadas.

Criterios de aceite:

- candidatos dos cargos definidos estao carregados;
- votos por municipio estao carregados;
- despesas declaradas estao carregadas;
- todas as cidades votadas possuem regiao;
- totais principais batem com fonte oficial ou divergencias estao explicadas.

## Fase 5: Views e Metricas

Objetivo:

- criar a camada analitica usada pelo dashboard.

Atividades:

- consolidar votos por candidato;
- consolidar votos por partido;
- consolidar votos por regiao;
- consolidar despesas por candidato;
- calcular custo por voto;
- calcular rankings;
- calcular concentracao territorial;
- calcular presenca territorial.

Entregaveis:

- views analiticas;
- queries de validacao;
- documentacao das formulas aplicadas.

Criterios de aceite:

- custo por voto esta calculado por candidato;
- rankings regionais funcionam por cargo;
- rankings municipais funcionam por cargo;
- partidos podem ser comparados por regiao;
- metricas batem com definicoes em `metricas.md`.

## Fase 6: Dashboard MVP em Metabase

Objetivo:

- criar uma interface analitica inicial.

Atividades:

- conectar Metabase ao Postgres/Supabase;
- criar perguntas/cards principais;
- criar filtros globais;
- montar dashboards por tema;
- validar respostas contra queries SQL.

Entregaveis:

- dashboard de visao geral;
- dashboard de candidatos;
- dashboard de partidos;
- dashboard de regioes;
- dashboard de cidades;
- dashboard de custo por voto.

Criterios de aceite:

- filtros por cargo, partido, candidato, cidade e regiao funcionam;
- rankings principais estao disponiveis;
- custo por voto aparece com aviso metodologico;
- e possivel identificar os mais fortes por regiao;
- e possivel comparar partidos por regiao.

## Fase 7: Analise Exploratória

Objetivo:

- usar o dashboard e SQL para descobrir padroes.

Atividades:

- responder perguntas do MVP;
- registrar achados;
- identificar metricas que precisam ajuste;
- encontrar lacunas nos dados;
- priorizar novas visualizacoes.

Entregaveis:

- notas de analise;
- lista de descobertas;
- lista de perguntas novas;
- melhorias propostas para dashboard.

Criterios de aceite:

- pelo menos as perguntas prioritarias do MVP foram respondidas;
- principais candidatos e partidos por regiao foram identificados;
- custo por voto foi analisado por cargo;
- concentracao territorial foi avaliada.

## Fase 8: Evolucao

Objetivo:

- evoluir o projeto apos o MVP.

Possibilidades:

- adicionar dashboard customizado em Next.js;
- criar MCP proprio para consultar o Supabase;
- adicionar novos anos eleitorais;
- adicionar outros cargos;
- adicionar dados demograficos ou socioeconomicos;
- automatizar ingestao;
- criar relatorios periodicos.

Critério para avancar:

- o MVP em Metabase revelou limitacoes claras ou novas necessidades analiticas.

## MVP Recomendado

O MVP deve incluir:

- dados de candidatos;
- dados de votacao por municipio;
- dados de prestacao de contas;
- planilha de regioes importada;
- views de custo por voto;
- views de forca regional;
- dashboard Metabase com filtros e rankings.

Votacao por urna/secao pode entrar no MVP se o volume e a ingestao forem simples. Caso contrario, deve ser fase 1.1 apos o MVP municipal/regional.

## Fora do MVP

- app customizado em Next.js;
- MCP proprio;
- autenticacao sofisticada;
- analise de outros anos;
- analise de outros estados;
- modelos estatisticos avancados;
- inferencia causal sobre efeito de gasto.

## Sequencia Recomendada

1. Fechar fontes exatas do TSE.
2. Validar planilha de regioes.
3. Definir schema final.
4. Carregar candidatos, municipios e regioes.
5. Carregar votacao por municipio.
6. Carregar prestacao de contas.
7. Criar views analiticas.
8. Criar dashboard Metabase.
9. Validar perguntas do MVP.
10. Decidir se entra votacao por secao/urna no ciclo seguinte.
