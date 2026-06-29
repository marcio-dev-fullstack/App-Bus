<#
/// AUTOR:Arquiteto de Solução e Desenvolvedor Líder
/// Márcio Rodrigues de Oliveira
/// cda.marcio@gmail.com
#>

# ==============================================================================
#   SCRIPT DE GERAÇÃO DE BANCO DE DADOS - POSTGRESQL COM EF CORE
#
#   Este script utiliza as ferramentas do Entity Framework Core para criar
#   e aplicar migrações, gerando o esquema do banco de dados PostgreSQL
#   com base nos modelos definidos no projeto de backend.
#
#   Pré-requisitos:
#   1. O projeto de backend já deve ter sido criado em 'c:\PROJETOS\App-Bus\backend'.
#   2. As ferramentas do EF Core (`dotnet ef`) devem estar instaladas globalmente
#      ou localmente no projeto.
#   3. A string de conexão em `backend/appsettings.json` deve estar configurada
#      corretamente para apontar para o seu servidor PostgreSQL.
# ==============================================================================

# --- Configuração ---
$nomeDaMigracao = "InitialCreate"
$diretorioBackend = (Join-Path $PSScriptRoot "backend")

# --- Início do Script ---
Clear-Host
Write-Host "==================================================" -ForegroundColor Blue
Write-Host "     GERADOR DE BANCO DE DADOS COM EF CORE        " -ForegroundColor Blue
Write-Host "==================================================" -ForegroundColor Blue

# 1. Verifica se o diretório do backend existe
if (-not (Test-Path $diretorioBackend)) {
    Write-Host "`nERRO: O diretório do backend '$diretorioBackend' não foi encontrado." -ForegroundColor Red
    Write-Host "Execute o passo 2.1 do MANUAL_API_BACKEND.md primeiro." -ForegroundColor Yellow
    exit 1
}

# 2. Navega para o diretório do projeto de backend
Push-Location $diretorioBackend
Write-Host "`nDiretório de trabalho alterado para: $(Get-Location)" -ForegroundColor Cyan

# 3. Adiciona uma nova migração
#    Isso cria uma "foto" do esquema do banco de dados com base nos seus Models e DbContext.
Write-Host "`nPasso 1/2: Criando a migração '$nomeDaMigracao'..." -ForegroundColor Yellow
dotnet ef migrations add $nomeDaMigracao

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nERRO: Falha ao criar a migração. Verifique os logs de erro acima." -ForegroundColor Red
    Pop-Location
    exit 1
}

# 4. Aplica a migração ao banco de dados
#    Isso executa o script SQL gerado pela migração no banco de dados alvo.
Write-Host "`nPasso 2/2: Aplicando a migração ao banco de dados..." -ForegroundColor Yellow
dotnet ef database update

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nERRO: Falha ao aplicar a migração ao banco de dados. Verifique sua string de conexão e se o servidor PostgreSQL está acessível." -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host "`nProcesso concluído! O banco de dados foi criado/atualizado com sucesso." -ForegroundColor Green
Pop-Location