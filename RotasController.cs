using AppBus.Backend.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AppBus.Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class RotasController : ControllerBase
    {
        private readonly SemecDbContext _context;

        public RotasController(SemecDbContext context)
        {
            _context = context;
        }

        // GET: api/rotas/{idVeiculo}/alunos
        [HttpGet("{idVeiculo}/alunos")]
        public async Task<IActionResult> GetAlunosPorVeiculo(int idVeiculo)
        {
            // Busca as rotas associadas ao veículo
            var rotas = await _context.Rotas
                .Include(r => r.Alunos) // Inclui os alunos de cada rota
                .Where(r => r.Veiculos.Any(v => v.Id == idVeiculo))
                .AsNoTracking()
                .ToListAsync();

            if (!rotas.Any())
            {
                return NotFound($"Nenhuma rota encontrada para o veículo com ID {idVeiculo}.");
            }

            // Agrupa todos os alunos de todas as rotas encontradas, evitando duplicatas.
            var todosAlunos = rotas.SelectMany(r => r.Alunos).DistinctBy(a => a.Id).ToList();

            return Ok(todosAlunos);
        }
    }
}