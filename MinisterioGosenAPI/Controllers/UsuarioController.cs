using Dapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Npgsql;
using MinisterioGosenAPI.Models;

namespace MinisterioGosenAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UsuarioController(IConfiguration _config) : ControllerBase
    {
        [HttpPut("CambiarContrasenaAPI")]
        public async Task<IActionResult> CambiarContrasenaAPI(CambiarContrasenaRequestModel model)
        {
            try
            {
                model.Contrasena = BCrypt.Net.BCrypt.HashPassword(model.Contrasena);

                await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

                var parameters = new DynamicParameters();
                parameters.Add("@Id_Usuario", model.Id_Usuario);
                parameters.Add("@Contrasena", model.Contrasena);
                parameters.Add("@IndicadorTemp", false);

                await context.ExecuteAsync(@"CALL spActualizarContrasenna(@Id_Usuario,@Contrasena,@IndicadorTemp)", parameters);

                return Ok("Contraseña actualizada correctamente");
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

        [HttpPut("CambiarPerfilAPI")]
        public async Task<IActionResult> CambiarPerfilAPI(ActualizarPerfilRequestModel model)
        {
            try
            {
                await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

                var parameters = new DynamicParameters();
                parameters.Add("@Id_Usuario", model.Id_Usuario);
                parameters.Add("@Identificacion", model.Identificacion);
                parameters.Add("@Nombre", model.Nombre);
                parameters.Add("@Correo", model.Correo);

                await context.ExecuteAsync(@"CALL spActualizarPerfil(@Id_Usuario,@Identificacion,@Nombre,@Correo)", parameters);

                return Ok("La información se ha actualizado correctamente");
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

        [HttpGet("ListarRolesAPI")]
        public IActionResult ListarRolesAPI()
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var response = context.Query<RolResponseModel>("SELECT * FROM spListarRoles()").ToList();

            return Ok(response);
        }

        [HttpGet("ListarUsuariosAPI")]
        public IActionResult ListarUsuariosAPI()
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var response = context.Query<UsuarioResponseModel>("SELECT * FROM spListarUsuarios()").ToList();

            return Ok(response);
        }

        [HttpGet("ObtenerUsuarioAPI")]
        public IActionResult ObtenerUsuarioAPI(int id)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Id_Usuario", id);

            var response = context.QueryFirstOrDefault<UsuarioResponseModel>("SELECT * FROM spObtenerUsuario(@Id_Usuario)", parameters);

            if (response != null)
                return Ok(response);

            return NotFound("No se encontró la información del usuario");
        }

        [HttpPut("ActualizarUsuarioAPI")]
        public async Task<IActionResult> ActualizarUsuarioAPI(UsuarioResponseModel model)
        {
            try
            {
                await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

                var parameters = new DynamicParameters();
                parameters.Add("@Id_Usuario", model.Id_Usuario);
                parameters.Add("@Nombre", model.Nombre);
                parameters.Add("@Correo", model.Correo);
                parameters.Add("@Estado", model.Estado);
                parameters.Add("@Id_Rol", model.Id_Rol);

                await context.ExecuteAsync(@"CALL spActualizarUsuario(
                                                            @Id_Usuario,
                                                            @Nombre,
                                                            @Correo,
                                                            @Estado,
                                                            @Id_Rol)", parameters);

                return Ok("Usuario actualizado correctamente");
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

        [HttpPut("DesactivarUsuarioAPI")]
        public async Task<IActionResult> DesactivarUsuarioAPI(UsuarioEstadoRequestModel model)
        {
            try
            {
                await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

                var parameters = new DynamicParameters();
                parameters.Add("@Id_Usuario", model.Id_Usuario);

                await context.ExecuteAsync("CALL spDesactivarUsuario(@Id_Usuario)", parameters);

                return Ok("Usuario desactivado correctamente");
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

        [HttpPut("ActivarUsuarioAPI")]
        public async Task<IActionResult> ActivarUsuarioAPI(UsuarioEstadoRequestModel model)
        {
            try
            {
                await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

                var parameters = new DynamicParameters();
                parameters.Add("@Id_Usuario", model.Id_Usuario);

                await context.ExecuteAsync("CALL spActivarUsuario(@Id_Usuario)", parameters);

                return Ok("Usuario activado correctamente");
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

        [HttpPost("CrearUsuarioAPI")]
        public async Task<IActionResult> CrearUsuarioAPI(CrearUsuarioRequestModel model)
        {
            try
            {
                model.Contrasena = BCrypt.Net.BCrypt.HashPassword(model.Contrasena);

                await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

                var parameters = new DynamicParameters();
                parameters.Add("@Identificacion", model.Identificacion);
                parameters.Add("@Nombre", model.Nombre);
                parameters.Add("@Correo", model.Correo);
                parameters.Add("@Contrasena", model.Contrasena);
                parameters.Add("@Estado", "A");
                parameters.Add("@Id_Rol", model.Id_Rol);

                await context.ExecuteAsync(@"CALL spCrearUsuario(
                                                            @Identificacion,
                                                            @Nombre,
                                                            @Correo,
                                                            @Contrasena,
                                                            @Estado,
                                                            @Id_Rol)", parameters);

                return Ok("Usuario registrado correctamente");
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
                return StatusCode(500, "No se ha registrado el usuario. Valide que la identificación o el correo no estén repetidos.");
            }
        }
    }
}
