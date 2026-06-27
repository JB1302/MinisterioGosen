using Microsoft.AspNetCore.Mvc;
using MinisterioGosen.Models;
using System.Diagnostics;

namespace MinisterioGosen.Controllers
{
    public class HomeController (
        IHttpClientFactory _http, 
        IConfiguration _config) : Controller
    {
        public IActionResult Index()
        {
            return View();
        }

        public IActionResult Principal()
        {
            return View();
        }

        #region Registro Usuario
        [HttpGet]
        public IActionResult Registrar()
        {
            return View();
        }

        [HttpPost]
        public IActionResult Registrar(UsuarioModel model)
        {
            using var client = _http.CreateClient();

            var url = _config["Valores:UrlApi"] + "Home/RegistrarAPI";
            var response = client.PostAsJsonAsync(url, model).Result;

            return View();
        }
        #endregion

        #region Recuperar Acceso
        public IActionResult RecuperarAcceso()
        {
            return View();
        }
        #endregion
    }
}
