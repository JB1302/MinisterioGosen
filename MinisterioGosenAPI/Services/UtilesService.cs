using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;

namespace MinisterioGosenAPI.Services
{
    public class UtilesService(
        IConfiguration _config) : IUtilesService
    {
        public string GenerarContrasena()
        {
            return Guid.NewGuid()
                .ToString("N")[..10];
        }

        public async Task EnviarCorreoAsync(
            string destinatario,
            string asunto,
            string cuerpoHtml)
        {
            // =====================================================
            // CONFIGURACIÓN SMTP2GO
            // =====================================================

            var smtpHost =
                _config["Correos:SmtpHost"] ?? "mail.smtp2go.com";

            var smtpPort =
                _config.GetValue<int>("Correos:SmtpPort", 2525);

            var smtpUsuario =
                _config["Correos:SmtpUsuario"];

            var smtpContrasena =
                _config["Correos:SmtpContrasena"];

            var remitente =
                _config["Correos:Remitente"];

            // =====================================================
            // VALIDACIONES
            // =====================================================

            if (string.IsNullOrWhiteSpace(smtpUsuario))
            {
                throw new InvalidOperationException(
                    "No se ha configurado el usuario SMTP."
                );
            }

            if (string.IsNullOrWhiteSpace(smtpContrasena))
            {
                throw new InvalidOperationException(
                    "No se ha configurado la contraseña SMTP."
                );
            }

            if (string.IsNullOrWhiteSpace(remitente))
            {
                throw new InvalidOperationException(
                    "No se ha configurado el correo remitente."
                );
            }

            if (string.IsNullOrWhiteSpace(destinatario))
            {
                throw new ArgumentException(
                    "El destinatario del correo es obligatorio.",
                    nameof(destinatario)
                );
            }

            if (string.IsNullOrWhiteSpace(asunto))
            {
                throw new ArgumentException(
                    "El asunto del correo es obligatorio.",
                    nameof(asunto)
                );
            }

            // =====================================================
            // MENSAJE
            // =====================================================

            var mensaje = new MimeMessage();

            mensaje.From.Add(
                new MailboxAddress(
                    "Ministerio Gosén",
                    remitente
                )
            );

            mensaje.To.Add(
                MailboxAddress.Parse(destinatario)
            );

            mensaje.Subject = asunto;

            mensaje.Body = new TextPart("html")
            {
                Text = cuerpoHtml ?? string.Empty
            };

            // =====================================================
            // CONEXIÓN SMTP
            // =====================================================

            using var cliente = new SmtpClient();

            cliente.Timeout = 10000;

            using var cancellationTokenSource =
                new CancellationTokenSource(
                    TimeSpan.FromSeconds(15)
                );

            var cancellationToken =
                cancellationTokenSource.Token;

            try
            {
                await cliente.ConnectAsync(
                    smtpHost,
                    smtpPort,
                    SecureSocketOptions.StartTls,
                    cancellationToken
                );

                await cliente.AuthenticateAsync(
                    smtpUsuario,
                    smtpContrasena,
                    cancellationToken
                );

                await cliente.SendAsync(
                    mensaje,
                    cancellationToken
                );
            }
            catch (OperationCanceledException ex)
                when (cancellationToken.IsCancellationRequested)
            {
                throw new TimeoutException(
                    "Se agotó el tiempo de espera del servidor SMTP.",
                    ex
                );
            }
            finally
            {
                if (cliente.IsConnected)
                {
                    try
                    {
                        using var desconexionToken =
                            new CancellationTokenSource(
                                TimeSpan.FromSeconds(3)
                            );

                        await cliente.DisconnectAsync(
                            true,
                            desconexionToken.Token
                        );
                    }
                    catch
                    {
                        // Evita ocultar un error previo de envío
                        // por un fallo durante la desconexión.
                    }
                }
            }
        }
    }
}