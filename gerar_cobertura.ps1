<#
## Arquiteto de Solução e Desenvolvedor Líder

**Márcio Rodrigues de Oliveira**

* Desenvolvedor Full Stack
* cda.marcio@gmail.com
#>

# ==============================================================================
#   GERADOR DE RELATÓRIO DE COBERTURA DE TESTES - PT-BR
#
#   Este script executa os testes do Flutter para gerar dados de cobertura
#   e, em seguida, cria um relatório HTML navegável a partir desses dados.
# ==============================================================================

# --- Configuração ---
$limiteMinimoCobertura = 80.0 # O alvo mínimo de cobertura em porcentagem (ex: 80.0)

# --- Início do Script ---
Clear-Host
Write-Host "==================================================" -ForegroundColor Blue
Write-Host "     GERADOR DE RELATÓRIO DE COBERTURA DE TESTES    " -ForegroundColor Blue
Write-Host "==================================================" -ForegroundColor Blue

# 1. Garante que o script execute a partir do diretório do projeto Flutter
Push-Location (Join-Path $PSScriptRoot "mobile")
Write-Host "`nDiretório de trabalho: $(Get-Location)" -ForegroundColor Cyan

# 2. Executa os testes e gera o arquivo lcov.info
Write-Host "Executando 'flutter test --coverage'..." -ForegroundColor Yellow
flutter test --coverage

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nERRO: Falha ao executar os testes. A geração do relatório foi cancelada." -ForegroundColor Red
    Pop-Location
    exit 1
}

# 3. Calcula a cobertura total a partir do arquivo lcov.info
Write-Host "Calculando a cobertura total de testes..." -ForegroundColor Yellow
$lcovFile = "coverage/lcov.info"
if (-not (Test-Path $lcovFile)) {
    Write-Host "`nERRO: Arquivo '$lcovFile' não encontrado. Não foi possível calcular a cobertura." -ForegroundColor Red
    Pop-Location
    exit 1
}

$totalLinhas = 0
$linhasCobertas = 0

Get-Content $lcovFile | ForEach-Object {
    if ($_ -match "^LF:(\d+)") {
        $totalLinhas += [int]$matches[1]
    }
    if ($_ -match "^LH:(\d+)") {
        $linhasCobertas += [int]$matches[1]
    }
}

$coberturaAtual = 0
if ($totalLinhas -gt 0) {
    $coberturaAtual = ($linhasCobertas / $totalLinhas) * 100
}

Write-Host ("Cobertura de linhas atual: {0:N2}%" -f $coberturaAtual) -ForegroundColor Cyan

if ($coberturaAtual -lt $limiteMinimoCobertura) {
    Write-Host ("`nERRO: A cobertura de testes ({0:N2}%) está abaixo do limite mínimo de {1}%." -f $coberturaAtual, $limiteMinimoCobertura) -ForegroundColor Red
    Pop-Location
    exit 1
}

# 3. Verifica se a ferramenta 'genhtml' (parte do lcov) está disponível
$genhtmlExists = Get-Command genhtml -ErrorAction SilentlyContinue
if (-not $genhtmlExists) {
    Write-Host "`nAVISO: Ferramenta 'genhtml' não encontrada. O relatório HTML não pôde ser gerado." -ForegroundColor Yellow
    Write-Host "Para gerar o relatório HTML, instale o 'lcov' (ex: 'sudo apt-get install lcov' no Linux/WSL)." -ForegroundColor Yellow
} else {
    Write-Host "Gerando relatório HTML em 'coverage/html'..." -ForegroundColor Yellow
    genhtml coverage/lcov.info -o coverage/html
}

Write-Host "`nProcesso concluído com sucesso!" -ForegroundColor Green
Pop-Location