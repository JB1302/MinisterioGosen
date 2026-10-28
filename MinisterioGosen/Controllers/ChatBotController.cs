
using Microsoft.AspNetCore.Mvc;
using MinisterioGosen.Models;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace MinisterioGosen.Controllers
{
    public class ChatBotController(
        IHttpClientFactory _http,
        IConfiguration _config) : Controller
    {

        [HttpGet]
        public IActionResult Index()
        {
            using var client = _http.CreateClient();

            var url = _config["Valores:UrlApi"] +
                      "ChatBot/ConsultarChatBotAPI";

            var response = client.GetAsync(url).Result;

            if (response.StatusCode == HttpStatusCode.OK)
            {
                var datos = response.Content
                    .ReadFromJsonAsync<ChatbotResultadoModel>()
                    .Result;

                return View(datos);
            }

            ViewBag.Mensaje =
                "No se pudieron cargar las opciones del chatbot";

            return View(new ChatbotResultadoModel());
        }

        [HttpGet]
        public IActionResult ConsultarChatBot(int? idOpcion)
        {
            using var client = _http.CreateClient();

            var url = _config["Valores:UrlApi"] +
                      "ChatBot/ConsultarChatBotAPI";

            if (idOpcion.HasValue)
            {
                url += "?idOpcion=" + idOpcion.Value;
            }

            var response = client.GetAsync(url).Result;

            if (response.StatusCode == HttpStatusCode.OK)
            {
                var datos = response.Content
                    .ReadFromJsonAsync<ChatbotResultadoModel>()
                    .Result;

                return Ok(datos);
            }

            if (response.StatusCode == HttpStatusCode.NotFound)
            {
                return NotFound(
                    "No se encontró la opción seleccionada"
                );
            }

            return BadRequest(
                "No se pudieron cargar las opciones del chatbot"
            );
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> RegistrarTicket(
            [FromBody] CrearTicketChatRequest request)
        {
            // Obtener el usuario autenticado
            var idUsuario = HttpContext.Session
                .GetInt32("Id_Usuario");

            if (!idUsuario.HasValue)
            {
                return Unauthorized(new
                {
                    mensaje = "Debes iniciar sesión para crear un ticket."
                });
            }

            // Validar campos obligatorios
            if (request == null ||
                string.IsNullOrWhiteSpace(request.Titulo) ||
                string.IsNullOrWhiteSpace(request.Descripcion))
            {
                return BadRequest(new
                {
                    mensaje = "El título y la descripción son obligatorios."
                });
            }

            var titulo = request.Titulo.Trim();
            var descripcion = request.Descripcion.Trim();

            // Validar longitud de campos
            if (titulo.Length > 150 || descripcion.Length > 500)
            {
                return BadRequest(new
                {
                    mensaje = "Se excedió el límite de caracteres."
                });
            }

            // Obtener dirección de la API
            var apiBase = _config["Valores:UrlApi"];

            if (string.IsNullOrWhiteSpace(apiBase))
            {
                return StatusCode(500, new
                {
                    mensaje = "La dirección de la API no está configurada."
                });
            }

            var url = apiBase.TrimEnd('/') +
                      "/ChatBot/RegistrarTicketDesdeChat";

            using var client = _http.CreateClient();

            // Preparar datos del ticket
            var ticket = new
            {
                IdRequestor = idUsuario.Value,
                Titulo = titulo,
                Descripcion = descripcion,
                IdAssignee = (int?)null
            };

            try
            {
                // Enviar solicitud a la API
                using var response = await client.PostAsJsonAsync(
                    url,
                    ticket
                );

                // Verificar respuesta de la API
                if (!response.IsSuccessStatusCode)
                {
                    return StatusCode((int)response.StatusCode, new
                    {
                        mensaje = "La API no pudo registrar el ticket."
                    });
                }

                // Obtener resultado del registro
                var resultado = await response.Content
                    .ReadFromJsonAsync<JsonElement>();

                return Ok(resultado);
            }
            catch (HttpRequestException)
            {
                return StatusCode(502, new
                {
                    mensaje = "No fue posible conectar con la API."
                });
            }
        }
    }
}
