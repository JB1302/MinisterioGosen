using Dapper;
using Microsoft.AspNetCore.Mvc;
using MinisterioGosenAPI.Models;
using Npgsql;
using System.Net;

namespace MinisterioGosenAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CampanaController(
        IConfiguration _config) : ControllerBase
    {
        // =========================================================
        // PLANTILLAS
        // =========================================================

        [HttpGet("ListarPlantillasCampanaAPI")]
        public IActionResult ListarPlantillasCampanaAPI()
        {
            using var context =
                new NpgsqlConnection(
                    _config["ConnectionStrings:DefaultConnection"]
                );

            var response =
                context.Query<CampanaPlantillaResponseModel>(
                    "SELECT * FROM spListarPlantillasCampana()"
                ).ToList();

            return Ok(response);
        }
    }
}using Dapper;
using Microsoft.AspNetCore.Mvc;
using MinisterioGosenAPI.Models;
using MinisterioGosenAPI.Services;
using Npgsql;
using System.Net;

namespace MinisterioGosenAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class CampanaController(
        IConfiguration _config,
        IUtilesService _utiles) : ControllerBase
    {
        // =========================================================
        // PLANTILLAS
        // =========================================================

        [HttpGet("ListarPlantillasCampanaAPI")]
        public IActionResult ListarPlantillasCampanaAPI()
        {
            using var context =
                new NpgsqlConnection(
                    _config["ConnectionStrings:DefaultConnection"]
                );


            var response =
                context.Query<CampanaPlantillaResponseModel>(
                    "SELECT * FROM spListarPlantillasCampana()"
                )
                .ToList();


            return Ok(response);
        }


        // =========================================================
        // CREAR Y ENVIAR CAMPAÑA
        // =========================================================

        [HttpPost("CrearCampanaAPI")]
        public async Task<IActionResult> CrearCampanaAPI(
            CampanaCrearRequestModel model)
        {
            // =====================================================
            // VALIDACIONES BÁSICAS
            // =====================================================

            if (model == null)
            {
                return BadRequest(
                    "No se recibió la información de la campaña."
                );
            }


            if (string.IsNullOrWhiteSpace(model.Titulo))
            {
                return BadRequest(
                    "Debe ingresar el título de la campaña."
                );
            }


            if (string.IsNullOrWhiteSpace(model.Asunto))
            {
                return BadRequest(
                    "Debe ingresar el asunto de la campaña."
                );
            }


            if (string.IsNullOrWhiteSpace(model.Contenido))
            {
                return BadRequest(
                    "Debe ingresar el contenido de la campaña."
                );
            }


            if (string.IsNullOrWhiteSpace(model.Plantilla))
            {
                return BadRequest(
                    "Debe seleccionar una plantilla."
                );
            }


            if (model.Id_Usuario_Creador <= 0)
            {
                return BadRequest(
                    "El usuario creador de la campaña no es válido."
                );
            }


            model.Ids_Roles ??= [];
            model.Ids_Ministerios ??= [];


            if (
                !model.Todos &&
                model.Ids_Roles.Count == 0 &&
                model.Ids_Ministerios.Count == 0
            )
            {
                return BadRequest(
                    "Debe seleccionar al menos un rol, " +
                    "un ministerio o la opción Todos."
                );
            }


            await using var context =
                new NpgsqlConnection(
                    _config["ConnectionStrings:DefaultConnection"]
                );


            try
            {
                await context.OpenAsync();


                // =================================================
                // 1. CREAR CAMPAÑA Y DESTINATARIOS
                // =================================================

                await using var transaction =
                    await context.BeginTransactionAsync();


                int idCampana;


                try
                {
                    var parametrosCampana =
                        new DynamicParameters();


                    parametrosCampana.Add(
                        "@Titulo",
                        model.Titulo
                    );

                    parametrosCampana.Add(
                        "@Asunto",
                        model.Asunto
                    );

                    parametrosCampana.Add(
                        "@Contenido",
                        model.Contenido
                    );

                    parametrosCampana.Add(
                        "@Plantilla",
                        model.Plantilla
                    );

                    parametrosCampana.Add(
                        "@IdUsuarioCreador",
                        model.Id_Usuario_Creador
                    );


                    /*
                     * Los CAST se utilizan porque Npgsql
                     * envía los string como TEXT y las
                     * funciones PostgreSQL reciben VARCHAR.
                     */
                    idCampana =
                        await context.QuerySingleAsync<int>(
                            @"
                            SELECT spCrearCampana(
                                CAST(@Titulo AS varchar(150)),
                                CAST(@Asunto AS varchar(200)),
                                @Contenido,
                                CAST(@Plantilla AS varchar(30)),
                                @IdUsuarioCreador
                            );
                            ",
                            parametrosCampana,
                            transaction
                        );


                    var parametrosDestinatarios =
                        new DynamicParameters();


                    parametrosDestinatarios.Add(
                        "@IdCampana",
                        idCampana
                    );

                    parametrosDestinatarios.Add(
                        "@IdsRoles",
                        model.Ids_Roles.ToArray()
                    );

                    parametrosDestinatarios.Add(
                        "@IdsMinisterios",
                        model.Ids_Ministerios.ToArray()
                    );

                    parametrosDestinatarios.Add(
                        "@Todos",
                        model.Todos
                    );


                    await context.ExecuteAsync(
                        @"
                        CALL spCrearDestinatariosCampana(
                            @IdCampana,
                            @IdsRoles,
                            @IdsMinisterios,
                            @Todos
                        );
                        ",
                        parametrosDestinatarios,
                        transaction
                    );


                    // =============================================
                    // VERIFICAR QUE EXISTAN DESTINATARIOS
                    // =============================================

                    var totalDestinatarios =
                        await context.QuerySingleAsync<int>(
                            @"
                            SELECT COUNT(*)::integer
                            FROM campana_destinatario
                            WHERE id_campana = @IdCampana;
                            ",
                            new
                            {
                                IdCampana = idCampana
                            },
                            transaction
                        );


                    if (totalDestinatarios == 0)
                    {
                        throw new InvalidOperationException(
                            "Los filtros seleccionados no " +
                            "generaron ningún destinatario."
                        );
                    }


                    // =============================================
                    // CAMPAÑA EN PROCESO
                    // =============================================

                    await context.ExecuteAsync(
                        @"
                        CALL spActualizarEstadoCampana(
                            @IdCampana,
                            'Procesando'
                        );
                        ",
                        new
                        {
                            IdCampana = idCampana
                        },
                        transaction
                    );


                    await transaction.CommitAsync();
                }
                catch
                {
                    await transaction.RollbackAsync();

                    throw;
                }


                // =================================================
                // 2. OBTENER DESTINATARIOS PENDIENTES
                // =================================================

                var destinatarios =
                    (
                        await context.QueryAsync<
                            CampanaDestinatarioResponseModel
                        >(
                            @"
                            SELECT *
                            FROM spListarDestinatariosPendientesCampana(
                                @IdCampana
                            );
                            ",
                            new
                            {
                                IdCampana = idCampana
                            }
                        )
                    )
                    .ToList();


                if (destinatarios.Count == 0)
                {
                    await context.ExecuteAsync(
                        @"
                        CALL spActualizarEstadoCampana(
                            @IdCampana,
                            'Error'
                        );
                        ",
                        new
                        {
                            IdCampana = idCampana
                        }
                    );


                    return BadRequest(
                        "No se encontraron destinatarios " +
                        "pendientes para la campaña."
                    );
                }


                // =================================================
                // 3. OBTENER COLOR DE LA PLANTILLA
                // =================================================

                var colorPlantilla =
                    await context.QueryFirstOrDefaultAsync<string>(
                        @"
                        SELECT color_encabezado
                        FROM campana_plantilla
                        WHERE codigo =
                              CAST(@Plantilla AS varchar(30))
                          AND activo = true;
                        ",
                        new
                        {
                            Plantilla = model.Plantilla
                        }
                    );


                if (string.IsNullOrWhiteSpace(colorPlantilla))
                {
                    colorPlantilla =
                        "#064442";
                }


                // =================================================
                // 4. ENVIAR CORREOS INDIVIDUALMENTE
                // =================================================

                var enviados = 0;
                var errores = 0;


                foreach (var destinatario in destinatarios)
                {
                    try
                    {
                        var cuerpoHtml =
                            ConstruirCorreoHtml(
                                destinatario.Nombre_Destinatario,
                                model.Titulo,
                                model.Contenido,
                                colorPlantilla
                            );


                        await _utiles.EnviarCorreoAsync(
                            destinatario.Correo_Destinatario,
                            model.Asunto,
                            cuerpoHtml
                        );


                        // =========================================
                        // MARCAR COMO ENVIADO
                        // =========================================

                        await context.ExecuteAsync(
                            @"
                            CALL spActualizarEstadoEnvioCampana(
                                @IdDestinatario,
                                'Enviado',
                                NULL
                            );
                            ",
                            new
                            {
                                IdDestinatario =
                                    destinatario
                                        .Id_Campana_Destinatario
                            }
                        );


                        enviados++;
                    }
                    catch (Exception ex)
                    {
                        errores++;


                        var detalleError =
                            ex.Message;


                        try
                        {
                            // =====================================
                            // MARCAR COMO ERROR
                            // =====================================

                            await context.ExecuteAsync(
                                @"
                                CALL spActualizarEstadoEnvioCampana(
                                    @IdDestinatario,
                                    'Error',
                                    @DetalleError
                                );
                                ",
                                new
                                {
                                    IdDestinatario =
                                        destinatario
                                            .Id_Campana_Destinatario,

                                    DetalleError =
                                        detalleError
                                }
                            );
                        }
                        catch
                        {
                            /*
                             * Si incluso falla el registro
                             * del error, continuamos con el
                             * siguiente destinatario.
                             *
                             * La excepción principal ya se
                             * contabilizó como error.
                             */
                        }
                    }
                }


                // =================================================
                // 5. DETERMINAR ESTADO FINAL
                // =================================================

                string estadoFinal;


                if (
                    enviados > 0 &&
                    errores == 0
                )
                {
                    estadoFinal =
                        "Enviada";
                }
                else if (
                    enviados > 0 &&
                    errores > 0
                )
                {
                    estadoFinal =
                        "Parcial";
                }
                else
                {
                    estadoFinal =
                        "Error";
                }


                await context.ExecuteAsync(
                    @"
                    CALL spActualizarEstadoCampana(
                        @IdCampana,
                        CAST(@Estado AS varchar(20))
                    );
                    ",
                    new
                    {
                        IdCampana = idCampana,
                        Estado = estadoFinal
                    }
                );


                // =================================================
                // RESPUESTA
                // =================================================

                return Ok(
                    new
                    {
                        Id_Campana =
                            idCampana,

                        Estado =
                            estadoFinal,

                        Total =
                            destinatarios.Count,

                        Enviados =
                            enviados,

                        Errores =
                            errores
                    }
                );
            }
            catch (PostgresException ex)
            {
                return BadRequest(
                    ex.MessageText
                );
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(
                    ex.Message
                );
            }
            catch (Exception ex)
            {
                return StatusCode(
                    500,
                    "Ocurrió un error al procesar la campaña: " +
                    ex.Message
                );
            }
        }


        // =========================================================
        // CONSTRUIR HTML DEL CORREO
        // =========================================================

        private static string ConstruirCorreoHtml(
            string nombre,
            string titulo,
            string contenido,
            string colorEncabezado)
        {
            /*
             * Los textos ingresados por el usuario
             * se codifican antes de insertarlos
             * dentro del HTML.
             */

            var nombreSeguro =
                WebUtility.HtmlEncode(
                    nombre
                );


            var tituloSeguro =
                WebUtility.HtmlEncode(
                    titulo
                );


            var contenidoSeguro =
                WebUtility.HtmlEncode(
                    contenido
                );


            /*
             * Conservamos los saltos de línea
             * escritos en el formulario.
             */
            contenidoSeguro =
                contenidoSeguro
                    .Replace(
                        "\r\n",
                        "<br>"
                    )
                    .Replace(
                        "\n",
                        "<br>"
                    );


            /*
             * El color procede de la tabla
             * campana_plantilla.
             */
            var color =
                string.IsNullOrWhiteSpace(
                    colorEncabezado
                )
                    ? "#064442"
                    : colorEncabezado;


            return $@"
<!DOCTYPE html>

<html>
<head>
    <meta charset=""utf-8"">

    <meta name=""viewport""
          content=""width=device-width, initial-scale=1.0"">
</head>

<body style=""
    margin:0;
    padding:0;
    background-color:#f4f6f6;
    font-family:Arial,Helvetica,sans-serif;
    color:#343a40;
"">

    <table role=""presentation""
           width=""100%""
           cellspacing=""0""
           cellpadding=""0""
           style=""
                width:100%;
                background-color:#f4f6f6;
                padding:30px 15px;
           "">

        <tr>
            <td align=""center"">

                <table role=""presentation""
                       width=""600""
                       cellspacing=""0""
                       cellpadding=""0""
                       style=""
                            width:100%;
                            max-width:600px;
                            background:#ffffff;
                            border-radius:12px;
                            overflow:hidden;
                       "">

                    <tr>
                        <td style=""
                            padding:28px;
                            background-color:{color};
                            color:#ffffff;
                        "">

                            <div style=""
                                font-size:13px;
                                margin-bottom:8px;
                                opacity:0.9;
                            "">
                                Ministerio Gosén
                            </div>

                            <div style=""
                                font-size:22px;
                                font-weight:bold;
                            "">
                                {tituloSeguro}
                            </div>

                        </td>
                    </tr>


                    <tr>
                        <td style=""
                            padding:32px 28px;
                            font-size:15px;
                            line-height:1.6;
                        "">

                            <p style=""
                                margin-top:0;
                            "">
                                Hola <strong>{nombreSeguro}</strong>,
                            </p>


                            <div>
                                {contenidoSeguro}
                            </div>


                            <hr style=""
                                margin:30px 0;
                                border:0;
                                border-top:1px solid #e9ecef;
                            "">


                            <div style=""
                                color:#6c757d;
                                font-size:13px;
                            "">
                                Ministerio Gosén
                            </div>

                        </td>
                    </tr>

                </table>

            </td>
        </tr>

    </table>

</body>
</html>";
        }
    }
}