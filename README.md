
# BusEscolar
Sistema Inteligente de Monitoramento do Transporte Escolar

![version](https://img.shields.io/badge/version-v1.1-blue)
![status](https://img.shields.io/badge/status-em%20desenvolvimento-yellow)
![platform](https://img.shields.io/badge/platform-React%20Native-blue)
![database](https://img.shields.io/badge/database-SQLite-orange)
![security](https://img.shields.io/badge/security-AES--256-green)

---

# Visão Geral

O **BusEscolar** é um sistema de monitoramento e auditoria do transporte escolar desenvolvido para a **Prefeitura de Conceição do Araguaia (SEMEC)**.

O sistema opera em **modo Offline First**, permitindo funcionamento em regiões rurais com baixa conectividade.

## Principais recursos:

**Offline First**: Operação total em zonas rurais sem sinal de internet.

**Reconhecimento Facial**: Validação de embarque via biometria facial processada localmente (Edge Computing).

**Rastreamento GPS**: Monitoramento contínuo do trajeto para conformidade com FNDE/INEP.

**Sincronização Inteligente**: Fila de upload automático ao detectar Wi-Fi ou sinal estável.

**Segurança (LGPD)**: Banco de dados SQLite criptografado para proteção de dados de menores.

---

# Documentação Técnica

Arquivos de documentação:

- Arquitetura → docs/arquitetura.md
- Banco de Dados → docs/banco.md
- Fluxo de Embarque → docs/fluxo-embarque.md
- Telas do Sistema → docs/telas.md
- Demonstração → docs/demo.md

---

# Tecnologias Utilizadas

**Frontend**: Flutter (Dart).

**Banco de Dados**: SQLite com SQLCipher (AES-256).

**Motor Biométrico**: Google ML Kit / TensorFlow Lite.

**Backend**: Integração via API com o sistema E-SEMEC (PostgreSQL).

**Segurança**: Autenticação JWT e Criptografia AES-256.

---

# Instalação

Clone o projeto:
git clone https://github.com/cdamarcio/Bus.git

Entre na pasta:

cd Bus

Instale dependências:

npm install

Execute:

npx expo start

---

## Como Operar o Sistema

1. **Início da Rota**: O monitor seleciona a rota designada no tablet.
   
3. **Embarque**: O aluno posiciona-se à frente da câmera. O sistema realiza o reconhecimento em < 3 segundos.

4. **Fallback**: Caso a biometria falhe, o monitor pode realizar o registro manual.

5. **Encerramento**: Ao chegar na escola, o sistema reconhece o perímetro (Geofencing) e inicia a sincronização dos logs.

---

## Autor

**Márcio Rodrigues de Oliveira | Desenvolvedor Líder Fullstack | cda.marcio@gmail.com**

---

### MIT License

### Copyright (c) 2026 MARCIO RODRIGUES DE OLIVEIRA

É concedida permissão, gratuitamente, a qualquer pessoa que obtenha uma cópia
deste software e arquivos de documentação associados (o "Software"), para lidar
com o Software sem restrições, incluindo, sem limitação, os direitos
de usar, copiar, modificar, fundir, publicar, distribuir, sublicenciar e/ou vender
cópias do Software, e para permitir que as pessoas a quem o Software é
fornecido o façam, sujeitas às seguintes condições:

O aviso de direitos autorais acima e este aviso de permissão devem ser incluídos em todas as
cópias ou partes substanciais do Software.

O SOFTWARE É FORNECIDO "NO ESTADO EM QUE SE ENCONTRA", SEM GARANTIA DE QUALQUER TIPO, EXPRESSA OU
IMPLÍCITA, INCLUINDO, MAS NÃO SE LIMITANDO ÀS GARANTIAS DE COMERCIALIZAÇÃO,
ADEQUAÇÃO A UM FIM ESPECÍFICO E NÃO VIOLAÇÃO. EM NENHUMA HIPÓTESE OS
AUTORES OU DETENTORES DOS DIREITOS AUTORAIS SERÃO RESPONSÁVEIS POR QUAISQUER REIVINDICAÇÕES, DANOS OU OUTRAS
RESPONSABILIDADES, SEJA EM AÇÃO CONTRATUAL, EXTRACONTRATUAL OU DE OUTRA NATUREZA, DECORRENTES DE,
OU RELACIONADAS COM O SOFTWARE OU O USO OU OUTRAS NEGOCIAÇÕES COM O
SOFTWARE.