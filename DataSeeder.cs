using AppBus.Backend.Models;

namespace AppBus.Backend.Data
{
    public static class DataSeeder
    {
        public static void Seed(SemecDbContext context)
        {
            // Verifica se já existem viagens no banco para não duplicar os dados.
            if (context.Viagens.Any())
            {
                Console.WriteLine("O banco de dados já contém dados. Nenhuma ação foi tomada.");
                return;
            }

            Console.WriteLine("Banco de dados vazio. Inserindo dados de teste...");

            var viagemTeste = new Viagem
            {
                DataInicio = DateTime.UtcNow.AddHours(-2),
                DataFim = DateTime.UtcNow.AddHours(-1),
                IdRota = 1,
                IdVeiculo = 101,
                Sincronizado = false, // Começa como não sincronizado
                Embarques = new List<Embarque>
                {
                    new() { DataHora = DateTime.UtcNow.AddMinutes(-90), Latitude = -5.9011, Longitude = -49.1355, IdAluno = 1 },
                    new() { DataHora = DateTime.UtcNow.AddMinutes(-75), Latitude = -5.9022, Longitude = -49.1366, IdAluno = 2 },
                    new() { DataHora = DateTime.UtcNow.AddMinutes(-60), Latitude = -5.9033, Longitude = -49.1377, IdAluno = 3 }
                }
            };

            context.Viagens.Add(viagemTeste);
            context.SaveChanges();

            Console.WriteLine("Dados de teste inseridos com sucesso!");
        }

        public static async Task SeedIdentityAsync(IServiceProvider serviceProvider)
        {
            var userManager = serviceProvider.GetRequiredService<UserManager<ApplicationUser>>();
            var roleManager = serviceProvider.GetRequiredService<RoleManager<IdentityRole>>();

            Console.WriteLine("Iniciando seeding de dados de identidade...");

            // --- Criação de Perfis (Roles) ---
            string[] roleNames = { "Admin", "Monitor" };
            foreach (var roleName in roleNames)
            {
                var roleExist = await roleManager.RoleExistsAsync(roleName);
                if (!roleExist)
                {
                    await roleManager.CreateAsync(new IdentityRole(roleName));
                    Console.WriteLine($"Perfil '{roleName}' criado com sucesso.");
                }
            }

            // --- Criação do Usuário Monitor Padrão ---
            var monitorUserEmail = "monitor@semec.com";
            var monitorUser = await userManager.FindByEmailAsync(monitorUserEmail);

            if (monitorUser == null)
            {
                var newMonitorUser = new ApplicationUser
                {
                    UserName = monitorUserEmail,
                    Email = monitorUserEmail,
                    EmailConfirmed = true // Confirma o email automaticamente para o seeder
                };

                // ATENÇÃO: Use uma senha mais forte em produção!
                var result = await userManager.CreateAsync(newMonitorUser, "Senha123!");
                if (result.Succeeded)
                {
                    await userManager.AddToRoleAsync(newMonitorUser, "Monitor");
                    Console.WriteLine($"Usuário '{monitorUserEmail}' criado e adicionado ao perfil 'Monitor'.");
                }
            }
        }
    }
}