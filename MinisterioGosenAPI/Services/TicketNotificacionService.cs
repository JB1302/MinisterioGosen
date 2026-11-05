using Dapper;
using Npgsql;
using System.Net;

namespace MinisterioGosenAPI.Services;

/// <summary>
/// Servicio independiente de campañas. Reutiliza exclusivamente el envío SMTP de IUtilesService.
/// El fallo del envío se registra, sin revertir la creación o actualización ya guardada.
/// </summary>
public class TicketNotificacionService(
    IConfiguration configuracion,
    IUtilesService correo,
    ILogger<TicketNotificacionService> logger) : ITicketNotificacionService
{
    private sealed class TicketCorreo
    {
        public int IdTicket { get; set; }
        public string Titulo { get; set; } = "";
        public string Descripcion { get; set; } = "";
        public string Estado { get; set; } = "";
        public string? Respuesta { get; set; }
        public string Nombre { get; set; } = "";
        public string Correo { get; set; } = "";
    }

    private async Task<TicketCorreo?> ObtenerTicketAsync(int idTicket)
    {
        await using var conexion = new NpgsqlConnection(
            configuracion.GetConnectionString("DefaultConnection"));

        return await conexion.QuerySingleOrDefaultAsync<TicketCorreo>("""
            SELECT t.id_ticket AS "IdTicket", t.titulo AS "Titulo",
                   t.descripcion AS "Descripcion", t.estado::text AS "Estado",
                   t.respuesta AS "Respuesta", u.nombre AS "Nombre",
                   u.correo AS "Correo"
            FROM tickets t
            INNER JOIN usuario u ON u.id_usuario = t.id_requestor
            WHERE t.id_ticket = @idTicket
            """, new { idTicket });
    }

    private static string Esc(string? valor) => WebUtility.HtmlEncode(valor ?? "");

    private static string EscConSaltos(string? valor) =>
        Esc(valor).Replace("\r\n", "\n").Replace("\n", "<br>");

    private static string Renderizar(string plantilla, TicketCorreo ticket,
        string encabezado, string mensaje, string? etiquetaRespuesta)
    {
        var bloqueRespuesta = etiquetaRespuesta is null ? "" : $"""
            <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"
                   style="margin-top:22px;background-color:#f2f8f7;border:1px solid #d8e8e5;border-radius:10px;">
              <tr><td style="padding:20px 22px;">
                <p style="margin:0 0 10px;color:#0d5a54;font-size:15px;font-weight:bold;">{Esc(etiquetaRespuesta)}</p>
                <p style="margin:0;color:#263c3a;font-size:14px;line-height:1.7;">{EscConSaltos(ticket.Respuesta)}</p>
              </td></tr>
            </table>
            """;

        return plantilla
            .Replace("{{ENCABEZADO}}", Esc(encabezado))
            .Replace("{{NOMBRE}}", Esc(ticket.Nombre))
            .Replace("{{MENSAJE}}", Esc(mensaje))
            .Replace("{{NUMERO}}", ticket.IdTicket.ToString())
            .Replace("{{TITULO}}", Esc(ticket.Titulo))
            .Replace("{{DESCRIPCION}}", EscConSaltos(ticket.Descripcion))
            .Replace("{{ESTADO}}", Esc(ticket.Estado))
            .Replace("{{BLOQUE_RESPUESTA}}", bloqueRespuesta)
            .Replace("{{ANIO}}", DateTime.UtcNow.Year.ToString());
    }

    private async Task EnviarSeguroAsync(TicketCorreo? ticket, string asunto,
        string encabezado, string mensaje, string? etiquetaRespuesta = null)
    {
        if (ticket is null || string.IsNullOrWhiteSpace(ticket.Correo))
        {
            logger.LogWarning("Tiquete inexistente o sin correo para notificación");
            return;
        }

        try
        {
            var ruta = Path.Combine(AppContext.BaseDirectory, "Templates", "TicketNotificacion.html");
            var plantilla = await File.ReadAllTextAsync(ruta);
            var cuerpo = Renderizar(plantilla, ticket, encabezado, mensaje, etiquetaRespuesta);
            await correo.EnviarCorreoAsync(ticket.Correo, asunto, cuerpo);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "No fue posible enviar la notificación del tiquete {IdTicket}", ticket.IdTicket);
        }
    }

    public async Task NotificarCreacionAsync(int idTicket)
    {
        TicketCorreo? ticket;
        try { ticket = await ObtenerTicketAsync(idTicket); }
        catch (Exception ex)
        {
            logger.LogError(ex, "No se pudo consultar el tiquete {IdTicket} para notificar su creación", idTicket);
            return;
        }
        await EnviarSeguroAsync(ticket, $"Tiquete #{idTicket} registrado - Ministerio Gosén",
            "Hemos recibido tu solicitud",
            "Tu tiquete fue registrado correctamente. Te notificaremos cuando cambie su estado.");
    }

    public async Task NotificarCambioEstadoAsync(int idTicket, string estadoAnterior)
    {
        TicketCorreo? ticket;
        try { ticket = await ObtenerTicketAsync(idTicket); }
        catch (Exception ex)
        {
            logger.LogError(ex, "No se pudo consultar el cambio de estado del tiquete {IdTicket}", idTicket);
            return;
        }
        if (ticket is null || ticket.Estado == estadoAnterior) return;

        switch (ticket.Estado)
        {
            case "En Progreso":
                await EnviarSeguroAsync(ticket, $"Tiquete #{idTicket} en progreso - Ministerio Gosén",
                    "Estamos atendiendo tu solicitud",
                    "Tu tiquete está En Progreso. Nuestro equipo está revisándolo.");
                break;
            case "Cerrado":
                await EnviarSeguroAsync(ticket, $"Tiquete #{idTicket} resuelto - Ministerio Gosén",
                    "Tu solicitud ha sido resuelta",
                    "El administrador finalizó la atención de tu tiquete.", "Respuesta del administrador");
                break;
            case "Cancelado":
                await EnviarSeguroAsync(ticket, $"Tiquete #{idTicket} cancelado - Ministerio Gosén",
                    "Tu solicitud ha sido cancelada",
                    "El administrador canceló tu tiquete por el motivo indicado a continuación.", "Motivo de cancelación");
                break;
        }
    }
}
