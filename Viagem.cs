namespace AppBus.Backend.Models
{
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
}