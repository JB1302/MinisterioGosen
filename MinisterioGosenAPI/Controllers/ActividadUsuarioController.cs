using Dapper;
using Microsoft.AspNetCore.Mvc;
using MinisterioGosenAPI.Models;
using Npgsql;
using System.Data;

namespace MinisterioGosenAPI.Controllers
{
	[Route("api/[controller]")]
	[ApiController]
	public class ActividadUsuarioController(IConfiguration _config) : ControllerBase
	{
		[HttpGet("ListarActividadUsuarioAPI")]
		public IActionResult ListarActividadUsuarioAPI(int? idUsuario = null, int? idActividad = null)
		{
			using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);
			var parameters = new DynamicParameters();

			if (idUsuario.HasValue)
				parameters.Add("@Id_Usuario", idUsuario.Value);

			if (idActividad.HasValue)
				parameters.Add("@Id_Actividad", idActividad.Value);

            var response = context.Query<ActividadUsuarioModel>(
				@"SELECT *
				  FROM spListarActividadUsuario(
					  @Id_Usuario,
					  @Id_Actividad)",
				new
				{
					Id_Usuario = idUsuario,
					Id_Actividad = idActividad
				}
			).ToList();

            return Ok(response);
		}

		[HttpGet("ObtenerActividadUsuarioAPI")]
		public IActionResult ObtenerActividadUsuarioAPI(int id)
		{
			using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);
			var parameters = new DynamicParameters();
			parameters.Add("@Id_Actividad_Usuario", id);

			var response = context.QueryFirstOrDefault<ActividadUsuarioModel>("SELECT * FROM spObtenerActividadUsuario(@Id_Actividad_Usuario)", parameters);

			if (response != null)
				return Ok(response);

			return NotFound(new { Success = false, Message = "No se encontró la participación" });
		}

		[HttpPost("CrearActividadUsuarioAPI")]
		public IActionResult CrearActividadUsuarioAPI([FromBody] ActividadUsuarioModel model)
		{
			if (!ModelState.IsValid)
				return BadRequest(ModelState);

			if (model.Id_Actividad <= 0 || model.Id_Usuario <= 0)
				return BadRequest(new { Success = false, Message = "Actividad y Usuario son obligatorios" });

			if (model.Fecha.Date < DateTime.Today)
				return BadRequest(new { Success = false, Message = "La fecha no puede ser anterior a la actual" });

			using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);
			var parameters = new DynamicParameters();
			parameters.Add("@Id_Actividad", model.Id_Actividad);
			parameters.Add("@Id_Usuario", model.Id_Usuario);
			parameters.Add("@Fecha", model.Fecha);
			parameters.Add("@Hora", model.Hora);

            var idActividadUsuario = context.QuerySingle<int>(
						@"SELECT spCrearActividadUsuario(
							@Id_Actividad,
							@Id_Usuario,
							@Fecha,
							@Hora)",parameters);

            if (idActividadUsuario > 0)
			{
				return Ok(new
				{
					Success = true,
					Id = idActividadUsuario,
					Message = "Participación registrada correctamente"
				});
			}

			return StatusCode(500, new { Success = false, Message = "Error interno: no se pudo registrar la participación" });
		}

		[HttpPut("ActualizarActividadUsuarioAPI")]
		public async Task<IActionResult> ActualizarActividadUsuarioAPI([FromBody] ActividadUsuarioModel model)
		{
			try
			{
				if (!ModelState.IsValid)
					return BadRequest(ModelState);

				if (model.Id_Actividad_Usuario <= 0)
					return BadRequest(new { Success = false, Message = "El identificador de la participación es obligatorio" });

				await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);
				var parameters = new DynamicParameters();
				parameters.Add("@Id_Actividad_Usuario", model.Id_Actividad_Usuario);
				parameters.Add("@Id_Actividad", model.Id_Actividad);
				parameters.Add("@Id_Usuario", model.Id_Usuario);
				parameters.Add("@Fecha", model.Fecha);
				parameters.Add("@Hora", model.Hora);

				await context.ExecuteAsync(
						@"CALL spActualizarActividadUsuario(
							@Id_Actividad_Usuario,
							@Id_Actividad,
							@Id_Usuario,
							@Fecha,
							@Hora
						)", parameters);

				return Ok(new
				{
					Success = true,
					Message = "Participación actualizada correctamente"
				});
			}
			catch (PostgresException ex)
			{
				return BadRequest(new { Success = false, Message = ex.MessageText });
			}
			catch (NpgsqlException ex)
			{
				return StatusCode(500, new { Success = false, Message = ex.Message });
			}
			catch (Exception ex)
			{
				return StatusCode(500, new { Success = false, Message = "Error interno" });
			}
		}

		[HttpDelete("EliminarActividadUsuarioAPI")]
		public async Task<IActionResult> EliminarActividadUsuarioAPI(int id)
		{
			try
			{
				await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);
				var parameters = new DynamicParameters();
				parameters.Add("@Id_Actividad_Usuario", id);

				await context.ExecuteAsync("CALL spEliminarActividadUsuario(@Id_Actividad_Usuario)", parameters);

				return Ok(new { Success = true, Message = "Participación eliminada correctamente" });
			}
			catch (PostgresException ex)
			{
				return BadRequest(new { Success = false, Message = ex.MessageText });
			}
			catch (NpgsqlException ex)
			{
				return StatusCode(500, new { Success = false, Message = ex.Message });
			}
			catch (Exception ex)
			{
				return StatusCode(500, new { Success = false, Message = "No se ha eliminado la participación" });
			}
		}
	}
}
