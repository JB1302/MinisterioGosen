namespace MinisterioGosen.Models
{
    public class CampanaDetalleModel
    {
        public int Id_Campana { get; set; }

        public string Titulo { get; set; } =
            string.Empty;

        public string Asunto { get; set; } =
            string.Empty;

        public string Contenido { get; set; } =
            string.Empty;

        public string Plantilla { get; set; } =
            string.Empty;

        public string Nombre_Plantilla { get; set; } =
            string.Empty;

        public string Color_Encabezado { get; set; } =
            string.Empty;

        public string Estado { get; set; } =
            string.Empty;

        public DateTime Fecha_Creacion { get; set; }

        public DateTime? Fecha_Envio { get; set; }

        public int Id_Usuario_Creador { get; set; }

        public string Nombre_Creador { get; set; } =
            string.Empty;
    }
}