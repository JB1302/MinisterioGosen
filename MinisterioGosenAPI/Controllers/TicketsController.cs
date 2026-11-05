using Dapper;
using Microsoft.AspNetCore.Mvc;
using MinisterioGosenAPI.Models;
using Npgsql;

namespace MinisterioGosenAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TicketsController(IConfiguration _configuration) : ControllerBase
    {
        [HttpGet]
        [Route("ListarTickets")]
        public async Task<IActionResult> ListarTickets()
        {
            try
            {
                await using var context = new NpgsqlConnection(
                    _configuration.GetConnectionString("DefaultConnection")
                );

                var tickets = await context.QueryAsync<TicketResponseModel>(
                    "SELECT * FROM fnListarTickets()"
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

    }
}