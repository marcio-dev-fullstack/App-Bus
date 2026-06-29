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
        [Authorize] // <-- Endpoint protegido!
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

                _context.Viagens.Add(viagemPayload);
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new { message = "Viagem sincronizada com sucesso!" });
            }
            catch (Exception ex)
            {
                // Em caso de erro, retorna uma resposta de erro do servidor.
                return StatusCode(500, $"Erro interno do servidor: {ex.Message}");
            }
        }
    }
}