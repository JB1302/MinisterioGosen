using Dapper;
using Microsoft.AspNetCore.Mvc;
using MinisterioGosenAPI.Models;
using MinisterioGosenAPI.Services;
using Npgsql;

namespace MinisterioGosenAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class HomeController(IConfiguration _config, IUtilesService _utiles) : ControllerBase
    {
        [HttpPost("RegistrarAPI")]
        public async Task<IActionResult> RegistrarAPI(
            RegistroUsuarioRequestModel model)
        {
            try
            {
                model.Contrasena = BCrypt.Net.BCrypt.HashPassword(model.Contrasena);

                await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

                var parameters = new DynamicParameters();
                parameters.Add("@Nombre", model.Nombre);
                parameters.Add("@Identificacion", model.Identificacion);
                parameters.Add("@Correo", model.Correo);
                parameters.Add("@Contrasena", model.Contrasena);

                await context.ExecuteAsync(@"CALL spRegistrarUsuario(
                                                                @Identificacion,
                                                                @Nombre,
                                                                @Correo,
                                                                @Contrasena)", parameters);

                // Enviar correo de confirmación de registro
                string ruta = Path.Combine(AppContext.BaseDirectory, "Templates", "RegistroUsuario.html");
                string plantilla = System.IO.File.ReadAllText(ruta);

                plantilla = plantilla.Replace("{{NOMBRE}}", model.Nombre);

                await _utiles.EnviarCorreoAsync(model.Correo, "Cuenta creada exitosamente", plantilla);
                return Ok("Usuario registrado correctamente");
            }
            catch (PostgresException ex)
            {
                return BadRequest(ex.MessageText);
            }
            catch (NpgsqlException ex)
            {
                return StatusCode(500, "No se ha registrado su información, valide que no tenga una cuenta ya creada");
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpPost("IniciarSesionAPI")]
        public IActionResult IniciarSesionAPI(InicioSesionUsuarioRequestModel model)
        {
            using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

            var parameters = new DynamicParameters();
            parameters.Add("@Correo", model.Correo);
            parameters.Add("@Contrasena", model.Contrasena);
            var response = context.QueryFirstOrDefault<UsuarioResponseModel>(@"SELECT * FROM spIniciarSesionUsuario(@Correo)", parameters);

            if (response != null && BCrypt.Net.BCrypt.Verify(model.Contrasena, response.Contrasena))
            {
                return Ok(response);
            }
            else
                return NotFound("No se ha validado su información correctamente");
        }

        [HttpPost("RecuperarAccesoAPI")]
        public async Task<IActionResult> RecuperarAccesoAPI(RecuperarAccesoRequestModel model)
        {
            try
            {
                await using var context = new NpgsqlConnection(_config["ConnectionStrings:DefaultConnection"]);

                var parameters = new DynamicParameters();
                parameters.Add("@Correo", model.Correo);
                var response = await context.QueryFirstOrDefaultAsync<UsuarioResponseModel>("SELECT * FROM spValidarCorreo(@Correo)", parameters);

                if (response == null)
                    return NotFound("No se ha validado su información correctamente");

                //2 Generar una contraseña temporal
                var temporal = _utiles.GenerarContrasena();
                var temporalCifrada = BCrypt.Net.BCrypt.HashPassword(temporal);

                parameters = new DynamicParameters();
                parameters.Add("@Id_Usuario", response.Id_Usuario);
                parameters.Add("@Contrasena", temporalCifrada);
                parameters.Add("@IndicadorTemp", true);

                await context.ExecuteAsync(
                                    @"CALL spActualizarContrasenna(
                                        @Id_Usuario,
                                        @Contrasena,
                                        @IndicadorTemp)", parameters);

                //3. Enviar la contraseña temporal al correo electrónico del usuario
                string ruta = Path.Combine(AppContext.BaseDirectory, "Templates", "RecuperarAcceso.html");
                string plantilla = System.IO.File.ReadAllText(ruta);

                plantilla = plantilla.Replace("{{TEMPORAL}}", temporal);
                plantilla = plantilla.Replace("{{NOMBRE}}", response.Nombre);

                await _utiles.EnviarCorreoAsync(model.Correo, "Recuperación de acceso", plantilla);
                return Ok("Acceso recuperado, revise su correo");
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
    }
}