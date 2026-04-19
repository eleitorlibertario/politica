-- 006_analise_eleitos.sql
-- Análise comparativa entre candidatos eleitos e não eleitos por partido
-- SC 2022 — Deputado Estadual e Federal

-- ─────────────────────────────────────────────────────────────────────────────
-- 1) SHARE DE VOTOS NOS ELEITOS POR PARTIDO
--    Mostra quantos votos do partido foram para quem se elegeu vs. total.
--    Referência: ILIKE 'ELEITO%' captura "ELEITO POR QP" e "ELEITO POR MÉDIA"
--    sem pegar "NÃO ELEITO".
-- ─────────────────────────────────────────────────────────────────────────────
WITH votos_cand AS (
    SELECT
        c.id,
        c.sigla_partido       AS partido,
        c.cargo,
        c.situacao_totalizacao,
        SUM(vm.votos)::bigint AS total_votos
    FROM candidatos c
    JOIN votacao_municipio vm ON vm.candidato_id = c.id
    GROUP BY c.id, c.sigla_partido, c.cargo, c.situacao_totalizacao
)
SELECT
    partido,
    cargo,
    COUNT(DISTINCT id)                                                              AS total_candidatos,
    COUNT(DISTINCT CASE WHEN situacao_totalizacao ILIKE 'ELEITO%' THEN id END)     AS candidatos_eleitos,
    SUM(total_votos)                                                                AS votos_total,
    SUM(CASE WHEN situacao_totalizacao ILIKE 'ELEITO%' THEN total_votos ELSE 0 END) AS votos_eleitos,
    ROUND(
        SUM(CASE WHEN situacao_totalizacao ILIKE 'ELEITO%' THEN total_votos ELSE 0 END)::numeric
        / NULLIF(SUM(total_votos), 0) * 100, 1
    )                                                                               AS pct_votos_eleitos
FROM votos_cand
GROUP BY partido, cargo
ORDER BY cargo, votos_total DESC;

-- Destaques SC 2022:
-- PL Estadual:  77,5% dos votos concentrados nos 11 eleitos (40 candidatos)
-- PL Federal:   82,6% nos 6 eleitos (15 candidatos) — maior concentração
-- CIDADANIA Federal: 95,7% — candidatura quase monocandidata (Ana Paula Lima)
-- NOVO Estadual: 9,7% — 31 candidatos, 1 eleito, votos extremamente pulverizados
-- UNIÃO: muitos candidatos, votos espalhados — lista ampla sem estrelas


-- ─────────────────────────────────────────────────────────────────────────────
-- 2) DIFERENÇA MÉDIA DE CUSTO/VOTO: ELEITOS vs. NÃO ELEITOS POR PARTIDO
--    Diferença positiva = não eleitos gastaram mais por voto (ineficientes)
--    Diferença negativa = eleitos gastaram mais por voto (pagaram caro pela vaga)
-- ─────────────────────────────────────────────────────────────────────────────
WITH votos_cand AS (
    SELECT candidato_id, SUM(votos)::bigint AS total_votos
    FROM votacao_municipio
    GROUP BY candidato_id
),
despesas_cand AS (
    SELECT
        candidato_id,
        SUM(CASE WHEN UPPER(tipo_lancamento) LIKE '%DESP%' THEN valor ELSE 0 END)::numeric(16,2)
            AS total_despesas
    FROM prestacao_contas
    WHERE candidato_id IS NOT NULL AND valor > 0
    GROUP BY candidato_id
),
custo AS (
    SELECT
        c.sigla_partido                                      AS partido,
        c.cargo,
        CASE WHEN c.situacao_totalizacao ILIKE 'ELEITO%'
             THEN 'Eleito' ELSE 'Não Eleito' END            AS status,
        CASE WHEN COALESCE(v.total_votos, 0) > 0
             THEN ROUND(COALESCE(d.total_despesas, 0) / v.total_votos, 2)
        END                                                  AS custo_por_voto
    FROM candidatos c
    LEFT JOIN votos_cand    v ON v.candidato_id = c.id
    LEFT JOIN despesas_cand d ON d.candidato_id = c.id
    WHERE COALESCE(v.total_votos, 0) > 0
      AND COALESCE(d.total_despesas, 0) > 0
)
SELECT
    partido,
    cargo,
    ROUND(AVG(CASE WHEN status = 'Eleito'     THEN custo_por_voto END), 2) AS custo_medio_eleitos,
    ROUND(AVG(CASE WHEN status = 'Não Eleito' THEN custo_por_voto END), 2) AS custo_medio_nao_eleitos,
    ROUND(
        AVG(CASE WHEN status = 'Não Eleito' THEN custo_por_voto END) -
        AVG(CASE WHEN status = 'Eleito'     THEN custo_por_voto END),
    2)                                                                      AS diferenca_custo_por_voto
FROM custo
GROUP BY partido, cargo
HAVING COUNT(CASE WHEN status = 'Eleito' THEN 1 END) > 0
ORDER BY cargo, diferenca_custo_por_voto DESC NULLS LAST;

-- Destaques SC 2022:
-- PSDB Estadual: eleitos R$14/voto vs. não eleitos R$174/voto (+R$159 de diferença)
-- PT e PL:       diferenças pequenas — base orgânica, não eleitos também gastam pouco
-- PTB Estadual:  único partido com diferença negativa (-R$2) — eleito gastou mais que não eleitos
-- PSD Federal:   custo_medio_eleitos de R$19.274/voto é anomalia — investigar candidato específico
