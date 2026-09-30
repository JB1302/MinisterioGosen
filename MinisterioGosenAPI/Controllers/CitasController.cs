using Dapper;
using Microsoft.AspNetCore.Mvc;
using MinisterioGosenAPI.Models;
using Npgsql;

namespace MinisterioGosenAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CitasController(IConfiguration _config) : ControllerBase
    {
        [HttpGet("ListarCitasAPI")]
        public async Task<IActionResult> ListarCitasAPI()
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var response = await context.QueryAsync<CitasModel>("SELECT * FROM spListarCitas()");

            return Ok(response);
        }

        [HttpGet("ObtenerCitaAPI")]
        public async Task<IActionResult> ObtenerCitaAPI(int id)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Id_Cita", id);

            var response = await context.QueryFirstOrDefaultAsync<CitasModel>(
                "SELECT * FROM spObtenerCita(@Id_Cita)", parameters);

            if (response != null)
                return Ok(response);

            return NotFound("No se encontró la cita");
        }

        [HttpPost("CrearCitaAPI")]
        public async Task<IActionResult> CrearCitaAPI(CitasModel model)
        {
            try
            {
                using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

                var parameters = new DynamicParameters();
                parameters.Add("@Fecha_Cita", model.Fecha_Cita);
                parameters.Add("@Hora_Cita", model.Hora_Cita);
                parameters.Add("@Id_Usuario_Cita", model.Id_Usuario_Cita);
                parameters.Add("@Id_Usuario_Encargado", model.Id_Usuario_Encargado);
                parameters.Add("@Observacion_Inicial", model.Observacion_Inicial);
                parameters.Add("@Detalle_Cita", model.Detalle_Cita);

                var idCita =
                        await context.QuerySingleAsync<int>(
                            @"SELECT spCrearCita(
                                @Fecha_Cita,
                                @Hora_Cita,
                                @Id_Usuario_Cita,
                                @Id_Usuario_Encargado,
                                @Observacion_Inicial,
                                @Detalle_Cita
                            )",parameters);

                if (idCita > 0)
                    return Ok(new { Id_Cita = idCita });

                return BadRequest("No se ha registrado la cita.");
            }
            catch (PostgresException ex)
            {
                // Error generado por PostgreSQL:
                // constraint, RAISE EXCEPTION, FK, etc.
                return BadRequest(ex.MessageText);
            }
            catch (NpgsqlException ex)
            {
                // Problemas del proveedor/conexión
                return BadRequest(ex.Message);
            }
            catch (Exception ex)
            {
                return BadRequest($"Error al registrar la cita: {ex.Message}");
            }
        }

        [HttpPut("ActualizarCitaAPI")]
        public async Task<IActionResult> ActualizarCitaAPI(CitasModel model)
        {
            try
            {
                using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

                var parameters = new DynamicParameters();
                parameters.Add("@Id_Cita", model.Id_Cita);
                parameters.Add("@Fecha_Cita", model.Fecha_Cita);
                parameters.Add("@Hora_Cita", model.Hora_Cita);
                parameters.Add("@Id_Usuario_Cita", model.Id_Usuario_Cita);
                parameters.Add("@Id_Usuario_Encargado", model.Id_Usuario_Encargado);
                parameters.Add("@Observacion_Inicial", model.Observacion_Inicial);
                parameters.Add("@Detalle_Cita", model.Detalle_Cita);

                await context.ExecuteAsync(
                                            @"CALL spActualizarCita(
                                                @Id_Cita,
                                                @Fecha_Cita,
                                                @Hora_Cita,
                                                @Id_Usuario_Cita,
                                                @Id_Usuario_Encargado,
                                                @Observacion_Inicial,
                                                @Detalle_Cita)", parameters);

                return Ok("Cita actualizada correctamente");
            }
            catch (PostgresException ex)
            {
                return BadRequest(ex.MessageText);
            }
            catch (NpgsqlException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (Exception ex)
            {
                return BadRequest($"Error al actualizar la cita: {ex.Message}");
            }
        }

        [HttpPut("AtenderCitaAPI")]
        public async Task<IActionResult> AtenderCitaAPI(CitasModel model)
        {
            try
            {
                using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

                var parameters = new DynamicParameters();
                parameters.Add("@Id_Cita", model.Id_Cita);
                parameters.Add("@Detalle_Cita", model.Detalle_Cita);

                await context.ExecuteAsync(
                                        @"CALL spAtenderCita(
                                            @Id_Cita,
                                            @Detalle_Cita)", parameters);

                return Ok("Cita marcada como atendida correctamente");
            }
            catch (PostgresException ex)
            {
                return BadRequest(ex.MessageText);
            }
            catch (NpgsqlException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (Exception ex)
            {
                return BadRequest($"Error al atender la cita: {ex.Message}");
            }
        }

        [HttpDelete("EliminarCitaAPI")]
        public async Task<IActionResult> EliminarCitaAPI(int id)
        {
            try
            {
                using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

                var parameters = new DynamicParameters();
                parameters.Add("@Id_Cita", id);

                await context.ExecuteAsync(
                                        "CALL spEliminarCita(@Id_Cita)", parameters);

                return Ok("Cita eliminada correctamente");
            }
            catch (PostgresException ex)
            {
                return BadRequest(ex.Message);
            }
            catch (Exception ex)
            {
                return BadRequest($"No se puede eliminar esta cita: {ex.Message}");
            }
        }
    }
}