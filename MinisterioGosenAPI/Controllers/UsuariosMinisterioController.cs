using Dapper;
using Microsoft.AspNetCore.Mvc;
using MinisterioGosenAPI.Models;
using Npgsql;
using System.Data;

namespace MinisterioGosenAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UsuariosMinisterioController(IConfiguration _config) : ControllerBase
    {
        [HttpGet("ListarUsuariosPorMinisterioAPI")]
        public IActionResult ListarUsuariosPorMinisterioAPI(int idMinisterio)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Id_Ministerio", idMinisterio);

            var response = context.Query<UsuariosMinisterioModel>(
                "SELECT * FROM spListarUsuariosPorMinisterio(@Id_Ministerio)", parameters).ToList();

            return Ok(response);
        }

        [HttpGet("ListarUsuariosDisponiblesMinisterioAPI")]
        public IActionResult ListarUsuariosDisponiblesMinisterioAPI(int idMinisterio)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Id_Ministerio", idMinisterio);

            var response = context.Query<UsuarioResponseModel>(
                "SELECT * FROM spListarUsuariosDisponiblesMinisterio(@Id_Ministerio)", parameters).ToList();

            return Ok(response);
        }

        [HttpGet("ListarMinisteriosPorUsuarioAPI")]
        public IActionResult ListarMinisteriosPorUsuarioAPI(int idUsuario)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Id_Usuario", idUsuario);

            var response = context.Query<UsuariosMinisterioModel>(
                "SELECT * FROM spListarMinisteriosPorUsuario(@Id_Usuario)", parameters).ToList();

            return Ok(response);
        }

        [HttpGet("ListarMinisteriosDisponiblesUsuarioAPI")]
        public IActionResult ListarMinisteriosDisponiblesUsuarioAPI(int idUsuario)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Id_Usuario", idUsuario);

            var response = context.Query<MinisterioModel>(
                "SELECT * FROM spListarMinisteriosDisponiblesUsuario(@Id_Usuario)", parameters).ToList();

            return Ok(response);
        }

        [HttpPost("CrearUsuarioMinisterioAPI")]
        public async Task<IActionResult> CrearUsuarioMinisterioAPI(UsuariosMinisterioModel model)
        {
            try
            {
                await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

                var parameters = new DynamicParameters();
                parameters.Add("@Id_Ministerio", model.Id_Ministerio);
                parameters.Add("@Id_Usuario", model.Id_Usuario);
                parameters.Add("@Fecha_Ingreso", model.Fecha_Ingreso);
                parameters.Add("@Estado", model.Estado);
                parameters.Add("@Observacion", model.Observacion);

                await context.ExecuteAsync(@"CALL spCrearUsuarioMinisterio(
                                                            @Id_Ministerio,
                                                            @Id_Usuario,
                                                            @Fecha_Ingreso,
                                                            @Estado,
                                                            @Observacion)", parameters);

                return Ok("Usuario asignado al ministerio correctamente");
            }
            catch (PostgresException ex)
            {
                return BadRequest(ex.MessageText);
            }
            catch (NpgsqlException ex)
            {
                return StatusCode(500, ex.Message);
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpPut("ActualizarUsuarioMinisterioAPI")]
        public async Task<IActionResult> ActualizarUsuarioMinisterioAPI(UsuariosMinisterioModel model)
        {
            try
            {
                await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

                var parameters = new DynamicParameters();
                parameters.Add("@Id_Usuario_Ministerio", model.Id_Usuario_Ministerio);
                parameters.Add("@Fecha_Ingreso", model.Fecha_Ingreso);
                parameters.Add("@Observacion", model.Observacion);

                await context.ExecuteAsync(@"CALL spEditarUsuarioMinisterio(
                                                            @Id_Usuario_Ministerio,
                                                            @Fecha_Ingreso,
                                                            @Observacion)", parameters);

                return Ok("Registro actualizado correctamente");
            }
            catch (PostgresException ex)
            {
                return BadRequest(ex.MessageText);
            }
            catch (NpgsqlException ex)
            {
                return StatusCode(500, ex.Message);
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpPut("SalirUsuarioMinisterioAPI")]
        public async Task<IActionResult> SalirUsuarioMinisterioAPI(UsuariosMinisterioModel model)
        {
            try
            {
                await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

                var parameters = new DynamicParameters();
                parameters.Add("@Id_Usuario_Ministerio", model.Id_Usuario_Ministerio);

                await context.ExecuteAsync("CALL spSalirUsuarioMinisterio(@Id_Usuario_Ministerio)", parameters);

                return Ok("Usuario sacado del ministerio correctamente");
            }
            catch (PostgresException ex)
            {
                return BadRequest(ex.MessageText);
            }
            catch (NpgsqlException ex)
            {
                return StatusCode(500, ex.Message);
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpPost("ReportePersonasMinisterioAPI")]
        public IActionResult ReportePersonasMinisterioAPI(ReportePersonasMinisterioFiltroModel filtros)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Buscar", filtros.Buscar);
            parameters.Add("@Id_Ministerio", filtros.IdMinisterio);
            parameters.Add("@Estado", filtros.Estado);
            parameters.Add(
                "@FechaInicio",
                filtros.FechaInicio,
                DbType.Date);

            parameters.Add(
                "@FechaFin",
                filtros.FechaFin,
                DbType.Date);

            var response = context.Query<UsuariosMinisterioModel>(@"SELECT * FROM spReportePersonasMinisterio(
                                                                                                @Buscar,
                                                                                                @Id_Ministerio,
                                                                                                @Estado,
                                                                                                @FechaInicio,
                                                                                                @FechaFin)",parameters).ToList();

            return Ok(response);
        }

    }
}