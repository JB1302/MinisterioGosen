using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using MinisterioGosen.Models;
using System.Net;

namespace MinisterioGosen.Controllers
{
    public class ActividadController(
        IHttpClientFactory _http,
        IConfiguration _config) : Controller
    {
        private bool EstaLogueado()
        {
            return HttpContext.Session.GetString("Autenticado") == "1";
        }

        private bool EsAdmin()
        {
            return HttpContext.Session.GetInt32("Id_Rol") == 1;
        }

        private void CargarTiposActividad(int? idTipoSeleccionado = null)
        {
            using var client = _http.CreateClient();

            var url = _config["Valores:UrlApi"] + "TipoActividad/ListarTiposActividadAPI";
            var response = client.GetAsync(url).Result;

            if (response.StatusCode == HttpStatusCode.OK)
            {
                var tipos = response.Content.ReadFromJsonAsync<List<TipoActividadModel>>().Result;
                ViewBag.TiposActividad = new SelectList(tipos, "Id_Tipo_Actividad", "Nombre_Tipo", idTipoSeleccionado);
            }
            else
            {
                ViewBag.TiposActividad = new SelectList(new List<TipoActividadModel>(), "Id_Tipo_Actividad", "Nombre_Tipo");
            }
        }

        [HttpGet]
        public IActionResult Consultar()
        {
            if (!EstaLogueado())
                return RedirectToAction("Index", "Home");

            using var client = _http.CreateClient();

            var url = _config["Valores:UrlApi"] + "Actividad/ListarActividadesAPI";
            var response = client.GetAsync(url).Result;

            if (response.StatusCode == HttpStatusCode.OK)
            {
                var datos = response.Content.ReadFromJsonAsync<List<ActividadModel>>().Result;
                return View(datos);
            }

            throw new Exception("Error al consultar las actividades");
        }

        [HttpGet]
        public IActionResult Index()
        {
            if (!EsAdmin())
                return RedirectToAction("Error", "Home", new { statusCode = 403 });

            using var client = _http.CreateClient();

            var url = _config["Valores:UrlApi"] + "Actividad/ListarActividadesAPI";
            var response = client.GetAsync(url).Result;

            if (response.StatusCode == HttpStatusCode.OK)
            {
                var datos = response.Content.ReadFromJsonAsync<List<ActividadModel>>().Result;
                return View(datos);
            }

            throw new Exception("Error al consultar las actividades");
        }

        [HttpGet]
        public IActionResult Crear()
        {
            if (!EsAdmin())
                return RedirectToAction("Error", "Home", new { statusCode = 403 });

            CargarTiposActividad();
            return View();
        }

        [HttpPost]
        public IActionResult Crear(ActividadModel model)
        {
            if (!EsAdmin())
                return RedirectToAction("Error", "Home", new { statusCode = 403 });

            using var client = _http.CreateClient();

            var url = _config["Valores:UrlApi"] + "Actividad/CrearActividadAPI";
            var response = client.PostAsJsonAsync(url, model).Result;

            if (response.StatusCode == HttpStatusCode.OK)
                return RedirectToAction("Index", "Actividad");

            ViewBag.Mensaje = response.Content.ReadAsStringAsync().Result;
            CargarTiposActividad(model.Id_Tipo_Actividad);

            return View(model);
        }

        [HttpGet]
        public IActionResult Editar(int id)
        {
            if (!EsAdmin())
                return RedirectToAction("Error", "Home", new { statusCode = 403 });

            using var client = _http.CreateClient();

            var url = _config["Valores:UrlApi"] + $"Actividad/ObtenerActividadAPI?id={id}";
            var response = client.GetAsync(url).Result;

            if (response.StatusCode == HttpStatusCode.OK)
            {
                var datos = response.Content.ReadFromJsonAsync<ActividadModel>().Result;
                CargarTiposActividad(datos!.Id_Tipo_Actividad);
                return View(datos);
            }

            return RedirectToAction("Index", "Actividad");
        }

        [HttpPost]
        public IActionResult Editar(ActividadModel model)
        {
            if (!EsAdmin())
                return RedirectToAction("Error", "Home", new { statusCode = 403 });

            using var client = _http.CreateClient();

            var url = _config["Valores:UrlApi"] + "Actividad/ActualizarActividadAPI";
            var response = client.PutAsJsonAsync(url, model).Result;

            if (response.StatusCode == HttpStatusCode.OK)
                return RedirectToAction("Index", "Actividad");

            ViewBag.Mensaje = response.Content.ReadAsStringAsync().Result;
            CargarTiposActividad(model.Id_Tipo_Actividad);

            return View(model);
        }

        [HttpGet]
        public IActionResult Eliminar(int id)
        {
            if (!EsAdmin())
                return RedirectToAction("Error", "Home", new { statusCode = 403 });

            using var client = _http.CreateClient();

            var url = _config["Valores:UrlApi"] + $"Actividad/ObtenerActividadAPI?id={id}";
            var response = client.GetAsync(url).Result;

            if (response.StatusCode == HttpStatusCode.OK)
            {
                var datos = response.Content.ReadFromJsonAsync<ActividadModel>().Result;
                return View(datos);
            }

            return RedirectToAction("Index", "Actividad");
        }

        [HttpPost]
        public IActionResult ConfirmarEliminar(ActividadModel model)
        {
            if (!EsAdmin())
                return RedirectToAction("Error", "Home", new { statusCode = 403 });

            using var client = _http.CreateClient();

            var url = _config["Valores:UrlApi"] + $"Actividad/EliminarActividadAPI?id={model.Id_Actividad}";
            var response = client.DeleteAsync(url).Result;

            if (response.StatusCode == HttpStatusCode.OK)
                return RedirectToAction("Index", "Actividad");

            ViewBag.Mensaje = response.Content.ReadAsStringAsync().Result;
            return View("Eliminar", model);
        }
    }
}