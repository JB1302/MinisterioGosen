using Dapper;
using Microsoft.AspNetCore.Mvc;
using MinisterioGosenAPI.Models;
using Npgsql;

namespace MinisterioGosenAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ActividadController(IConfiguration _config) : ControllerBase
    {
        [HttpGet("ListarActividadesAPI")]
        public IActionResult ListarActividadesAPI()
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var response = context.Query<ActividadModel>("SELECT * FROM spListarActividades()").ToList();

            return Ok(response);
        }

        [HttpGet("ObtenerActividadAPI")]
        public IActionResult ObtenerActividadAPI(int id)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Id_Actividad", id);

            var response = context.QueryFirstOrDefault<ActividadModel>("SELECT * FROM spObtenerActividad(@Id_Actividad)", parameters);

            if (response != null)
                return Ok(response);

            return NotFound("No se encontró la actividad");
        }

        [HttpPost("CrearActividadAPI")]
        public async Task<IActionResult> CrearActividadAPI(ActividadModel model)
        {
            await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            try
            {
                await context.OpenAsync();
                await using var transaction = await context.BeginTransactionAsync();

                try
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@Nombre_Actividad", model.Nombre_Actividad);
                    parameters.Add("@Fecha_Ini", model.Fecha_Ini);
                    parameters.Add("@Fecha_Fin", model.Fecha_Fin);
                    parameters.Add("@Lugar", model.Lugar);
                    parameters.Add("@Hora_Ini", model.Hora_Ini);
                    parameters.Add("@Hora_Fin", model.Hora_Fin);
                    parameters.Add("@Id_Tipo_Actividad", model.Id_Tipo_Actividad);

                    var idActividad = await context.QuerySingleAsync<int>(
                                                @"SELECT spCrearActividad(
                                                @Nombre_Actividad,
                                                @Fecha_Ini,
                                                @Fecha_Fin,
                                                @Lugar,
                                                @Hora_Ini,
                                                @Hora_Fin,
                                                @Id_Tipo_Actividad)", parameters);

                    if (model.Id_Ministerio != null && model.Id_Ministerio > 0)
                    {
                        var parametersMinisterio = new DynamicParameters();
                        parametersMinisterio.Add("@Id_Actividad", idActividad);
                        parametersMinisterio.Add("@Id_Ministerio", model.Id_Ministerio);
                        parametersMinisterio.Add("@Observacion", model.Observacion_Ministerio_Actividad);

                        await context.ExecuteAsync(@"CALL spGuardarMinisterioActividad(
                                                   @Id_Actividad,
                                                   @Id_Ministerio,
                                                   @Observacion)", parametersMinisterio);
                    }

                    await transaction.CommitAsync();
                    return Ok(idActividad);
                }
                catch
                {
                    await transaction.RollbackAsync();
                    throw;
                }
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

        [HttpPut("ActualizarActividadAPI")]
        public async Task<IActionResult> ActualizarActividadAPI(ActividadModel model)
        {
            await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            try
            {
                await context.OpenAsync();
                await using var transaction = await context.BeginTransactionAsync();

                try
                {
                    var parameters = new DynamicParameters();
                    parameters.Add("@Id_Actividad", model.Id_Actividad);
                    parameters.Add("@Nombre_Actividad", model.Nombre_Actividad);
                    parameters.Add("@Fecha_Ini", model.Fecha_Ini);
                    parameters.Add("@Fecha_Fin", model.Fecha_Fin);
                    parameters.Add("@Lugar", model.Lugar);
                    parameters.Add("@Hora_Ini", model.Hora_Ini);
                    parameters.Add("@Hora_Fin", model.Hora_Fin);
                    parameters.Add("@Id_Tipo_Actividad", model.Id_Tipo_Actividad);

                    await context.ExecuteAsync(@"CALL spActualizarActividad(
                                                @Id_Actividad,
                                                @Nombre_Actividad,
                                                @Fecha_Ini,
                                                @Fecha_Fin,
                                                @Lugar,
                                                @Hora_Ini,
                                                @Hora_Fin,
                                                @Id_Tipo_Actividad)", parameters);

                    if (model.Id_Ministerio != null && model.Id_Ministerio > 0)
                    {
                        var parametersMinisterio = new DynamicParameters();
                        parametersMinisterio.Add("@Id_Actividad", model.Id_Actividad);
                        parametersMinisterio.Add("@Id_Ministerio", model.Id_Ministerio);
                        parametersMinisterio.Add("@Observacion", model.Observacion_Ministerio_Actividad);

                        await context.ExecuteAsync(@"CALL spGuardarMinisterioActividad(
                                                @Id_Actividad,
                                                @Id_Ministerio,
                                                @Observacion)", parametersMinisterio);
                    }
                    else
                    {
                        var parametersEliminarMinisterio = new DynamicParameters();
                        parametersEliminarMinisterio.Add("@Id_Actividad", model.Id_Actividad);

                        await context.ExecuteAsync("CALL spEliminarMinisterioPorActividad(@Id_Actividad)", parametersEliminarMinisterio);
                    }

                    await transaction.CommitAsync();
                    return Ok("Actividad actualizada correctamente");
                }
                catch
                {
                    await transaction.RollbackAsync();
                    throw;
                }
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

        [HttpDelete("EliminarActividadAPI")]
        public async Task<IActionResult> EliminarActividadAPI(int id)
        {
            await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            try
            {
                var parametersMinisterio = new DynamicParameters();
                parametersMinisterio.Add("@Id_Actividad", id);

                await context.ExecuteAsync("CALL spEliminarMinisterioPorActividad(@Id_Actividad)", parametersMinisterio);

                var parameters = new DynamicParameters();
                parameters.Add("@Id_Actividad", id);

                await context.ExecuteAsync("CALL spEliminarActividad(@Id_Actividad)", parameters);

                return Ok("Actividad eliminada correctamente");
            }
            catch (PostgresException ex)
            {
                return BadRequest(ex.MessageText);
            }
            catch (NpgsqlException ex)
            {
                return BadRequest("No se puede eliminar esta actividad porque tiene información relacionada.");
            }
            catch (Exception ex)
            {
                return BadRequest("No se puede eliminar esta actividad porque tiene información relacionada.");
            }
        }

        [HttpPut("InactivarActividadAPI")]
        public async Task<IActionResult> InactivarActividadAPI(int id)
        {
            await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            try
            {
                var parameters = new DynamicParameters();
                parameters.Add("@Id_Actividad", id);

                await context.ExecuteAsync("CALL spInactivarActividad(@Id_Actividad)", parameters);

                return Ok("Actividad inactivada correctamente");
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

        [HttpPut("ActivarActividadAPI")]
        public async Task<IActionResult> ActivarActividadAPI(int id)
        {
            await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            try
            {
                var parameters = new DynamicParameters();
                parameters.Add("@Id_Actividad", id);

                await context.ExecuteAsync("CALL spActivarActividad(@Id_Actividad)", parameters);

                return Ok("Actividad activada correctamente");
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

        [HttpPost("ReporteActividadesAPI")]
        public IActionResult ReporteActividadesAPI(ReporteActividadesFiltroModel filtros)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Buscar", filtros.Buscar);
            parameters.Add("@Id_Ministerio", filtros.IdMinisterio);
            parameters.Add("@Id_Tipo_Actividad", filtros.IdTipoActividad);
            parameters.Add("@FechaInicio", filtros.FechaInicio);
            parameters.Add("@FechaFin", filtros.FechaFin);

            var response = context.Query<ActividadModel>(
                @"SELECT * FROM spReporteActividades(
                      @Buscar,
                      @Id_Ministerio,
                      @Id_Tipo_Actividad,
                      @FechaInicio,
                      @FechaFin
                  )",
                parameters
            ).ToList();

            return Ok(response);
        }

        [HttpPost("ReporteHorariosAPI")]
        public IActionResult ReporteHorariosAPI(ReporteHorariosFiltroModel filtros)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Buscar", filtros.Buscar);
            parameters.Add("@Id_Ministerio", filtros.IdMinisterio);
            parameters.Add("@Id_Tipo_Actividad", filtros.IdTipoActividad);
            parameters.Add("@FechaInicio", filtros.FechaInicio);
            parameters.Add("@FechaFin", filtros.FechaFin);

            var response = context.Query<ActividadModel>(
                @"SELECT * FROM spReporteHorarios(
                      @Buscar,
                      @Id_Ministerio,
                      @Id_Tipo_Actividad,
                      @FechaInicio,
                      @FechaFin
                  )",
                parameters
            ).ToList();

            return Ok(response);
        }

    }
}