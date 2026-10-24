using System.ComponentModel.DataAnnotations;

namespace MinisterioGosen.Models
{
    public class TicketModel
    {
        [Key]
        public int IdTicket { get; set; }

        public int IdRequestor { get; set; }

        [Required(ErrorMessage = "El título es obligatorio")]
        [StringLength(150, ErrorMessage = "El título no puede superar 150 caracteres")]
        public string Titulo { get; set; } = string.Empty;

        [Required(ErrorMessage = "La descripción es obligatoria")]
        [StringLength(500, ErrorMessage = "La descripción no puede superar 500 caracteres")]
        public string Descripcion { get; set; } = string.Empty;

        // Abierto, En Progreso, Cerrado o Cancelado
        public string Estado { get; set; } = "Abierto";

        //? sirve para aceptar nulos.
        public int? IdAssignee { get; set; }

        [StringLength(500, ErrorMessage = "La respuesta no puede superar 500 caracteres")]
        public string? Respuesta { get; set; }

        public DateTime FechaCreacion { get; set; }

        public DateTime? FechaCierre { get; set; }

        // Campos de solo lectura que llegan de fnListarTickets / fnObtenerTicketPorId
        // (join con Usuario). No se usan para crear o atender, solo para mostrar nombres.
        public string? NombreRequestor { get; set; }

        public string? NombreAssignee { get; set; }
    }
}