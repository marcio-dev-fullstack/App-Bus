/// AUTOR:Arquiteto de Solução e Desenvolvedor Líder
/// Márcio Rodrigues de Oliveira
/// cda.marcio@gmail.com

# Manual de Testes – Aplicativo App-Bus

---

## 1. Objetivo do Teste

Validar as funcionalidades principais do aplicativo App-Bus em um ambiente de simulação, garantindo que todos os fluxos de usuário operem conforme o esperado e que o aplicativo esteja estável para a entrega ao cliente.

---

## 2. Pré-requisitos

### Passo 2.1: Preparar o Dispositivo de Teste

- **Opção A: Emulador Android:** Abra o Android Studio, vá em `Tools > Device Manager` e inicie um dos emuladores (API 29 ou superior recomendado).
- **Opção B: Dispositivo Físico:** Conecte seu celular Android ao computador com um cabo USB e certifique-se de que o **Modo de Desenvolvedor** e a **Depuração USB** estejam ativados nele.

### Passo 2.2: Instalar o Aplicativo para Teste

1. No VS Code, abra um terminal e navegue até a pasta raiz do projeto Flutter:
   ```powershell
   cd C:\PROJETOS\App-Bus\front_end
   ```
2. Execute o comando para instalar e rodar o aplicativo no dispositivo/emulador:
   ```powershell
   flutter run
   ```

### Passo 2.3: Dados de Teste

- Para realizar os testes de forma eficaz, é necessário ter pelo menos 2 ou 3 alunos cadastrados com seus respectivos vetores faciais. Se o banco de dados estiver vazio, comece pelo **Caso de Teste TC-02**.

---

## 3. Roteiro de Casos de Teste

Execute os passos abaixo e marque o status de cada teste.

### TC-01: Autenticação e Navegação

- **Funcionalidade:** Login, Logout e Navegação Principal.
- **Passos:**
  1.  Na tela de Login, insira as credenciais de teste.
  2.  Pressione o botão "Entrar".
  3.  Na tela "Home", toque no ícone "Mapa" na barra de navegação inferior.
  4.  Toque no ícone "Home" para retornar.
  5.  Na AppBar, toque no ícone de "Sair" (logout).
- **Resultado Esperado:**
  - Após o login, a tela "Home" deve ser exibida.
  - A navegação entre as telas "Home" e "Mapa" deve ocorrer sem erros.
  - Ao sair, o aplicativo deve retornar para a tela de Login.
- **Status:** `[ ] Passou` `[ ] Falhou`

---

### TC-02: Cadastro de Aluno com Reconhecimento Facial

- **Funcionalidade:** Cadastrar um novo aluno e capturar seu rosto.
- **Passos:**
  1.  Na tela "Home", toque no botão "Cadastrar".
  2.  Preencha os campos "Nome Completo" e "Matrícula".
  3.  Posicione um rosto em frente à câmera.
  4.  Toque no botão "CAPTURAR E SALVAR".
- **Resultado Esperado:**
  - Uma mensagem de "Aluno cadastrado com sucesso!" deve aparecer.
  - O aplicativo deve retornar para a tela anterior (Home).
  - O novo aluno deve aparecer na lista de alunos (verificar no TC-03).
- **Status:** `[ ] Passou` `[ ] Falhou`

---

### TC-03: Listagem, Busca e Ordenação de Alunos

- **Funcionalidade:** Gerenciar a lista de alunos cadastrados.
- **Passos:**
  1.  Na tela "Home", toque no botão "Alunos".
  2.  Verifique se a lista de alunos é exibida e se o contador no título está correto.
  3.  Toque no ícone de busca (lupa) e digite parte do nome de um aluno.
  4.  Verifique se a lista é filtrada corretamente e se o contador de alunos é atualizado.
  5.  Limpe o campo de busca e toque no ícone de fechar (X).
  6.  Toque no ícone de ordenação (três linhas) e selecione "Ordenar por Matrícula".
- **Resultado Esperado:**
  - A lista deve exibir todos os alunos.
  - A busca deve filtrar os resultados em tempo real com animação.
  - A lista deve ser reordenada conforme a opção selecionada.
  - A posição da rolagem e o termo de busca devem ser mantidos ao sair e voltar para a tela.
- **Status:** `[ ] Passou` `[ ] Falhou`

---

### TC-04: Edição e Exclusão de Aluno

- **Funcionalidade:** Modificar e remover registros de alunos.
- **Passos:**
  1.  Na tela "Lista de Alunos", toque em um dos alunos.
  2.  Na tela "Editar Aluno", modifique o nome e toque em "SALVAR".
  3.  Verifique se a lista foi atualizada com o novo nome.
  4.  Pressione e segure sobre um aluno na lista.
  5.  No diálogo de confirmação, toque em "Deletar".
- **Resultado Esperado:**
  - Os dados do aluno devem ser atualizados com sucesso.
  - O aluno selecionado deve ser removido da lista e do banco de dados.
- **Status:** `[ ] Passou` `[ ] Falhou`

---

### TC-05: Reconhecimento Facial para Embarque

- **Funcionalidade:** Validar o embarque de um aluno usando a câmera.
- **Passos:**
  1.  Na tela "Home", selecione uma rota e inicie uma viagem (este fluxo pode precisar de simulação se a UI não estiver completa).
  2.  Na tela "Embarque", posicione o rosto de um aluno **cadastrado** em frente à câmera.
  3.  Observe a borda do overlay e o contorno do rosto.
  4.  Mantenha o rosto centralizado até a confirmação.
  5.  Afaste o rosto e posicione o rosto de uma pessoa **não cadastrada**.
- **Resultado Esperado:**
  - A borda do overlay e o contorno do rosto devem ficar amarelos ao detectar um rosto.
  - Ao reconhecer um aluno cadastrado, a borda deve ficar verde e a mensagem "Bem-vindo(a), [Nome do Aluno]!" deve ser exibida.
  - Após alguns segundos, a tela deve voltar ao estado inicial, pronta para um novo reconhecimento.
  - Um rosto não cadastrado não deve ser confirmado, e a borda deve permanecer amarela ou branca.
- **Status:** `[ ] Passou` `[ ] Falhou`

---

### TC-06: Teste de Mapa e Rota

- **Funcionalidade:** Visualizar o mapa e traçar rotas.
- **Passos:**
  1.  Navegue para a tela "Mapa".
  2.  Aguarde o mapa carregar e centralizar na sua localização atual.
  3.  No campo "Origem", digite um endereço e selecione uma das sugestões.
  4.  No campo "Destino", digite outro endereço e selecione uma das sugestões.
- **Resultado Esperado:**
  - O mapa deve exibir um marcador na origem e no destino.
  - Uma linha (polilinha) representando a rota deve ser desenhada no mapa.
  - Um card com informações de distância e tempo da rota deve aparecer.
- **Status:** `[ ] Passou` `[ ] Falhou`
