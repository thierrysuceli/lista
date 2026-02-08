-- ================================================================
-- DESABILITAR RLS COMPLETAMENTE (para grupo fechado sem autenticação)
-- Execute este script no Supabase SQL Editor
-- ================================================================

-- Desabilitar RLS em todas as tabelas
ALTER TABLE listas DISABLE ROW LEVEL SECURITY;
ALTER TABLE itens DISABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios DISABLE ROW LEVEL SECURITY;
ALTER TABLE itens_usuarios DISABLE ROW LEVEL SECURITY;
ALTER TABLE grupos DISABLE ROW LEVEL SECURITY;

-- Remover todas as políticas existentes
DROP POLICY IF EXISTS "Permitir leitura pública de listas" ON listas;
DROP POLICY IF EXISTS "Permitir leitura pública de grupos" ON grupos;
DROP POLICY IF EXISTS "Permitir leitura pública de itens" ON itens;
DROP POLICY IF EXISTS "Permitir inserção pública de itens" ON itens;
DROP POLICY IF EXISTS "Permitir atualização pública de itens" ON itens;
DROP POLICY IF EXISTS "Permitir leitura pública de usuários" ON usuarios;
DROP POLICY IF EXISTS "Permitir inserção pública de usuários" ON usuarios;
DROP POLICY IF EXISTS "Permitir leitura pública de itens_usuarios" ON itens_usuarios;
DROP POLICY IF EXISTS "Permitir inserção pública de itens_usuarios" ON itens_usuarios;

SELECT 'RLS desabilitado com sucesso!' as status;
