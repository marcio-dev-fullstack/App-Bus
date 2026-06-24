#!/bin/bash

# Cores para o terminal (Melhor visualização)
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # Sem cor

clear
echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}    ESTEIRA DE ATUALIZAÇÃO REPOSITÓRIO GITHUB     ${NC}"
echo -e "${BLUE}==================================================${NC}"

# ==========================================
# PASSO 1: Verificar se é um repositório Git
# ==========================================
echo -e "\n${YELLOW}[1/6] Verificando ambiente local...${NC}"
if [ ! -d ".git" ]; then
    echo -e "${RED}ERRO: Esta pasta não é um repositório Git local.${NC}"
    read -p "Deseja iniciar (git init) nesta pasta agora? (s/n): " init_choice
    case "$init_choice" in
        [sS]|[sS][eE][mM])
            git init
            echo -e "${GREEN}Repositório inicializado com sucesso!${NC}"
            ;;
        *)
            echo -e "${RED}Operação cancelada. Abortando...${NC}"
            exit 1
            ;;
    esac
else
    echo -e "${GREEN}✔ Pasta local já é um repositório Git.${NC}"
fi

# ==========================================
# PASSO 2: Verificar conexão com o Remote (GitHub)
# ==========================================
echo -e "\n${YELLOW}[2/6] Verificando conexão remota...${NC}"
if ! git remote -v | grep -q 'origin'; then
    echo -e "${RED}ERRO: Nenhum repositório remoto 'origin' configurado.${NC}"
    read -p "Digite a URL do seu repositório do GitHub: " remote_url
    if [ -z "$remote_url" ]; then
        echo -e "${RED}URL inválida. Abortando...${NC}"
        exit 1
    fi
    git remote add origin "$remote_url"
    echo -e "${GREEN}✔ Origem remota adicionada com sucesso!${NC}"
else
    echo -e "${GREEN}✔ Repositório remoto detectado:${NC}"
    git remote -v | grep 'push'
fi

# ==========================================
# PASSO 3: Sincronizar com o Remote (Evitar conflitos)
# ==========================================
echo -e "\n${YELLOW}[3/6] Sincronizando com o GitHub (Fetch/Pull)...${NC}"
current_branch=$(git branch --show-current)

# Se estiver vazio (ex: repositório recém-criado sem commits)
if [ -z "$current_branch" ]; then
    current_branch="main"
    echo -e "${YELLOW}Nenhuma branch detectada. Definindo branch padrão como: '$current_branch'${NC}"
    git branch -M "$current_branch"
fi

echo -e "Buscando atualizações na branch de origem: ${BLUE}$current_branch${NC}..."
git fetch origin "$current_branch" &> /dev/null

# Verifica se o repositório remoto tem commits para puxar
if git rev-parse --verify origin/"$current_branch" &> /dev/null; then
    echo -e "Verificando se há atualizações pendentes no servidor..."
    LOCAL=$(git rev-parse HEAD 2>/dev/null || echo "LOCAL_VAZIO")
    REMOTE=$(git rev-parse origin/"$current_branch")

    if [ "$LOCAL" != "$REMOTE" ] && [ "$LOCAL" != "LOCAL_VAZIO" ]; then
        echo -e "${YELLOW}Aviso: Seu repositório remoto tem modificações que você não tem localmente.${NC}"
        read -p "Deseja fazer o 'git pull' antes de continuar? (s/n): " pull_choice
        case "$pull_choice" in
            [sS]|[sS][eE][mM])
                git pull origin "$current_branch"
                echo -e "${GREEN}✔ Repositório atualizado localmente.${NC}"
                ;;
            *)
                echo -e "${RED}Aviso: Prosseguindo sem atualizar. Isso pode gerar conflitos no push.${NC}"
                ;;
        esac
    else
        echo -e "${GREEN}✔ Seu repositório local está em sincronia com o remoto.${NC}"
    fi
else
    echo -e "${YELLOW}Primeiro push detectado ou branch remota não encontrada. Pulando pull.${NC}"
fi

# ==========================================
# PASSO 4: Status e Seleção de Arquivos
# ==========================================
echo -e "\n${YELLOW}[4/6] Analisando arquivos modificados/novos...${NC}"
git status -s

if [ -z "$(git status --porcelain)" ]; then
    echo -e "${GREEN}Nada para atualizar. O working directory está limpo.${NC}"
    exit 0
fi

echo -e "\n${BLUE}Como deseja adicionar as alterações?${NC}"
echo "1) Adicionar TUDO (git add .)"
echo "2) Selecionar manualmente os arquivos"
echo "3) Cancelar operação"
read -p "Escolha uma opção (1-3): " add_stage

case "$add_stage" in
    1)
        git add .
        echo -e "${GREEN}✔ Todos os arquivos foram preparados (staged).${NC}"
        ;;
    2)
        echo -e "${YELLOW}Digite o caminho dos arquivos separados por espaço (ex: main.py config.json):${NC}"
        read -p "> " files_to_add
        git add $files_to_add
        echo -e "${GREEN}✔ Arquivos selecionados foram preparados.${NC}"
        ;;
    *)
        echo -e "${RED}Operação cancelada pelo usuário.${NC}"
        exit 0
        ;;
esac

# ==========================================
# PASSO 5: Criação do Commit
# ==========================================
echo -e "\n${YELLOW}[5/6] Preparando o Commit...${NC}"
echo -e "${BLUE}Escolha o tipo de alteração (Convenção de Commits):${NC}"
echo "1) feat: Nova funcionalidade/arquivo"
echo "2) fix: Correção de bug"
echo "3) docs: Mudança em documentação (ex: README)"
echo "4) refactor: Mudança de código que não altera comportamento"
echo "5) custom: Digitar mensagem personalizada livre"
read -p "Escolha o tipo (1-5): " commit_type_choice

case "$commit_type_choice" in
    1) prefix="feat: " ;;
    2) prefix="fix: " ;;
    3) prefix="docs: " ;;
    4) prefix="refactor: " ;;
    *) prefix="" ;;
esac

read -p "Digite a mensagem descritiva do commit: " commit_msg
final_message="${prefix}${commit_msg}"

echo -e "\nSua mensagem de commit será: ${GREEN}\"$final_message\"${NC}"
read -p "Confirma a criação do commit? (s/n): " confirm_commit

case "$confirm_commit" in
    [sS]|[sS][eE][mM])
        git commit -m "$final_message"
        echo -e "${GREEN}✔ Commit criado com sucesso!${NC}"
        ;;
    *)
        echo -e "${RED}Commit cancelado. As alterações continuam na área de stage.${NC}"
        exit 0
        ;;
esac

# ==========================================
# PASSO 6: Push para o GitHub
# ==========================================
echo -e "\n${YELLOW}[6/6] Enviando para o GitHub...${NC}"
echo -e "Você está enviando para a branch: ${BLUE}$current_branch${NC}"
read -p "Confirma o envio definitivo (git push)? (s/n): " confirm_push

case "$confirm_push" in
    [sS]|[sS][eE][mM])
        echo -e "${BLUE}Subindo arquivos...${NC}"
        if git push -u origin "$current_branch"; then
            echo -e "\n${GREEN}==================================================${NC}"
            echo -e "${GREEN}    REPOSITÓRIO ATUALIZADO COM SUCESSO! 🚀       ${NC}"
            echo -e "${GREEN}==================================================${NC}"
        else
            echo -e "${RED}ERRO ao fazer o push. Verifique suas permissões ou conexão.${NC}"
        fi
        ;;
    *)
        echo -e "${RED}Push cancelado. Suas alterações foram salvas localmente no commit.${NC}"
        ;;
esac