<!--
## Arquiteto de Solução e Desenvolvedor Líder

**Márcio Rodrigues de Oliveira**

* Desenvolvedor Full Stack
* cda.marcio@gmail.com
-->

# 📐 Diagramas do Projeto

Este documento centraliza todos os diagramas de arquitetura e fluxo do **Sistema de Monitoramento Inteligente da Frota Escolar**.

---

## 1. Diagrama de Casos de Uso

Este diagrama descreve as principais interações entre os atores (usuários) e o sistema.

```mermaid
graph TD
    subgraph "Atores"
        M(Monitor)
        A(Administrador)
        S(Sistema)
    end

    subgraph "Casos de Uso"
        UC1[Fazer Login]
        UC2[Sincronizar Dados Iniciais]
        UC3[Realizar Reconhecimento Facial]
        UC4[Registrar Embarque/Desembarque]
        UC5[Visualizar Rota no Mapa]
        UC6[Gerar Relatório Local]
        UC7[Sincronizar Viagem Concluída]
        UC8[Gerenciar Alunos e Rotas]
        UC9[Auditar Viagens]
        UC10[Visualizar Dashboard]
        UC11[Capturar Coordenadas GPS]
    end

    M -- "Inicia a jornada" --> UC1
    M -- "Prepara o dispositivo" --> UC2
    M -- "Valida o aluno" --> UC3
    M -- "Confirma a presença" --> UC4
    M -- "Orienta-se" --> UC5
    M -- "Confere a viagem" --> UC6

    A -- "Gerencia dados" --> UC8
    A -- "Controla a operação" --> UC9
    A -- "Analisa resultados" --> UC10

    S -- "Processo automático" --> UC7
    S -- "Processo automático" --> UC11

    UC3 -- "inclui" --> UC4
    UC4 -- "inclui" --> UC11
```

---

## 2. Diagrama de Arquitetura da Solução (C4 - Nível 1: Contexto)

Visão macro do sistema e suas interações com sistemas externos e usuários.

```mermaid
graph TD
    subgraph "Sistema de Monitoramento Escolar"
        direction LR
        App["<b>Aplicativo Móvel</b><br>(Flutter)<br>Realiza a coleta de dados em campo (offline/online)."]
        API["<b>API Central</b><br>(ASP.NET Core)<br>Gerencia, armazena e disponibiliza os dados consolidados."]
    end

    Monitor["<b>Monitor de Ônibus</b><br>(Usuário)<br>Usa o aplicativo para registrar a frequência e rota."]
    Admin["<b>Administrador SEMEC</b><br>(Usuário)<br>Usa um painel web para gerenciar e auditar os dados."]

    Monitor -- "Usa" --> App
    App -- "Sincroniza dados via HTTPS/JSON" --> API
    Admin -- "Acessa" --> API

    style App fill:#2D9CDB,stroke:#333,stroke-width:2px
    style API fill:#27AE60,stroke:#333,stroke-width:2px
```

---

## 3. Diagrama de Componentes (C4 - Nível 2: Contêineres)

Detalha os principais blocos de construção (contêineres) do sistema.

```mermaid
graph TD
    subgraph "Dispositivo Móvel (Android)"
        direction TB
        FlutterApp["<b>Aplicativo Flutter</b><br><i>[Dart]</i><br>Interface do usuário e orquestração das tarefas."]
        SQLite["<b>Banco de Dados Local</b><br><i>[SQLite + SQLCipher]</i><br>Armazena dados de forma segura para operação offline."]

        FlutterApp -- "Lê/Escreve em" --> SQLite
    end

    subgraph "Infraestrutura do Servidor"
        direction TB
        WebApp["<b>Aplicação Web API</b><br><i>[ASP.NET Core]</i><br>Implementa a lógica de negócio e os endpoints."]
        PostgresDB["<b>Banco de Dados Central</b><br><i>[PostgreSQL]</i><br>Armazena permanentemente todos os dados do sistema."]

        WebApp -- "Lê/Escreve em" --> PostgresDB
    end

    Monitor["<b>Monitor</b><br>(Usuário)"]
    Admin["<b>Administrador</b><br>(Usuário)"]

    Monitor -- "Usa" --> FlutterApp
    FlutterApp -- "Faz chamadas API via HTTPS" --> WebApp
    Admin -- "Usa (via Browser)" --> WebApp

    style FlutterApp fill:#82D1F7
    style SQLite fill:#F4D03F
    style WebApp fill:#7DCEA0
    style PostgresDB fill:#5DADE2
```

---

## 4. Diagrama de Classes (Aplicativo Flutter)

Este diagrama detalha as principais classes do aplicativo mobile, suas responsabilidades e relacionamentos, com foco na tela de mapa.

```mermaid
classDiagram
    direction BT

    class ChangeNotifier {
        <<abstract>>
        +addListener()
        +removeListener()
        +notifyListeners()
    }

    class TickerProviderMixin {
        <<mixin>>
        +createTicker() Ticker
    }

    class MapController {
        <<State Controller>>
        -PlacesService _placesService
        -DirectionsService _directionsService
        -Set~Marker~ _markers
        -Set~Polyline~ _polylines
        -Set~Circle~ _circles
        -LatLng? _origin
        -LatLng? _destination
        +handleMapTap(LatLng, placeDetails) void
        +resetRoute() void
        +centerOnUserLocation() void
        +onCameraMove() void
        +selectNextRoute() void
    }

    class MapScreen {
        <<UI / Widget>>
        +build(BuildContext) Widget
        -buildSearchCard(MapController) Widget
        -buildRouteInfoCard(MapController) Widget
        -buildSuggestionsList(MapController) Widget
    }

    class AppShell {
        <<UI / Widget>>
        +build(BuildContext) Widget
    }

    class PlacesService { <<Service>> +getAutocomplete(String) Future~List~ }
    class DirectionsService { <<Service>> +getDirections(LatLng, LatLng) Future~Map~ }

    ChangeNotifier <|-- MapController
    MapController --|> TickerProviderMixin
    AppShell o-- MapScreen : exibe
    AppShell ..> MapController : provê via ChangeNotifierProvider
    MapScreen ..> MapController : consome via Consumer
    MapController "1" *-- "1" PlacesService : usa
    MapController "1" *-- "1" DirectionsService : usa
```

---

## 4. Diagrama de Entidade e Relacionamento (DER)

Modelo conceitual dos principais dados do sistema.

```mermaid
erDiagram
    ROTA {
        int id PK
        string nome
        string descricao
    }

    VEICULO {
        int id PK
        string placa
        string modelo
    }

    ALUNO {
        int id PK
        string nome
        string matricula
        blob vetor_facial
    }

    VIAGEM {
        int id PK
        datetime data_inicio
        datetime data_fim
        int id_rota FK
        int id_veiculo FK
    }

    EMBARQUE {
        int id PK
        datetime data_hora
        float latitude
        float longitude
        int id_viagem FK
        int id_aluno FK
    }

    ROTA ||--o{ VIAGEM : "possui"
    VEICULO ||--o{ VIAGEM : "realiza"
    VIAGEM ||--o{ EMBARQUE : "contém"
    ALUNO ||--o{ EMBARQUE : "realiza"
    ROTA }o--o{ ALUNO : "atende"
```

---

## 5. Diagrama de Sequência: Sincronização de Viagem

Descreve o fluxo de comunicação para enviar os dados coletados offline para o servidor central.

```mermaid
sequenceDiagram
    participant M as Monitor
    participant App as Aplicativo Flutter
    participant DB_Local as SQLite Criptografado
    participant API as API Central (E-SEMEC)
    participant DB_Central as PostgreSQL

    M->>App: Inicia a sincronização (ou é automático)
    App->>DB_Local: Ler viagens pendentes de sincronização
    DB_Local-->>App: Retorna lista de viagens e embarques

    loop Para cada viagem pendente
        App->>API: POST /api/viagens/sincronizar (payload com dados da viagem)
        API->>DB_Central: Inicia transação
        API->>DB_Central: Insere/Atualiza dados da Viagem
        API->>DB_Central: Insere/Atualiza dados dos Embarques
        DB_Central-->>API: Confirma transação
        API-->>App: Resposta de Sucesso (200 OK)
        App->>DB_Local: Atualiza status da viagem para "Sincronizado"
    end

    App-->>M: Notificação de sucesso
```

---

## 6. Diagrama de Implantação

Mostra como os componentes de software são distribuídos na infraestrutura de hardware.

```mermaid
deploymentDiagram
    node "Dispositivo Móvel (Android)" {
        artifact "app-bus.apk" {
            component [Aplicativo Flutter]
            database [Banco SQLite]
        }
    }

    node "Servidor Cloud (ex: Azure, AWS)" {
        node "Servidor de Aplicação" {
            artifact "api-semec.dll" {
                component [API ASP.NET Core]
            }
        }
        node "Servidor de Banco de Dados" {
            database [Banco PostgreSQL]
        }
    }

    [Aplicativo Flutter] -->> [API ASP.NET Core] : HTTPS/JSON
    [API ASP.NET Core] -->> [Banco PostgreSQL] : TCP/IP
```

---

## 7. Diagrama de Fluxo de Dados (DFD) - Nível 0

Ilustra o fluxo de informações entre o sistema e as entidades externas.

```mermaid
graph TD
    subgraph "Entidades Externas"
        E1(Monitor)
        E2(Administrador)
    end

    P1[Sistema de<br>Monitoramento<br>de Frota]

    subgraph "Armazenamento de Dados"
        D1[Dados de Viagens e Alunos]
    end

    E1 -- "Dados de Login e Embarques" --> P1
    P1 -- "Relatórios e Status da Rota" --> E1

    E2 -- "Dados de Gestão (Alunos, Rotas)" --> P1
    P1 -- "Dashboards e Auditorias" --> E2

    P1 -- "Armazena e Lê" --> D1

    style P1 fill:#A9CCE3,stroke:#333,stroke-width:2px,rx:10,ry:10
```
