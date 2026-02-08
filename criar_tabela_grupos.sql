-- ================================================================
-- Script SQL para criar tabela de GRUPOS
-- PostgreSQL / Supabase
-- ================================================================

-- Tabela de grupos/categorias
CREATE TABLE IF NOT EXISTS grupos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    descricao TEXT,
    cor VARCHAR(7),
    ordem INT DEFAULT 0,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ativo BOOLEAN DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_grupos_nome ON grupos(nome);
CREATE INDEX IF NOT EXISTS idx_grupos_ordem ON grupos(ordem);
CREATE INDEX IF NOT EXISTS idx_grupos_ativo ON grupos(ativo);

-- Adicionar coluna grupo_id na tabela itens
ALTER TABLE itens 
ADD COLUMN IF NOT EXISTS grupo_id INT REFERENCES grupos(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_itens_grupo_id ON itens(grupo_id);

-- View para listar itens com nome do grupo
CREATE OR REPLACE VIEW itens_com_grupo AS
SELECT 
    i.id,
    i.lista_id,
    i.nome,
    i.quantidade_total,
    i.unidade_medida,
    i.data_criacao,
    i.ativo,
    g.id AS grupo_id,
    g.nome AS grupo_nome,
    g.cor AS grupo_cor,
    g.ordem AS grupo_ordem
FROM itens i
LEFT JOIN grupos g ON i.grupo_id = g.id
WHERE i.ativo = TRUE
ORDER BY g.ordem, g.nome, i.nome;

-- View de progresso por grupo
CREATE OR REPLACE VIEW progresso_por_grupo AS
SELECT 
    g.id AS grupo_id,
    g.nome AS grupo_nome,
    g.ordem AS grupo_ordem,
    COUNT(DISTINCT i.id) AS total_itens,
    SUM(i.quantidade_total) AS quantidade_total,
    COALESCE(SUM(iu.quantidade_pegada), 0) AS quantidade_pegada,
    ROUND(
        (COALESCE(SUM(iu.quantidade_pegada), 0) / NULLIF(SUM(i.quantidade_total), 0)) * 100, 
        2
    ) AS percentual_completo
FROM grupos g
LEFT JOIN itens i ON g.id = i.grupo_id AND i.ativo = TRUE
LEFT JOIN itens_usuarios iu ON i.id = iu.item_id
WHERE g.ativo = TRUE
GROUP BY g.id, g.nome, g.ordem
ORDER BY g.ordem, g.nome;

COMMENT ON TABLE grupos IS 'Grupos/categorias para organizar os itens da lista (Mercado, Açougue, Hortifruti, etc)';
