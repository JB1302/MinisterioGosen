namespace MinisterioGosenAPI.Models
{
    public class CampanaDestinatarioResponseModel
    {
        public long Id_Campana_Destinatario { get; set; }


        public int? Id_Usuario { get; set; }


        public string Nombre_Destinatario { get; set; } =
            string.Empty;


        public string Correo_Destinatario { get; set; } =
            string.Empty;
    }
}