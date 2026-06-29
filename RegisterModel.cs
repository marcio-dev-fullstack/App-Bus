using System.ComponentModel.DataAnnotations;

namespace AppBus.Backend.Models
{
    public class RegisterModel
    {
        [Required(ErrorMessage = "O e-mail é obrigatório.")]
        [EmailAddress(ErrorMessage = "Formato de e-mail inválido.")]
        public required string Email { get; set; }

        [Required(ErrorMessage = "A senha é obrigatória.")]
        public required string Password { get; set; }
    }
}