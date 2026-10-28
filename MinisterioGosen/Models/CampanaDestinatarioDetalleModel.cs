namespace MinisterioGosen.Models
{
    public class CampanaDestinatarioDetalleModel
    {
        public long Id_Campana_Destinatario { get; set; }

        public int? Id_Usuario { get; set; }

        public string Nombre_Destinatario { get; set; } =
            string.Empty;

        public string Correo_Destinatario { get; set; } =
            string.Empty;

        public string Estado_Envio { get; set; } =
            string.Empty;

        public DateTime? Fecha_Envio { get; set; }

        public string? Detalle_Error { get; set; }
    }
}