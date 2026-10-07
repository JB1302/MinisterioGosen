namespace MinisterioGosen.Models
{
    public class CampanaCrearModel
    {
        public string Titulo { get; set; } = string.Empty;

        public string Asunto { get; set; } = string.Empty;

        public string Contenido { get; set; } = string.Empty;

        public string Plantilla { get; set; } = "General";

        public List<int> IdsRoles { get; set; } = [];

        public List<int> IdsMinisterios { get; set; } = [];

        public bool Todos { get; set; }
    }
}