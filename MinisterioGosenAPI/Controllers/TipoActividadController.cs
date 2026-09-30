using Dapper;
using Microsoft.AspNetCore.Mvc;
using MinisterioGosenAPI.Models;
using Npgsql;

namespace MinisterioGosenAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TipoActividadController(IConfiguration _config) : ControllerBase
    {
        [HttpGet("ListarTiposActividadAPI")]
        public IActionResult ListarTiposActividadAPI()
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var response = context.Query<TipoActividadModel>("SELECT * FROM spListarTiposActividad()").ToList();

            return Ok(response);
        }

        [HttpGet("ObtenerTipoActividadAPI")]
        public IActionResult ObtenerTipoActividadAPI(int id)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Id_Tipo_Actividad", id);

            var response = context.QueryFirstOrDefault<TipoActividadModel>("SELECT * FROM spObtenerTipoActividad(@Id_Tipo_Actividad)", parameters);

            if (response != null)
                return Ok(response);

            return NotFound("No se encontró el tipo de actividad");
        }

        [HttpPost("CrearTipoActividadAPI")]
        public IActionResult CrearTipoActividadAPI(TipoActividadModel model)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Nombre_Tipo", model.Nombre_Tipo);

            var response = context.Execute("CALL spCrearTipoActividad(@Nombre_Tipo)", parameters);

            if (response > 0)
                return Ok(response);

            return BadRequest("No se ha registrado el tipo de actividad");
        }

        [HttpPut("ActualizarTipoActividadAPI")]
        public IActionResult ActualizarTipoActividadAPI(TipoActividadModel model)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Id_Tipo_Actividad", model.Id_Tipo_Actividad);
            parameters.Add("@Nombre_Tipo", model.Nombre_Tipo);

            var response = context.Execute(@"CALL spActualizarTipoActividad(@Id_Tipo_Actividad,@Nombre_Tipo)", parameters);

            if (response > 0)
                return Ok(response);

            return BadRequest("No se ha actualizado el tipo de actividad");
        }

        [HttpDelete("EliminarTipoActividadAPI")]
        public IActionResult EliminarTipoActividadAPI(int id)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Id_Tipo_Actividad", id);

            try{
                var response = context.Execute("CALL spEliminarTipoActividad(@Id_Tipo_Actividad)", parameters);

                if (response > 0)
                    return Ok(response);

                return BadRequest("No se ha eliminado el tipo de actividad");
            }catch{
                    return BadRequest("No se puede eliminar este tipo de actividad porque tiene información relacionada.");
                }
        }
    }
}