using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using MinisterioGosenAPI.Models;
using System.Data;
using Npgsql;

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
        public IActionResult CrearUsuarioMinisterioAPI(UsuariosMinisterioModel model)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Id_Ministerio", model.Id_Ministerio);
            parameters.Add("@Id_Usuario", model.Id_Usuario);
            parameters.Add("@Fecha_Ingreso", model.Fecha_Ingreso);
            parameters.Add("@Estado", model.Estado);
            parameters.Add("@Observacion", model.Observacion);

            var response = context.Execute(@"CALL spCrearUsuarioMinisterio(
                                                            @Id_Ministerio,
                                                            @Id_Usuario,
                                                            @Fecha_Ingreso,
                                                            @Estado,
                                                            @Observacion)", parameters);

            if (response > 0)
                return Ok(response);

            return BadRequest("No se pudo registrar el usuario al ministerio.");
        }

        [HttpPut("ActualizarUsuarioMinisterioAPI")]
        public IActionResult ActualizarUsuarioMinisterioAPI(UsuariosMinisterioModel model)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Id_Usuario_Ministerio", model.Id_Usuario_Ministerio);
            parameters.Add("@Fecha_Ingreso", model.Fecha_Ingreso);
            parameters.Add("@Observacion", model.Observacion);

            var response = context.Execute(@"CALL spEditarUsuarioMinisterio(
                                                            @Id_Usuario_Ministerio,
                                                            @Fecha_Ingreso,
                                                            @Observacion)", parameters);

            if (response > 0)
                return Ok(response);

            return BadRequest("No se pudo actualizar el registro.");
        }

        [HttpPut("SalirUsuarioMinisterioAPI")]
        public IActionResult SalirUsuarioMinisterioAPI(UsuariosMinisterioModel model)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Id_Usuario_Ministerio", model.Id_Usuario_Ministerio);

            var response = context.Execute("CALL spSalirUsuarioMinisterio(@Id_Usuario_Ministerio)", parameters);

            if (response > 0)
                return Ok(response);

            return BadRequest("No se pudo sacar el usuario del ministerio.");
        }

        [HttpPost("ReportePersonasMinisterioAPI")]
        public IActionResult ReportePersonasMinisterioAPI(ReportePersonasMinisterioFiltroModel filtros)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Buscar", filtros.Buscar);
            parameters.Add("@Id_Ministerio", filtros.IdMinisterio);
            parameters.Add("@Estado", filtros.Estado);
            parameters.Add("@FechaInicio", filtros.FechaInicio);
            parameters.Add("@FechaFin", filtros.FechaFin);

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