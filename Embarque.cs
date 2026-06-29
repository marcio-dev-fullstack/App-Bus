namespace AppBus.Backend.Models
{
    public class Embarque
    {
        public int Id { get; set; }
        public DateTime DataHora { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public int IdViagem { get; set; }
        public int IdAluno { get; set; }
    }
}