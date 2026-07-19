using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using MinisterioGosen.Models;
using System.Net;

namespace MinisterioGosen.Controllers
{
	public class ActividadUsuarioController(
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

		private void CargarUsuarios(int? idUsuarioSeleccionado = null)
		{
			using var client = _http.CreateClient();
			var url = _config["Valores:UrlApi"] + "Usuario/ListarUsuariosAPI";
			var response = client.GetAsync(url).Result;

			if (response.StatusCode == HttpStatusCode.OK)
			{
				var usuarios = response.Content.ReadFromJsonAsync<List<UsuarioModel>>().Result?
					.Select(u => new {
						u.Id_Usuario,
						Texto = u.Identificacion + " - " + u.Nombre
					}).ToList();

				ViewBag.Usuarios = new SelectList(usuarios, "Id_Usuario", "Texto", idUsuarioSeleccionado);
			}
			else
			{
				ViewBag.Usuarios = new SelectList(new List<UsuarioModel>(), "Id_Usuario", "Nombre");
			}
		}

		[HttpGet]
		public IActionResult Index()
		{
			if (!EsAdmin())
				return RedirectToAction("Error", "Home", new { statusCode = 403 });

			using var client = _http.CreateClient();
			var url = _config["Valores:UrlApi"] + "ActividadUsuario/ListarActividadUsuarioAPI";
			var response = client.GetAsync(url).Result;

			if (response.StatusCode == HttpStatusCode.OK)
			{
				var datos = response.Content.ReadFromJsonAsync<List<ActividadUsuarioModel>>().Result;
				return View(datos);
			}

			throw new Exception("Error al consultar las participaciones");
		}

		[HttpGet]
		public IActionResult Crear()
		{
			if (!EsAdmin())
				return RedirectToAction("Error", "Home", new { statusCode = 403 });

			CargarActividades();
			CargarUsuarios();

			return View();
		}

		[HttpPost]
		public IActionResult Crear(ActividadUsuarioModel model)
		{
			if (!EsAdmin())
				return RedirectToAction("Error", "Home", new { statusCode = 403 });

			if (model.Fecha.Date < DateTime.Today)
			{
				ViewBag.Mensaje = "La fecha no puede ser anterior a la fecha actual.";
				CargarActividades(model.Id_Actividad);
				CargarUsuarios(model.Id_Usuario);
				return View(model);
			}

			using var client = _http.CreateClient();
			var url = _config["Valores:UrlApi"] + "ActividadUsuario/CrearActividadUsuarioAPI";
			var response = client.PostAsJsonAsync(url, model).Result;

			if (response.StatusCode == HttpStatusCode.OK)
				return RedirectToAction("Index", "ActividadUsuario");

			ViewBag.Mensaje = response.Content.ReadAsStringAsync().Result;
			CargarActividades(model.Id_Actividad);
			CargarUsuarios(model.Id_Usuario);
			return View(model);
		}

		[HttpGet]
		public IActionResult Editar(int id)
		{
			if (!EsAdmin())
				return RedirectToAction("Error", "Home", new { statusCode = 403 });

			using var client = _http.CreateClient();
			var url = _config["Valores:UrlApi"] + $"ActividadUsuario/ObtenerActividadUsuarioAPI?id={id}";
			var response = client.GetAsync(url).Result;

			if (response.StatusCode == HttpStatusCode.OK)
			{
				var datos = response.Content.ReadFromJsonAsync<ActividadUsuarioModel>().Result;
				CargarActividades(datos!.Id_Actividad);
				CargarUsuarios(datos.Id_Usuario);
				return View(datos);
			}

			return RedirectToAction("Index", "ActividadUsuario");
		}

		[HttpPost]
		public IActionResult Editar(ActividadUsuarioModel model)
		{
			if (!EsAdmin())
				return RedirectToAction("Error", "Home", new { statusCode = 403 });

			if (model.Fecha.Date < DateTime.Today)
			{
				ViewBag.Mensaje = "La fecha no puede ser anterior a la fecha actual.";
				CargarActividades(model.Id_Actividad);
				CargarUsuarios(model.Id_Usuario);
				return View(model);
			}

			using var client = _http.CreateClient();
			var url = _config["Valores:UrlApi"] + "ActividadUsuario/ActualizarActividadUsuarioAPI";
			var response = client.PutAsJsonAsync(url, model).Result;

			if (response.StatusCode == HttpStatusCode.OK)
				return RedirectToAction("Index", "ActividadUsuario");

			ViewBag.Mensaje = response.Content.ReadAsStringAsync().Result;
			CargarActividades(model.Id_Actividad);
			CargarUsuarios(model.Id_Usuario);
			return View(model);
		}

		[HttpGet]
		public IActionResult Eliminar(int id)
		{
			if (!EsAdmin())
				return RedirectToAction("Error", "Home", new { statusCode = 403 });

			using var client = _http.CreateClient();
			var url = _config["Valores:UrlApi"] + $"ActividadUsuario/ObtenerActividadUsuarioAPI?id={id}";
			var response = client.GetAsync(url).Result;

			if (response.StatusCode == HttpStatusCode.OK)
			{
				var datos = response.Content.ReadFromJsonAsync<ActividadUsuarioModel>().Result;
				return View(datos);
			}

			return RedirectToAction("Index", "ActividadUsuario");
		}

		[HttpPost]
		public IActionResult ConfirmarEliminar(ActividadUsuarioModel model)
		{
			if (!EsAdmin())
				return RedirectToAction("Error", "Home", new { statusCode = 403 });

			using var client = _http.CreateClient();
			var url = _config["Valores:UrlApi"] + $"ActividadUsuario/EliminarActividadUsuarioAPI?id={model.Id_Actividad_Usuario}";
			var response = client.DeleteAsync(url).Result;

			if (response.StatusCode == HttpStatusCode.OK)
				return RedirectToAction("Index", "ActividadUsuario");

			ViewBag.Mensaje = response.Content.ReadAsStringAsync().Result;
			return View("Eliminar", model);
		}
	}
}
