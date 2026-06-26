# Inicializa o repositório local (caso ainda não tenha feito)
git init

# Adiciona todos os arquivos do projeto ao stage
git add .

# Cria o primeiro commit local
git commit -m "Initial commit: Estrutura base do APP-BUS"

# 1. Vincula a sua pasta local ao repositório do GitHub
git remote add origin https://github.com/marcio-dev-fullstack/App-Bus.git

# 2. Garante que você está na branch principal ('main')
git branch -M main

# 3. Envia e força o alinhamento inicial
git push -u origin main --force