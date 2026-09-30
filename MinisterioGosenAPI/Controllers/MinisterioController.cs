using Dapper;
using Microsoft.AspNetCore.Mvc;
using MinisterioGosenAPI.Models;
using Npgsql;

namespace MinisterioGosenAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class MinisterioController(IConfiguration _config) : ControllerBase
    {
        [HttpGet("ListarMinisteriosAPI")]
        public IActionResult ListarMinisteriosAPI()
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var response = context.Query<MinisterioModel>("SELECT * FROM spListarMinisterios()").ToList();

            return Ok(response);
        }

        [HttpGet("ObtenerMinisterioAPI")]
        public IActionResult ObtenerMinisterioAPI(int id)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Id_Ministerio", id);

            var response = context.QueryFirstOrDefault<MinisterioModel>("SELECT * FROM spObtenerMinisterio(@Id_Ministerio)", parameters);

            if (response != null)
                return Ok(response);

            return NotFound("No se encontró el ministerio");
        }

        [HttpPost("CrearMinisterioAPI")]
        public async Task<IActionResult> CrearMinisterioAPI(MinisterioModel model)
        {
            try
            {
                await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

                var parameters = new DynamicParameters();
                parameters.Add("@Descripcion_Ministerio", model.Descripcion_Ministerio);
                parameters.Add("@Observaciones_Ministerio", model.Observaciones_Ministerio);

                await context.ExecuteAsync(@"CALL spCrearMinisterio(@Descripcion_Ministerio,@Observaciones_Ministerio)", parameters);

                return Ok("Ministerio creado correctamente");
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

        [HttpPut("ActualizarMinisterioAPI")]
        public async Task<IActionResult> ActualizarMinisterioAPI(MinisterioModel model)
        {
            try
            {
                await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

                var parameters = new DynamicParameters();
                parameters.Add("@Id_Ministerio", model.Id_Ministerio);
                parameters.Add("@Descripcion_Ministerio", model.Descripcion_Ministerio);
                parameters.Add("@Observaciones_Ministerio", model.Observaciones_Ministerio);

                await context.ExecuteAsync(@"CALL spActualizarMinisterio(@Id_Ministerio,@Descripcion_Ministerio,@Observaciones_Ministerio)", parameters);

                return Ok("Ministerio actualizado correctamente");
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

        [HttpDelete("EliminarMinisterioAPI")]
        public async Task<IActionResult> EliminarMinisterioAPI(int id)
        {
            try
            {
                await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

                var parameters = new DynamicParameters();
                parameters.Add("@Id_Ministerio", id);

                await context.ExecuteAsync("CALL spEliminarMinisterio(@Id_Ministerio)", parameters);

                return Ok("Ministerio eliminado correctamente");
            }
            catch (PostgresException ex)
            {
                return BadRequest(ex.MessageText);
            }
            catch (NpgsqlException ex)
            {
                return BadRequest("No se puede eliminar este ministerio porque tiene información relacionada.");
            }
            catch (Exception ex)
            {
                return BadRequest("No se puede eliminar este ministerio porque tiene información relacionada.");
            }
        }
    }
}