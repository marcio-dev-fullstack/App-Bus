# Configuração de Codificação para evitar problemas com acentos no terminal
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Clear-Host
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "    ESTEIRA DE ATUALIZAÇÃO REPOSITÓRIO GITHUB     " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# ==========================================
# PASSO 1: Verificar se é um repositório Git
# ==========================================
Write-Host "`n[1/6] Verificando ambiente local..." -ForegroundColor Yellow
if (-not (Test-Path -Path ".git" -PathType Container)) {
    Write-Host "ERRO: Esta pasta não é um repositório Git local." -ForegroundColor Red
    $initChoice = Read-Host "Deseja iniciar (git init) nesta pasta agora? (s/n)"
    switch ($initChoice) {
        { $_ -in 's', 'S', 'sim', 'Sim', 'SIM' } {
            git init
            Write-Host "Repositório inicializado com sucesso!" -ForegroundColor Green
        }
        Default {
            Write-Host "Operação cancelada. Abortando..." -ForegroundColor Red
            Exit
        }
    }
} else {
    Write-Host "✔ Pasta local já é um repositório Git." -ForegroundColor Green
}

# ==========================================
# PASSO 2: Verificar conexão com o Remote (GitHub)
# ==========================================
Write-Host "`n[2/6] Verificando conexão remota..." -ForegroundColor Yellow
$remotes = git remote -v
if (-not ($remotes -match 'origin')) {
    Write-Host "ERRO: Nenhum repositório remoto 'origin' configurado." -ForegroundColor Red
    $remoteUrl = Read-Host "Digite a URL do seu repositório do GitHub"
    if ([string]::IsNullOrEmpty($remoteUrl)) {
        Write-Host "URL inválida. Abortando..." -ForegroundColor Red
        Exit
    }
    git remote add origin "$remoteUrl"
    Write-Host "✔ Origem remota adicionada com sucesso!" -ForegroundColor Green
} else {
    Write-Host "✔ Repositório remoto detectado:" -ForegroundColor Green
    git remote -v | Select-String "push" | ForEach-Object { Write-Host $_.Line -ForegroundColor Gray }
}

# ==========================================
# PASSO 3: Sincronizar com o Remote (Evitar conflitos)
# ==========================================
Write-Host "`n[3/6] Sincronizando com o GitHub (Fetch/Pull)..." -ForegroundColor Yellow
$currentBranch = (git branch --show-current).Trim()

if ([string]::IsNullOrEmpty($currentBranch)) {
    $currentBranch = "main"
    Write-Host "Nenhuma branch detectada. Definindo branch padrão como: '$currentBranch'" -ForegroundColor Yellow
    git branch -M "$currentBranch"
}

Write-Host "Buscando atualizações na branch de origem: $currentBranch..." -ForegroundColor Cyan
git fetch origin "$currentBranch" 2>$null

# Verifica se a branch remota existe
$remoteBranchExists = git rev-parse --verify origin/"$currentBranch" 2>$null
if ($remoteBranchExists) {
    Write-Host "Verificando se há atualizações pendentes no servidor..." -ForegroundColor Cyan
    $localSHA = git rev-parse HEAD 2>$null
    $remoteSHA = git rev-parse origin/"$currentBranch" 2>$null

    if ($localSHA -ne $remoteSHA -and -not [string]::IsNullOrEmpty($localSHA)) {
        Write-Host "Aviso: Seu repositório remoto tem modificações que você não tem localmente." -ForegroundColor Yellow
        $pullChoice = Read-Host "Deseja fazer o 'git pull' antes de continuar? (s/n)"
        switch ($pullChoice) {
            { $_ -in 's', 'S', 'sim', 'Sim', 'SIM' } {
                git pull origin "$currentBranch"
                Write-Host "✔ Repositório atualizado localmente." -ForegroundColor Green
            }
            Default {
                Write-Host "Aviso: Prosseguindo sem atualizar. Isso pode gerar conflitos no push." -ForegroundColor Red
            }
        }
    } else {
        Write-Host "✔ Seu repositório local está em sincronia com o remoto." -ForegroundColor Green
    }
} else {
    Write-Host "Primeiro push detectado ou branch remota não encontrada. Pulando pull." -ForegroundColor Yellow
}

# ==========================================
# PASSO 4: Status e Seleção de Arquivos
# ==========================================
Write-Host "`n[4/6] Analisando arquivos modificados/novos..." -ForegroundColor Yellow
git status -s

$statusPorcelain = git status --porcelain
if ([string]::IsNullOrEmpty($statusPorcelain)) {
    Write-Host "Nada para atualizar. O working directory está limpo." -ForegroundColor Green
    Exit
}

Write-Host "`nComo deseja adicionar as alterações?" -ForegroundColor Cyan
Write-Host "1) Adicionar TUDO (git add .)"
Write-Host "2) Selecionar manualmente os arquivos"
Write-Host "3) Cancelar operação"
$addStage = Read-Host "Escolha uma opção (1-3)"

switch ($addStage) {
    "1" {
        git add .
        Write-Host "✔ Todos os arquivos foram preparados (staged)." -ForegroundColor Green
    }
    "2" {
        $filesToAdd = Read-Host "Digite o caminho dos arquivos separados por espaço (ex: main.py config.json)"
        if (-not [string]::IsNullOrEmpty($filesToAdd)) {
            # Converte a string de arquivos separados por espaço em um array para o Git processar corretamente
            $fileList = $filesToAdd -split ' '
            git add $fileList
            Write-Host "✔ Arquivos selecionados foram preparados." -ForegroundColor Green
        } else {
            Write-Host "Nenhum arquivo informado. Cancelando..." -ForegroundColor Red
            Exit
        }
    }
    Default {
        Write-Host "Operação cancelada pelo usuário." -ForegroundColor Red
        Exit
    }
}

# ==========================================
# PASSO 5: Criação do Commit
# ==========================================
Write-Host "`n[5/6] Preparando o Commit..." -ForegroundColor Yellow
Write-Host "Escolha o tipo de alteração (Convenção de Commits):" -ForegroundColor Cyan
Write-Host "1) feat: Nova funcionalidade/arquivo"
Write-Host "2) fix: Correção de bug"
Write-Host "3) docs: Mudança em documentação (ex: README)"
Write-Host "4) refactor: Mudança de código que não altera comportamento"
Write-Host "5) custom: Digitar mensagem personalizada livre"
$commitTypeChoice = Read-Host "Escolha o tipo (1-5)"

$prefix = ""
switch ($commitTypeChoice) {
    "1" { $prefix = "feat: " }
    "2" { $prefix = "fix: " }
    "3" { $prefix = "docs: " }
    "4" { $prefix = "refactor: " }
    Default { $prefix = "" }
}

$commitMsg = Read-Host "Digite a mensagem descritiva do commit"
$finalMessage = "$prefix$commitMsg"

Write-Host "`nSua mensagem de commit será: `"$finalMessage`"" -ForegroundColor Green
$confirmCommit = Read-Host "Confirma a criação do commit? (s/n)"

switch ($confirmCommit) {
    { $_ -in 's', 'S', 'sim', 'Sim', 'SIM' } {
        git commit -m "$finalMessage"
        Write-Host "✔ Commit criado com sucesso!" -ForegroundColor Green
    }
    Default {
        Write-Host "Commit cancelado. As alterações continuam na área de stage." -ForegroundColor Red
        Exit
    }
}

# ==========================================
# PASSO 6: Push para o GitHub
# ==========================================
Write-Host "`n[6/6] Enviando para o GitHub..." -ForegroundColor Yellow
Write-Host "Você está enviando para a branch: $currentBranch" -ForegroundColor Cyan
$confirmPush = Read-Host "Confirma o envio definitivo (git push)? (s/n)"

switch ($confirmPush) {
    { $_ -in 's', 'S', 'sim', 'Sim', 'SIM' } {
        Write-Host "Subindo arquivos..." -ForegroundColor Cyan
        git push -u origin "$currentBranch"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n==================================================" -ForegroundColor Green
            Write-Host "    REPOSITÓRIO ATUALIZADO COM SUCESSO! 🚀       " -ForegroundColor Green
            Write-Host "==================================================" -ForegroundColor Green
        } else {
            Write-Host "ERRO ao fazer o push. Verifique suas permissões ou conexão." -ForegroundColor Red
        }
    }
    Default {
        Write-Host "Push cancelado. Suas alterações foram salvas localmente no commit." -ForegroundColor Red
    }
}
