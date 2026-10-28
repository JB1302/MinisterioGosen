using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using MinisterioGosen.Helpers;
using MinisterioGosen.Models;
using System.Net;
using System.Net.Http.Json;

namespace MinisterioGosen.Controllers
{
    [ValidarSesion]
    public class CampanaController(
        IHttpClientFactory _http,
        IConfiguration _config) : Controller
    {
        // =========================================================
        // MODELO INTERNO DE RESPUESTA DE LA API
        // =========================================================

        private sealed class CampanaEnvioResponse
        {
            public int Id_Campana { get; set; }

            public string Estado { get; set; } =
                string.Empty;

            public int Total { get; set; }

            public int Enviados { get; set; }

            public int Errores { get; set; }
        }


        // =========================================================
        // VALIDAR ADMINISTRADOR
        // =========================================================

        private bool EsAdmin()
        {
            return HttpContext.Session
                .GetInt32("Id_Rol") == 1;
        }


        // =========================================================
        // INDEX - HISTORIAL DE CAMPAÑAS
        // =========================================================

        [HttpGet]
        public async Task<IActionResult> Index()
        {
            if (!EsAdmin())
            {
                return RedirectToAction(
                    "Error",
                    "Home",
                    new
                    {
                        statusCode = 403
                    }
                );
            }


            using var client =
                _http.CreateClient();


            var url =
                _config["Valores:UrlApi"] +
                "Campana/ListarCampanasAPI";


            try
            {
                var response =
                    await client.GetAsync(url);


                if (!response.IsSuccessStatusCode)
                {
                    ViewBag.Mensaje =
                        "No fue posible cargar el historial de campañas.";

                    return View(
                        new List<CampanaHistorialModel>()
                    );
                }


                var campanas =
                    await response.Content
                        .ReadFromJsonAsync<
                            List<CampanaHistorialModel>
                        >()
                    ?? new List<CampanaHistorialModel>();


                return View(campanas);
            }
            catch (HttpRequestException)
            {
                ViewBag.Mensaje =
                    "No fue posible comunicarse con la API.";

                return View(
                    new List<CampanaHistorialModel>()
                );
            }
        }



        // =========================================================
        // DETALLE DE CAMPAÑA
        // =========================================================

        [HttpGet]
        public async Task<IActionResult> Detalle(
            int idCampana)
        {
            if (!EsAdmin())
            {
                return RedirectToAction(
                    "Error",
                    "Home",
                    new
                    {
                        statusCode = 403
                    }
                );
            }


            if (idCampana <= 0)
            {
                return RedirectToAction(
                    nameof(Index)
                );
            }


            using var client =
                _http.CreateClient();


            var urlCampana =
                _config["Valores:UrlApi"] +
                $"Campana/ObtenerCampanaAPI/{idCampana}";


            var urlDestinatarios =
                _config["Valores:UrlApi"] +
                $"Campana/ListarDestinatariosCampanaAPI/{idCampana}";


            try
            {
                // =====================================================
                // OBTENER CAMPAÑA
                // =====================================================

                var responseCampana =
                    await client.GetAsync(
                        urlCampana
                    );


                if (!responseCampana.IsSuccessStatusCode)
                {
                    return RedirectToAction(
                        nameof(Index)
                    );
                }


                var campana =
                    await responseCampana.Content
                        .ReadFromJsonAsync<
                            CampanaDetalleModel
                        >();


                if (campana == null)
                {
                    return RedirectToAction(
                        nameof(Index)
                    );
                }


                // =====================================================
                // OBTENER DESTINATARIOS
                // =====================================================

                var responseDestinatarios =
                    await client.GetAsync(
                        urlDestinatarios
                    );


                var destinatarios =
                    new List<
                        CampanaDestinatarioDetalleModel
                    >();


                if (responseDestinatarios.IsSuccessStatusCode)
                {
                    destinatarios =
                        await responseDestinatarios.Content
                            .ReadFromJsonAsync<
                                List<CampanaDestinatarioDetalleModel>
                            >()
                        ?? new List<
                            CampanaDestinatarioDetalleModel
                        >();
                }


                // =====================================================
                // VIEW MODEL
                // =====================================================

                var model =
                    new CampanaDetalleViewModel
                    {
                        Campana =
                            campana,

                        Destinatarios =
                            destinatarios
                    };


                return View(model);
            }
            catch (HttpRequestException)
            {
                TempData["Mensaje"] =
                    "No fue posible comunicarse con la API.";

                return RedirectToAction(
                    nameof(Index)
                );
            }
        }
        // =========================================================
        // CREAR - GET
        // =========================================================

        [HttpGet]
        public IActionResult Crear()
        {
            if (!EsAdmin())
            {
                return RedirectToAction(
                    "Error",
                    "Home",
                    new
                    {
                        statusCode = 403
                    }
                );
            }


            CargarCatalogos();


            var plantillas =
                ViewBag.Plantillas
                as List<CampanaPlantillaModel>
                ?? new List<CampanaPlantillaModel>();


            var model =
                new CampanaCrearModel();


            /*
             * Seleccionamos dinámicamente la
             * primera plantilla disponible.
             */
            if (plantillas.Count > 0)
            {
                model.Plantilla =
                    plantillas[0].Codigo;
            }


            return View(model);
        }


        // =========================================================
        // CREAR - POST
        // =========================================================

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Crear(
            CampanaCrearModel model)
        {
            if (!EsAdmin())
            {
                return RedirectToAction(
                    "Error",
                    "Home",
                    new
                    {
                        statusCode = 403
                    }
                );
            }


            // =====================================================
            // VALIDACIONES
            // =====================================================

            if (string.IsNullOrWhiteSpace(
                    model.Titulo))
            {
                return RetornarFormulario(
                    model,
                    "Debe ingresar el título de la campaña."
                );
            }


            if (string.IsNullOrWhiteSpace(
                    model.Asunto))
            {
                return RetornarFormulario(
                    model,
                    "Debe ingresar el asunto del correo."
                );
            }


            if (string.IsNullOrWhiteSpace(
                    model.Contenido))
            {
                return RetornarFormulario(
                    model,
                    "Debe ingresar el contenido de la campaña."
                );
            }


            if (string.IsNullOrWhiteSpace(
                    model.Plantilla))
            {
                return RetornarFormulario(
                    model,
                    "Debe seleccionar una plantilla."
                );
            }


            if (
                !model.Todos &&
                model.IdsRoles.Count == 0 &&
                model.IdsMinisterios.Count == 0
            )
            {
                return RetornarFormulario(
                    model,
                    "Debe seleccionar al menos un rol, " +
                    "un ministerio o la opción Todos."
                );
            }


            // =====================================================
            // USUARIO CREADOR DESDE LA SESIÓN
            // =====================================================

            var idUsuarioCreador =
                HttpContext.Session
                    .GetInt32("Id_Usuario");


            if (
                idUsuarioCreador == null ||
                idUsuarioCreador <= 0
            )
            {
                return RedirectToAction(
                    "Error",
                    "Home",
                    new
                    {
                        statusCode = 401
                    }
                );
            }


            // =====================================================
            // REQUEST PARA LA API
            // =====================================================

            var request =
                new
                {
                    Titulo =
                        model.Titulo,

                    Asunto =
                        model.Asunto,

                    Contenido =
                        model.Contenido,

                    Plantilla =
                        model.Plantilla,

                    Id_Usuario_Creador =
                        idUsuarioCreador.Value,

                    Ids_Roles =
                        model.IdsRoles,

                    Ids_Ministerios =
                        model.IdsMinisterios,

                    Todos =
                        model.Todos
                };


            using var client =
                _http.CreateClient();


            var url =
                _config["Valores:UrlApi"] +
                "Campana/CrearCampanaAPI";


            try
            {
                // =================================================
                // ENVIAR CAMPAÑA A LA API
                // =================================================

                var response =
                    await client.PostAsJsonAsync(
                        url,
                        request
                    );


                // =================================================
                // ERROR DEVUELTO POR LA API
                // =================================================

                if (!response.IsSuccessStatusCode)
                {
                    var mensajeApi =
                        await response.Content
                            .ReadAsStringAsync();


                    if (string.IsNullOrWhiteSpace(
                            mensajeApi))
                    {
                        mensajeApi =
                            "No fue posible procesar la campaña.";
                    }


                    /*
                     * La API puede devolver texto entre
                     * comillas cuando responde BadRequest(string).
                     */
                    mensajeApi =
                        mensajeApi.Trim();


                    if (
                        mensajeApi.StartsWith("\"") &&
                        mensajeApi.EndsWith("\"") &&
                        mensajeApi.Length >= 2
                    )
                    {
                        mensajeApi =
                            mensajeApi[1..^1];
                    }


                    return RetornarFormulario(
                        model,
                        mensajeApi
                    );
                }


                // =================================================
                // LEER RESULTADO
                // =================================================

                var resultado =
                    await response.Content
                        .ReadFromJsonAsync<
                            CampanaEnvioResponse
                        >();


                if (resultado == null)
                {
                    return RetornarFormulario(
                        model,
                        "La API procesó la solicitud, " +
                        "pero no devolvió un resultado válido."
                    );
                }


                // =================================================
                // RESULTADO EXITOSO
                // =================================================

                if (
                    resultado.Estado ==
                    "Enviada"
                )
                {
                    TempData["MensajeExito"] =
                        "Campaña enviada correctamente. " +
                        $"Destinatarios: {resultado.Total}. " +
                        $"Enviados: {resultado.Enviados}.";


                    return RedirectToAction(
                        nameof(Crear)
                    );
                }


                // =================================================
                // RESULTADO PARCIAL
                // =================================================

                if (
                    resultado.Estado ==
                    "Parcial"
                )
                {
                    TempData["Mensaje"] =
                        "La campaña fue procesada parcialmente. " +
                        $"Total: {resultado.Total}. " +
                        $"Enviados: {resultado.Enviados}. " +
                        $"Errores: {resultado.Errores}.";


                    return RedirectToAction(
                        nameof(Crear)
                    );
                }


                // =================================================
                // TODOS LOS ENVÍOS FALLARON
                // =================================================

                TempData["Mensaje"] =
                    "No fue posible enviar la campaña. " +
                    $"Total: {resultado.Total}. " +
                    $"Enviados: {resultado.Enviados}. " +
                    $"Errores: {resultado.Errores}.";


                return RedirectToAction(
                    nameof(Crear)
                );
            }
            catch (HttpRequestException)
            {
                return RetornarFormulario(
                    model,
                    "No fue posible comunicarse con la API. " +
                    "Verifique que el proyecto MinisterioGosenAPI " +
                    "se encuentre ejecutándose."
                );
            }
            catch (Exception ex)
            {
                return RetornarFormulario(
                    model,
                    "Ocurrió un error al procesar la campaña: " +
                    ex.Message
                );
            }
        }


        // =========================================================
        // RETORNAR FORMULARIO
        // =========================================================

        private IActionResult RetornarFormulario(
            CampanaCrearModel model,
            string mensaje)
        {
            ViewBag.Mensaje =
                mensaje;


            CargarCatalogos(
                model.IdsRoles,
                model.IdsMinisterios
            );


            return View(
                "Crear",
                model
            );
        }


        // =========================================================
        // CATÁLOGOS
        // =========================================================

        private void CargarCatalogos(
            List<int>? rolesSeleccionados = null,
            List<int>? ministeriosSeleccionados = null)
        {
            CargarRoles(
                rolesSeleccionados
            );


            CargarMinisterios(
                ministeriosSeleccionados
            );


            CargarPlantillas();
        }


        // =========================================================
        // ROLES
        // =========================================================

        private void CargarRoles(
            List<int>? seleccionados = null)
        {
            using var client =
                _http.CreateClient();


            var url =
                _config["Valores:UrlApi"] +
                "Usuario/ListarRolesAPI";


            var response =
                client.GetAsync(
                    url
                ).Result;


            if (
                response.StatusCode ==
                HttpStatusCode.OK
            )
            {
                var roles =
                    response.Content
                        .ReadFromJsonAsync<
                            List<RolModel>
                        >()
                        .Result
                    ?? new List<RolModel>();


                ViewBag.Roles =
                    roles
                        .Select(
                            rol =>
                                new SelectListItem
                                {
                                    Value =
                                        rol.Id_Rol
                                            .ToString(),

                                    Text =
                                        rol.Descripcion,

                                    Selected =
                                        seleccionados
                                            ?.Contains(
                                                rol.Id_Rol
                                            ) == true
                                }
                        )
                        .ToList();


                return;
            }


            ViewBag.Roles =
                new List<SelectListItem>();
        }


        // =========================================================
        // MINISTERIOS
        // =========================================================

        private void CargarMinisterios(
            List<int>? seleccionados = null)
        {
            using var client =
                _http.CreateClient();


            var url =
                _config["Valores:UrlApi"] +
                "Ministerio/ListarMinisteriosAPI";


            var response =
                client.GetAsync(
                    url
                ).Result;


            if (
                response.StatusCode ==
                HttpStatusCode.OK
            )
            {
                var ministerios =
                    response.Content
                        .ReadFromJsonAsync<
                            List<MinisterioModel>
                        >()
                        .Result
                    ?? new List<MinisterioModel>();


                ViewBag.Ministerios =
                    ministerios
                        .Select(
                            ministerio =>
                                new SelectListItem
                                {
                                    Value =
                                        ministerio
                                            .Id_Ministerio
                                            .ToString(),

                                    Text =
                                        ministerio
                                            .Descripcion_Ministerio,

                                    Selected =
                                        seleccionados
                                            ?.Contains(
                                                ministerio
                                                    .Id_Ministerio
                                            ) == true
                                }
                        )
                        .ToList();


                return;
            }


            ViewBag.Ministerios =
                new List<SelectListItem>();
        }


        // =========================================================
        // PLANTILLAS
        // =========================================================

        private void CargarPlantillas()
        {
            using var client =
                _http.CreateClient();


            var url =
                _config["Valores:UrlApi"] +
                "Campana/ListarPlantillasCampanaAPI";


            var response =
                client.GetAsync(
                    url
                ).Result;


            if (
                response.StatusCode ==
                HttpStatusCode.OK
            )
            {
                var plantillas =
                    response.Content
                        .ReadFromJsonAsync<
                            List<CampanaPlantillaModel>
                        >()
                        .Result
                    ?? new List<CampanaPlantillaModel>();


                ViewBag.Plantillas =
                    plantillas;


                return;
            }


            ViewBag.Plantillas =
                new List<CampanaPlantillaModel>();
        }
    }
}