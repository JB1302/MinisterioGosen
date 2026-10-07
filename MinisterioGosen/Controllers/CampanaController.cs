using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using MinisterioGosen.Helpers;
using MinisterioGosen.Models;
using System.Net;

namespace MinisterioGosen.Controllers
{
    [ValidarSesion]
    public class CampanaController(
        IHttpClientFactory _http,
        IConfiguration _config) : Controller
    {
        private bool EsAdmin()
        {
            return HttpContext.Session.GetInt32("Id_Rol") == 1;
        }


        // =========================================================
        // INDEX
        // =========================================================

        [HttpGet]
        public IActionResult Index()
        {
            if (!EsAdmin())
            {
                return RedirectToAction(
                    "Error",
                    "Home",
                    new { statusCode = 403 }
                );
            }

            // Temporal hasta crear el historial de campañas.
            return RedirectToAction(nameof(Crear));
        }


        // =========================================================
        // CREAR
        // =========================================================

        [HttpGet]
        public IActionResult Crear()
        {
            if (!EsAdmin())
            {
                return RedirectToAction(
                    "Error",
                    "Home",
                    new { statusCode = 403 }
                );
            }

            CargarCatalogos();

            return View(new CampanaCrearModel());
        }


        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult Crear(CampanaCrearModel model)
        {
            if (!EsAdmin())
            {
                return RedirectToAction(
                    "Error",
                    "Home",
                    new { statusCode = 403 }
                );
            }


            // =====================================================
            // VALIDACIONES
            // =====================================================

            if (string.IsNullOrWhiteSpace(model.Titulo))
            {
                return RetornarFormulario(
                    model,
                    "Debe ingresar el título de la campaña."
                );
            }


            if (string.IsNullOrWhiteSpace(model.Asunto))
            {
                return RetornarFormulario(
                    model,
                    "Debe ingresar el asunto del correo."
                );
            }


            if (string.IsNullOrWhiteSpace(model.Contenido))
            {
                return RetornarFormulario(
                    model,
                    "Debe ingresar el contenido de la campaña."
                );
            }


            if (string.IsNullOrWhiteSpace(model.Plantilla))
            {
                return RetornarFormulario(
                    model,
                    "Debe seleccionar una plantilla."
                );
            }


            if (!model.Todos &&
                model.IdsRoles.Count == 0 &&
                model.IdsMinisterios.Count == 0)
            {
                return RetornarFormulario(
                    model,
                    "Debe seleccionar al menos un rol, " +
                    "un ministerio o la opción Todos."
                );
            }


            /*
             * Todavía no enviamos la campaña.
             *
             * El siguiente paso será consumir:
             *
             * Campana/CrearCampanaAPI
             */

            ViewBag.Mensaje =
                "El formulario fue validado correctamente. " +
                "El envío se implementará en el siguiente paso.";


            CargarCatalogos(
                model.IdsRoles,
                model.IdsMinisterios
            );


            return View(model);
        }


        // =========================================================
        // RETORNAR FORMULARIO
        // =========================================================

        private IActionResult RetornarFormulario(
            CampanaCrearModel model,
            string mensaje)
        {
            ViewBag.Mensaje = mensaje;

            CargarCatalogos(
                model.IdsRoles,
                model.IdsMinisterios
            );

            return View("Crear", model);
        }


        // =========================================================
        // CATÁLOGOS
        // =========================================================

        private void CargarCatalogos(
            List<int>? rolesSeleccionados = null,
            List<int>? ministeriosSeleccionados = null)
        {
            CargarRoles(rolesSeleccionados);

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
                client.GetAsync(url).Result;


            if (response.StatusCode == HttpStatusCode.OK)
            {
                var roles =
                    response.Content
                        .ReadFromJsonAsync<List<RolModel>>()
                        .Result
                    ?? new List<RolModel>();


                ViewBag.Roles =
                    roles.Select(rol =>
                        new SelectListItem
                        {
                            Value =
                                rol.Id_Rol.ToString(),

                            Text =
                                rol.Descripcion,

                            Selected =
                                seleccionados?.Contains(
                                    rol.Id_Rol
                                ) == true
                        })
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
                client.GetAsync(url).Result;


            if (response.StatusCode == HttpStatusCode.OK)
            {
                var ministerios =
                    response.Content
                        .ReadFromJsonAsync<List<MinisterioModel>>()
                        .Result
                    ?? new List<MinisterioModel>();


                ViewBag.Ministerios =
                    ministerios.Select(
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
                                    seleccionados?.Contains(
                                        ministerio.Id_Ministerio
                                    ) == true
                            })
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
                client.GetAsync(url).Result;


            if (response.StatusCode == HttpStatusCode.OK)
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