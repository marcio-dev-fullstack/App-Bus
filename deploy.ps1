# Configuração de Codificação para o Terminal Windows
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Clear-Host
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "    ESTEIRA DE ATUALIZAÇÃO REPOSITÓRIO GITHUB     " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# URL Oficial do Projeto
$RepoUrl = "https://github.com/marcio-dev-fullstack/App-Bus.git"

# ==========================================
# PASSO 1: Verificar se é um repositório Git
# ==========================================
Write-Host ""
Write-Host "[1/6] Verificando ambiente local..." -ForegroundColor Yellow

if (-not (Test-Path -Path ".git" -PathType Container)) {
    Write-Host "ERRO: Esta pasta nao e um repositorio Git local." -ForegroundColor Red
    $initChoice = Read-Host "Deseja iniciar (git init) nesta pasta agora? (s/n)"
    if ($initChoice -match "^(s|S|sim|Sim|SIM)$") {
        git init
        Write-Host "Repositorio inicializado com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "Operacao cancelada. Abortando..." -ForegroundColor Red
        Exit
    }
} else {
    Write-Host "✔ Pasta local ja e um repositorio Git." -ForegroundColor Green
}

# ==========================================
# PASSO 2: Verificar conexão com o Remote (GitHub)
# ==========================================
Write-Host ""
Write-Host "[2/6] Verificando conexao remota..." -ForegroundColor Yellow
$remotes = git remote -v
if (-not ($remotes -match 'origin')) {
    Write-Host "Aviso: Nenhum repositorio remoto 'origin' configurado." -ForegroundColor Yellow
    Write-Host "Configurando URL oficial: $RepoUrl" -ForegroundColor Cyan
    git remote add origin $RepoUrl
    Write-Host "✔ Origem remota adicionada com sucesso!" -ForegroundColor Green
} else {
    # Garante que a URL cadastrada seja exatamente a do seu repositório oficial
    git remote set-url origin $RepoUrl
    Write-Host "✔ Repositorio remoto alinhado com o GitHub oficial:" -ForegroundColor Green
    git remote -v | Select-String "push" | ForEach-Object { Write-Host $_.Line -ForegroundColor Gray }
}

# ==========================================
# PASSO 3: Sincronizar com o Remote (Evitar conflitos)
# ==========================================
Write-Host ""
Write-Host "[3/6] Sincronizando com o GitHub (Fetch/Pull)..." -ForegroundColor Yellow
$currentBranch = (git branch --show-current)
if ($null -ne $currentBranch) { $currentBranch = $currentBranch.Trim() }

if ([string]::IsNullOrEmpty($currentBranch)) {
    $currentBranch = "main"
    Write-Host "Nenhuma branch detectada. Definindo branch padrao como: '$currentBranch'" -ForegroundColor Yellow
    git branch -M "$currentBranch"
}

Write-Host "Buscando atualizacoes na branch de origem: $currentBranch..." -ForegroundColor Cyan
git fetch origin "$currentBranch" 2>$null

$remoteBranchExists = git rev-parse --verify origin/"$currentBranch" 2>$null
if ($remoteBranchExists) {
    Write-Host "Verificando se ha atualizacoes pendentes no servidor..." -ForegroundColor Cyan
    $localSHA = git rev-parse HEAD 2>$null
    $remoteSHA = git rev-parse origin/"$currentBranch" 2>$null

    if ($localSHA -ne $remoteSHA -and -not [string]::IsNullOrEmpty($localSHA)) {
        Write-Host "Aviso: Seu repositorio remoto tem modificacoes que voce nao tem localmente." -ForegroundColor Yellow
        $pullChoice = Read-Host "Deseja fazer o 'git pull' antes de continuar? (s/n)"
        if ($pullChoice -match "^(s|S|sim|Sim|SIM)$") {
            git pull origin "$currentBranch"
            Write-Host "✔ Repositorio atualizado localmente." -ForegroundColor Green
        } else {
            Write-Host "Aviso: Prosseguindo sem atualizar. Isso pode gerar conflitos no push." -ForegroundColor Red
        }
    } else {
        Write-Host "✔ Seu repositorio local esta em sincronia com o remoto." -ForegroundColor Green
    }
} else {
    Write-Host "Primeiro push detectado ou branch remota nao encontrada. Pulando pull." -ForegroundColor Yellow
}

# ==========================================
# PASSO 4: Status e Seleção de Arquivos
# ==========================================
Write-Host ""
Write-Host "[4/6] Analisando arquivos modificados/novos..." -ForegroundColor Yellow
git status -s

$statusPorcelain = git status --porcelain
if ([string]::IsNullOrEmpty($statusPorcelain)) {
    Write-Host "Nada para atualizar. O working directory esta limpo." -ForegroundColor Green
    Exit
}

Write-Host ""
Write-Host "Como deseja adicionar as alteracoes?" -ForegroundColor Cyan
Write-Host "1) Adicionar TUDO (git add .)"
Write-Host "2) Selecionar manualmente os arquivos"
Write-Host "3) Cancelar operacao"
$addStage = Read-Host "Escolha uma opcao (1-3)"

if ($addStage -eq "1") {
    git add .
    Write-Host "✔ Todos os arquivos foram preparados (staged)." -ForegroundColor Green
} elseif ($addStage -eq "2") {
    $filesToAdd = Read-Host "Digite o caminho dos arquivos separados por espaco (ex: main.py config.json)"
    if (-not [string]::IsNullOrEmpty($filesToAdd)) {
        $fileList = $filesToAdd -split ' '
        git add $fileList
        Write-Host "✔ Arquivos selecionados foram preparados." -ForegroundColor Green
    } else {
        Write-Host "Nenhum arquivo informado. Cancelando..." -ForegroundColor Red
        Exit
    }
} else {
    Write-Host "Operacao cancelada pelo usuario." -ForegroundColor Red
    Exit
}

# ==========================================
# PASSO 5: Criação do Commit
# ==========================================
Write-Host ""
Write-Host "[5/6] Preparando o Commit..." -ForegroundColor Yellow
Write-Host "Escolha o tipo de alteracao (Convencao de Commits):" -ForegroundColor Cyan
Write-Host "1) feat: Nova funcionalidade/arquivo"
Write-Host "2) fix: Correcao de bug"
Write-Host "3) docs: Mudanca em documentacao (ex: README)"
Write-Host "4) refactor: Mudanca de codigo que nao altera comportamento"
Write-Host "5) custom: Digitar mensagem personalizada livre"
$commitTypeChoice = Read-Host "Escolha o tipo (1-5)"

$prefix = ""
if ($commitTypeChoice -eq "1") { $prefix = "feat: " }
if ($commitTypeChoice -eq "2") { $prefix = "fix: " }
if ($commitTypeChoice -eq "3") { $prefix = "docs: " }
if ($commitTypeChoice -eq "4") { $prefix = "refactor: " }

$commitMsg = Read-Host "Digite a mensagem descritiva do commit"
$finalMessage = "$prefix$commitMsg"

Write-Host ""
Write-Host "Sua mensagem de commit será: `"$finalMessage`"" -ForegroundColor Green
$confirmCommit = Read-Host "Confirma a criacao do commit? (s/n)"

if ($confirmCommit -match "^(s|S|sim|Sim|SIM)$") {
    git commit -m "$finalMessage"
    Write-Host "✔ Commit criado com sucesso!" -ForegroundColor Green
} else {
    Write-Host "Commit cancelado. As alteracoes continuam na area de stage." -ForegroundColor Red
    Exit
}

# ==========================================
# PASSO 6: Push para o GitHub com Validação Estrita
# ==========================================
Write-Host ""
Write-Host "[6/6] Enviando para o GitHub..." -ForegroundColor Yellow
Write-Host "Voce esta enviando para a branch: $currentBranch" -ForegroundColor Cyan
$confirmPush = Read-Host "Confirma o envio definitivo (git push)? (s/n)"

if ($confirmPush -match "^(s|S|sim|Sim|SIM)$") {
    Write-Host "Subindo arquivos..." -ForegroundColor Cyan
    
    # Executa o push
    git push -u origin "$currentBranch"
    
    # Valida o resultado final do Git (Código de saída deve ser 0 para sucesso)
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "==================================================" -ForegroundColor Green
        Write-Host "    REPOSITORIO ATUALIZADO COM SUCESSO! 🚀       " -ForegroundColor Green
        Write-Host "==================================================" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "--------------------------------------------------" -ForegroundColor Red
        Write-Host "    ERRO: Ocorreu uma falha ao tentar fazer o push." -ForegroundColor Red
        Write-Host "    Verifique suas permissoes ou conexao.        " -ForegroundColor Red
        Write-Host "--------------------------------------------------" -ForegroundColor Red
    }
} else {
    Write-Host "Push cancelado. Suas alteracoes foram salvas localmente no commit." -ForegroundColor Red
}