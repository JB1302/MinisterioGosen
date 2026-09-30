using Dapper;
using Microsoft.AspNetCore.Mvc;
using MinisterioGosenAPI.Models;
using Npgsql;
using System.Text.Json;

namespace MinisterioGosen.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DashboardController(IConfiguration _configuration) : ControllerBase
    {
        private class DashboardDbRow
        {
            public int TotalPersonas { get; set; }
            public int TotalActividades { get; set; }
            public int TotalMinisterios { get; set; }
            public int TotalCitasPendientes { get; set; }
            public string CitasEstado { get; set; } = "[]";
            public string ActividadesMes { get; set; } = "[]";
            public string TopActividades { get; set; } = "[]";
            public string PersonasMinisterio { get; set; } = "[]";
        }

        [HttpGet]
        [Route("ConsultarDashboardAPI")]
        public async Task<IActionResult> ConsultarDashboardAPI()
        {
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");

                await using var connection = new NpgsqlConnection(connectionString);

                var row = await connection.QuerySingleAsync<DashboardDbRow>(
                    """
                    SELECT
                        totalpersonas AS "TotalPersonas",
                        totalactividades AS "TotalActividades",
                        totalministerios AS "TotalMinisterios",
                        totalcitaspendientes AS "TotalCitasPendientes",
                        citas_estado::text AS "CitasEstado",
                        actividades_mes::text AS "ActividadesMes",
                        top_actividades::text AS "TopActividades",
                        personas_ministerio::text AS "PersonasMinisterio"
                    FROM spConsultarDashboard()
                    """
                );

                if (row == null)
                {
                    return NotFound(new
                    {
                        mensaje = "No se encontró información para el dashboard."
                    });
                }

                var jsonOptions = new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
                    PropertyNameCaseInsensitive = true
                };

                var dashboard = new DashboardModel
                {
                    TotalPersonas = row.TotalPersonas,
                    TotalActividades = row.TotalActividades,
                    TotalMinisterios = row.TotalMinisterios,
                    TotalCitasPendientes = row.TotalCitasPendientes,
                    CitasPorEstado = JsonSerializer.Deserialize<List<DashboardGraficoModel>>(
                        row.CitasEstado, jsonOptions) ?? new(),
                    ActividadesPorMes = JsonSerializer.Deserialize<List<DashboardGraficoModel>>(
                        row.ActividadesMes, jsonOptions) ?? new(),
                    AsistenciaPorActividad = JsonSerializer.Deserialize<List<DashboardGraficoModel>>(
                        row.TopActividades, jsonOptions) ?? new(),
                    PersonasPorMinisterio = JsonSerializer.Deserialize<List<DashboardGraficoModel>>(
                        row.PersonasMinisterio, jsonOptions) ?? new()
                };

                return Ok(dashboard);
            }
            catch (PostgresException ex)
            {
                // Error generado por PostgreSQL:
                // constraint, RAISE EXCEPTION, FK, etc.
                return StatusCode(
                    StatusCodes.Status500InternalServerError,
                    new
                    {
                        mensaje = "Ocurrió un error al consultar la base de datos.", detalle = ex.MessageText
                    }
                );
            }
            catch (NpgsqlException ex)
            {
                // Problemas del proveedor/conexión
                return StatusCode(
                    StatusCodes.Status500InternalServerError,
                    new
                    {
                        mensaje = "Ocurrió un error al consultar la base de datos.", detalle = ex.Message
                    }
                );
            }
            catch (Exception ex)
            {
                return StatusCode(
                    StatusCodes.Status500InternalServerError,
                    new
                    {
                        mensaje = "Ocurrió un error al cargar el dashboard.", detalle = ex.Message
                    }
                );
            }
        }
    }
}