-- ================================================================
-- Script SQL para Sistema de Gerenciamento de Lista de Compras
-- Nome da Lista: Carnaval do Apostolado Seja Santo
-- PostgreSQL / Supabase
-- 
-- Conexão:
-- URL: https://oducerahpqqqeeycyadg.supabase.co
-- Secret: sb_secret_11xlfC2o-g1GXJiFr_gOHg_stEAwmTd
-- ================================================================

-- PostgreSQL não precisa criar/usar database (já está conectado)

-- ================================================================
-- Tabela: listas
-- Armazena informações sobre as listas de compras
-- ================================================================
CREATE TABLE IF NOT EXISTS listas (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    descricao TEXT,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ativa BOOLEAN DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_listas_ativa ON listas(ativa);
CREATE INDEX IF NOT EXISTS idx_listas_data_criacao ON listas(data_criacao);

-- ================================================================
-- Tabela: itens
-- Armazena os itens da lista de compras
-- ================================================================
CREATE TABLE IF NOT EXISTS itens (
    id SERIAL PRIMARY KEY,
    lista_id INT NOT NULL,
    nome VARCHAR(255) NOT NULL,
    quantidade_total DECIMAL(10, 2) NOT NULL,
    unidade_medida VARCHAR(50) NOT NULL,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ativo BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (lista_id) REFERENCES listas(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_itens_lista_id ON itens(lista_id);
CREATE INDEX IF NOT EXISTS idx_itens_ativo ON itens(ativo);
CREATE INDEX IF NOT EXISTS idx_itens_nome ON itens(nome);

-- ================================================================
-- Tabela: usuarios
-- Armazena os usuários que pegam itens
-- ================================================================
CREATE TABLE IF NOT EXISTS usuarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    telefone VARCHAR(20),
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ativo BOOLEAN DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_usuarios_nome ON usuarios(nome);
CREATE INDEX IF NOT EXISTS idx_usuarios_email ON usuarios(email);
CREATE INDEX IF NOT EXISTS idx_usuarios_ativo ON usuarios(ativo);

-- ================================================================
-- Tabela: itens_usuarios
-- Relacionamento entre itens e usuários (quem pegou o quê)
-- ================================================================
CREATE TABLE IF NOT EXISTS itens_usuarios (
    id SERIAL PRIMARY KEY,
    item_id INT NOT NULL,
    usuario_id INT NOT NULL,
    quantidade_pegada DECIMAL(10, 2) NOT NULL,
    data_retirada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observacao TEXT,
    FOREIGN KEY (item_id) REFERENCES itens(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_itens_usuarios_item_id ON itens_usuarios(item_id);
CREATE INDEX IF NOT EXISTS idx_itens_usuarios_usuario_id ON itens_usuarios(usuario_id);
CREATE INDEX IF NOT EXISTS idx_itens_usuarios_data_retirada ON itens_usuarios(data_retirada);

-- ================================================================
-- Trigger para atualizar data_atualizacao automaticamente
-- ================================================================
CREATE OR REPLACE FUNCTION atualizar_data_atualizacao()
RETURNS TRIGGER AS $$
BEGIN
    NEW.data_atualizacao = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_atualizar_listas
BEFORE UPDATE ON listas
FOR EACH ROW
EXECUTE FUNCTION atualizar_data_atualizacao();

CREATE TRIGGER trigger_atualizar_itens
BEFORE UPDATE ON itens
FOR EACH ROW
EXECUTE FUNCTION atualizar_data_atualizacao();

-- ================================================================
-- VIEW: progresso_itens
-- Calcula o progresso de cada item
-- ================================================================
CREATE OR REPLACE VIEW progresso_itens AS
SELECT 
    i.id AS item_id,
    i.lista_id,
    i.nome AS item_nome,
    i.quantidade_total,
    i.unidade_medida,
    COALESCE(SUM(iu.quantidade_pegada), 0) AS quantidade_pegada,
    i.quantidade_total - COALESCE(SUM(iu.quantidade_pegada), 0) AS quantidade_restante,
    ROUND((COALESCE(SUM(iu.quantidade_pegada), 0) / i.quantidade_total) * 100, 2) AS percentual_completo
FROM 
    itens i
LEFT JOIN 
    itens_usuarios iu ON i.id = iu.item_id
WHERE 
    i.ativo = TRUE
GROUP BY 
    i.id, i.lista_id, i.nome, i.quantidade_total, i.unidade_medida;

-- ================================================================
-- VIEW: progresso_listas
-- Calcula o progresso geral de cada lista
-- ================================================================
CREATE OR REPLACE VIEW progresso_listas AS
SELECT 
    l.id AS lista_id,
    l.nome AS lista_nome,
    COUNT(DISTINCT i.id) AS total_itens,
    SUM(i.quantidade_total) AS quantidade_total_lista,
    COALESCE(SUM(iu.quantidade_pegada), 0) AS quantidade_pegada_lista,
    ROUND((COALESCE(SUM(iu.quantidade_pegada), 0) / SUM(i.quantidade_total)) * 100, 2) AS percentual_completo
FROM 
    listas l
LEFT JOIN 
    itens i ON l.id = i.lista_id AND i.ativo = TRUE
LEFT JOIN 
    itens_usuarios iu ON i.id = iu.item_id
WHERE 
    l.ativa = TRUE
GROUP BY 
    l.id, l.nome;

-- ================================================================
-- VIEW: usuarios_por_item
-- Mostra todos os usuários que pegaram cada item
-- ================================================================
CREATE OR REPLACE VIEW usuarios_por_item AS
SELECT 
    i.id AS item_id,
    i.nome AS item_nome,
    i.unidade_medida,
    u.id AS usuario_id,
    u.nome AS usuario_nome,
    iu.quantidade_pegada,
    iu.data_retirada,
    iu.observacao
FROM 
    itens i
INNER JOIN 
    itens_usuarios iu ON i.id = iu.item_id
INNER JOIN 
    usuarios u ON iu.usuario_id = u.id
WHERE 
    i.ativo = TRUE AND u.ativo = TRUE
ORDER BY 
    i.nome, iu.data_retirada;

-- ================================================================
-- STORED PROCEDURE: inserir_lista
-- Insere uma nova lista de compras
-- ================================================================
CREATE OR REPLACE FUNCTION inserir_lista(
    p_nome VARCHAR(255),
    p_descricao TEXT
)
RETURNS INT AS $$
DECLARE
    v_lista_id INT;
BEGIN
    INSERT INTO listas (nome, descricao)
    VALUES (p_nome, p_descricao)
    RETURNING id INTO v_lista_id;
    
    RETURN v_lista_id;
END;
$$ LANGUAGE plpgsql;

-- ================================================================
-- STORED PROCEDURE: inserir_item
-- Insere um novo item na lista
-- ================================================================
CREATE OR REPLACE FUNCTION inserir_item(
    p_lista_id INT,
    p_nome VARCHAR(255),
    p_quantidade_total DECIMAL(10, 2),
    p_unidade_medida VARCHAR(50)
)
RETURNS INT AS $$
DECLARE
    v_item_id INT;
BEGIN
    INSERT INTO itens (lista_id, nome, quantidade_total, unidade_medida)
    VALUES (p_lista_id, p_nome, p_quantidade_total, p_unidade_medida)
    RETURNING id INTO v_item_id;
    
    RETURN v_item_id;
END;
$$ LANGUAGE plpgsql;

-- ================================================================
-- STORED PROCEDURE: registrar_usuario
-- Registra um novo usuário ou retorna ID se já existe
-- ================================================================
CREATE OR REPLACE FUNCTION registrar_usuario(
    p_nome VARCHAR(255),
    p_email VARCHAR(255),
    p_telefone VARCHAR(20)
)
RETURNS INT AS $$
DECLARE
    v_usuario_id INT;
BEGIN
    -- Verifica se usuário já existe pelo email
    IF p_email IS NOT NULL THEN
        SELECT id INTO v_usuario_id FROM usuarios WHERE email = p_email LIMIT 1;
    END IF;
    
    -- Se não existe, insere novo usuário
    IF v_usuario_id IS NULL THEN
        INSERT INTO usuarios (nome, email, telefone)
        VALUES (p_nome, p_email, p_telefone)
        RETURNING id INTO v_usuario_id;
    END IF;
    
    RETURN v_usuario_id;
END;
$$ LANGUAGE plpgsql;

-- ================================================================
-- STORED PROCEDURE: pegar_item
-- Registra que um usuário pegou determinada quantidade de um item
-- ================================================================
CREATE OR REPLACE FUNCTION pegar_item(
    p_item_id INT,
    p_usuario_id INT,
    p_quantidade_pegada DECIMAL(10, 2),
    p_observacao TEXT
)
RETURNS TABLE(status TEXT, mensagem TEXT, retirada_id INT) AS $$
DECLARE
    v_quantidade_restante DECIMAL(10, 2);
    v_retirada_id INT;
BEGIN
    -- Verifica quantidade disponível
    SELECT quantidade_restante INTO v_quantidade_restante
    FROM progresso_itens
    WHERE item_id = p_item_id;
    
    -- Valida se há quantidade suficiente
    IF v_quantidade_restante >= p_quantidade_pegada THEN
        INSERT INTO itens_usuarios (item_id, usuario_id, quantidade_pegada, observacao)
        VALUES (p_item_id, p_usuario_id, p_quantidade_pegada, p_observacao)
        RETURNING id INTO v_retirada_id;
        
        RETURN QUERY SELECT 'sucesso'::TEXT, 'Item pegado com sucesso'::TEXT, v_retirada_id;
    ELSE
        RETURN QUERY SELECT 'erro'::TEXT, 'Quantidade insuficiente'::TEXT, NULL::INT;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ================================================================
-- STORED PROCEDURE: obter_progresso_lista
-- Retorna o progresso completo de uma lista
-- ================================================================
CREATE OR REPLACE FUNCTION obter_progresso_lista(p_lista_id INT)
RETURNS TABLE(
    tipo TEXT,
    lista_id INT,
    lista_nome VARCHAR,
    total_itens BIGINT,
    quantidade_total_lista NUMERIC,
    quantidade_pegada_lista NUMERIC,
    percentual_completo NUMERIC
) AS $$
BEGIN
    -- Retorna progresso geral da lista
    RETURN QUERY 
    SELECT 
        'geral'::TEXT as tipo,
        pl.lista_id,
        pl.lista_nome,
        pl.total_itens,
        pl.quantidade_total_lista,
        pl.quantidade_pegada_lista,
        pl.percentual_completo
    FROM progresso_listas pl 
    WHERE pl.lista_id = p_lista_id;
END;
$$ LANGUAGE plpgsql;

-- ================================================================
-- Dados Iniciais: Inserir a lista "Carnaval do Apostolado Seja Santo"
-- ================================================================
INSERT INTO listas (nome, descricao) 
VALUES ('Carnaval do Apostolado Seja Santo', 'Lista de compras para o evento do Carnaval do Apostolado Seja Santo');

-- ================================================================
-- Exemplos de consultas úteis
-- ================================================================

-- Consultar progresso geral da lista
-- SELECT * FROM progresso_listas WHERE lista_id = 1;

-- Consultar progresso de cada item
-- SELECT * FROM progresso_itens WHERE lista_id = 1;

-- Consultar quem pegou cada item
-- SELECT * FROM usuarios_por_item WHERE item_id = 1;

-- Listar todos os itens com seu progresso
-- SELECT 
--     i.nome,
--     i.quantidade_total,
--     i.unidade_medida,
--     pi.quantidade_pegada,
--     pi.quantidade_restante,
--     pi.percentual_completo
-- FROM itens i
-- JOIN progresso_itens pi ON i.id = pi.item_id
-- WHERE i.lista_id = 1 AND i.ativo = TRUE;

-- ================================================================
-- TRIGGERS: Auditoria e validações
-- ================================================================

-- Trigger para validar quantidade ao pegar item
CREATE OR REPLACE FUNCTION validar_quantidade_antes_inserir()
RETURNS TRIGGER AS $$
DECLARE
    v_quantidade_restante DECIMAL(10, 2);
BEGIN
    SELECT quantidade_restante INTO v_quantidade_restante
    FROM progresso_itens
    WHERE item_id = NEW.item_id;
    
    IF NEW.quantidade_pegada > v_quantidade_restante THEN
        RAISE EXCEPTION 'Quantidade solicitada excede a quantidade disponível';
    END IF;
    
    IF NEW.quantidade_pegada <= 0 THEN
        RAISE EXCEPTION 'Quantidade deve ser maior que zero';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validar_quantidade
BEFORE INSERT ON itens_usuarios
FOR EACH ROW
EXECUTE FUNCTION validar_quantidade_antes_inserir();

-- ================================================================
-- Índices adicionais para performance
-- ================================================================

-- Índice composto para consultas frequentes
CREATE INDEX IF NOT EXISTS idx_itens_lista_ativo ON itens(lista_id, ativo);
CREATE INDEX IF NOT EXISTS idx_itens_usuarios_item_usuario ON itens_usuarios(item_id, usuario_id);

-- ================================================================
-- Comentários nas tabelas
-- ================================================================

COMMENT ON TABLE listas IS 'Tabela principal que armazena as listas de compras';
COMMENT ON TABLE itens IS 'Itens das listas com quantidade e unidade de medida';
COMMENT ON TABLE usuarios IS 'Usuários que podem pegar itens das listas';
COMMENT ON TABLE itens_usuarios IS 'Registro de quais usuários pegaram quais itens e em que quantidade';
