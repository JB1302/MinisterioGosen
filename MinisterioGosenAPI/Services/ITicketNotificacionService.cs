namespace MinisterioGosenAPI.Services;

public interface ITicketNotificacionService
{
    Task NotificarCreacionAsync(int idTicket);
    Task NotificarCambioEstadoAsync(int idTicket, string estadoAnterior);
}
