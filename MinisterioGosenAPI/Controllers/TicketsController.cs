using Dapper;
using Microsoft.AspNetCore.Mvc;
using MinisterioGosenAPI.Models;
using Npgsql;
using System.Data;

namespace MinisterioGosenAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TicketsController(IConfiguration _configuration) : ControllerBase
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

                var parameters = new DynamicParameters();
                parameters.Add("@p_id_requestor", request.IdRequestor);
                parameters.Add("@p_titulo", request.Titulo);
                parameters.Add("@p_descripcion", request.Descripcion);
                parameters.Add("@p_id_assignee", request.IdAssignee ?? (object)DBNull.Value);
                parameters.Add("@p_id_ticket", dbType: DbType.Int32, direction: ParameterDirection.Output);

                await context.ExecuteAsync(
                    "CALL spCrearTicket(@p_id_requestor, @p_titulo, @p_descripcion, @p_id_assignee, @p_id_ticket)",
                    parameters
                );

                var idTicket = parameters.Get<int>("@p_id_ticket");

                if (idTicket > 0)
                {
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

        [HttpGet]
        [Route("ObtenerTicketsPorUsuario")]
        public async Task<IActionResult> ObtenerTicketsPorUsuario(int idUsuario)
        {
            if (idUsuario <= 0)
            {
                return BadRequest("El ID del usuario es inválido");
            }

            try
            {
                await using var context = new NpgsqlConnection(
                    _configuration.GetConnectionString("DefaultConnection")
                );

                var parameters = new DynamicParameters();
                parameters.Add("@p_id_usuario", idUsuario);

                var tickets = await context.QueryAsync<TicketResponseModel>(
                    "SELECT * FROM fnObtenerTicketsPorUsuario(@p_id_usuario)",
                    parameters
                );

                return Ok(tickets);
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

        [HttpGet]
        [Route("ObtenerTicketPorId")]
        public async Task<IActionResult> ObtenerTicketPorId(int idTicket)
        {
            if (idTicket <= 0)
            {
                return BadRequest("El ID del ticket es inválido");
            }

            try
            {
                await using var context = new NpgsqlConnection(
                    _configuration.GetConnectionString("DefaultConnection")
                );

                var parameters = new DynamicParameters();
                parameters.Add("@p_id_ticket", idTicket);

                var ticket = await context.QueryFirstOrDefaultAsync<TicketResponseModel>(
                    "SELECT * FROM fnObtenerTicketPorId(@p_id_ticket)",
                    parameters
                );

                if (ticket == null)
                {
                    return NotFound("El ticket no existe");
                }

                return Ok(ticket);
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

            try
            {
                await using var context = new NpgsqlConnection(
                    _configuration.GetConnectionString("DefaultConnection")
                );

                var parameters = new DynamicParameters();
                parameters.Add("@p_id_ticket", request.IdTicket);
                parameters.Add("@p_estado", request.Estado);
                parameters.Add("@p_id_assignee", request.IdAssignee ?? (object)DBNull.Value);

                await context.ExecuteAsync(
                    "CALL spActualizarTicket(@p_id_ticket, @p_estado, @p_id_assignee)",
                    parameters
                );

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
