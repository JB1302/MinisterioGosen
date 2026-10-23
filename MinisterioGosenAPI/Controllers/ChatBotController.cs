using Dapper;
using Microsoft.AspNetCore.Mvc;
using MinisterioGosenAPI.Models;
using Npgsql;
using System.Data;
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

        [HttpPost]
        [Route("RegistrarTicketDesdeChat")]
        public async Task<IActionResult> RegistrarTicketDesdeChat([FromBody] CrearTicketRequestModel request)
        {
            if (request == null)
            {
                return BadRequest("El objeto de solicitud no puede estar vacío");
            }

            if (string.IsNullOrWhiteSpace(request.Titulo) || string.IsNullOrWhiteSpace(request.Descripcion))
            {
                return BadRequest("El título y la descripción del ticket son obligatorios");
            }

            if (request.IdRequestor <= 0)
            {
                return BadRequest("El ID del solicitante es inválido");
            }

            try
            {
                await using var context = new NpgsqlConnection(
                    _configuration.GetConnectionString("DefaultConnection")
                );

                var parameters = new DynamicParameters();
                var idTicket = await context.QuerySingleAsync<int>(
                                """
                                    CALL spcrearticket(
                                        @p_id_requestor,
                                        @p_titulo,
                                        @p_descripcion,
                                        @p_id_assignee,
                                        NULL
                                    )
                                """,
                                new
                                {
                                    p_id_requestor = request.IdRequestor,
                                    p_titulo = request.Titulo.Trim(),
                                    p_descripcion = request.Descripcion.Trim(),
                                    p_id_assignee = request.IdAssignee
                                }
                            );

                if (idTicket > 0)
                {
                    return Ok(new
                    {
                        idTicket = idTicket,
                        mensaje = "Tu ticket ha sido registrado exitosamente",
                        estado = "exito"
                    });
                }

                return BadRequest(new
                {
                    mensaje = "No se ha registrado el ticket",
                    estado = "error"
                });
            }
            catch (PostgresException ex)
            {
                return BadRequest(new
                {
                    mensaje = "Error al registrar el ticket",
                    estado = "error",
                    detalle = ex.MessageText
                });
            }
            catch (NpgsqlException ex)
            {
                return BadRequest(new
                {
                    mensaje = "Error de conexión",
                    estado = "error",
                    detalle = ex.Message
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new
                {
                    mensaje = "Error al registrar el ticket",
                    estado = "error",
                    detalle = ex.Message
                });
            }
        }

        [HttpPost]
        [Route("ValidarDatosTicket")]
        public async Task<IActionResult> ValidarDatosTicket([FromBody] CrearTicketRequestModel request)
        {
            var errores = new List<string>();

            if (request == null)
            {
                errores.Add("La solicitud no contiene datos");
            }
            else
            {
                if (string.IsNullOrWhiteSpace(request.Titulo))
                {
                    errores.Add("El título del ticket es obligatorio");
                }
                else if (request.Titulo.Length > 150)
                {
                    errores.Add("El título no puede exceder 150 caracteres");
                }

                if (string.IsNullOrWhiteSpace(request.Descripcion))
                {
                    errores.Add("La descripción del ticket es obligatoria");
                }
                else if (request.Descripcion.Length > 500)
                {
                    errores.Add("La descripción no puede exceder 500 caracteres");
                }

                if (request.IdRequestor <= 0)
                {
                    errores.Add("El ID del solicitante es inválido");
                }
            }

            if (errores.Count > 0)
            {
                return BadRequest(new
                {
                    valido = false,
                    errores = errores
                });
            }

            return Ok(new
            {
                valido = true,
                mensaje = "Datos válidos"
            });
        }
    }
}
