using Microsoft.AspNetCore.Identity;

namespace AppBus.Backend.Models
{
    // Você pode adicionar propriedades de perfil para o usuário aqui, se necessário.
    public class ApplicationUser : IdentityUser
    {
        public string? RefreshToken { get; set; }
        public DateTime? RefreshTokenExpiryTime { get; set; }
    }
}