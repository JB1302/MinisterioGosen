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
            // CONFIGURACIÓN
            // =====================================================

            var cuentaGmail =
                _config["Correos:CuentaGmail"];

            var contrasenaAplicacion =
                _config["Correos:ContrasenaAplicacion"];


            if (string.IsNullOrWhiteSpace(cuentaGmail))
            {
                throw new InvalidOperationException(
                    "No se ha configurado la cuenta de correo."
                );
            }


            if (string.IsNullOrWhiteSpace(
                    contrasenaAplicacion))
            {
                throw new InvalidOperationException(
                    "No se ha configurado la contraseña de aplicación del correo."
                );
            }


            if (string.IsNullOrWhiteSpace(
                    destinatario))
            {
                throw new ArgumentException(
                    "El destinatario del correo es obligatorio.",
                    nameof(destinatario)
                );
            }


            if (string.IsNullOrWhiteSpace(
                    asunto))
            {
                throw new ArgumentException(
                    "El asunto del correo es obligatorio.",
                    nameof(asunto)
                );
            }


            // =====================================================
            // MENSAJE
            // =====================================================

            var mensaje =
                new MimeMessage();


            mensaje.From.Add(
                new MailboxAddress(
                    "Ministerio Gosén",
                    cuentaGmail
                )
            );


            mensaje.To.Add(
                MailboxAddress.Parse(
                    destinatario
                )
            );


            mensaje.Subject =
                asunto;


            mensaje.Body =
                new TextPart("html")
                {
                    Text = cuerpoHtml ?? string.Empty
                };


            // =====================================================
            // SMTP
            // =====================================================

            using var cliente =
                new SmtpClient();


            try
            {
                await cliente.ConnectAsync(
                    "smtp.gmail.com",
                    587,
                    SecureSocketOptions.StartTls
                );


                await cliente.AuthenticateAsync(
                    cuentaGmail,
                    contrasenaAplicacion
                );


                await cliente.SendAsync(
                    mensaje
                );
            }
            finally
            {
                /*
                 * Solo intentamos desconectar si realmente
                 * se estableció una conexión.
                 *
                 * Esto evita ocultar la excepción original
                 * si ConnectAsync falla.
                 */
                if (cliente.IsConnected)
                {
                    await cliente.DisconnectAsync(
                        true
                    );
                }
            }
        }
    }
}