<#
## Arquiteto de Solução e Desenvolvedor Líder

**Márcio Rodrigues de Oliveira**

* Desenvolvedor Full Stack
* cda.marcio@gmail.com
#>

# ==============================================================================
#   GERADOR AUTOMÁTICO DE DIAGRAMAS MERMAID (VERSÃO POWERSHELL) - PT-BR
#
#   Este script lê um arquivo Markdown, extrai todos os blocos de código
#   Mermaid e os converte em arquivos de imagem (PNG ou SVG).
# ==============================================================================

# --- Configuração ---
$inputFile = "DIAGRAMAS.md"
$outputDir = "docs/diagramas" # Diretório de saída para as imagens
$format = "png"                # Formato de saída: 'png' ou 'svg'

# --- Início do Script ---
Clear-Host
Write-Host "==================================================" -ForegroundColor Blue
Write-Host "     GERADOR DE IMAGENS DE DIAGRAMAS MERMAID      " -ForegroundColor Blue
Write-Host "==================================================" -ForegroundColor Blue

# 1. Verifica se o arquivo de entrada existe
if (-not (Test-Path $inputFile)) {
    Write-Host "`nERRO: O arquivo de entrada '$inputFile' não foi encontrado!" -ForegroundColor Red
    exit 1
}

# 2. Verifica se a CLI do Mermaid (mmdc) está instalada
$mmdcExists = Get-Command mmdc -ErrorAction SilentlyContinue
if (-not $mmdcExists) {
    Write-Host "`nERRO: A CLI do Mermaid (mmdc) não está instalada." -ForegroundColor Red
    Write-Host "Por favor, instale-a globalmente com o comando:" -ForegroundColor Yellow
    Write-Host "npm install -g @mermaid-js/mermaid-cli"
    exit 1
}

# 3. Cria o diretório de saída se ele não existir
if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory | Out-Null
}
Write-Host "`nIniciando... As imagens serão salvas em '$outputDir'." -ForegroundColor Yellow

# 4. Define uma função auxiliar para gerar cada diagrama
function Invoke-GeracaoDiagrama {
    param(
        [string]$Codigo,
        [string]$NomeArquivo,
        [string]$DiretorioSaida,
        [string]$FormatoArquivo
    )
    # Cria um nome de arquivo temporário seguro
    $arquivoTemporario = [System.IO.Path]::GetTempFileName() + ".mmd"
    $arquivoSaida = Join-Path -Path $DiretorioSaida -ChildPath "$($NomeArquivo).$($FormatoArquivo)"

    Set-Content -Path $arquivoTemporario -Value $Codigo -Encoding utf8
    mmdc -i $arquivoTemporario -o $arquivoSaida -w 1024
    Write-Host "✔ Diagrama gerado: $arquivoSaida" -ForegroundColor Green
    Remove-Item $arquivoTemporario -Force
}

# 5. Processa o arquivo Markdown
$conteudo = Get-Content $inputFile -Raw
$linhas = $conteudo.Split([Environment]::NewLine)

$dentroDoBloco = $false
$codigoDiagrama = ""
$prefixoNomeArquivo = "diagrama_sem_titulo"

foreach ($linha in $linhas) {
    # Captura o cabeçalho de nível 2 para usar como nome de arquivo
    if ($linha.StartsWith("## ")) {
        $prefixoNomeArquivo = $linha.Substring(3).Trim()
        $prefixoNomeArquivo = $prefixoNomeArquivo -replace '[^a-zA-Z0-9_ ]', '' # Remove caracteres especiais
        $prefixoNomeArquivo = $prefixoNomeArquivo -replace ' ', '_'
        $prefixoNomeArquivo = $prefixoNomeArquivo.ToLower()
    }

    # Início de um bloco mermaid
    if ($linha.Trim() -eq "```mermaid") {
        $dentroDoBloco = $true
        $codigoDiagrama = ""
        continue
    }

    # Fim de um bloco
    if ($dentroDoBloco -and $linha.Trim() -eq "```") {
        $dentroDoBloco = $false
        Invoke-GeracaoDiagrama -Codigo $codigoDiagrama -NomeArquivo $prefixoNomeArquivo -DiretorioSaida $outputDir -FormatoArquivo $format
    }

    if ($dentroDoBloco) {
        $codigoDiagrama += $linha + [Environment]::NewLine
    }
}

Write-Host "`nProcesso concluído com sucesso!" -ForegroundColor Green