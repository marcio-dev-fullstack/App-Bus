<#
/// AUTOR:Arquiteto de Solução e Desenvolvedor Líder
/// Márcio Rodrigues de Oliveira
/// cda.marcio@gmail.com
#>

# ==============================================================================
#   SCRIPT PARA POPULAR O BANCO DE DADOS COM DADOS DE TESTE
#
#   Este script invoca a lógica de "seeding" definida no projeto de backend
#   para popular o banco de dados com dados de exemplo (uma viagem e alguns
#   embarques).
#
#   Pré-requisitos:
#   1. O banco de dados já deve ter sido criado (use `gerar_banco_de_dados.ps1`).
#   2. A lógica de seeding deve existir no `Program.cs` do projeto backend.
# ==============================================================================

# --- Configuração ---
$diretorioBackend = (Join-Path $PSScriptRoot "backend")

# --- Início do Script ---
Clear-Host
Write-Host "==================================================" -ForegroundColor Magenta
Write-Host "     POPULANDO BANCO DE DADOS COM DADOS DE TESTE  " -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta

# 1. Verifica se o diretório do backend existe
if (-not (Test-Path $diretorioBackend)) {
    Write-Host "`nERRO: O diretório do backend '$diretorioBackend' não foi encontrado." -ForegroundColor Red
    Write-Host "Execute o passo 2.1 do MANUAL_API_BACKEND.md para criar o projeto da API primeiro." -ForegroundColor Yellow
    exit 1
}

# 2. Navega para o diretório do projeto de backend
Push-Location $diretorioBackend
Write-Host "`nDiretório de trabalho alterado para: $(Get-Location)" -ForegroundColor Cyan

# 3. Executa o projeto com o argumento '--seed' para acionar a lógica de seeding
Write-Host "`nInvocando a lógica de seeding no projeto ASP.NET Core..." -ForegroundColor Yellow
dotnet run -- --seed

Write-Host "`nProcesso de seeding concluído." -ForegroundColor Green
Pop-Location