namespace MinisterioGosen.Models
{
    public class CampanaDetalleViewModel
    {
        public CampanaDetalleModel Campana { get; set; } =
            new CampanaDetalleModel();

        public List<CampanaDestinatarioDetalleModel> Destinatarios
        { get; set; } = [];
    }
}