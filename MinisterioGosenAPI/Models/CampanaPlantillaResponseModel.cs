namespace MinisterioGosenAPI.Models
{
    public class CampanaPlantillaResponseModel
    {
        public string Codigo { get; set; } = string.Empty;

        public string Nombre { get; set; } = string.Empty;

        public string Descripcion { get; set; } = string.Empty;

        public string Icono { get; set; } = string.Empty;

        public string Color_Encabezado { get; set; } = string.Empty;

        public bool Activo { get; set; }
    }
}