using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using MinisterioGosenAPI.Models;

namespace MinisterioGosenAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ActividadController(IConfiguration _config) : ControllerBase
    {
        [HttpGet("ListarActividadesAPI")]
        public IActionResult ListarActividadesAPI()
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var response = context.Query<ActividadModel>("spListarActividades").ToList();

            return Ok(response);
        }

        [HttpGet("ObtenerActividadAPI")]
        public IActionResult ObtenerActividadAPI(int id)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Id_Actividad", id);

            var response = context.QueryFirstOrDefault<ActividadModel>("spObtenerActividad", parameters);

            if (response != null)
                return Ok(response);

            return NotFound("No se encontró la actividad");
        }

        [HttpPost("CrearActividadAPI")]
        public IActionResult CrearActividadAPI(ActividadModel model)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Nombre_Actividad", model.Nombre_Actividad);
            parameters.Add("@Fecha_Ini", model.Fecha_Ini);
            parameters.Add("@Fecha_Fin", model.Fecha_Fin);
            parameters.Add("@Lugar", model.Lugar);
            parameters.Add("@Hora_Ini", model.Hora_Ini);
            parameters.Add("@Hora_Fin", model.Hora_Fin);
            parameters.Add("@Id_Tipo_Actividad", model.Id_Tipo_Actividad);

            var response = context.Execute("spCrearActividad", parameters);

            if (response > 0)
                return Ok(response);

            return BadRequest("No se ha registrado la actividad");
        }

        [HttpPut("ActualizarActividadAPI")]
        public IActionResult ActualizarActividadAPI(ActividadModel model)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Id_Actividad", model.Id_Actividad);
            parameters.Add("@Nombre_Actividad", model.Nombre_Actividad);
            parameters.Add("@Fecha_Ini", model.Fecha_Ini);
            parameters.Add("@Fecha_Fin", model.Fecha_Fin);
            parameters.Add("@Lugar", model.Lugar);
            parameters.Add("@Hora_Ini", model.Hora_Ini);
            parameters.Add("@Hora_Fin", model.Hora_Fin);
            parameters.Add("@Id_Tipo_Actividad", model.Id_Tipo_Actividad);

            var response = context.Execute("spActualizarActividad", parameters);

            if (response > 0)
                return Ok(response);

            return BadRequest("No se ha actualizado la actividad");
        }

        [HttpDelete("EliminarActividadAPI")]
        public IActionResult EliminarActividadAPI(int id)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Id_Actividad", id);

            try
            {
                var response = context.Execute("spEliminarActividad", parameters);

                if (response > 0)
                    return Ok(response);

                return BadRequest("No se ha eliminado la actividad");
            }
            catch
            {
                return BadRequest("No se puede eliminar esta actividad porque tiene información relacionada.");
            }
        }
    }
}