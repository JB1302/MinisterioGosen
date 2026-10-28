using Microsoft.AspNetCore.Mvc;
using MinisterioGosen.Helpers;
using MinisterioGosen.Models;
using System.Net;

namespace MinisterioGosen.Controllers
{
    [ValidarSesion]
    public class TicketsController(
        IHttpClientFactory _http,
        IConfiguration _config) : Controller
    {
        private static readonly string[] EstadosValidos =
            { "Abierto", "En Progreso", "Cerrado", "Cancelado" };

        #region Validaciones de sesión

        private bool EsAdmin()
        {
            return HttpContext.Session.GetInt32("Id_Rol") == 1;
        }

        private int IdUsuarioSesion()
        {
            return HttpContext.Session.GetInt32("Id_Usuario") ?? 0;
        }

        private IActionResult Prohibido()
        {
            return RedirectToAction("Error", "Home", new { statusCode = 403 });
        }

        #endregion

        #region Helpers

        // Consulta un ticket en la API. Devuelve null si no existe.
        private async Task<TicketModel?> ObtenerTicketAsync(int id)
        {
            using var client = _http.CreateClient();

            var url = _config["Valores:UrlApi"] + $"Tickets/ObtenerTicketPorId?idTicket={id}";
            var response = await client.GetAsync(url);

            if (response.StatusCode == HttpStatusCode.OK)
                return await response.Content.ReadFromJsonAsync<TicketModel>();

            return null;
        }

        #endregion

        #region Listado

        // Admin: todos los tickets.
        // Usuario: solo los que creó (o los que tenga asignados).
        [HttpGet]
        public async Task<IActionResult> Index()
        {
            var esAdmin = EsAdmin();

            using var client = _http.CreateClient();

            var url = _config["Valores:UrlApi"] + (esAdmin
                ? "Tickets/ListarTickets"
                : $"Tickets/ObtenerTicketsPorUsuario?idUsuario={IdUsuarioSesion()}");

            var response = await client.GetAsync(url);

            if (response.StatusCode == HttpStatusCode.OK)
            {
                var datos = await response.Content.ReadFromJsonAsync<List<TicketModel>>()
                    ?? new List<TicketModel>();

                ViewBag.EsAdmin = esAdmin;
                return View(datos);
            }

            throw new Exception("Error al consultar los tickets");
        }

        #endregion

        #region Detalle

        [HttpGet]
        public async Task<IActionResult> Detalle(int id)
        {
            var ticket = await ObtenerTicketAsync(id);

            if (ticket == null)
                return RedirectToAction("Index", "Tickets");

            // La API no valida permisos, se valida aquí:
            // solo el admin, el solicitante o el asignado pueden ver el ticket.
            var idUsuario = IdUsuarioSesion();

            if (!EsAdmin() &&
                ticket.IdRequestor != idUsuario &&
                ticket.IdAssignee != idUsuario)
                return Prohibido();

            return View(ticket);
        }

        #endregion

        #region Atender Ticket

        [HttpGet]
        public async Task<IActionResult> Atender(int id)
        {
            if (!EsAdmin())
                return Prohibido();

            var ticket = await ObtenerTicketAsync(id);

            if (ticket == null)
                return RedirectToAction("Index", "Tickets");

            return View(ticket);
        }

        [HttpPost]
        public async Task<IActionResult> ConfirmarAtender(TicketModel model)
        {
            if (!EsAdmin())
                return Prohibido();

            // el formulario solo envía Id, Estado y Respuesta.
            var respuesta = model.Respuesta?.Trim();
            string? error = null;

            if (!EstadosValidos.Contains(model.Estado))
                error = "Seleccione un estado válido.";
            else if (model.Estado == "Cerrado" && string.IsNullOrWhiteSpace(respuesta))
                error = "Debe registrar una respuesta para cerrar el ticket.";
            else if (respuesta is { Length: > 500 })
                error = "La respuesta no puede superar 500 caracteres.";

            if (error == null)
            {
                using var client = _http.CreateClient();

                var url = _config["Valores:UrlApi"] + "Tickets/ActualizarEstado";

                // Quien atiende el ticket queda como responsable.
                var response = await client.PutAsJsonAsync(url, new
                {
                    IdTicket = model.IdTicket,
                    Estado = model.Estado,
                    IdAssignee = IdUsuarioSesion(),
                    Respuesta = respuesta
                });

                if (response.StatusCode == HttpStatusCode.OK)
                {
                    TempData["TicketAtendido"] = "true";
                    return RedirectToAction("Index", "Tickets");
                }

                error = await response.Content.ReadAsStringAsync();
            }

            // Se vuelve a cargar el ticket para que la vista conserve sus datos,
            // y se respeta lo que el admin había escrito.
            var ticket = await ObtenerTicketAsync(model.IdTicket);

            if (ticket == null)
                return RedirectToAction("Index", "Tickets");

            ticket.Estado = string.IsNullOrWhiteSpace(model.Estado) ? ticket.Estado : model.Estado;
            ticket.Respuesta = model.Respuesta;

            ViewBag.Mensaje = error;
            return View("Atender", ticket);
        }

        #endregion
    }
}