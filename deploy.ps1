# Garante que o script execute a partir do diretório do projeto Flutter
Push-Location (Join-Path $PSScriptRoot "front_end")

Write-Host "Diretório de trabalho alterado para: $(Get-Location)" -ForegroundColor Cyan

Write-Host "Verificando branch atual..." -ForegroundColor Cyan
$currentBranch = git rev-parse --abbrev-ref HEAD

if ($currentBranch -ne "main") {
    Write-Host "ERRO: Você não está na branch 'main'. O deploy foi cancelado." -ForegroundColor Red
    exit 1
}

Write-Host "Você está na branch 'main'. Iniciando testes..." -ForegroundColor Green

# Executa os testes do Flutter
flutter test

if ($LASTEXITCODE -ne 0) {
    Write-Host "-----------------------------------------" -ForegroundColor Red
    Write-Host " ERRO: Falha nos testes do Flutter. O push foi cancelado." -ForegroundColor Red
    Write-Host "-----------------------------------------" -ForegroundColor Red
    exit 1
}

Write-Host "Todos os testes passaram com sucesso!" -ForegroundColor Green

$confirmPush = Read-Host "Confirma o envio definitivo para a branch 'main' (git push)? (s/n)"

# Verifica se o usuário digitou 's' ou 'S'
if ($confirmPush -eq "s" -or $confirmPush -eq "S") {
    Write-Host "Subindo arquivos..." -ForegroundColor Cyan

    # Executa o push
    git push -u origin main

    # Valida o resultado final do Git
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "=========================================" -ForegroundColor Green
        Write-Host " REPOSITORIO ATUALIZADO COM SUCESSO! 🚀 " -ForegroundColor Green
        Write-Host "=========================================" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "-----------------------------------------" -ForegroundColor Red
        Write-Host " ERRO: Ocorreu uma falha ao tentar fazer o push." -ForegroundColor Red
        Write-Host " Verifique suas permissoes ou conexao. " -ForegroundColor Red
        Write-Host "-----------------------------------------" -ForegroundColor Red
    }
} else {
    Write-Host "Push cancelado pelo usuario." -ForegroundColor Yellow
}

# Retorna ao diretório original
Pop-Location