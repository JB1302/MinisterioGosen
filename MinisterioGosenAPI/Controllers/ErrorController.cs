using Dapper;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Npgsql;
using System.Linq.Expressions;

namespace MinisterioGosen.Controllers
{
    [ApiExplorerSettings(IgnoreApi = true)]
    [Route("api/[controller]")]
    [ApiController]
    public class ErrorController(IConfiguration _config) : ControllerBase
    {
        [Route("RegistrarError")]
        public async Task<IActionResult> RegistrarError()
        {
            try
            {
                var ex = HttpContext.Features.Get<IExceptionHandlerFeature>();

                await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

                var parameters = new DynamicParameters();
                parameters.Add("@Mensaje", ex?.Error.Message);
                parameters.Add("@Lugar", ex?.Path);
                parameters.Add("@FechaHora", DateTime.Now);
                parameters.Add("@Id_Usuario", 0);

                await context.ExecuteAsync(
                                        @"CALL spRegistrarError(
                                            @Mensaje,
                                            @Lugar,
                                            @FechaHora,
                                            @Id_Usuario)", parameters);

                return StatusCode(500, "Se presentó un inconveniente técnico");
            }
            catch (PostgresException ex)
            {
                return StatusCode(500, "Error al registrar el error: " + ex.MessageText);
            }
            catch (NpgsqlException ex)
            {
                return StatusCode(500, "Conexión perdida: " + ex.Message);
            }
            catch (Exception ex)
            {
                return StatusCode(500, "Se presentó un inconveniente técnico");
            }
        }
    }
}
