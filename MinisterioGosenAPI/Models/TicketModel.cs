namespace MinisterioGosenAPI.Models
{
    public class TicketModel
    {
        public int IdTicket { get; set; }
        public int IdRequestor { get; set; }
        public string Titulo { get; set; } = string.Empty;
        public string Descripcion { get; set; } = string.Empty;
        public string Estado { get; set; } = "Abierto";
        public int? IdAssignee { get; set; }
        public string? Respuesta { get; set; }
        public DateTime FechaCreacion { get; set; }
        public DateTime? FechaCierre { get; set; }
    }

    public class CrearTicketRequestModel
    {
        public int IdRequestor { get; set; }
        public string Titulo { get; set; } = string.Empty;
        public string Descripcion { get; set; } = string.Empty;
        public int? IdAssignee { get; set; }
    }

    public class ActualizarTicketRequestModel
    {
        public int IdTicket { get; set; }
        public string Estado { get; set; } = string.Empty;
        public int? IdAssignee { get; set; }
        public string? Respuesta { get; set; }
    }

    public class TicketResponseModel
    {
        public int IdTicket { get; set; }
        public int IdRequestor { get; set; }
        public string NombreRequestor { get; set; } = string.Empty;
        public string Titulo { get; set; } = string.Empty;
        public string Descripcion { get; set; } = string.Empty;
        public string Estado { get; set; } = "Abierto";
        public int? IdAssignee { get; set; }
        public string? NombreAssignee { get; set; }
        public string? Respuesta { get; set; }
        public DateTime FechaCreacion { get; set; }
        public DateTime? FechaCierre { get; set; }
    }
}