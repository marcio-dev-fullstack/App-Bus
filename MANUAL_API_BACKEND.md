/// AUTOR:Arquiteto de Solução e Desenvolvedor Líder
/// Márcio Rodrigues de Oliveira
/// cda.marcio@gmail.com

---

## 1. Objetivo

Este documento serve como um guia passo a passo para a criação e configuração da API de backend para o sistema **App-Bus**. A API será responsável por receber os dados sincronizados do aplicativo Flutter, processá-los e armazená-los no banco de dados central do e-SEMEC.

---

## 2. Passo a Passo da Implementação

### Passo 2.1: Criar o Projeto da API ASP.NET Core

O primeiro passo é criar a estrutura base do projeto de API.

1.  Abra um terminal na raiz do repositório: `c:\PROJETOS\App-Bus\`.
2.  Execute o comando do .NET CLI para criar um novo projeto de Web API em uma pasta `backend`:
    ```bash
    dotnet new webapi -n AppBus.Backend -o backend
    ```
    Isso criará uma estrutura de projeto ASP.NET Core dentro da pasta `backend`.

---

### Passo 2.2: Conectar ao Banco de Dados com Entity Framework Core

O Entity Framework (EF) Core é o ORM (Object-Relational Mapper) que usaremos para mapear as tabelas do banco de dados para classes C#.

1.  **Instale os pacotes necessários:** Navegue até a nova pasta e adicione os pacotes do EF Core e do provedor PostgreSQL.

    ```bash
    cd backend
    dotnet add package Microsoft.EntityFrameworkCore.Design
    dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL
    ```

2.  **Defina suas Entidades (Models):** Crie uma pasta `Models` e adicione as classes C# que correspondem às suas tabelas do DER.

    **`Models/Viagem.cs`**

    ```csharp
    public class Viagem
    {
        public int Id { get; set; }
        public DateTime DataInicio { get; set; }
        public DateTime? DataFim { get; set; }
        public int IdRota { get; set; }
        public int IdVeiculo { get; set; }
        public bool Sincronizado { get; set; }
        public List<Embarque> Embarques { get; set; } = new();
    }
    ```

    **`Models/Embarque.cs`**

    ```csharp
    public class Embarque
    {
        public int Id { get; set; }
        public DateTime DataHora { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public int IdViagem { get; set; }
        public int IdAluno { get; set; }
    }
    ```

    _(Adicione outras classes de modelo como `Aluno.cs` e `Rota.cs` conforme necessário)._

3.  **Crie o `DbContext`:** Esta classe é a "ponte" entre seu código e o banco de dados. Crie uma pasta `Data` e adicione o arquivo:

    **`Data/SemecDbContext.cs`**

    ```csharp
    using Microsoft.EntityFrameworkCore;
    using AppBus.Backend.Models;

    namespace AppBus.Backend.Data
    {
        public class SemecDbContext : DbContext
        {
            public SemecDbContext(DbContextOptions<SemecDbContext> options) : base(options) { }

            public DbSet<Viagem> Viagens { get; set; }
            public DbSet<Embarque> Embarques { get; set; }
            // public DbSet<Aluno> Alunos { get; set; }
            // public DbSet<Rota> Rotas { get; set; }
        }
    }
    ```

4.  **Configure a Conexão:** Abra o arquivo `appsettings.json` e adicione a sua string de conexão com o PostgreSQL.

    ```json
    {
      "ConnectionStrings": {
        "DefaultConnection": "Host=SEU_SERVIDOR_PG;Database=e-semec;Username=SEU_USUARIO;Password=SUA_SENHA"
      },
      "Logging": {
        "LogLevel": {
          "Default": "Information",
          "Microsoft.AspNetCore": "Warning"
        }
      },
      "AllowedHosts": "*"
    }
    ```

5.  **Registre o `DbContext`:** No arquivo `Program.cs`, configure o serviço para usar o `DbContext` e a string de conexão.

    ```csharp
    using Microsoft.EntityFrameworkCore;
    using AppBus.Backend.Data;

    var builder = WebApplication.CreateBuilder(args);

    // Adiciona a string de conexão
    var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
    builder.Services.AddDbContext<SemecDbContext>(options =>
        options.UseNpgsql(connectionString));

    builder.Services.AddControllers();
    builder.Services.AddEndpointsApiExplorer();
    builder.Services.AddSwaggerGen();

    var app = builder.Build();

    if (app.Environment.IsDevelopment())
    {
        app.UseSwagger();
        app.UseSwaggerUI();
    }

    app.UseHttpsRedirection();
    app.UseAuthorization();
    app.MapControllers();
    app.Run();
    ```

---

### Passo 2.3: Criar o Controller e o Endpoint de Sincronização

Este é o endpoint que o aplicativo Flutter chamará para enviar os dados coletados offline.

1.  **Crie o Controller:** Na pasta `Controllers`, crie um novo arquivo `ViagensController.cs`.
2.  **Implemente o Endpoint:** Adicione o método `Sincronizar` que recebe os dados da viagem.

    **`Controllers/ViagensController.cs`**

    ```csharp
    using Microsoft.AspNetCore.Mvc;
    using AppBus.Backend.Data;
    using AppBus.Backend.Models;
    using Microsoft.AspNetCore.Authorization; // Será usado para autenticação

    namespace AppBus.Backend.Controllers
    {
        [ApiController]
        [Route("api/[controller]")]
        public class ViagensController : ControllerBase
        {
            private readonly SemecDbContext _context;

            public ViagensController(SemecDbContext context)
            {
                _context = context;
            }

            // POST: api/viagens/sincronizar
            [HttpPost("sincronizar")]
            // [Authorize] // Descomente esta linha após configurar a autenticação JWT
            public async Task<IActionResult> Sincronizar([FromBody] Viagem viagemPayload)
            {
                if (viagemPayload == null || viagemPayload.Embarques == null)
                {
                    return BadRequest("Dados da viagem inválidos.");
                }

                try
                {
                    // Inicia uma transação para garantir a consistência dos dados.
                    using var transaction = await _context.Database.BeginTransactionAsync();

                    // Adiciona a viagem e seus embarques ao contexto do EF Core.
                    _context.Viagens.Add(viagemPayload);

                    // Salva todas as mudanças no banco de dados.
                    await _context.SaveChangesAsync();

                    // Confirma a transação.
                    await transaction.CommitAsync();

                    return Ok(new { message = "Viagem sincronizada com sucesso!" });
                }
                catch (Exception ex)
                {
                    // Em caso de erro, retorna uma resposta de erro do servidor.
                    // Idealmente, você logaria o erro aqui.
                    return StatusCode(500, $"Erro interno do servidor: {ex.Message}");
                }
            }
        }
    }
    ```

---

### Passo 2.4: Rodar e Testar a API

Com o endpoint criado, você pode iniciar a API para testes.

1.  No terminal, dentro da pasta `backend`, execute:
    ```bash
    dotnet run
    ```
2.  A API estará rodando em um endereço como `https://localhost:7123`.
3.  Você pode usar ferramentas como o **Swagger** (acessando `/swagger` no navegador), **Postman** ou **Insomnia** para enviar uma requisição `POST` para `/api/viagens/sincronizar` com um JSON de exemplo e verificar se os dados são salvos no banco.

---

## 3. Implementando Autenticação Segura com ASP.NET Core Identity e JWT

Para proteger a API e gerenciar usuários de forma segura, usaremos o **ASP.NET Core Identity** para o gerenciamento de usuários e senhas, combinado com **JWT** para a autenticação baseada em tokens.

### Passo 3.1: Instalar os Pacotes Necessários

No terminal, na pasta `backend`, instale o pacote de autenticação do ASP.NET Core:

```bash
dotnet add package Microsoft.AspNetCore.Identity.EntityFrameworkCore
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer
```

### Passo 3.2: Configurar `appsettings.json`

Adicione uma seção `Jwt` ao seu `appsettings.json` para armazenar a chave secreta e outras configurações do token.

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "..."
  },
  "Jwt": {
    "Key": "SUA_CHAVE_SECRETA_SUPER_LONGA_E_SEGURA_AQUI_COM_PELO_MENOS_32_CARACTERES",
    "Issuer": "AppBus.Backend",
    "Audience": "AppBus.MobileApp"
  },
  "Logging": {
    //...
  }
}
```

> **IMPORTANTE:** A `Key` deve ser uma string longa e complexa, e deve ser mantida em segredo. Em um ambiente de produção, use o "User Secrets" do .NET ou um cofre de chaves como o Azure Key Vault.

### Passo 3.3: Configurar `Program.cs`

Registre os serviços de autenticação e adicione o middleware ao pipeline de requisições.

```csharp
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
// ... outros usings

var builder = WebApplication.CreateBuilder(args);

// ... configuração do DbContext

// --- INÍCIO DA CONFIGURAÇÃO JWT ---
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = builder.Configuration["Jwt:Issuer"],
        ValidAudience = builder.Configuration["Jwt:Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]))
    };
});
// --- FIM DA CONFIGURAÇÃO JWT ---

builder.Services.AddControllers();
// ...

var app = builder.Build();

// ...
app.UseHttpsRedirection();

// Adiciona os middlewares de autenticação e autorização
// IMPORTANTE: A ordem é crucial! Deve vir antes de `MapControllers`.
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.Run();
```

### Passo 3.4: Criar o Endpoint de Login

Crie um novo controller para lidar com a autenticação e a geração de tokens.

**`Models/LoginModel.cs`**

```csharp
public class LoginModel
{
    public required string Email { get; set; }
    public required string Password { get; set; }
}
```

**`Controllers/AuthController.cs`**

```csharp
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using AppBus.Backend.Models;

namespace AppBus.Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IConfiguration _configuration;

        public AuthController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        [HttpPost("login")]
        public IActionResult Login([FromBody] LoginModel login)
        {
            // ATENÇÃO: Lógica de validação de exemplo.
            // Substitua pela sua lógica real de validação contra o banco de dados.
            if (login.Email == "monitor@semec.com" && login.Password == "senha123")
            {
                var token = GenerateJwtToken(login.Email);
                return Ok(new { token });
            }

            return Unauthorized("Credenciais inválidas.");
        }

        private async Task<string> GenerateJwtToken(ApplicationUser user)
        {
            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            var userRoles = await _userManager.GetRolesAsync(user);

            var claims = new List<Claim>
            {
                new Claim(JwtRegisteredClaimNames.Sub, email),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            var token = new JwtSecurityToken(
                issuer: _configuration["Jwt:Issuer"],
                audience: _configuration["Jwt:Audience"],
                claims: claims,
                expires: DateTime.Now.AddHours(8), // Duração do token
                signingCredentials: credentials);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}
```

### Passo 3.5: Proteger o Endpoint de Sincronização

Adicione o atributo `[Authorize]` ao método `Sincronizar` no `ViagensController.cs`.

```csharp
// ...
using Microsoft.AspNetCore.Authorization; // Adicione este using

namespace AppBus.Backend.Controllers
{
    // ...
    public class ViagensController : ControllerBase
    {
        // ...

        // POST: api/viagens/sincronizar
        [HttpPost("sincronizar")]
        [Authorize] // <-- Endpoint protegido!
        public async Task<IActionResult> Sincronizar([FromBody] Viagem viagemPayload)
        {
            // ... sua lógica de sincronização ...
        }
    }
}
```

---

## 4. Próximos Passos

Com o esqueleto fundamental pronto, os próximos passos recomendados são:

1.  **Criar Endpoints de Leitura:** Desenvolver endpoints `GET` para que o aplicativo Flutter possa baixar os dados iniciais, como a lista de alunos de uma rota (`GET /api/rotas/{id}/alunos`).
2.  **Adicionar Validação:** Usar pacotes como o `FluentValidation` para validar os dados recebidos nos payloads.
3.  **Implementar Logging:** Configurar um sistema de logs (como o Serilog) para registrar erros e informações importantes em produção.
