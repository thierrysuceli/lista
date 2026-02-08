// Configuração do Supabase REST API
const SUPABASE_URL = 'https://oducerahpqqqeeycyadg.supabase.co';
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9kdWNlcmFocHFxcWVleWN5YWRnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MDU0MzM0NSwiZXhwIjoyMDg2MTE5MzQ1fQ.18igN69OJAJagruX8HjbmLothxf5OHyeoOgV06QJVgo';

// Headers com SERVICE_ROLE KEY
const headers = {
    'apikey': SUPABASE_SERVICE_KEY,
    'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
    'Content-Type': 'application/json'
};

// ID da lista
let LISTA_ID = 1; // Assumindo ID 1 para "Carnaval do Apostolado Seja Santo"

// Dados da aplicação
let items = [];
let grupos = [];
let currentItemId = null;

// Inicialização
document.addEventListener('DOMContentLoaded', async () => {
    await loadItems();
    renderItems();
    updateGeneralProgress();
    setupEventListeners();
});

// Carregar itens do banco
async function loadItems() {
    try {
        // Buscar itens com grupos
        const response = await fetch(
            `${SUPABASE_URL}/rest/v1/itens?lista_id=eq.${LISTA_ID}&ativo=eq.true&select=*,grupos(id,nome,cor,ordem)`,
            { headers }
        );
        
        if (!response.ok) throw new Error('Erro ao carregar itens');
        
        const data = await response.json();
        
        // Buscar usuários para cada item
        for (let item of data) {
            const usersResponse = await fetch(
                `${SUPABASE_URL}/rest/v1/itens_usuarios?item_id=eq.${item.id}&select=*,usuarios(id,nome)`,
                { headers }
            );
            
            if (usersResponse.ok) {
                const usuarios = await usersResponse.json();
                item.pickedBy = usuarios.map(u => ({
                    name: u.usuarios.nome,
                    quantity: parseFloat(u.quantidade_pegada),
                    timestamp: u.data_retirada
                }));
            } else {
                item.pickedBy = [];
            }
        }
        
        // Converter para formato do frontend
        items = data.map(item => ({
            id: item.id,
            group: item.grupos?.nome || 'Sem Grupo',
            groupColor: item.grupos?.cor || '#d4c5a9',
            name: item.nome,
            totalQuantity: parseFloat(item.quantidade_total),
            unit: item.unidade_medida,
            pickedBy: item.pickedBy || []
        }));
        
    } catch (error) {
        console.error('Erro ao carregar itens:', error);
        alert('Erro ao carregar itens: ' + error.message);
        items = [];
    }
}

// Event Listeners
function setupEventListeners() {
    document.getElementById('toggleAddBtn').addEventListener('click', toggleAddForm);
    document.getElementById('addItemForm').addEventListener('submit', handleAddItem);

    const modal = document.getElementById('pickItemModal');
    const closeBtn = document.querySelector('.close');
    closeBtn.addEventListener('click', closeModal);
    window.addEventListener('click', (e) => {
        if (e.target === modal) closeModal();
    });

    document.getElementById('pickItemForm').addEventListener('submit', handlePickItem);
    document.getElementById('pickAll').addEventListener('change', handlePickAllChange);
}

// Toggle formulário de adicionar
function toggleAddForm() {
    const container = document.getElementById('addItemFormContainer');
    const btn = document.getElementById('toggleAddBtn');
    
    if (container.style.display === 'none') {
        container.style.display = 'block';
        btn.textContent = '➖ Fechar';
    } else {
        container.style.display = 'none';
        btn.textContent = '➕ Adicionar Item';
    }
}

// Adicionar novo item
async function handleAddItem(e) {
    e.preventDefault();
    
    const groupName = document.getElementById('itemGroup').value;
    const name = document.getElementById('itemName').value.trim();
    const quantity = parseFloat(document.getElementById('itemQuantity').value);
    const unit = document.getElementById('itemUnit').value;

    try {
        // Buscar grupo_id
        const grupoResponse = await fetch(
            `${SUPABASE_URL}/rest/v1/grupos?nome=eq.${groupName}`,
            { headers }
        );
        const grupos = await grupoResponse.json();
        const grupo_id = grupos[0]?.id || null;
        
        // Inserir no banco
        const response = await fetch(
            `${SUPABASE_URL}/rest/v1/itens`,
            {
                method: 'POST',
                headers,
                body: JSON.stringify({
                    lista_id: LISTA_ID,
                    grupo_id: grupo_id,
                    nome: name,
                    quantidade_total: quantity,
                    unidade_medida: unit
                })
            }
        );
        
        if (!response.ok) throw new Error('Erro ao adicionar item');

        // Recarregar itens
        await loadItems();
        renderItems();
        updateGeneralProgress();

        // Limpar e fechar formulário
        e.target.reset();
        document.getElementById('addItemFormContainer').style.display = 'none';
        document.getElementById('toggleAddBtn').textContent = '➕ Adicionar Item';
    } catch (error) {
        console.error('Erro ao adicionar item:', error);
        alert('Erro ao adicionar item: ' + error.message);
    }
}

// Renderizar lista de itens
function renderItems() {
    const itemsList = document.getElementById('itemsList');
    
    if (items.length === 0) {
        itemsList.innerHTML = '<div class="empty-message">Nenhum item adicionado ainda. Comece adicionando itens à lista!</div>';
        return;
    }

    // Agrupar itens por grupo
    const groups = {};
    items.forEach(item => {
        const group = item.group || 'Sem Grupo';
        if (!groups[group]) {
            groups[group] = {
                items: [],
                color: item.groupColor
            };
        }
        groups[group].items.push(item);
    });

    // Renderizar por grupo
    itemsList.innerHTML = Object.keys(groups).sort().map(groupName => {
        const groupData = groups[groupName];
        const groupItems = groupData.items.map(item => renderItemCard(item)).join('');
        return `
            <div class="group-section">
                <div class="group-header" style="background: ${groupData.color || '#3d2817'}">
                    ${groupName}
                </div>
                ${groupItems}
            </div>
        `;
    }).join('');
}

function renderItemCard(item) {
    const pickedQuantity = calculatePickedQuantity(item);
    const remainingQuantity = item.totalQuantity - pickedQuantity;
    const progressPercent = (pickedQuantity / item.totalQuantity) * 100;

    return `
        <div class="item-card">
            <div class="item-header">
                <div class="item-name">${item.name}</div>
                <div class="item-quantity">${item.totalQuantity} ${item.unit}</div>
            </div>
            
            <div class="item-progress">
                <div class="item-progress-label">
                    Pegado: ${pickedQuantity.toFixed(2)} ${item.unit} | 
                    Restante: ${remainingQuantity.toFixed(2)} ${item.unit}
                </div>
                <div class="item-progress-bar">
                    <div class="item-progress-fill" style="width: ${progressPercent}%"></div>
                    <span class="item-progress-text">${progressPercent.toFixed(1)}%</span>
                </div>
            </div>

            <div class="item-actions">
                <button class="btn-pick" onclick="openPickModal(${item.id})">
                    👤 Pegar
                </button>
                <button class="btn-delete" onclick="deleteItem(${item.id})">
                    🗑️ Excluir
                </button>
            </div>
        </div>
    `;
}

// Calcular quantidade já pegada de um item
function calculatePickedQuantity(item) {
    return item.pickedBy.reduce((sum, user) => sum + user.quantity, 0);
}

// Atualizar progresso geral
function updateGeneralProgress() {
    if (items.length === 0) {
        document.getElementById('progressGeneral').style.width = '0%';
        document.getElementById('progressGeneralText').textContent = '0%';
        return;
    }

    let totalItems = 0;
    let totalPicked = 0;

    items.forEach(item => {
        totalItems += item.totalQuantity;
        totalPicked += calculatePickedQuantity(item);
    });

    const progressPercent = (totalPicked / totalItems) * 100;
    
    document.getElementById('progressGeneral').style.width = `${progressPercent}%`;
    document.getElementById('progressGeneralText').textContent = `${progressPercent.toFixed(1)}%`;
}

// Abrir modal para pegar item
function openPickModal(itemId) {
    currentItemId = itemId;
    const item = items.find(i => i.id === itemId);
    
    if (!item) return;

    const pickedQuantity = calculatePickedQuantity(item);
    const remainingQuantity = item.totalQuantity - pickedQuantity;

    document.getElementById('modalItemName').textContent = item.name;
    document.getElementById('modalItemTotal').textContent = 
        `Total: ${item.totalQuantity} ${item.unit} | Restante: ${remainingQuantity.toFixed(2)} ${item.unit}`;
    
    document.getElementById('pickItemForm').reset();
    document.getElementById('userQuantity').max = remainingQuantity;
    
    renderUsersList(item);
    
    document.getElementById('pickItemModal').style.display = 'block';
}

// Fechar modal
function closeModal() {
    document.getElementById('pickItemModal').style.display = 'none';
    currentItemId = null;
}

// Renderizar lista de usuários que pegaram o item
function renderUsersList(item) {
    const usersList = document.getElementById('usersList');
    
    if (item.pickedBy.length === 0) {
        usersList.innerHTML = '<div class="empty-message">Ninguém pegou este item ainda.</div>';
        return;
    }

    usersList.innerHTML = item.pickedBy.map(user => `
        <div class="user-card">
            <div class="user-name">👤 ${user.name}</div>
            <div class="user-quantity">${user.quantity} ${item.unit}</div>
        </div>
    `).join('');
}

// Handle checkbox "pegar tudo"
function handlePickAllChange(e) {
    const userQuantityInput = document.getElementById('userQuantity');
    
    if (e.target.checked) {
        const item = items.find(i => i.id === currentItemId);
        const pickedQuantity = calculatePickedQuantity(item);
        const remainingQuantity = item.totalQuantity - pickedQuantity;
        
        userQuantityInput.value = remainingQuantity.toFixed(2);
        userQuantityInput.disabled = true;
    } else {
        userQuantityInput.value = '';
        userQuantityInput.disabled = false;
    }
}

// Pegar item (adicionar usuário)
async function handlePickItem(e) {
    e.preventDefault();
    
    const item = items.find(i => i.id === currentItemId);
    if (!item) return;

    const userName = document.getElementById('userName').value.trim();
    const userQuantity = parseFloat(document.getElementById('userQuantity').value);

    const pickedQuantity = calculatePickedQuantity(item);
    const remainingQuantity = item.totalQuantity - pickedQuantity;

    if (userQuantity > remainingQuantity) {
        alert(`Quantidade inválida! Restam apenas ${remainingQuantity.toFixed(2)} ${item.unit}`);
        return;
    }

    if (userQuantity <= 0) {
        alert('A quantidade deve ser maior que zero!');
        return;
    }

    try {
        // Buscar ou criar usuário
        let usuarioResponse = await fetch(
            `${SUPABASE_URL}/rest/v1/usuarios?nome=eq.${encodeURIComponent(userName)}`,
            { headers }
        );
        
        let usuarios = await usuarioResponse.json();
        let usuario_id;
        
        if (usuarios.length === 0) {
            // Criar novo usuário
            const novoUsuarioResponse = await fetch(
                `${SUPABASE_URL}/rest/v1/usuarios`,
                {
                    method: 'POST',
                    headers,
                    body: JSON.stringify({ nome: userName })
                }
            );
            
            if (!novoUsuarioResponse.ok) throw new Error('Erro ao criar usuário');
            
            const novoUsuario = await novoUsuarioResponse.json();
            usuario_id = novoUsuario[0].id;
        } else {
            usuario_id = usuarios[0].id;
        }

        // Registrar item pegado
        const itemUsuarioResponse = await fetch(
            `${SUPABASE_URL}/rest/v1/itens_usuarios`,
            {
                method: 'POST',
                headers,
                body: JSON.stringify({
                    item_id: currentItemId,
                    usuario_id: usuario_id,
                    quantidade_pegada: userQuantity
                })
            }
        );
        
        if (!itemUsuarioResponse.ok) throw new Error('Erro ao registrar item');

        // Recarregar itens
        await loadItems();
        renderItems();
        updateGeneralProgress();
        
        // Atualizar modal
        const updatedItem = items.find(i => i.id === currentItemId);
        const newPickedQuantity = calculatePickedQuantity(updatedItem);
        const newRemainingQuantity = updatedItem.totalQuantity - newPickedQuantity;
        
        document.getElementById('modalItemTotal').textContent = 
            `Total: ${updatedItem.totalQuantity} ${updatedItem.unit} | Restante: ${newRemainingQuantity.toFixed(2)} ${updatedItem.unit}`;
        
        renderUsersList(updatedItem);
        
        e.target.reset();
        document.getElementById('userQuantity').max = newRemainingQuantity;
        
        if (newRemainingQuantity <= 0) {
            alert('✅ Este item foi completamente distribuído!');
            closeModal();
        }
    } catch (error) {
        console.error('Erro ao pegar item:', error);
        alert('Erro ao pegar item: ' + error.message);
    }
}

// Excluir item
async function deleteItem(itemId) {
    if (!confirm('Tem certeza que deseja excluir este item?')) return;
    
    try {
        const response = await fetch(
            `${SUPABASE_URL}/rest/v1/itens?id=eq.${itemId}`,
            {
                method: 'PATCH',
                headers,
                body: JSON.stringify({ ativo: false })
            }
        );
        
        if (!response.ok) throw new Error('Erro ao excluir item');

        await loadItems();
        renderItems();
        updateGeneralProgress();
    } catch (error) {
        console.error('Erro ao excluir item:', error);
        alert('Erro ao excluir item: ' + error.message);
    }
}
