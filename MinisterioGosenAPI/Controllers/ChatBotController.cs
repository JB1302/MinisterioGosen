using Dapper;
using Microsoft.AspNetCore.Mvc;
using MinisterioGosenAPI.Models;
using Npgsql;
using System.Text.Json;

namespace MinisterioGosenAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ChatbotController(IConfiguration _configuration) : ControllerBase
    {
        private class ChatbotDbRow
        {
            public string? OpcionActual { get; set; }
            public string Opciones { get; set; } = "[]";
            public string? Padre { get; set; }
        }

        [HttpGet]
        [Route("ConsultarChatbotAPI")]
        public IActionResult ConsultarChatbotAPI(int? idOpcion = null)
        {
            try
            {
                using var context = new NpgsqlConnection(
                    _configuration.GetConnectionString("DefaultConnection")
                );

                var parameters = new { Id_Opcion = idOpcion };

                var row = context.QuerySingle<ChatbotDbRow>(
                    """
                    SELECT
                        opcion_actual::text AS "OpcionActual",
                        opciones::text AS "Opciones",
                        padre::text AS "Padre"
                    FROM sp_Consultarchatbot(@Id_Opcion)
                    """,
                    parameters
                );

                var jsonOptions = new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
                    PropertyNameCaseInsensitive = true
                };

                var response = new ChatbotResultadoModel
                {
                    Seleccion = row.OpcionActual == null
                        ? null
                        : JsonSerializer.Deserialize<ChatBotOpcionesModel>(
                            row.OpcionActual, jsonOptions),

                    Opciones = JsonSerializer.Deserialize<List<ChatBotOpcionesModel>>(
                        row.Opciones, jsonOptions) ?? new(),

                    OpcionPadre = row.Padre == null
                        ? null
                        : JsonSerializer.Deserialize<ChatBotOpcionesModel>(
                            row.Padre, jsonOptions)
                };

                if (idOpcion.HasValue && response.Seleccion == null)
                {
                    return NotFound("No se encontró la opción seleccionada");
                }

                return Ok(response);
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
                return BadRequest(ex.Message);
            }
        }
    }
}