using System.Data;
using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using MinisterioGosenAPI.Models;

namespace MinisterioGosenAPI.Controllers
{
	[Route("api/[controller]")]
	[ApiController]
	public class ActividadMinisterioController(IConfiguration _config) : ControllerBase
	{
		[HttpGet("ListarActividadMinisterioAPI")]
		public async Task<IActionResult> ListarActividadMinisterioAPI()
		{
			using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
			var response = await context.QueryAsync<ActividadMinisterioModel>("spListarActividadMinisterio");
			return Ok(response.ToList());
		}

		[HttpGet("ObtenerActividadMinisterioAPI")]
		public async Task<IActionResult> ObtenerActividadMinisterioAPI(int id)
		{
			using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
			var parameters = new DynamicParameters();
			parameters.Add("@Id_Minis_Actividad", id);

			var response = await context.QueryFirstOrDefaultAsync<ActividadMinisterioModel>(
				"spObtenerActividadMinisterio", parameters, commandType: CommandType.StoredProcedure);

			if (response != null)
				return Ok(response);

			return NotFound(new { Success = false, Message = "No se encontró la asignación de ministerio en la actividad" });
		}

		[HttpPost("CrearActividadMinisterioAPI")]
		public async Task<IActionResult> CrearActividadMinisterioAPI([FromBody] ActividadMinisterioModel model)
		{
			if (model.Id_Actividad <= 0 || model.Id_Ministerio <= 0)
				return BadRequest(new { Success = false, Message = "Actividad y Ministerio son obligatorios" });

			using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
			var parameters = new DynamicParameters();
			parameters.Add("@Id_Actividad", model.Id_Actividad);
			parameters.Add("@Id_Ministerio", model.Id_Ministerio);
			parameters.Add("@Fecha", model.Fecha);
			parameters.Add("@Observacion", model.Observacion);

			var idActividadMinisterio = await context.QuerySingleAsync<int>(
				"spCrearActividadesMinisterio", parameters, commandType: CommandType.StoredProcedure);

			if (idActividadMinisterio > 0)
			{
				return Ok(new
				{
					Success = true,
					Id = idActividadMinisterio,
					Message = "Asignación registrada correctamente"
				});
			}

			return StatusCode(500, new { Success = false, Message = "Error interno: no se pudo registrar la asignación" });
		}

		[HttpPut("ActualizarActividadMinisterioAPI")]
		public async Task<IActionResult> ActualizarActividadMinisterioAPI([FromBody] ActividadMinisterioModel model)
		{
			if (model.Id_Minis_Actividad <= 0)
				return BadRequest(new { Success = false, Message = "El identificador de la asignación es obligatorio" });

			using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
			var parameters = new DynamicParameters();
			parameters.Add("@Id_Minis_Actividad", model.Id_Minis_Actividad);
			parameters.Add("@Id_Actividad", model.Id_Actividad);
			parameters.Add("@Id_Ministerio", model.Id_Ministerio);
			parameters.Add("@Fecha", model.Fecha);
			parameters.Add("@Observacion", model.Observacion);

			var response = await context.ExecuteAsync("spActualizarActividadesMinisterio", parameters, commandType: CommandType.StoredProcedure);

			if (response > 0)
				return Ok(new { Success = true, Message = "Asignación actualizada correctamente" });

			return BadRequest(new { Success = false, Message = "No se ha actualizado la asignación" });
		}

		[HttpDelete("EliminarActividadMinisterioAPI")]
		public async Task<IActionResult> EliminarActividadMinisterioAPI(int id)
		{
			using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);
			var parameters = new DynamicParameters();
			parameters.Add("@Id_Minis_Actividad", id);

			var response = await context.ExecuteAsync("spEliminarActividadMinisterio", parameters, commandType: CommandType.StoredProcedure);

			if (response > 0)
				return Ok(new { Success = true, Message = "Asignación eliminada correctamente" });

			return BadRequest(new { Success = false, Message = "No se ha eliminado la asignación" });
		}
	}
}
