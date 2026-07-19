using System;
using System.ComponentModel.DataAnnotations;

namespace MinisterioGosen.Models
{
	public class ActividadUsuarioModel
	{
		[Key]
		public int Id_Actividad_Usuario { get; set; }

		[Required(ErrorMessage = "Debe seleccionar una actividad")]
		public int Id_Actividad { get; set; }

		[Required(ErrorMessage = "Debe seleccionar una persona")]
		public int Id_Usuario { get; set; }

		[Required(ErrorMessage = "La fecha es obligatoria")]
		[DataType(DataType.Date)]
		public DateTime Fecha { get; set; } = DateTime.Today;

		[DataType(DataType.Time)]
		public TimeSpan? Hora { get; set; }

		// 🔹 Campos auxiliares para vistas y API
		public string? NombreActividad { get; set; }
		public string? NombreUsuario { get; set; }
		public string? IdentificacionUsuario { get; set; }
	}
}

