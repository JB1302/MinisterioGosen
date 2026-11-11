using Dapper;
using Microsoft.AspNetCore.Mvc;
using MinisterioGosenAPI.Models;
using MinisterioGosenAPI.Services;
using Npgsql;
using System.Data;

namespace MinisterioGosenAPI.Controllers
{
    /// <summary>
    /// Operaciones que generan notificaciones de tiquetes.
    /// Conserva las rutas existentes api/Tickets/CrearTicket y api/Tickets/ActualizarEstado.
    /// </summary>
    [Route("api/Tickets")]
    [ApiController]
    public class TicketOperacionesController(IConfiguration _configuration,
        ITicketNotificacionService notificaciones) : ControllerBase
    {
        [HttpPost]
        [Route("CrearTicket")]
        public async Task<IActionResult> CrearTicket([FromBody] CrearTicketRequestModel request)
        {
            if (request == null)
            {
                return BadRequest("El objeto de solicitud no puede estar vacío");
            }

            if (string.IsNullOrWhiteSpace(request.Titulo))
            {
                return BadRequest("El título del ticket es obligatorio");
            }

            if (string.IsNullOrWhiteSpace(request.Descripcion))
            {
                return BadRequest("La descripción del ticket es obligatoria");
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

                // CALL devuelve el parámetro OUT en una fila de PostgreSQL.
                var idTicket = await context.QuerySingleAsync<int>("""
                    CALL spCrearTicket(@p_id_requestor, @p_titulo, @p_descripcion, @p_id_assignee, NULL)
                    """, new
                    {
                        p_id_requestor = request.IdRequestor,
                        p_titulo = request.Titulo.Trim(),
                        p_descripcion = request.Descripcion.Trim(),
                        p_id_assignee = request.IdAssignee
                    });

                if (idTicket > 0)
                {
                    await notificaciones.NotificarCreacionAsync(idTicket);
                    return Ok(new
                    {
                        idTicket = idTicket,
                        mensaje = "Ticket registrado exitosamente"
                    });
                }

                return BadRequest("No se ha registrado el ticket.");
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

        [HttpPut]
        [Route("ActualizarEstado")]
        public async Task<IActionResult> ActualizarEstado([FromBody] ActualizarTicketRequestModel request)
        {
            if (request == null || request.IdTicket <= 0)
            {
                return BadRequest("El ID del ticket es inválido");
            }

            if (string.IsNullOrWhiteSpace(request.Estado))
            {
                return BadRequest("El estado del ticket es obligatorio");
            }

            var estadosValidos = new[] { "Abierto", "En Progreso", "Cerrado", "Cancelado" };
            if (!estadosValidos.Contains(request.Estado))
            {
                return BadRequest($"Estado inválido. Estados válidos: {string.Join(", ", estadosValidos)}");
            }

            var respuesta = request.Respuesta?.Trim();
            if ((request.Estado is "Cerrado" or "Cancelado") && string.IsNullOrWhiteSpace(respuesta))
                return BadRequest("Debe registrar una respuesta o motivo para finalizar o cancelar el ticket.");

            if (respuesta is { Length: > 500 })
            {
                return BadRequest("La respuesta no puede superar 500 caracteres");
            }

            try
            {
                await using var context = new NpgsqlConnection(
                    _configuration.GetConnectionString("DefaultConnection")
                );

                // Capturamos el estado previo para enviar correos solo cuando cambie.
                var estadoAnterior = await context.QuerySingleOrDefaultAsync<string>(
                    "SELECT estado::text FROM tickets WHERE id_ticket = @idTicket",
                    new { idTicket = request.IdTicket });
                if (estadoAnterior is null) return NotFound("El ticket no existe");

                var parameters = new DynamicParameters();
                parameters.Add("@p_id_ticket", request.IdTicket, DbType.Int32);
                parameters.Add("@p_estado", request.Estado, DbType.String);
                parameters.Add("@p_id_assignee", request.IdAssignee, DbType.Int32);
                parameters.Add("@p_respuesta", respuesta, DbType.String);

                await context.ExecuteAsync(
                    "CALL spActualizarTicket(@p_id_ticket, @p_estado, @p_id_assignee, @p_respuesta)",
                    parameters
                );

                await notificaciones.NotificarCambioEstadoAsync(request.IdTicket, estadoAnterior);
                return Ok("Ticket actualizado correctamente");
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
