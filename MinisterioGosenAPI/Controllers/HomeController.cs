using Dapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using MinisterioGosenAPI.Models;

namespace MinisterioGosenAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class HomeController(IConfiguration _config) : ControllerBase
    {
        [HttpPost("RegistrarAPI")]
        public IActionResult RegistrarAPI(UsuarioModel model)
        {
            using var context = new SqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
                parameters.Add("@Nombre", model.Nombre);
                parameters.Add("@Identificacion", model.Identificacion);
                parameters.Add("@Correo", model.Correo);
                parameters.Add("@Contrasena", model.Contrasena);

            var response = context.Execute("spRegistrarUsuario", parameters);
            return Ok(response);      
        }
    }
}
