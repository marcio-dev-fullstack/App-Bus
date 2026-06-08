$confirmPush = Read-Host "Confirma o envio definitivo (git push)? (s/n)"

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