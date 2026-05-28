
<div align="center">

![Plataforma](https://img.shields.io/badge/Plataforma-Windows_Desktop-0078D4?style=for-the-badge&logo=windows&logoColor=white)
![Framework](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Arquitetura](https://img.shields.io/badge/Padrão-Clean_Arch-💡?style=for-the-badge)
![Integração](https://img.shields.io/badge/E--SEMEC-Homologado-brightgreen?style=for-the-badge)

# 🖥️ App-Bus — Central de Gestão & Auditoria Escolar

**Painel Administrativo de Retaguarda desenvolvido para a Secretaria Municipal de Educação (SEMEC). O sistema atua como a central de comando para monitoramento de frotas, consolidação de frequências e auditoria de logs de embarque.**

</div>

---

## 📊 Escopo do Sistema Administrativo

Enquanto o **App-Bus** atua na ponta coletando os registros biométricos dos alunos nas rotas rurais, o **E-SEMEC** consolida esses dados na sede da Secretaria, oferecendo uma interface analítica para a gestão educacional:

* 👥 **Gestão de Alunos:** Sincronização e cruzamento do cadastro de matrículas com o banco de dados do E-SEMEC.
* 📈 **Painel de Auditoria:** Gráficos de assiduidade, alertas de inconsistências e monitoramento de sincronizações offline rebatidas pelos motoristas.
* 📑 **Módulo de Exportação:** Geração de relatórios gerenciais e planilhas unificadas para prestação de contas do PNATE.
* 🗺️ **Rastreamento de Rotas:** Visualização e mapeamento dos perímetros de geofencing das escolas polo.

---

## 🏗️ Estrutura Arquitetural do Módulo Desktop

O projeto segue as diretrizes de desenvolvimento do ecossistema Flutter Desktop, separando as responsabilidades de controle administrativo de forma limpa:

```text
lib/
│
├── core/                  # Configurações globais e inicialização de janelas
│   ├── theme/             # Identidade visual corporativa da SEMEC
│   └── network/           # Cliente HTTP para consumo do barramento E-SEMEC
│
├── data/                  # Repositórios e comunicação com serviços externos
│   ├── models/            # Modelos de dados (Aluno, Rota, LogAuditoria)
│   └── datasources/       # Requisições diretas de API
│
├── providers/             # Gerenciamento de estado global e cache gerencial
│
└── screens/               # Telas adaptadas para ambiente Desktop (1280x800+)
    ├── dashboard_screen.dart   # Visão analítica geral das rotas rurais
    ├── auditoria_screen.dart   # Tabela de conferência de logs e biometria
    └── alunos_screen.dart      # Controle e espelhamento de matrículas

```

---

## ⚡ Requisitos e Configuração do Ambiente

Por se tratar de uma aplicação nativa para Windows, certifique-se de ter os componentes de compilação desktop instalados na sua máquina de desenvolvimento:

### 1. Pré-requisitos do Sistema

* Flutter SDK (Versão estável)
* Ferramentas de compilação C++ do **Visual Studio** (Development with C++)

### 2. Inicialização do Projeto

Abra o terminal na pasta raiz do projeto `Bus-Desktop` e execute o comando para baixar os pacotes de integração:

```bash
# Sincroniza as dependências do projeto
flutter pub get

```

### 3. Execução em Modo de Desenvolvimento

Como o seu script local já automatiza o bind de portas na rede, para rodar o ambiente Desktop nativo no Windows, utilize o comando:

```bash
flutter run -d windows

```

---

## ☁️ Comunicação Side-by-Side (Ecossistema)

O ecossistema opera de forma integrada com os demais microsserviços através da API central:

```text
  ┌─────────────────┐           ┌──────────────────┐
  │     App-Bus     │           │   Bus-Desktop    │
  │ (Campos/Rotas)  │           │ (Secretaria/Adm) │
  └────────┬────────┘           └────────┬─────────┘
           │                             │
           ▼                             ▼
  ┌────────────────────────────────────────────────┘
  │        API Gateway — Backend (FastAPI)
  │        ➔ Banco de Dados Central E-SEMEC
  └────────────────────────────────────────────────┘

```

---

## 👥 Desenvolvimento


**MÁRCIO RODRIGUES DE OLIVEIRA - DEV FULLSTACK.**

Especificado, Desenvolvido e Gerenciado no ecossistema de TI da SEMEC.


```
