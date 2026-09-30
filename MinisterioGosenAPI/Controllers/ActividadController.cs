using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using MinisterioGosenAPI.Models;
using Npgsql;
using System.Data;

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
        public IActionResult CrearActividadAPI(ActividadModel model)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Nombre_Actividad", model.Nombre_Actividad);
            parameters.Add("@Fecha_Ini", model.Fecha_Ini);
            parameters.Add("@Fecha_Fin", model.Fecha_Fin);
            parameters.Add("@Lugar", model.Lugar);
            parameters.Add("@Hora_Ini", model.Hora_Ini);
            parameters.Add("@Hora_Fin", model.Hora_Fin);
            parameters.Add("@Id_Tipo_Actividad", model.Id_Tipo_Actividad);

            var idActividad = context.QuerySingle<int>(
                                        @"SELECT spCrearActividad(
                                        @Nombre_Actividad,
                                        @Fecha_Ini,
                                        @Fecha_Fin,
                                        @Lugar,
                                        @Hora_Ini,
                                        @Hora_Fin,
                                        @Id_Tipo_Actividad)",parameters);

            if (idActividad > 0)
            {
                if (model.Id_Ministerio != null && model.Id_Ministerio > 0)
                {
                    var parametersMinisterio = new DynamicParameters();
                    parametersMinisterio.Add("@Id_Actividad", idActividad);
                    parametersMinisterio.Add("@Id_Ministerio", model.Id_Ministerio);
                    parametersMinisterio.Add("@Observacion", model.Observacion_Ministerio_Actividad);

                    context.Execute(@"CALL spGuardarMinisterioActividad(
                                                   @Id_Actividad,
                                                   @Id_Ministerio,
                                                   @Observacion)", parametersMinisterio);
                }

                return Ok(idActividad);
            }

            return BadRequest("No se ha registrado la actividad");
        }

        [HttpPut("ActualizarActividadAPI")]
        public IActionResult ActualizarActividadAPI(ActividadModel model)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Id_Actividad", model.Id_Actividad);
            parameters.Add("@Nombre_Actividad", model.Nombre_Actividad);
            parameters.Add("@Fecha_Ini", model.Fecha_Ini);
            parameters.Add("@Fecha_Fin", model.Fecha_Fin);
            parameters.Add("@Lugar", model.Lugar);
            parameters.Add("@Hora_Ini", model.Hora_Ini);
            parameters.Add("@Hora_Fin", model.Hora_Fin);
            parameters.Add("@Id_Tipo_Actividad", model.Id_Tipo_Actividad);

            var response = context.Execute(@"CALL spActualizarActividad(
                                        @Id_Actividad,
                                        @Nombre_Actividad,
                                        @Fecha_Ini,
                                        @Fecha_Fin,
                                        @Lugar,
                                        @Hora_Ini,
                                        @Hora_Fin,
                                        @Id_Tipo_Actividad)",parameters);

            if (response > 0)
            {
                if (model.Id_Ministerio != null && model.Id_Ministerio > 0)
                {
                    var parametersMinisterio = new DynamicParameters();
                    parametersMinisterio.Add("@Id_Actividad", model.Id_Actividad);
                    parametersMinisterio.Add("@Id_Ministerio", model.Id_Ministerio);
                    parametersMinisterio.Add("@Observacion", model.Observacion_Ministerio_Actividad);

                    context.Execute(@"CALL spGuardarMinisterioActividad(
                                        @Id_Actividad,
                                        @Id_Ministerio,
                                        @Observacion)",parametersMinisterio);
                }
                else
                {
                    var parametersEliminarMinisterio = new DynamicParameters();
                    parametersEliminarMinisterio.Add("@Id_Actividad", model.Id_Actividad);

                    context.Execute("CALL spEliminarMinisterioPorActividad(@Id_Actividad)", parametersEliminarMinisterio);
                }

                return Ok(response);
            }

            return BadRequest("No se ha actualizado la actividad");
        }

        [HttpDelete("EliminarActividadAPI")]
        public IActionResult EliminarActividadAPI(int id)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            try
            {
                var parametersMinisterio = new DynamicParameters();
                parametersMinisterio.Add("@Id_Actividad", id);

                context.Execute("CALL spEliminarMinisterioPorActividad(@Id_Actividad)", parametersMinisterio);

                var parameters = new DynamicParameters();
                parameters.Add("@Id_Actividad", id);

                var response = context.Execute("CALL spEliminarActividad(@Id_Actividad)", parameters);

                if (response > 0)
                    return Ok(response);

                return BadRequest("No se ha eliminado la actividad");
            }
            catch
            {
                return BadRequest("No se puede eliminar esta actividad porque tiene información relacionada.");
            }
        }

        [HttpPut("InactivarActividadAPI")]
        public IActionResult InactivarActividadAPI(int id)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Id_Actividad", id);

            var response = context.Execute("CALL spInactivarActividad(@Id_Actividad)", parameters);

            if (response > 0)
                return Ok(response);

            return BadRequest("No se pudo inactivar la actividad.");
        }

        [HttpPut("ActivarActividadAPI")]
        public IActionResult ActivarActividadAPI(int id)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Id_Actividad", id);

            var response = context.Execute("CALL spActivarActividad(@Id_Actividad)", parameters);

            if (response > 0)
                return Ok(response);

            return BadRequest("No se pudo activar la actividad.");
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