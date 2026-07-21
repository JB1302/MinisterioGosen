using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using MinisterioGosen.Models;
using System.Net;

namespace MinisterioGosen.Controllers
{
	public class ActividadMinisterioController(
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

		private void CargarActividades(int? idActividadSeleccionada = null)
		{
			using var client = _http.CreateClient();
			var url = _config["Valores:UrlApi"] + "Actividad/ListarActividadesAPI";
			var response = client.GetAsync(url).Result;

			if (response.StatusCode == HttpStatusCode.OK)
			{
				var actividades = response.Content.ReadFromJsonAsync<List<ActividadModel>>().Result;
				ViewBag.Actividades = new SelectList(actividades, "Id_Actividad", "Nombre_Actividad", idActividadSeleccionada);

			}
			else
			{
				ViewBag.Actividades = new SelectList(new List<ActividadModel>(), "Id_Actividad", "Nombre_Actividad");
			}
		}

		private void CargarMinisterios(int? idMinisterioSeleccionado = null)
		{
			using var client = _http.CreateClient();
			var url = _config["Valores:UrlApi"] + "Ministerio/ListarMinisteriosAPI";
			var response = client.GetAsync(url).Result;

			if (response.StatusCode == HttpStatusCode.OK)
			{
				var ministerios = response.Content.ReadFromJsonAsync<List<MinisterioModel>>().Result?
					.Select(u => new {
						u.Id_Ministerio,
						Texto = u.Descripcion_Ministerio
					}).ToList();

				ViewBag.Ministerios =new SelectList(ministerios, "Id_Ministerio", "Texto", idMinisterioSeleccionado);


			}
			else
			{
				ViewBag.Ministerios = new SelectList(new List<MinisterioModel>(), "Id_Ministerio", "Descripcion_Ministerio");
			}
		}

		[HttpGet]
		public IActionResult Index()
		{
			ViewBag.Mensaje = ViewBag.Mensaje ?? string.Empty;

			if (!EsAdmin())
				return RedirectToAction("Error", "Home", new { statusCode = 403 });

			using var client = _http.CreateClient();
			var url = _config["Valores:UrlApi"] + "ActividadMinisterio/ListarActividadMinisterioAPI";
			var response = client.GetAsync(url).Result;

			if (response.StatusCode == HttpStatusCode.OK)
			{
				var datos = response.Content.ReadFromJsonAsync<List<ActividadMinisterioModel>>().Result;
				return View(datos ?? new List<ActividadMinisterioModel>());
			}

			ViewBag.Mensaje = "Error al consultar las asignaciones.";
			return View(new List<ActividadMinisterioModel>());
		}

		[HttpGet]
		public IActionResult Crear()
		{
			ViewBag.Mensaje = ViewBag.Mensaje ?? string.Empty;

			if (!EsAdmin())
				return RedirectToAction("Error", "Home", new { statusCode = 403 });

			CargarActividades();
			CargarMinisterios();

			return View();
		}

		[HttpPost]
		public IActionResult Crear(ActividadMinisterioModel model)
		{
			ViewBag.Mensaje = ViewBag.Mensaje ?? string.Empty;

			if (!EsAdmin())
				return RedirectToAction("Error", "Home", new { statusCode = 403 });

			using var client = _http.CreateClient();
			var url = _config["Valores:UrlApi"] + "ActividadMinisterio/CrearActividadMinisterioAPI";
			var response = client.PostAsJsonAsync(url, model).Result;

			if (response.StatusCode == HttpStatusCode.OK)
				return RedirectToAction("Index", "ActividadMinisterio");

			ViewBag.Mensaje = response.Content.ReadAsStringAsync().Result;
			CargarActividades(model.Id_Actividad);
			CargarMinisterios(model.Id_Ministerio);
			return View(model);
		}

		[HttpGet]
		public IActionResult Editar(int id)
		{
			ViewBag.Mensaje = ViewBag.Mensaje ?? string.Empty;

			if (!EsAdmin())
				return RedirectToAction("Error", "Home", new { statusCode = 403 });

			using var client = _http.CreateClient();
			var url = _config["Valores:UrlApi"] + $"ActividadMinisterio/ObtenerActividadMinisterioAPI?id={id}";
			var response = client.GetAsync(url).Result;

			if (response.StatusCode == HttpStatusCode.OK)
			{
				var datos = response.Content.ReadFromJsonAsync<ActividadMinisterioModel>().Result;
				CargarActividades(datos.Id_Actividad);
				CargarMinisterios(datos.Id_Ministerio);
				return View(datos);
			}

			return RedirectToAction("Index", "ActividadMinisterio");
		}

		[HttpPost]
		public IActionResult Editar(ActividadMinisterioModel model)
		{
			ViewBag.Mensaje = ViewBag.Mensaje ?? string.Empty;

			if (!EsAdmin())
				return RedirectToAction("Error", "Home", new { statusCode = 403 });

			using var client = _http.CreateClient();
			var url = _config["Valores:UrlApi"] + "ActividadMinisterio/ActualizarActividadMinisterioAPI";
			var response = client.PutAsJsonAsync(url, model).Result;
			if (response.StatusCode == HttpStatusCode.OK)
				return RedirectToAction("Index", "ActividadMinisterio");

			ViewBag.Mensaje = response.Content.ReadAsStringAsync().Result;
			CargarActividades(model.Id_Actividad);
			CargarMinisterios(model.Id_Ministerio);
			return View(model);
		}

		[HttpGet]
		public IActionResult Eliminar(int id)
		{
			ViewBag.Mensaje = ViewBag.Mensaje ?? string.Empty;

			if (!EsAdmin())
				return RedirectToAction("Error", "Home", new { statusCode = 403 });

			using var client = _http.CreateClient();
			var url = _config["Valores:UrlApi"] + $"ActividadMinisterio/ObtenerActividadMinisterioAPI?id={id}";
			var response = client.GetAsync(url).Result;

			if (response.StatusCode == HttpStatusCode.OK)
			{
				var datos = response.Content.ReadFromJsonAsync<ActividadMinisterioModel>().Result;
				return View(datos ?? new ActividadMinisterioModel());
			}

			ViewBag.Mensaje = "Error al consultar la asignación.";
			return RedirectToAction("Index", "ActividadMinisterio");
		}

		[HttpPost]
		public IActionResult ConfirmarEliminar(ActividadMinisterioModel model)
		{
			ViewBag.Mensaje = ViewBag.Mensaje ?? string.Empty;

			if (!EsAdmin())
				return RedirectToAction("Error", "Home", new { statusCode = 403 });

			using var client = _http.CreateClient();
			var url = _config["Valores:UrlApi"] + $"ActividadMinisterio/EliminarActividadMinisterioAPI?id={model.Id_Minis_Actividad}";
			var response = client.DeleteAsync(url).Result;

			if (response.StatusCode == HttpStatusCode.OK)
				return RedirectToAction("Index", "ActividadMinisterio");

			ViewBag.Mensaje = response.Content.ReadAsStringAsync().Result;
			return View("Eliminar", model);
		}
	}
}

