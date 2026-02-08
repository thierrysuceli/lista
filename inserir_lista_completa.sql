-- ================================================================
-- Script SQL para INSERIR ITENS da lista do Carnaval
-- PostgreSQL / Supabase
-- 
-- IMPORTANTE: Execute primeiro o arquivo criar_tabela_grupos.sql
-- ================================================================

-- Inserir grupos
INSERT INTO grupos (nome, descricao, cor, ordem) VALUES
('Mercado', 'Produtos de supermercado', '#f9d976', 1),
('Açougue', 'Carnes e produtos do açougue', '#d4a574', 2),
('Hortifruti', 'Frutas, verduras e legumes', '#a8d08d', 3)
ON CONFLICT (nome) DO NOTHING;

-- Obter IDs dos grupos
DO $$
DECLARE
    v_lista_id INT;
    v_grupo_mercado_id INT;
    v_grupo_acougue_id INT;
    v_grupo_hortifruti_id INT;
BEGIN
    -- Obter ID da lista "Carnaval do Apostolado Seja Santo"
    SELECT id INTO v_lista_id FROM listas WHERE nome = 'Carnaval do Apostolado Seja Santo' LIMIT 1;
    
    -- Se não existir, criar
    IF v_lista_id IS NULL THEN
        INSERT INTO listas (nome, descricao) 
        VALUES ('Carnaval do Apostolado Seja Santo', 'Lista de compras para o evento do Carnaval')
        RETURNING id INTO v_lista_id;
    END IF;
    
    -- Obter IDs dos grupos
    SELECT id INTO v_grupo_mercado_id FROM grupos WHERE nome = 'Mercado' LIMIT 1;
    SELECT id INTO v_grupo_acougue_id FROM grupos WHERE nome = 'Açougue' LIMIT 1;
    SELECT id INTO v_grupo_hortifruti_id FROM grupos WHERE nome = 'Hortifruti' LIMIT 1;
    
    -- ================================================================
    -- INSERIR ITENS - MERCADO
    -- ================================================================
    INSERT INTO itens (lista_id, grupo_id, nome, quantidade_total, unidade_medida) VALUES
    (v_lista_id, v_grupo_mercado_id, 'Arroz', 8, 'kg'),
    (v_lista_id, v_grupo_mercado_id, 'Feijão', 3, 'kg'),
    (v_lista_id, v_grupo_mercado_id, 'Macarrão', 4, 'kg'),
    (v_lista_id, v_grupo_mercado_id, 'Molho de tomate', 6, 'l'),
    (v_lista_id, v_grupo_mercado_id, 'Batata palha', 2, 'kg'),
    (v_lista_id, v_grupo_mercado_id, 'Farofa pronta', 2, 'kg'),
    (v_lista_id, v_grupo_mercado_id, 'Açúcar', 2, 'kg'),
    (v_lista_id, v_grupo_mercado_id, 'Óleo', 2, 'l'),
    (v_lista_id, v_grupo_mercado_id, 'Azeite', 1, 'l'),
    (v_lista_id, v_grupo_mercado_id, 'Sal', 1, 'kg'),
    (v_lista_id, v_grupo_mercado_id, 'Temperos diversos', 1, 'un'),
    (v_lista_id, v_grupo_mercado_id, 'Suco', 15, 'l'),
    (v_lista_id, v_grupo_mercado_id, 'Refrigerante', 12, 'l'),
    (v_lista_id, v_grupo_mercado_id, 'Café', 1.5, 'kg'),
    (v_lista_id, v_grupo_mercado_id, 'Chá', 2, 'cx'),
    (v_lista_id, v_grupo_mercado_id, 'Leite', 15, 'l'),
    (v_lista_id, v_grupo_mercado_id, 'Manteiga', 2, 'kg'),
    (v_lista_id, v_grupo_mercado_id, 'Queijo', 3, 'kg'),
    (v_lista_id, v_grupo_mercado_id, 'Presunto', 2, 'kg'),
    (v_lista_id, v_grupo_mercado_id, 'Pão de queijo', 4, 'kg'),
    (v_lista_id, v_grupo_mercado_id, 'Pão de forma', 6, 'pct'),
    (v_lista_id, v_grupo_mercado_id, 'Ovos', 15, 'dúzias'),
    (v_lista_id, v_grupo_mercado_id, 'Frutas variadas', 10, 'kg'),
    (v_lista_id, v_grupo_mercado_id, 'Ingredientes para bolo simples (2 bolos)', 1, 'un');
    
    -- ================================================================
    -- INSERIR ITENS - AÇOUGUE
    -- ================================================================
    INSERT INTO itens (lista_id, grupo_id, nome, quantidade_total, unidade_medida) VALUES
    (v_lista_id, v_grupo_acougue_id, 'Frango para empadão', 4, 'kg'),
    (v_lista_id, v_grupo_acougue_id, 'Frango para strogonoff', 3, 'kg'),
    (v_lista_id, v_grupo_acougue_id, 'Carne bovina para strogonoff', 3, 'kg'),
    (v_lista_id, v_grupo_acougue_id, 'Filé mignon', 4, 'kg'),
    (v_lista_id, v_grupo_acougue_id, 'Carnes para churrasco', 12, 'kg'),
    (v_lista_id, v_grupo_acougue_id, 'Bife de carne bovina', 4, 'kg'),
    (v_lista_id, v_grupo_acougue_id, 'Pão de alho', 20, 'un');
    
    -- ================================================================
    -- INSERIR ITENS - HORTIFRUTI
    -- ================================================================
    INSERT INTO itens (lista_id, grupo_id, nome, quantidade_total, unidade_medida) VALUES
    (v_lista_id, v_grupo_hortifruti_id, 'Alface', 10, 'pés'),
    (v_lista_id, v_grupo_hortifruti_id, 'Tomate', 5, 'kg'),
    (v_lista_id, v_grupo_hortifruti_id, 'Cebola', 3, 'kg'),
    (v_lista_id, v_grupo_hortifruti_id, 'Cenoura', 3, 'kg'),
    (v_lista_id, v_grupo_hortifruti_id, 'Cheiro-verde', 6, 'maços'),
    (v_lista_id, v_grupo_hortifruti_id, 'Outras folhas verdes', 4, 'maços');
    
    RAISE NOTICE 'Lista completa inserida com sucesso!';
    RAISE NOTICE 'Lista ID: %', v_lista_id;
    RAISE NOTICE 'Total de itens: %', (SELECT COUNT(*) FROM itens WHERE lista_id = v_lista_id);
END $$;

-- ================================================================
-- Consulta para verificar os itens inseridos
-- ================================================================
SELECT 
    g.nome AS grupo,
    i.nome AS item,
    i.quantidade_total,
    i.unidade_medida
FROM itens i
JOIN grupos g ON i.grupo_id = g.id
WHERE i.lista_id = (SELECT id FROM listas WHERE nome = 'Carnaval do Apostolado Seja Santo' LIMIT 1)
ORDER BY g.ordem, i.nome;
