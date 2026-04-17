# Metodologia

## Objetivo

Este documento define cuidados metodologicos para evitar leituras incorretas dos dados eleitorais e financeiros.

## Natureza da Analise

O projeto sera descritivo e exploratorio.

Ele deve responder perguntas como:

- quem teve mais votos;
- onde teve mais votos;
- qual partido foi mais forte em cada regiao;
- qual candidato teve melhor custo por voto;
- quais votos foram mais concentrados territorialmente.

O projeto nao deve afirmar causalidade sem evidencia adicional.

## Voto por Municipio

Analise por municipio permite:

- comparar cidades;
- agregar por regiao propria;
- identificar bases territoriais;
- calcular rankings locais;
- medir concentracao dos votos.

Limitacoes:

- nao mostra variacao dentro da cidade;
- pode esconder concentracoes em bairros ou locais de votacao.

## Voto por Urna/Secao

Analise por urna/secao permite:

- detalhar o comportamento dentro de municipios;
- identificar concentracoes muito localizadas;
- investigar diferencas entre zonas e locais de votacao.

Limitacoes:

- secao eleitoral nao e equivalente direta a bairro;
- eleitores podem votar em locais que nao representam exatamente sua residencia;
- mudancas de secao podem dificultar comparacoes futuras;
- dados granulares exigem mais cuidado de performance no banco e dashboard.

## Gasto Declarado

Prestacao de contas informa gastos declarados por candidatos, partidos ou campanhas conforme regras eleitorais.

O dado deve ser interpretado como:

- despesa declarada;
- registro financeiro da campanha;
- base para custo medio por voto.

O dado nao deve ser interpretado automaticamente como:

- gasto aplicado em uma cidade especifica;
- gasto aplicado em uma regiao especifica;
- causa direta do voto obtido.

## Custo por Voto

Formula principal:

```text
custo_por_voto = total_despesas_declaradas / total_votos
```

Interpretacao correta:

- indicador medio de eficiencia financeira da campanha;
- permite comparar candidatos no mesmo cargo e eleicao;
- ajuda a identificar campanhas com alto gasto e baixo retorno ou baixo gasto e alto retorno.

Cuidados:

- candidatos com poucos votos podem ter custo por voto extremo;
- despesas podem ser retificadas;
- nem toda despesa tem impacto eleitoral direto;
- comparacoes devem considerar cargo, partido e contexto.

## Forca Regional

Forca regional sera medida pela votacao em regioes proprias definidas pelo usuario.

Indicadores possiveis:

- votos totais na regiao;
- share regional;
- ranking regional;
- dependencia regional;
- presenca em cidades da regiao.

Interpretacao:

- candidato forte em uma regiao e aquele com alta votacao, alto share ou boa posicao no ranking regional.

Cuidados:

- regioes com mais eleitores tendem a gerar mais votos absolutos;
- share regional pode ser mais comparavel que voto absoluto;
- ranking regional deve ser calculado separadamente por cargo.

## Comparacao entre Cargos

Deputado estadual e deputado federal devem ser analisados separadamente.

Comparacoes entre os cargos podem ser uteis para:

- ver alinhamento de partidos;
- comparar bases territoriais;
- identificar regioes em que o partido e forte em um cargo e fraco em outro.

Cuidados:

- candidaturas, numero de concorrentes e dinamica de voto sao diferentes;
- nao assumir que votos de deputado estadual transferem para deputado federal;
- sempre explicitar o cargo comparado.

## Candidatos com Baixa Votacao

Candidatos com poucos votos podem distorcer rankings de custo, concentracao e dependencia regional.

Possiveis regras de analise:

- mostrar todos os candidatos por padrao;
- permitir filtro por minimo de votos;
- destacar rankings gerais com candidatos acima de um limiar minimo;
- manter candidatos de baixa votacao acessiveis para auditoria.

## Dados Ausentes e Divergentes

Possiveis problemas:

- cidade da planilha nao encontrada no TSE;
- candidato sem prestacao de contas associada;
- candidato com votos mas sem cadastro correspondente;
- despesa sem candidato correspondente;
- divergencia de nome entre fontes.

Tratamento recomendado:

- registrar divergencias;
- nao descartar dados silenciosamente;
- criar tabela ou relatorio de pendencias;
- validar amostras manualmente.

## Linguagem dos Resultados

Usar termos como:

- "teve maior votacao";
- "apresentou maior share";
- "teve melhor custo por voto";
- "concentrou mais votos";
- "foi mais forte no recorte analisado".

Evitar termos como:

- "comprou votos";
- "gastou nessa cidade";
- "o gasto causou a votacao";
- "dominou eleitoralmente" sem criterio definido.
