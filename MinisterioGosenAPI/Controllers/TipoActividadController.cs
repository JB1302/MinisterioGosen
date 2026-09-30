using Dapper;
using Microsoft.AspNetCore.Mvc;
using MinisterioGosenAPI.Models;
using Npgsql;

namespace MinisterioGosenAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TipoActividadController(IConfiguration _config) : ControllerBase
    {
        [HttpGet("ListarTiposActividadAPI")]
        public IActionResult ListarTiposActividadAPI()
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var response = context.Query<TipoActividadModel>("SELECT * FROM spListarTiposActividad()").ToList();

            return Ok(response);
        }

        [HttpGet("ObtenerTipoActividadAPI")]
        public IActionResult ObtenerTipoActividadAPI(int id)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Id_Tipo_Actividad", id);

            var response = context.QueryFirstOrDefault<TipoActividadModel>("SELECT * FROM spObtenerTipoActividad(@Id_Tipo_Actividad)", parameters);

            if (response != null)
                return Ok(response);

            return NotFound("No se encontró el tipo de actividad");
        }

        [HttpPost("CrearTipoActividadAPI")]
        public async Task<IActionResult> CrearTipoActividadAPI(TipoActividadModel model)
        {
            try
            {
                await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

                var parameters = new DynamicParameters();
                parameters.Add("@Nombre_Tipo", model.Nombre_Tipo);

                await context.ExecuteAsync("CALL spCrearTipoActividad(@Nombre_Tipo)", parameters);

                return Ok("Tipo de actividad creado correctamente");
            }
            catch (PostgresException ex)
            {
                return BadRequest(ex.MessageText);
            }
            catch (NpgsqlException ex)
            {
                return StatusCode(500, ex.Message);
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpPut("ActualizarTipoActividadAPI")]
        public async Task<IActionResult> ActualizarTipoActividadAPI(TipoActividadModel model)
        {
            try
            {
                await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

                var parameters = new DynamicParameters();
                parameters.Add("@Id_Tipo_Actividad", model.Id_Tipo_Actividad);
                parameters.Add("@Nombre_Tipo", model.Nombre_Tipo);

                await context.ExecuteAsync(@"CALL spActualizarTipoActividad(@Id_Tipo_Actividad,@Nombre_Tipo)", parameters);

                return Ok("Tipo de actividad actualizado correctamente");
            }
            catch (PostgresException ex)
            {
                return BadRequest(ex.MessageText);
            }
            catch (NpgsqlException ex)
            {
                return StatusCode(500, ex.Message);
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpDelete("EliminarTipoActividadAPI")]
        public async Task<IActionResult> EliminarTipoActividadAPI(int id)
        {
            try
            {
                await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

                var parameters = new DynamicParameters();
                parameters.Add("@Id_Tipo_Actividad", id);

                await context.ExecuteAsync("CALL spEliminarTipoActividad(@Id_Tipo_Actividad)", parameters);

                return Ok("Tipo de actividad eliminado correctamente");
            }
            catch (PostgresException ex)
            {
                return BadRequest(ex.MessageText);
            }
            catch (NpgsqlException ex)
            {
                return BadRequest("No se puede eliminar este tipo de actividad porque tiene información relacionada.");
            }
            catch (Exception ex)
            {
                return BadRequest("No se puede eliminar este tipo de actividad porque tiene información relacionada.");
            }
        }
    }
}