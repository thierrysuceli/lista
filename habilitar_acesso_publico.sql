-- ================================================================
-- Habilitar Row Level Security (RLS) e criar políticas públicas
-- Execute este script no Supabase SQL Editor
-- ================================================================

-- Habilitar RLS nas tabelas
ALTER TABLE listas ENABLE ROW LEVEL SECURITY;
ALTER TABLE itens ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE itens_usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE grupos ENABLE ROW LEVEL SECURITY;

-- Criar políticas para permitir acesso público de LEITURA

-- Listas - permitir leitura pública
CREATE POLICY "Permitir leitura pública de listas"
ON listas FOR SELECT
USING (true);

-- Grupos - permitir leitura pública
CREATE POLICY "Permitir leitura pública de grupos"
ON grupos FOR SELECT
USING (true);

-- Itens - permitir leitura e escrita pública
CREATE POLICY "Permitir leitura pública de itens"
ON itens FOR SELECT
USING (true);

CREATE POLICY "Permitir inserção pública de itens"
ON itens FOR INSERT
WITH CHECK (true);

CREATE POLICY "Permitir atualização pública de itens"
ON itens FOR UPDATE
USING (true);

-- Usuários - permitir leitura e escrita pública
CREATE POLICY "Permitir leitura pública de usuários"
ON usuarios FOR SELECT
USING (true);

CREATE POLICY "Permitir inserção pública de usuários"
ON usuarios FOR INSERT
WITH CHECK (true);

-- Itens_usuarios - permitir leitura e escrita pública
CREATE POLICY "Permitir leitura pública de itens_usuarios"
ON itens_usuarios FOR SELECT
USING (true);

CREATE POLICY "Permitir inserção pública de itens_usuarios"
ON itens_usuarios FOR INSERT
WITH CHECK (true);

-- Confirmar que as políticas foram criadas
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
