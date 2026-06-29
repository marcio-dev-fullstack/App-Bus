using Microsoft.EntityFrameworkCore;
using AppBus.Backend.Data;

var builder = WebApplication.CreateBuilder(args);

// Adiciona a string de conexão
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<SemecDbContext>(options =>
    options.UseNpgsql(connectionString));

// --- INÍCIO DA CONFIGURAÇÃO DO IDENTITY ---
builder.Services.AddIdentity<ApplicationUser, IdentityRole>()
    .AddEntityFrameworkStores<SemecDbContext>()
    .AddDefaultTokenProviders();
// --- FIM DA CONFIGURAÇÃO DO IDENTITY ---

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
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// --- INÍCIO DA LÓGICA DE SEEDING ---
// Verifica se o app foi iniciado com o argumento '--seed'
if (args.Contains("--seed")) // Tornando o bloco assíncrono
{
    using (var scope = app.Services.CreateScope())
    {
        // Seeding de Viagens (síncrono)
        var dbContext = scope.ServiceProvider.GetRequiredService<SemecDbContext>();
        DataSeeder.SeedViagens(dbContext);

        // Seeding de Usuários e Perfis (assíncrono)
        await DataSeeder.SeedIdentityAsync(scope.ServiceProvider);
    }
    // Encerra a aplicação após o seeding para não iniciar o servidor web.
    return;
}
// --- FIM DA LÓGICA DE SEEDING ---

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();
app.Run();