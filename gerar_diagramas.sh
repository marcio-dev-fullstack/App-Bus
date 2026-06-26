#!/bin/bash

# ## Arquiteto de Solução e Desenvolvedor Líder
#
# **Márcio Rodrigues de Oliveira**
#
# * Desenvolvedor Full Stack
# * cda.marcio@gmail.com

#!/bin/bash

# ==============================================================================
#   GERADOR AUTOMÁTICO DE DIAGRAMAS MERMAID
#
#   Este script lê um arquivo Markdown, extrai todos os blocos de código
#   Mermaid e os converte em arquivos de imagem (PNG ou SVG).
# ==============================================================================

# --- Configuração ---
INPUT_FILE="DIAGRAMAS.md"
OUTPUT_DIR="docs/diagramas" # Diretório de saída para as imagens
FORMAT="png"                # Formato de saída: 'png' ou 'svg'

# --- Cores para o terminal ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # Sem cor

clear
echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}     GERADOR DE IMAGENS DE DIAGRAMAS MERMAID      ${NC}"
echo -e "${BLUE}==================================================${NC}"

# 1. Verifica se o arquivo de entrada existe
if [ ! -f "$INPUT_FILE" ]; then
    echo -e "\n${RED}ERRO: O arquivo de entrada '$INPUT_FILE' não foi encontrado!${NC}"
    exit 1
fi

# 2. Verifica se a CLI do Mermaid (mmdc) está instalada
if ! command -v mmdc &> /dev/null; then
    echo -e "\n${RED}ERRO: A CLI do Mermaid (mmdc) não está instalada.${NC}"
    echo -e "${YELLOW}Por favor, instale-a globalmente com o comando:${NC}"
    echo "npm install -g @mermaid-js/mermaid-cli"
    exit 1
fi

# 3. Cria o diretório de saída se ele não existir
mkdir -p "$OUTPUT_DIR"
echo -e "\n${YELLOW}Iniciando... As imagens serão salvas em '$OUTPUT_DIR'.${NC}"

# 4. Usa 'awk' para processar o arquivo Markdown
#    - Ele procura por títulos (##) para nomear os arquivos.
#    - Extrai cada bloco ```mermaid ... ``` para um arquivo temporário.
#    - Executa o mmdc nesse arquivo temporário.
#    - Limpa os arquivos temporários.
awk -v out_dir="$OUTPUT_DIR" -v format="$FORMAT" '
BEGIN { 
    in_block = 0;
    count = 0;
    # Define um nome padrão caso nenhum título seja encontrado antes do diagrama
    filename_prefix = "diagrama";
}

# Captura o cabeçalho de nível 2 para usar como nome de arquivo
 /^## / {
    # Extrai o texto, converte para minúsculas e substitui espaços por underscores
    filename_prefix = substr($0, 4);
    gsub(/[^a-zA-Z0-9_ ]/, "", filename_prefix); # Remove caracteres especiais, mas mantém o underscore
    gsub(/ /, "_", filename_prefix);
    filename_prefix = tolower(filename_prefix);
}

# Início de um bloco mermaid
/```mermaid/ {
    in_block = 1;
    count++;
    temp_file = "temp_diagram_" count ".mmd";
    next;
}

# Fim de um bloco
in_block && /```/ {
    in_block = 0;
    output_file = out_dir "/" filename_prefix "." format; 
    # Comando para gerar a imagem
    system("mmdc -i " temp_file " -o " output_file " -w 1024");
    print "✔ Diagrama gerado: " output_file;
    # Limpa o arquivo temporário
    system("rm " temp_file);
    next;
}

# Escreve o conteúdo do bloco no arquivo temporário
in_block {
    print > temp_file;
}
' "$INPUT_FILE"

echo -e "\n${GREEN}Processo concluído com sucesso!${NC}"