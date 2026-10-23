namespace MinisterioGosen.Models
{
    public class TicketModel
    {
        public int IdTicket { get; set; }
        public int IdRequestor { get; set; }
        public string Titulo { get; set; } = string.Empty;
        public string Descripcion { get; set; } = string.Empty;
        public string Estado { get; set; } = "Abierto";
        //? sirve para aceptar nulos.
        public int? IdAssignee { get; set; }
        public DateTime FechaCreacion { get; set; }
    }
}
