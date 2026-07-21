using System.Data;
using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using MinisterioGosen.Models;
using MinisterioGosenAPI.Models;

namespace MinisterioGosenAPI.Controllers
{
	[Route("api/[controller]")]
	[ApiController]
	public class ActividadUsuarioController(IConfiguration _config) : ControllerBase
	{
		[HttpGet("ListarActividadUsuarioAPI")]
		public IActionResult ListarActividadUsuarioAPI()
		{
			using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
			var response = context.Query<ActividadUsuarioModel>("spListarActividadUsuario").ToList();
			return Ok(response);
		}

		[HttpGet("ObtenerActividadUsuarioAPI")]
		public IActionResult ObtenerActividadUsuarioAPI(int id)
		{
			using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
			var parameters = new DynamicParameters();
			parameters.Add("@Id_Actividad_Usuario", id);

			var response = context.QueryFirstOrDefault<ActividadUsuarioModel>("spObtenerActividadUsuario", parameters);

			if (response != null)
				return Ok(response);

			return NotFound("No se encontró la participación");
		}

		[HttpPost("CrearActividadUsuarioAPI")]
		public IActionResult CrearActividadUsuarioAPI(ActividadUsuarioModel model)
		{
			using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
			var parameters = new DynamicParameters();
			parameters.Add("@Id_Actividad", model.Id_Actividad);
			parameters.Add("@Id_Usuario", model.Id_Usuario);
			parameters.Add("@Fecha", model.Fecha);
			parameters.Add("@Hora", model.Hora);

			var idActividadUsuario = context.QuerySingle<int>("spCrearActividadUsuario", parameters, commandType: CommandType.StoredProcedure);

			if (idActividadUsuario > 0)
			{
				return Ok(new
				{
					Success = true,
					Id = idActividadUsuario,
					Message = "Participación registrada correctamente"
				});
			}

			// Si llega 0 o negativo, algo falló en el SP o en la captura
			return StatusCode(500, new
			{
				Success = false,
				Message = "Error interno: no se pudo registrar la participación"
			});
		}

		[HttpPut("ActualizarActividadUsuarioAPI")]
		public IActionResult ActualizarActividadUsuarioAPI(ActividadUsuarioModel model)
		{
			using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
			var parameters = new DynamicParameters();
			parameters.Add("@Id_Actividad_Usuario", model.Id_Actividad_Usuario);
			parameters.Add("@Id_Actividad", model.Id_Actividad);
			parameters.Add("@Id_Usuario", model.Id_Usuario);
			parameters.Add("@Fecha", model.Fecha);
			parameters.Add("@Hora", model.Hora);

			var response = context.Execute("spActualizarActividadUsuario", parameters);

			if (response > 0)
				return Ok(response);

			return BadRequest("No se ha actualizado la participación");
		}

		[HttpDelete("EliminarActividadUsuarioAPI")]
		public IActionResult EliminarActividadUsuarioAPI(int id)
		{
			using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
			var parameters = new DynamicParameters();
			parameters.Add("@Id_Actividad_Usuario", id);

			var response = context.Execute("spEliminarActividadUsuario", parameters);

			if (response > 0)
				return Ok(response);

			return BadRequest("No se ha eliminado la participación");
		}
	}
}

