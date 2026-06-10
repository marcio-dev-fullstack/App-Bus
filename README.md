# 🚍 Sistema de Monitoramento da Frota Escolar

![Version](https://img.shields.io/badge/version-1.1-blue.svg)
![Status](https://img.shields.io/badge/status-Em%20Desenvolvimento-orange.svg)
![Platform](https://img.shields.io/badge/platform-Android-green.svg)
![License](https://img.shields.io/badge/license-Proprietário-red.svg)

## 📋 Sobre o Projeto

O **Sistema de Monitoramento da Frota Escolar** é uma solução tecnológica desenvolvida para a **Secretaria Municipal de Educação (SEMEC) de Conceição do Araguaia - PA**, com o objetivo de modernizar e automatizar o controle do transporte escolar municipal.

A aplicação foi concebida seguindo a filosofia **Offline First**, permitindo operação contínua mesmo em regiões sem cobertura de internet, cenário comum nas rotas rurais do município.

O sistema realiza:

* Reconhecimento facial de alunos embarcados;
* Registro automatizado de frequência;
* Rastreamento GPS das rotas;
* Auditoria completa das viagens;
* Integração com o sistema E-SEMEC;
* Geração de relatórios gerenciais.

---

# 🎯 Objetivos

## Objetivos Principais

### ✔ Automatização da Chamada Escolar

Eliminar processos manuais através da identificação biométrica facial.

### ✔ Auditoria de Rotas

Registrar geolocalização do trajeto para fins de fiscalização e conformidade com:

* FNDE
* INEP
* Tribunal de Contas
* Ministério Público

### ✔ Digitalização dos Processos

Eliminar planilhas e registros em papel utilizados atualmente.

---

# 🏗 Arquitetura da Solução

```text
┌──────────────────────────────┐
│      Sistema E-SEMEC         │
│      PostgreSQL/API          │
└──────────────┬───────────────┘
               │
        Internet/Wi-Fi
               │
┌──────────────▼───────────────┐
│    Aplicativo Mobile         │
│         Flutter              │
└──────────────┬───────────────┘
               │
      SQLite Criptografado
               │
┌──────────────▼───────────────┐
│ Reconhecimento Facial Offline│
│      ML Kit / FaceNet        │
└──────────────────────────────┘
```

---

# ⚙ Funcionalidades

## RF-001 - Sincronização de Dados

Realiza download automático de:

* Alunos
* Matrículas
* Fotos biométricas
* Rotas
* Escolas
* Pontos de parada

### Fluxo

```text
SEMEC API
     ↓
Download
     ↓
SQLite Local
     ↓
Operação Offline
```

---

## RF-002 - Reconhecimento Facial Offline

### Características

* Processamento local (Edge Computing)
* Não depende de internet
* Identificação instantânea
* Utilização de IA embarcada

### Tecnologias sugeridas

* Google ML Kit
* TensorFlow Lite
* FaceNet

### Meta de desempenho

```text
Tempo de reconhecimento:
< 3 segundos
```

---

## RF-003 - Embarque Manual (Fallback)

Caso ocorra:

* Falha biométrica
* Baixa iluminação
* Rosto coberto
* Lesão facial

O monitor poderá:

* Pesquisar aluno
* Selecionar manualmente
* Confirmar embarque

---

## RF-004 - Rastreamento de Rota

Registro contínuo de:

* Latitude
* Longitude
* Data
* Hora
* Velocidade (opcional)

Cada embarque fica vinculado ao local exato onde ocorreu.

---

## RF-005 - Geofencing Inteligente

O sistema detecta automaticamente:

### Entrada na escola

ou

### Conexão Wi-Fi autorizada

Disparando:

```text
Sincronização automática
dos dados coletados.
```

---

## RF-006 - Relatórios

### Disponíveis

* Alunos embarcados
* Alunos ausentes
* Quilometragem percorrida
* Tempo de viagem
* Histórico de rotas

Exportação:

* PDF
* Tela
* API

---

# 🔒 Segurança

## LGPD

O sistema manipula dados de menores de idade.

Por isso:

### Banco Criptografado

```text
AES-256
SQLCipher
```

### Autenticação

```text
JWT
OAuth 2.0 (Futuro)
```

### Dados Protegidos

* Nome
* Matrícula
* Fotografias
* Vetores biométricos
* Localização

---

# 📱 Requisitos de Hardware

## Dispositivos

* Tablets Android
* Smartphones Android

### Requisitos mínimos

| Item          | Especificação       |
| ------------- | ------------------- |
| Android       | 10+                 |
| RAM           | 3 GB                |
| Armazenamento | 32 GB               |
| GPS           | Obrigatório         |
| Câmera        | Frontal ou Traseira |

---

# 🎨 UX/UI

Identidade visual baseada nas cores oficiais de Conceição do Araguaia.

### Paleta

```css
Verde
Amarelo
Azul
Branco
```

### Diretrizes

* Botões grandes
* Alto contraste
* Operação com uma mão
* Uso em movimento

---

# 🗄 Estrutura de Banco de Dados

## Tabela: alunos

```sql
CREATE TABLE alunos (
    id UUID PRIMARY KEY,
    matricula VARCHAR(30),
    nome VARCHAR(255),
    hash_facial TEXT,
    escola_id UUID
);
```

## Tabela: embarques

```sql
CREATE TABLE embarques (
    id UUID PRIMARY KEY,
    aluno_id UUID,
    data_hora TIMESTAMP,
    latitude DOUBLE,
    longitude DOUBLE,
    sincronizado BOOLEAN
);
```

## Tabela: rotas

```sql
CREATE TABLE rotas (
    id UUID PRIMARY KEY,
    veiculo_id UUID,
    descricao VARCHAR(255)
);
```

---

# 🔄 APIs

## Download de Dados

```http
GET /api/rotas/{id_veiculo}/alunos
```

### Resposta

```json
{
  "id": 1,
  "nome": "Aluno Exemplo",
  "matricula": "20260001"
}
```

---

## Upload de Viagens

```http
POST /api/viagens/sincronizar
```

### Payload

```json
{
  "embarques": [],
  "coordenadas": []
}
```

---

# 🚀 Tecnologias Recomendadas

## Frontend

* Flutter
* Dart

## Backend

* ASP.NET Core
* Node.js
* Laravel

## Banco

* PostgreSQL
* SQLite

## IA

* TensorFlow Lite
* Google ML Kit

## Mapas

* OpenStreetMap
* Google Maps

---

# 🔄 Fluxo Operacional

```text
1. Login do Monitor
          ↓
2. Download de Dados
          ↓
3. Início da Rota
          ↓
4. Reconhecimento Facial
          ↓
5. Registro GPS
          ↓
6. Chegada na Escola
          ↓
7. Sincronização
          ↓
8. Relatórios
```

---

# 📈 Melhorias Futuras

## Planejadas

* Dashboard Web
* Aplicativo para Pais
* Notificações em Tempo Real
* QR Code de Emergência
* Reconhecimento de Placa do Veículo
* Inteligência Artificial para Auditoria

---

# 👨‍💻 Equipe do Projeto

## Cliente

Secretaria Municipal de Educação (SEMEC)

## Supervisor

Alcides Platiny Alves Batista

## Desenvolvedor Líder

Márcio Rodrigues de Oliveira

---

# 📄 Licença

Este software é propriedade da Prefeitura Municipal de Conceição do Araguaia e da Secretaria Municipal de Educação (SEMEC).

Todos os direitos reservados.

---

# 📞 Contato

**Márcio Rodrigues de Oliveira**

Desenvolvedor Full Stack | Engenheiro de Software

🌐 [https://mgrupo.online](https://mgrupo.online/RAZGO-Tecnologia/index.html)

---

© 2026 - Sistema de Monitoramento da Frota Escolar
Prefeitura de Conceição do Araguaia - PA
