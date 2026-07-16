/* =========================
   MENÚ PRINCIPAL
   ========================= */

DECLARE @IdInformacion INT;
DECLARE @IdMinisterios INT;
DECLARE @IdActividades INT;
DECLARE @IdCitas INT;
DECLARE @IdHorarios INT;
DECLARE @IdContacto INT;

INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Información general',
 'Seleccione la información general que desea consultar.',
 NULL, 1, 1);

SET @IdInformacion = SCOPE_IDENTITY();


INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Ministerios',
 'Seleccione el ministerio sobre el cual desea obtener información.',
 NULL, 2, 1);

SET @IdMinisterios = SCOPE_IDENTITY();


INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Actividades',
 'Seleccione la información que desea consultar sobre actividades.',
 NULL, 3, 1);

SET @IdActividades = SCOPE_IDENTITY();


INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Citas',
 'Seleccione una opción relacionada con citas.',
 NULL, 4, 1);

SET @IdCitas = SCOPE_IDENTITY();


INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Horarios',
 'Seleccione el horario que desea consultar.',
 NULL, 5, 1);

SET @IdHorarios = SCOPE_IDENTITY();


INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Contacto',
 'Seleccione el medio por el cual desea comunicarse.',
 NULL, 6, 1);

SET @IdContacto = SCOPE_IDENTITY();


/* =========================
   INFORMACIÓN GENERAL
   ========================= */

DECLARE @IdQueEs INT;
DECLARE @IdUbicacion INT;

INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'¿Qué es Ministerio Gosén?',
 'Ministerio Gosén es una organización dedicada al acompañamiento espiritual, apoyo comunitario y desarrollo de actividades para la comunidad.',
 @IdInformacion, 1, 1);

SET @IdQueEs = SCOPE_IDENTITY();


INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Ubicación',
 'Seleccione la información de ubicación que desea consultar.',
 @IdInformacion, 2, 1);

SET @IdUbicacion = SCOPE_IDENTITY();


INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'¿A quién atienden?',
 'Se brinda apoyo a personas de la comunidad que requieren orientación, acompañamiento o participación en actividades del ministerio.',
 @IdInformacion, 3, 1);


/* =========================
   UBICACIÓN
   ========================= */

INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Dirección',
 'El Ministerio Gosén se ubica en La Fila de Mora, Puriscal. Consulte con la administración para indicaciones exactas.',
 @IdUbicacion, 1, 1);


INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Cómo llegar',
 'Puede solicitar indicaciones por teléfono o revisar la ubicación compartida por la administración.',
 @IdUbicacion, 2, 1);


/* =========================
   MINISTERIOS
   ========================= */

DECLARE @IdNinos INT;
DECLARE @IdJovenes INT;
DECLARE @IdAdultos INT;
DECLARE @IdMujeres INT;

INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Ministerio de Niños',
 'El Ministerio de Niños realiza actividades formativas, recreativas y espirituales para la población infantil.',
 @IdMinisterios, 1, 1);

SET @IdNinos = SCOPE_IDENTITY();


INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Ministerio de Jóvenes',
 'El Ministerio de Jóvenes promueve espacios de formación, integración y crecimiento espiritual para adolescentes y jóvenes.',
 @IdMinisterios, 2, 1);

SET @IdJovenes = SCOPE_IDENTITY();


INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Ministerio de Adultos',
 'El Ministerio de Adultos brinda espacios de enseñanza, acompañamiento y participación comunitaria.',
 @IdMinisterios, 3, 1);

SET @IdAdultos = SCOPE_IDENTITY();


INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Ministerio de Mujeres',
 'El Ministerio de Mujeres desarrolla actividades de apoyo, enseñanza y acompañamiento espiritual.',
 @IdMinisterios, 4, 1);

SET @IdMujeres = SCOPE_IDENTITY();


/* =========================
   DETALLE DE MINISTERIOS
   ========================= */

INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Horario de niños',
 'Las actividades para niños se coordinan según la programación semanal del ministerio.',
 @IdNinos, 1, 1);


INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Participar en jóvenes',
 'Para participar en el Ministerio de Jóvenes, comuníquese con la administración o consulte las próximas actividades.',
 @IdJovenes, 1, 1);


INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Actividades de adultos',
 'Las actividades para adultos incluyen reuniones, enseñanzas y espacios de acompañamiento.',
 @IdAdultos, 1, 1);


INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Reuniones de mujeres',
 'Las reuniones del Ministerio de Mujeres se anuncian mediante la programación oficial.',
 @IdMujeres, 1, 1);


/* =========================
   ACTIVIDADES
   ========================= */

DECLARE @IdProximasActividades INT;

INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Próximas actividades',
 'Puede consultar las próximas actividades desde la sección Actividades del sistema.',
 @IdActividades, 1, 1);

SET @IdProximasActividades = SCOPE_IDENTITY();


INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Inscripción a actividades',
 'Para participar en una actividad, consulte los detalles y comuníquese con la administración.',
 @IdActividades, 2, 1);


INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Tipos de actividades',
 'El ministerio realiza reuniones, charlas, talleres, visitas y actividades comunitarias.',
 @IdActividades, 3, 1);


/* =========================
   CITAS
   ========================= */

DECLARE @IdAgendar INT;

INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Agendar una cita',
 'Para agendar una cita, ingrese a la opción Agendar Cita del menú principal.',
 @IdCitas, 1, 1);

SET @IdAgendar = SCOPE_IDENTITY();


INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Consultar una cita',
 'Para consultar una cita registrada, revise la sección Citas o comuníquese con la administración.',
 @IdCitas, 2, 1);


INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Cancelar una cita',
 'Para cancelar una cita, comuníquese con la administración con anticipación.',
 @IdCitas, 3, 1);


/* =========================
   AGENDAR CITA
   ========================= */

INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Datos necesarios',
 'Para agendar se requiere nombre, teléfono, motivo de la cita y disponibilidad de horario.',
 @IdAgendar, 1, 1);


INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Confirmación de cita',
 'La cita queda sujeta a confirmación por parte de la administración.',
 @IdAgendar, 2, 1);


/* =========================
   HORARIOS
   ========================= */

INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Horario de atención',
 'El horario de atención se coordina según la disponibilidad de la administración.',
 @IdHorarios, 1, 1);


INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Horario de actividades',
 'Los horarios de actividades pueden variar según el ministerio y la programación semanal.',
 @IdHorarios, 2, 1);


INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Atención en feriados',
 'La atención en feriados depende de la programación oficial del ministerio.',
 @IdHorarios, 3, 1);


/* =========================
   CONTACTO
   ========================= */

INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Teléfono',
 'Puede comunicarse con la administración al número registrado por el Ministerio Gosén.',
 @IdContacto, 1, 1);


INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Correo electrónico',
 'Puede escribir al correo oficial registrado por la administración del ministerio.',
 @IdContacto, 2, 1);


INSERT INTO Chat_Bot_Opciones
(Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
VALUES
(N'Solicitar ayuda',
 'Para solicitar ayuda, comuníquese con la administración o registre una cita desde el sistema.',
 @IdContacto, 3, 1);