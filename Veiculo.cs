namespace AppBus.Backend.Models
{
    public class Veiculo
    {
        public int Id { get; set; }
        public string Placa { get; set; } = string.Empty;
        public string Modelo { get; set; } = string.Empty;
        public List<Rota> Rotas { get; set; } = new();
    }
}