namespace AppBus.Backend.Models
{
    public class Rota
    {
        public int Id { get; set; }
        public string Nome { get; set; } = string.Empty;
        public string Descricao { get; set; } = string.Empty;
        public List<Aluno> Alunos { get; set; } = new();
        public List<Veiculo> Veiculos { get; set; } = new();
    }
}