using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using AppBus.Backend.Models;

namespace AppBus.Backend.Data
{
    public class SemecDbContext : IdentityDbContext<ApplicationUser>
    {
        public SemecDbContext(DbContextOptions<SemecDbContext> options) : base(options) { }

        public DbSet<Viagem> Viagens { get; set; }
        public DbSet<Embarque> Embarques { get; set; }
        public DbSet<Aluno> Alunos { get; set; }
        public DbSet<Rota> Rotas { get; set; }
        public DbSet<Veiculo> Veiculos { get; set; }
    }
}