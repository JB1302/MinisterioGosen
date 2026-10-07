
BEGIN;

-- Campo agregado en la version mas reciente del SQL Server original.
ALTER TABLE actividad
    ADD COLUMN IF NOT EXISTS estado varchar(20) NOT NULL DEFAULT 'Activo';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'chk_estado_actividad'
          AND conrelid = 'actividad'::regclass
    ) THEN
        ALTER TABLE actividad
            ADD CONSTRAINT chk_estado_actividad
            CHECK (estado IN ('Activo','Inactivo'));
    END IF;
END $$;


CREATE OR REPLACE FUNCTION sp_Consultarchatbot(p_id_opcion integer DEFAULT NULL)
RETURNS TABLE (
    opcion_actual jsonb,
    opciones jsonb,
    padre jsonb
)
LANGUAGE sql
AS $$
SELECT
    (
        SELECT to_jsonb(x)
        FROM (
            SELECT c.id_opcion, c.texto_opcion, c.respuesta,
                   c.id_opcion_padre, c.orden, c.activo
            FROM chat_bot_opciones c
            WHERE c.id_opcion = p_id_opcion
              AND c.activo = true
        ) x
    ) AS opcion_actual,
    COALESCE((
        SELECT jsonb_agg(to_jsonb(x) ORDER BY x.orden, x.texto_opcion)
        FROM (
            SELECT c.id_opcion, c.texto_opcion, c.respuesta,
                   c.id_opcion_padre, c.orden, c.activo
            FROM chat_bot_opciones c
            WHERE c.activo = true
              AND (
                    (p_id_opcion IS NULL AND c.id_opcion_padre IS NULL)
                 OR (p_id_opcion IS NOT NULL AND c.id_opcion_padre = p_id_opcion)
              )
        ) x
    ), '[]'::jsonb) AS opciones,
    (
        SELECT to_jsonb(x)
        FROM (
            SELECT padre.id_opcion, padre.texto_opcion, padre.respuesta,
                   padre.id_opcion_padre, padre.orden, padre.activo
            FROM chat_bot_opciones hijo
            INNER JOIN chat_bot_opciones padre
                ON padre.id_opcion = hijo.id_opcion_padre
            WHERE hijo.id_opcion = p_id_opcion
              AND padre.activo = true
        ) x
    ) AS padre;
$$;

CREATE OR REPLACE FUNCTION spConsultarDashboard()
RETURNS TABLE (
    totalpersonas bigint,
    totalactividades bigint,
    totalministerios bigint,
    totalcitaspendientes bigint,
    citas_estado jsonb,
    actividades_mes jsonb,
    top_actividades jsonb,
    personas_ministerio jsonb
)
LANGUAGE sql
AS $$
SELECT
    (SELECT COUNT(*) FROM usuario WHERE estado = 'A'),
    (SELECT COUNT(*) FROM actividad),
    (SELECT COUNT(*) FROM ministerio),
    (SELECT COUNT(*) FROM citas WHERE estado = 'Pendiente'),
    COALESCE((
        SELECT jsonb_agg(to_jsonb(q) ORDER BY q.cantidad DESC)
        FROM (
            SELECT CASE WHEN estado IS NULL OR btrim(estado) = '' THEN 'Sin estado' ELSE estado END AS etiqueta,
                   COUNT(*) AS cantidad
            FROM citas
            GROUP BY CASE WHEN estado IS NULL OR btrim(estado) = '' THEN 'Sin estado' ELSE estado END
        ) q
    ), '[]'::jsonb),
    COALESCE((
        SELECT jsonb_agg(to_jsonb(q) ORDER BY q.anio, q.mes)
        FROM (
            SELECT
                CASE EXTRACT(MONTH FROM fecha_ini)::int
                    WHEN 1 THEN 'Ene' WHEN 2 THEN 'Feb' WHEN 3 THEN 'Mar'
                    WHEN 4 THEN 'Abr' WHEN 5 THEN 'May' WHEN 6 THEN 'Jun'
                    WHEN 7 THEN 'Jul' WHEN 8 THEN 'Ago' WHEN 9 THEN 'Sep'
                    WHEN 10 THEN 'Oct' WHEN 11 THEN 'Nov' WHEN 12 THEN 'Dic'
                END || ' ' || EXTRACT(YEAR FROM fecha_ini)::int AS etiqueta,
                COUNT(*) AS cantidad,
                EXTRACT(YEAR FROM fecha_ini)::int AS anio,
                EXTRACT(MONTH FROM fecha_ini)::int AS mes
            FROM actividad
            WHERE fecha_ini >= (date_trunc('month', CURRENT_DATE) - interval '11 months')::date
            GROUP BY EXTRACT(YEAR FROM fecha_ini), EXTRACT(MONTH FROM fecha_ini)
        ) q
    ), '[]'::jsonb),
    COALESCE((
        SELECT jsonb_agg(to_jsonb(q) ORDER BY q.cantidad DESC, q.etiqueta ASC)
        FROM (
            SELECT a.nombre_actividad AS etiqueta,
                   COUNT(DISTINCT au.id_usuario) AS cantidad
            FROM actividad a
            INNER JOIN actividad_usuario au ON au.id_actividad = a.id_actividad
            INNER JOIN usuario u ON u.id_usuario = au.id_usuario
            WHERE u.estado = 'A'
            GROUP BY a.id_actividad, a.nombre_actividad
            ORDER BY cantidad DESC, a.nombre_actividad ASC
            LIMIT 10
        ) q
    ), '[]'::jsonb),
    COALESCE((
        SELECT jsonb_agg(to_jsonb(q) ORDER BY q.cantidad DESC, q.etiqueta ASC)
        FROM (
            SELECT m.descripcion_ministerio AS etiqueta,
                   COUNT(DISTINCT um.id_usuario) AS cantidad
            FROM ministerio m
            INNER JOIN usuarios_ministerio um ON um.id_ministerio = m.id_ministerio
            INNER JOIN usuario u ON u.id_usuario = um.id_usuario
            WHERE u.estado = 'A'
              AND um.fecha_salida IS NULL
              AND (um.estado IS NULL OR um.estado <> 'Inactivo')
            GROUP BY m.id_ministerio, m.descripcion_ministerio
        ) q
    ), '[]'::jsonb);
$$;


CREATE OR REPLACE PROCEDURE spActivarUsuario(p_id_usuario integer)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE usuario SET estado = 'A' WHERE id_usuario = p_id_usuario;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró el usuario.';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE spDesactivarUsuario(p_id_usuario integer)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE usuario SET estado = 'I' WHERE id_usuario = p_id_usuario;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró el usuario.';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE spActualizarContrasenna(
    p_id_usuario integer,
    p_contrasena varchar(255),
    p_indicador_temp boolean
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE usuario
       SET contrasena = p_contrasena,
           usa_contrasena_temp = p_indicador_temp
     WHERE id_usuario = p_id_usuario;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró el usuario.';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE spActualizarPerfil(
    p_id_usuario integer,
    p_identificacion varchar(20),
    p_nombre varchar(100),
    p_correo varchar(100)
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE usuario
       SET nombre = p_nombre,
           identificacion = p_identificacion,
           correo = p_correo
     WHERE id_usuario = p_id_usuario;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró el usuario.';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE spActualizarUsuario(
    p_id_usuario integer,
    p_nombre varchar(100),
    p_correo varchar(100),
    p_estado char(1),
    p_id_rol integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE usuario
       SET nombre = p_nombre,
           correo = p_correo,
           estado = p_estado,
           id_rol = p_id_rol
     WHERE id_usuario = p_id_usuario;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró el usuario.';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE spCrearUsuario(
    p_identificacion varchar(20),
    p_nombre varchar(100),
    p_correo varchar(100),
    p_contrasena varchar(255),
    p_estado char(1),
    p_id_rol integer
)
LANGUAGE sql
AS $$
    INSERT INTO usuario
        (identificacion, nombre, correo, contrasena, estado, id_rol, usa_contrasena_temp)
    VALUES
        (p_identificacion, p_nombre, p_correo, p_contrasena, p_estado, p_id_rol, false);
$$;

CREATE OR REPLACE PROCEDURE spEliminarUsuario(p_id_usuario integer)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM usuario WHERE id_usuario = p_id_usuario;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró el usuario.';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE spRegistrarUsuario(
    p_identificacion varchar(20),
    p_nombre varchar(100),
    p_correo varchar(100),
    p_contrasena varchar(255)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_rol_usuario integer;
BEGIN
    SELECT id_rol INTO v_id_rol_usuario
    FROM rol
    WHERE descripcion = 'Usuario';

    IF v_id_rol_usuario IS NULL THEN
        RAISE EXCEPTION 'No existe el rol Usuario.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM usuario
        WHERE identificacion = p_identificacion
    ) THEN
        RAISE EXCEPTION 'Ya existe un usuario con esa identificación.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM usuario
        WHERE correo = p_correo
    ) THEN
        RAISE EXCEPTION 'Ya existe un usuario con ese correo.';
    END IF;

    INSERT INTO usuario
        (identificacion, nombre, correo, contrasena, estado, id_rol, usa_contrasena_temp)
    VALUES
        (p_identificacion, p_nombre, p_correo, p_contrasena, 'A', v_id_rol_usuario, false);
END;
$$;

-- Compatibilidad con Npgsql/Dapper:
-- los parámetros string preparados llegan a PostgreSQL como TEXT.
-- Se conserva el segundo parámetro original por compatibilidad.
DROP FUNCTION IF EXISTS spIniciarSesionUsuario(varchar, varchar);
DROP FUNCTION IF EXISTS spIniciarSesionUsuario(text, text);

CREATE OR REPLACE FUNCTION spIniciarSesionUsuario(
    p_correo text,
    p_contrasena text DEFAULT NULL
)
RETURNS TABLE (
    id_usuario integer,
    identificacion varchar(20),
    nombre varchar(100),
    correo varchar(100),
    contrasena varchar(255),
    estado char(1),
    id_rol integer,
    usacontrasenatemp boolean
)
LANGUAGE sql
AS $$
    SELECT u.id_usuario, u.identificacion, u.nombre, u.correo,
           u.contrasena, u.estado, u.id_rol, u.usa_contrasena_temp
    FROM usuario u
    WHERE u.correo = p_correo
      AND u.estado = 'A';
$$;

DROP FUNCTION IF EXISTS spValidarCorreo(varchar);
DROP FUNCTION IF EXISTS spValidarCorreo(text);

CREATE OR REPLACE FUNCTION spValidarCorreo(p_correo text)
RETURNS TABLE (
    id_usuario integer,
    identificacion varchar(20),
    nombre varchar(100),
    correo varchar(100),
    estado char(1)
)
LANGUAGE sql
AS $$
    SELECT u.id_usuario, u.identificacion, u.nombre, u.correo, u.estado
    FROM usuario u
    WHERE u.correo = p_correo
      AND u.estado = 'A';
$$;

CREATE OR REPLACE FUNCTION spListarUsuarios()
RETURNS TABLE (
    id_usuario integer,
    identificacion varchar(20),
    nombre varchar(100),
    correo varchar(100),
    estado char(1),
    id_rol integer,
    rol varchar(20)
)
LANGUAGE sql
AS $$
    SELECT u.id_usuario, u.identificacion, u.nombre, u.correo,
           u.estado, u.id_rol, r.descripcion AS rol
    FROM usuario u
    INNER JOIN rol r ON u.id_rol = r.id_rol
    ORDER BY u.nombre;
$$;

CREATE OR REPLACE FUNCTION spObtenerUsuario(p_id_usuario integer)
RETURNS TABLE (
    id_usuario integer,
    identificacion varchar(20),
    nombre varchar(100),
    correo varchar(100),
    contrasena varchar(255),
    estado char(1),
    id_rol integer,
    usacontrasenatemp boolean
)
LANGUAGE sql
AS $$
    SELECT u.id_usuario, u.identificacion, u.nombre, u.correo,
           u.contrasena, u.estado, u.id_rol, u.usa_contrasena_temp
    FROM usuario u
    WHERE u.id_usuario = p_id_usuario;
$$;

CREATE OR REPLACE PROCEDURE spActualizarRol(
    p_id_rol integer,
    p_descripcion varchar(20)
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE rol SET descripcion = p_descripcion WHERE id_rol = p_id_rol;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró el rol.';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE spCrearRol(p_descripcion varchar(20))
LANGUAGE sql
AS $$
    INSERT INTO rol(descripcion) VALUES (p_descripcion);
$$;

CREATE OR REPLACE PROCEDURE spEliminarRol(p_id_rol integer)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM rol WHERE id_rol = p_id_rol;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró el rol.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION spListarRoles()
RETURNS TABLE (id_rol integer, descripcion varchar(20))
LANGUAGE sql
AS $$
    SELECT r.id_rol, r.descripcion FROM rol r ORDER BY r.id_rol;
$$;

CREATE OR REPLACE FUNCTION spObtenerRol(p_id_rol integer)
RETURNS TABLE (id_rol integer, descripcion varchar(20))
LANGUAGE sql
AS $$
    SELECT r.id_rol, r.descripcion FROM rol r WHERE r.id_rol = p_id_rol;
$$;

-- =============================================================
-- MINISTERIOS Y MEMBRESIAS
-- =============================================================

CREATE OR REPLACE PROCEDURE spActualizarMinisterio(
    p_id_ministerio integer,
    p_descripcion_ministerio varchar(100),
    p_observaciones_ministerio varchar(200)
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE ministerio
       SET descripcion_ministerio = p_descripcion_ministerio,
           observaciones_ministerio = p_observaciones_ministerio
     WHERE id_ministerio = p_id_ministerio;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró el ministerio.';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE spCrearMinisterio(
    p_descripcion_ministerio varchar(100),
    p_observaciones_ministerio varchar(200)
)
LANGUAGE sql
AS $$
    INSERT INTO ministerio(descripcion_ministerio, observaciones_ministerio)
    VALUES (p_descripcion_ministerio, p_observaciones_ministerio);
$$;

CREATE OR REPLACE PROCEDURE spEliminarMinisterio(p_id_ministerio integer)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM ministerio WHERE id_ministerio = p_id_ministerio;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró el ministerio.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION spListarMinisterios()
RETURNS TABLE (
    id_ministerio integer,
    descripcion_ministerio varchar(100),
    observaciones_ministerio varchar(200)
)
LANGUAGE sql
AS $$
    SELECT m.id_ministerio, m.descripcion_ministerio, m.observaciones_ministerio
    FROM ministerio m
    ORDER BY m.descripcion_ministerio;
$$;

CREATE OR REPLACE FUNCTION spObtenerMinisterio(p_id_ministerio integer)
RETURNS TABLE (
    id_ministerio integer,
    descripcion_ministerio varchar(100),
    observaciones_ministerio varchar(200)
)
LANGUAGE sql
AS $$
    SELECT m.id_ministerio, m.descripcion_ministerio, m.observaciones_ministerio
    FROM ministerio m
    WHERE m.id_ministerio = p_id_ministerio;
$$;

CREATE OR REPLACE PROCEDURE spCrearUsuarioMinisterio(
    p_id_ministerio integer,
    p_id_usuario integer,
    p_fecha_ingreso date,
    p_estado varchar(20),
    p_observacion varchar(200)
)
LANGUAGE sql
AS $$
    INSERT INTO usuarios_ministerio
        (id_ministerio, id_usuario, fecha_ingreso, fecha_salida, estado, observacion)
    VALUES
        (p_id_ministerio, p_id_usuario, p_fecha_ingreso, NULL, p_estado, p_observacion);
$$;

CREATE OR REPLACE PROCEDURE spActualizarUsuarioMinisterio(
    p_id_usuario_ministerio integer,
    p_id_ministerio integer,
    p_id_usuario integer,
    p_fecha_ingreso date,
    p_fecha_salida date,
    p_estado varchar(20),
    p_observacion varchar(200)
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE usuarios_ministerio
       SET id_ministerio = p_id_ministerio,
           id_usuario = p_id_usuario,
           fecha_ingreso = p_fecha_ingreso,
           fecha_salida = p_fecha_salida,
           estado = p_estado,
           observacion = p_observacion
     WHERE id_usuario_ministerio = p_id_usuario_ministerio;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró la membresía del usuario en el ministerio.';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE spEditarUsuarioMinisterio(
    p_id_usuario_ministerio integer,
    p_fecha_ingreso date,
    p_observacion varchar(200)
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE usuarios_ministerio
       SET fecha_ingreso = p_fecha_ingreso,
           observacion = p_observacion
     WHERE id_usuario_ministerio = p_id_usuario_ministerio;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró la membresía del usuario en el ministerio.';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE spEliminarUsuarioMinisterio(p_id_usuario_ministerio integer)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM usuarios_ministerio
    WHERE id_usuario_ministerio = p_id_usuario_ministerio;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró la membresía del usuario en el ministerio.';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE spSalirUsuarioMinisterio(p_id_usuario_ministerio integer)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE usuarios_ministerio
       SET fecha_salida = CURRENT_DATE,
           estado = 'Inactivo'
     WHERE id_usuario_ministerio = p_id_usuario_ministerio;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró la membresía del usuario en el ministerio.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION spObtenerUsuarioMinisterio(p_id_usuario_ministerio integer)
RETURNS TABLE (
    id_usuario_ministerio integer,
    id_ministerio integer,
    id_usuario integer,
    fecha_ingreso date,
    fecha_salida date,
    estado varchar(20),
    observacion varchar(200)
)
LANGUAGE sql
AS $$
    SELECT um.id_usuario_ministerio, um.id_ministerio, um.id_usuario,
           um.fecha_ingreso, um.fecha_salida, um.estado, um.observacion
    FROM usuarios_ministerio um
    WHERE um.id_usuario_ministerio = p_id_usuario_ministerio;
$$;

CREATE OR REPLACE FUNCTION spListarUsuariosPorMinisterio(p_id_ministerio integer)
RETURNS TABLE (
    id_usuario_ministerio integer,
    id_ministerio integer,
    id_usuario integer,
    fecha_ingreso date,
    fecha_salida date,
    estado varchar(20),
    observacion varchar(200),
    nombre varchar(100),
    correo varchar(100),
    rol varchar(20)
)
LANGUAGE sql
AS $$
    SELECT um.id_usuario_ministerio, um.id_ministerio, um.id_usuario,
           um.fecha_ingreso, um.fecha_salida, um.estado, um.observacion,
           u.nombre, u.correo, r.descripcion AS rol
    FROM usuarios_ministerio um
    INNER JOIN usuario u ON um.id_usuario = u.id_usuario
    INNER JOIN rol r ON u.id_rol = r.id_rol
    WHERE um.id_ministerio = p_id_ministerio
      AND um.fecha_salida IS NULL
    ORDER BY u.nombre;
$$;

CREATE OR REPLACE FUNCTION spListarUsuariosDisponiblesMinisterio(p_id_ministerio integer)
RETURNS TABLE (
    id_usuario integer,
    identificacion varchar(20),
    nombre varchar(100),
    correo varchar(100),
    estado char(1),
    id_rol integer,
    rol varchar(20)
)
LANGUAGE sql
AS $$
    SELECT u.id_usuario, u.identificacion, u.nombre, u.correo,
           u.estado, u.id_rol, r.descripcion AS rol
    FROM usuario u
    INNER JOIN rol r ON u.id_rol = r.id_rol
    WHERE u.id_rol <> 1
      AND u.estado = 'A'
      AND NOT EXISTS (
          SELECT 1
          FROM usuarios_ministerio um
          WHERE um.id_usuario = u.id_usuario
            AND um.id_ministerio = p_id_ministerio
            AND um.fecha_salida IS NULL
      )
    ORDER BY u.nombre;
$$;

CREATE OR REPLACE FUNCTION spListarMinisteriosPorUsuario(p_id_usuario integer)
RETURNS TABLE (
    id_usuario_ministerio integer,
    id_ministerio integer,
    id_usuario integer,
    fecha_ingreso date,
    fecha_salida date,
    estado varchar(20),
    observacion varchar(200),
    descripcion_ministerio varchar(100)
)
LANGUAGE sql
AS $$
    SELECT um.id_usuario_ministerio, um.id_ministerio, um.id_usuario,
           um.fecha_ingreso, um.fecha_salida, um.estado, um.observacion,
           m.descripcion_ministerio
    FROM usuarios_ministerio um
    INNER JOIN ministerio m ON um.id_ministerio = m.id_ministerio
    WHERE um.id_usuario = p_id_usuario
      AND um.fecha_salida IS NULL
    ORDER BY m.descripcion_ministerio;
$$;

CREATE OR REPLACE FUNCTION spListarMinisteriosDisponiblesUsuario(p_id_usuario integer)
RETURNS TABLE (
    id_ministerio integer,
    descripcion_ministerio varchar(100),
    observaciones_ministerio varchar(200)
)
LANGUAGE sql
AS $$
    SELECT m.id_ministerio, m.descripcion_ministerio, m.observaciones_ministerio
    FROM ministerio m
    WHERE NOT EXISTS (
        SELECT 1
        FROM usuarios_ministerio um
        WHERE um.id_ministerio = m.id_ministerio
          AND um.id_usuario = p_id_usuario
          AND um.fecha_salida IS NULL
    )
    ORDER BY m.descripcion_ministerio;
$$;

-- =============================================================
-- TIPO DE ACTIVIDAD
-- =============================================================

CREATE OR REPLACE PROCEDURE spActualizarTipoActividad(
    p_id_tipo_actividad integer,
    p_nombre_tipo varchar(50)
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE tipo_actividad
       SET nombre_tipo = p_nombre_tipo
     WHERE id_tipo_actividad = p_id_tipo_actividad;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró el tipo de actividad.';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE spCrearTipoActividad(p_nombre_tipo varchar(50))
LANGUAGE sql
AS $$
    INSERT INTO tipo_actividad(nombre_tipo) VALUES (p_nombre_tipo);
$$;

CREATE OR REPLACE PROCEDURE spEliminarTipoActividad(p_id_tipo_actividad integer)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM tipo_actividad WHERE id_tipo_actividad = p_id_tipo_actividad;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró el tipo de actividad.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION spListarTiposActividad()
RETURNS TABLE (id_tipo_actividad integer, nombre_tipo varchar(50))
LANGUAGE sql
AS $$
    SELECT t.id_tipo_actividad, t.nombre_tipo
    FROM tipo_actividad t
    ORDER BY t.nombre_tipo;
$$;

CREATE OR REPLACE FUNCTION spObtenerTipoActividad(p_id_tipo_actividad integer)
RETURNS TABLE (id_tipo_actividad integer, nombre_tipo varchar(50))
LANGUAGE sql
AS $$
    SELECT t.id_tipo_actividad, t.nombre_tipo
    FROM tipo_actividad t
    WHERE t.id_tipo_actividad = p_id_tipo_actividad;
$$;

-- =============================================================
-- ACTIVIDADES
-- =============================================================

CREATE OR REPLACE FUNCTION spCrearActividad(
    p_nombre_actividad varchar(100),
    p_fecha_ini date,
    p_fecha_fin date,
    p_lugar varchar(100),
    p_hora_ini time,
    p_hora_fin time,
    p_id_tipo_actividad integer
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE v_id integer;
BEGIN
    INSERT INTO actividad
        (nombre_actividad, fecha_ini, fecha_fin, lugar, hora_ini, hora_fin, id_tipo_actividad)
    VALUES
        (p_nombre_actividad, p_fecha_ini, p_fecha_fin, p_lugar, p_hora_ini, p_hora_fin, p_id_tipo_actividad)
    RETURNING id_actividad INTO v_id;
    RETURN v_id;
END;
$$;

CREATE OR REPLACE PROCEDURE spActualizarActividad(
    p_id_actividad integer,
    p_nombre_actividad varchar(100),
    p_fecha_ini date,
    p_fecha_fin date,
    p_lugar varchar(100),
    p_hora_ini time,
    p_hora_fin time,
    p_id_tipo_actividad integer
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE actividad
       SET nombre_actividad = p_nombre_actividad,
           fecha_ini = p_fecha_ini,
           fecha_fin = p_fecha_fin,
           lugar = p_lugar,
           hora_ini = p_hora_ini,
           hora_fin = p_hora_fin,
           id_tipo_actividad = p_id_tipo_actividad
     WHERE id_actividad = p_id_actividad;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró la actividad.';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE spEliminarActividad(p_id_actividad integer)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM actividad WHERE id_actividad = p_id_actividad;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró la actividad.';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE spInactivarActividad(p_id_actividad integer)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE actividad SET estado = 'Inactivo' WHERE id_actividad = p_id_actividad;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró la actividad.';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE spActivarActividad(p_id_actividad integer)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE actividad SET estado = 'Activo' WHERE id_actividad = p_id_actividad;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró la actividad.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION spListarActividades()
RETURNS TABLE (
    id_actividad integer,
    nombre_actividad varchar(100),
    fecha_ini date,
    fecha_fin date,
    lugar varchar(100),
    hora_ini varchar(5),
    hora_fin varchar(5),
    id_tipo_actividad integer,
    nombre_tipo varchar(50),
    id_ministerio integer,
    descripcion_ministerio varchar(100),
    observacion_ministerio_actividad varchar(200),
    estado varchar(20)
)
LANGUAGE sql
AS $$
    SELECT a.id_actividad, a.nombre_actividad, a.fecha_ini, a.fecha_fin, a.lugar,
           CASE WHEN a.hora_ini IS NULL THEN NULL ELSE to_char(a.hora_ini, 'HH24:MI')::varchar(5) END,
           CASE WHEN a.hora_fin IS NULL THEN NULL ELSE to_char(a.hora_fin, 'HH24:MI')::varchar(5) END,
           a.id_tipo_actividad, t.nombre_tipo,
           am.id_ministerio, m.descripcion_ministerio,
           am.observacion AS observacion_ministerio_actividad,
           a.estado
    FROM actividad a
    INNER JOIN tipo_actividad t ON a.id_tipo_actividad = t.id_tipo_actividad
    LEFT JOIN actividades_ministerio am ON a.id_actividad = am.id_actividad
    LEFT JOIN ministerio m ON am.id_ministerio = m.id_ministerio
    ORDER BY a.fecha_ini DESC;
$$;

CREATE OR REPLACE FUNCTION spObtenerActividad(p_id_actividad integer)
RETURNS TABLE (
    id_actividad integer,
    nombre_actividad varchar(100),
    fecha_ini date,
    fecha_fin date,
    lugar varchar(100),
    hora_ini varchar(5),
    hora_fin varchar(5),
    id_tipo_actividad integer,
    id_ministerio integer,
    descripcion_ministerio varchar(100),
    observacion_ministerio_actividad varchar(200),
    estado varchar(20)
)
LANGUAGE sql
AS $$
    SELECT a.id_actividad, a.nombre_actividad, a.fecha_ini, a.fecha_fin, a.lugar,
           CASE WHEN a.hora_ini IS NULL THEN NULL ELSE to_char(a.hora_ini, 'HH24:MI')::varchar(5) END,
           CASE WHEN a.hora_fin IS NULL THEN NULL ELSE to_char(a.hora_fin, 'HH24:MI')::varchar(5) END,
           a.id_tipo_actividad,
           am.id_ministerio, m.descripcion_ministerio,
           am.observacion AS observacion_ministerio_actividad,
           a.estado
    FROM actividad a
    LEFT JOIN actividades_ministerio am ON a.id_actividad = am.id_actividad
    LEFT JOIN ministerio m ON am.id_ministerio = m.id_ministerio
    WHERE a.id_actividad = p_id_actividad;
$$;

-- =============================================================
-- ACTIVIDAD - MINISTERIO
-- =============================================================

CREATE OR REPLACE FUNCTION spCrearActividadesMinisterio(
    p_id_actividad integer,
    p_id_ministerio integer,
    p_fecha date,
    p_observacion varchar(200)
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE v_id integer;
BEGIN
    INSERT INTO actividades_ministerio(id_actividad, id_ministerio, fecha, observacion)
    VALUES (p_id_actividad, p_id_ministerio, p_fecha, p_observacion)
    RETURNING id_minis_actividad INTO v_id;
    RETURN v_id;
END;
$$;

CREATE OR REPLACE PROCEDURE spActualizarActividadesMinisterio(
    p_id_minis_actividad integer,
    p_id_actividad integer,
    p_id_ministerio integer,
    p_fecha date,
    p_observacion varchar(200)
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE actividades_ministerio
       SET id_actividad = p_id_actividad,
           id_ministerio = p_id_ministerio,
           fecha = p_fecha,
           observacion = p_observacion
     WHERE id_minis_actividad = p_id_minis_actividad;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró la relación entre actividad y ministerio.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION spEliminarActividadMinisterio(p_id_minis_actividad integer)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE v_count integer;
BEGIN
    DELETE FROM actividades_ministerio
    WHERE id_minis_actividad = p_id_minis_actividad;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$;

CREATE OR REPLACE FUNCTION spEliminarActividadesMinisterio(p_id_minis_actividad integer)
RETURNS integer
LANGUAGE sql
AS $$
    SELECT spEliminarActividadMinisterio(p_id_minis_actividad);
$$;

CREATE OR REPLACE PROCEDURE spEliminarMinisterioPorActividad(p_id_actividad integer)
LANGUAGE plpgsql
AS $$
BEGIN
    -- La actividad debe existir; tener un ministerio asociado es opcional.
    PERFORM 1 FROM actividad WHERE id_actividad = p_id_actividad FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró la actividad.';
    END IF;

    -- Cero relaciones eliminadas es válido para una actividad sin ministerio.
    DELETE FROM actividades_ministerio WHERE id_actividad = p_id_actividad;
END;
$$;

CREATE OR REPLACE PROCEDURE spGuardarMinisterioActividad(
    p_id_actividad integer,
    p_id_ministerio integer,
    p_observacion varchar(200)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM actividades_ministerio WHERE id_actividad = p_id_actividad) THEN
        UPDATE actividades_ministerio
           SET id_ministerio = p_id_ministerio,
               fecha = CURRENT_DATE,
               observacion = p_observacion
         WHERE id_actividad = p_id_actividad;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'No se encontró la relación entre actividad y ministerio.';
        END IF;
    ELSE
        INSERT INTO actividades_ministerio(id_actividad, id_ministerio, fecha, observacion)
        VALUES (p_id_actividad, p_id_ministerio, CURRENT_DATE, p_observacion);
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION spListarActividadMinisterio(
    p_id_ministerio integer DEFAULT NULL,
    p_id_actividad integer DEFAULT NULL
)
RETURNS TABLE (
    id_minis_actividad integer,
    id_actividad integer,
    nombreactividad varchar(100),
    id_ministerio integer,
    nombreministerio varchar(100),
    fecha date,
    observacion varchar(200)
)
LANGUAGE sql
AS $$
    SELECT am.id_minis_actividad, am.id_actividad,
           a.nombre_actividad AS nombreactividad,
           am.id_ministerio,
           m.descripcion_ministerio AS nombreministerio,
           am.fecha, am.observacion
    FROM actividades_ministerio am
    INNER JOIN actividad a ON a.id_actividad = am.id_actividad
    INNER JOIN ministerio m ON m.id_ministerio = am.id_ministerio
    WHERE (p_id_ministerio IS NULL OR am.id_ministerio = p_id_ministerio)
      AND (p_id_actividad IS NULL OR am.id_actividad = p_id_actividad)
    ORDER BY am.fecha DESC, am.id_minis_actividad ASC;
$$;

CREATE OR REPLACE FUNCTION spObtenerActividadMinisterio(p_id_minis_actividad integer)
RETURNS TABLE (
    id_minis_actividad integer,
    id_actividad integer,
    nombreactividad varchar(100),
    id_ministerio integer,
    nombreministerio varchar(100),
    fecha date,
    observacion varchar(200)
)
LANGUAGE sql
AS $$
    SELECT am.id_minis_actividad, am.id_actividad,
           a.nombre_actividad AS nombreactividad,
           am.id_ministerio,
           m.descripcion_ministerio AS nombreministerio,
           am.fecha, am.observacion
    FROM actividades_ministerio am
    INNER JOIN actividad a ON a.id_actividad = am.id_actividad
    INNER JOIN ministerio m ON m.id_ministerio = am.id_ministerio
    WHERE am.id_minis_actividad = p_id_minis_actividad;
$$;

CREATE OR REPLACE FUNCTION spObtenerActividadesMinisterio(p_id_minis_actividad integer)
RETURNS TABLE (
    id_minis_actividad integer,
    id_actividad integer,
    nombreactividad varchar(100),
    id_ministerio integer,
    nombreministerio varchar(100),
    fecha date,
    observacion varchar(200)
)
LANGUAGE sql
AS $$
    SELECT * FROM spObtenerActividadMinisterio(p_id_minis_actividad);
$$;

-- =============================================================
-- ACTIVIDAD - USUARIO
-- =============================================================

CREATE OR REPLACE FUNCTION spCrearActividadUsuario(
    p_id_actividad integer,
    p_id_usuario integer,
    p_fecha date,
    p_hora time
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE v_id integer;
BEGIN
    INSERT INTO actividad_usuario(id_actividad, id_usuario, fecha, hora)
    VALUES (p_id_actividad, p_id_usuario, p_fecha, p_hora)
    RETURNING id_actividad_usuario INTO v_id;
    RETURN v_id;
END;
$$;

CREATE OR REPLACE PROCEDURE spActualizarActividadUsuario(
    p_id_actividad_usuario integer,
    p_id_actividad integer,
    p_id_usuario integer,
    p_fecha date,
    p_hora time
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE actividad_usuario
       SET id_actividad = p_id_actividad,
           id_usuario = p_id_usuario,
           fecha = p_fecha,
           hora = p_hora
     WHERE id_actividad_usuario = p_id_actividad_usuario;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró la relación entre actividad y usuario.';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE spEliminarActividadUsuario(p_id_actividad_usuario integer)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM actividad_usuario WHERE id_actividad_usuario = p_id_actividad_usuario;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró la relación entre actividad y usuario.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION spListarActividadUsuario(
    p_id_usuario integer DEFAULT NULL,
    p_id_actividad integer DEFAULT NULL
)
RETURNS TABLE (
    id_actividad_usuario integer,
    id_actividad integer,
    nombreactividad varchar(100),
    id_usuario integer,
    identificacionusuario varchar(20),
    nombreusuario varchar(100),
    fecha date,
    hora time
)
LANGUAGE sql
AS $$
    SELECT au.id_actividad_usuario, au.id_actividad,
           a.nombre_actividad AS nombreactividad,
           au.id_usuario,
           u.identificacion AS identificacionusuario,
           u.nombre AS nombreusuario,
           au.fecha, au.hora
    FROM actividad_usuario au
    INNER JOIN actividad a ON a.id_actividad = au.id_actividad
    INNER JOIN usuario u ON u.id_usuario = au.id_usuario
    WHERE (p_id_usuario IS NULL OR au.id_usuario = p_id_usuario)
      AND (p_id_actividad IS NULL OR au.id_actividad = p_id_actividad)
    ORDER BY au.fecha DESC, au.hora ASC, a.nombre_actividad, u.nombre;
$$;

CREATE OR REPLACE FUNCTION spObtenerActividadUsuario(p_id_actividad_usuario integer)
RETURNS TABLE (
    id_actividad_usuario integer,
    id_actividad integer,
    nombreactividad varchar(100),
    id_usuario integer,
    identificacionusuario varchar(20),
    nombreusuario varchar(100),
    fecha date,
    hora time
)
LANGUAGE sql
AS $$
    SELECT au.id_actividad_usuario, au.id_actividad,
           a.nombre_actividad AS nombreactividad,
           au.id_usuario,
           u.identificacion AS identificacionusuario,
           u.nombre AS nombreusuario,
           au.fecha, au.hora
    FROM actividad_usuario au
    INNER JOIN actividad a ON a.id_actividad = au.id_actividad
    INNER JOIN usuario u ON u.id_usuario = au.id_usuario
    WHERE au.id_actividad_usuario = p_id_actividad_usuario;
$$;

-- =============================================================
-- CITAS
-- =============================================================

CREATE OR REPLACE FUNCTION spCrearCita(
    p_fecha_cita date,
    p_hora_cita time,
    p_id_usuario_cita integer,
    p_id_usuario_encargado integer,
    p_observacion_inicial varchar(200),
    p_detalle_cita varchar(500)
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE v_id integer;
BEGIN
    IF p_id_usuario_cita = p_id_usuario_encargado THEN
        RAISE EXCEPTION 'No puede agendar una cita consigo mismo como encargado.';
    END IF;

    IF p_fecha_cita < CURRENT_DATE THEN
        RAISE EXCEPTION 'La fecha de la cita no puede ser anterior a la fecha actual.';
    END IF;

    IF p_hora_cita < TIME '08:00:00' OR p_hora_cita > TIME '17:00:00' THEN
        RAISE EXCEPTION 'La hora de la cita debe estar entre las 08:00 y las 17:00.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM citas
        WHERE id_usuario_encargado = p_id_usuario_encargado
          AND fecha_cita = p_fecha_cita
          AND hora_cita = p_hora_cita
    ) THEN
        RAISE EXCEPTION 'El encargado ya tiene una cita agendada en esa fecha y hora.';
    END IF;

    INSERT INTO citas
        (fecha_cita, hora_cita, id_usuario_cita, id_usuario_encargado,
         observacion_inicial, detalle_cita)
    VALUES
        (p_fecha_cita, p_hora_cita, p_id_usuario_cita, p_id_usuario_encargado,
         p_observacion_inicial, p_detalle_cita)
    RETURNING id_cita INTO v_id;

    RETURN v_id;
END;
$$;

CREATE OR REPLACE PROCEDURE spActualizarCita(
    p_id_cita integer,
    p_fecha_cita date,
    p_hora_cita time,
    p_id_usuario_cita integer,
    p_id_usuario_encargado integer,
    p_observacion_inicial varchar(200),
    p_detalle_cita varchar(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_hora_cita < TIME '08:00:00' OR p_hora_cita > TIME '17:00:00' THEN
        RAISE EXCEPTION 'La hora de la cita debe estar entre las 08:00 y las 17:00.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM citas
        WHERE id_usuario_encargado = p_id_usuario_encargado
          AND fecha_cita = p_fecha_cita
          AND hora_cita = p_hora_cita
          AND id_cita <> p_id_cita
    ) THEN
        RAISE EXCEPTION 'El encargado ya tiene una cita agendada en esa fecha y hora.';
    END IF;

    UPDATE citas
       SET fecha_cita = p_fecha_cita,
           hora_cita = p_hora_cita,
           id_usuario_cita = p_id_usuario_cita,
           id_usuario_encargado = p_id_usuario_encargado,
           observacion_inicial = p_observacion_inicial,
           detalle_cita = p_detalle_cita
     WHERE id_cita = p_id_cita;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró la cita.';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE spAtenderCita(
    p_id_cita integer,
    p_detalle_cita varchar(500)
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE citas
       SET estado = 'Atendida', detalle_cita = p_detalle_cita
     WHERE id_cita = p_id_cita;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró la cita.';
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE spEliminarCita(p_id_cita integer)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM citas WHERE id_cita = p_id_cita;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró la cita.';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION spListarCitas()
RETURNS TABLE (
    id_cita integer,
    fecha_cita date,
    hora_cita time,
    id_usuario_cita integer,
    nombre_usuario_cita varchar(100),
    id_usuario_encargado integer,
    nombre_usuario_encargado varchar(100),
    observacion_inicial varchar(200),
    detalle_cita varchar(500),
    estado varchar(20)
)
LANGUAGE sql
AS $$
    SELECT c.id_cita, c.fecha_cita, c.hora_cita,
           c.id_usuario_cita, uc.nombre AS nombre_usuario_cita,
           c.id_usuario_encargado, ue.nombre AS nombre_usuario_encargado,
           c.observacion_inicial, c.detalle_cita, c.estado
    FROM citas c
    INNER JOIN usuario uc ON c.id_usuario_cita = uc.id_usuario
    INNER JOIN usuario ue ON c.id_usuario_encargado = ue.id_usuario
    ORDER BY c.fecha_cita DESC, c.hora_cita ASC;
$$;

CREATE OR REPLACE FUNCTION spObtenerCita(p_id_cita integer)
RETURNS TABLE (
    id_cita integer,
    fecha_cita date,
    hora_cita time,
    id_usuario_cita integer,
    nombre_usuario_cita varchar(100),
    id_usuario_encargado integer,
    nombre_usuario_encargado varchar(100),
    observacion_inicial varchar(200),
    detalle_cita varchar(500),
    estado varchar(20)
)
LANGUAGE sql
AS $$
    SELECT c.id_cita, c.fecha_cita, c.hora_cita,
           c.id_usuario_cita, uc.nombre AS nombre_usuario_cita,
           c.id_usuario_encargado, ue.nombre AS nombre_usuario_encargado,
           c.observacion_inicial, c.detalle_cita, c.estado
    FROM citas c
    INNER JOIN usuario uc ON c.id_usuario_cita = uc.id_usuario
    INNER JOIN usuario ue ON c.id_usuario_encargado = ue.id_usuario
    WHERE c.id_cita = p_id_cita;
$$;

-- =============================================================
-- ERRORES
-- =============================================================

CREATE OR REPLACE PROCEDURE spRegistrarError(
    p_mensaje text,
    p_lugar varchar(50),
    p_fechahora timestamp,
    p_id_usuario integer
)
LANGUAGE sql
AS $$
    INSERT INTO error(mensaje, lugar, fechahora, id_usuario)
    VALUES (p_mensaje, p_lugar, p_fechahora, p_id_usuario);
$$;

-- =============================================================
-- REPORTES
-- =============================================================

CREATE OR REPLACE FUNCTION spReporteActividades(
    p_buscar varchar(100) DEFAULT NULL,
    p_id_ministerio integer DEFAULT NULL,
    p_id_tipo_actividad integer DEFAULT NULL,
    p_fechainicio date DEFAULT NULL,
    p_fechafin date DEFAULT NULL
)
RETURNS TABLE (
    id_actividad integer,
    nombre_actividad varchar(100),
    fecha_ini date,
    fecha_fin date,
    lugar varchar(100),
    hora_ini timestamp,
    hora_fin timestamp,
    id_tipo_actividad integer,
    nombre_tipo varchar(50),
    id_ministerio integer,
    descripcion_ministerio varchar(100),
    observacion_ministerio_actividad varchar(200)
)
LANGUAGE sql
AS $$
    SELECT a.id_actividad, a.nombre_actividad, a.fecha_ini, a.fecha_fin, a.lugar,
           CASE WHEN a.hora_ini IS NULL THEN NULL
                ELSE a.fecha_ini + a.hora_ini END AS hora_ini,
           CASE WHEN a.hora_fin IS NULL THEN NULL
                ELSE COALESCE(a.fecha_fin, a.fecha_ini) + a.hora_fin END AS hora_fin,
           a.id_tipo_actividad, ta.nombre_tipo,
           am.id_ministerio, m.descripcion_ministerio,
           am.observacion AS observacion_ministerio_actividad
    FROM actividad a
    INNER JOIN tipo_actividad ta ON a.id_tipo_actividad = ta.id_tipo_actividad
    LEFT JOIN actividades_ministerio am ON a.id_actividad = am.id_actividad
    LEFT JOIN ministerio m ON am.id_ministerio = m.id_ministerio
    WHERE (
            p_buscar IS NULL OR p_buscar = ''
            OR a.nombre_actividad ILIKE '%' || p_buscar || '%'
            OR a.lugar ILIKE '%' || p_buscar || '%'
            OR m.descripcion_ministerio ILIKE '%' || p_buscar || '%'
            OR ta.nombre_tipo ILIKE '%' || p_buscar || '%'
          )
      AND (p_id_ministerio IS NULL OR am.id_ministerio = p_id_ministerio)
      AND (p_id_tipo_actividad IS NULL OR a.id_tipo_actividad = p_id_tipo_actividad)
      AND (p_fechainicio IS NULL OR a.fecha_ini >= p_fechainicio)
      AND (p_fechafin IS NULL OR a.fecha_ini <= p_fechafin)
    ORDER BY a.fecha_ini, a.hora_ini;
$$;

CREATE OR REPLACE FUNCTION spReporteHorarios(
    p_buscar varchar(100) DEFAULT NULL,
    p_id_ministerio integer DEFAULT NULL,
    p_id_tipo_actividad integer DEFAULT NULL,
    p_fechainicio date DEFAULT NULL,
    p_fechafin date DEFAULT NULL
)
RETURNS TABLE (
    id_actividad integer,
    nombre_actividad varchar(100),
    fecha_ini date,
    fecha_fin date,
    lugar varchar(100),
    hora_ini timestamp,
    hora_fin timestamp,
    id_tipo_actividad integer,
    nombre_tipo varchar(50),
    id_ministerio integer,
    descripcion_ministerio varchar(100),
    observacion_ministerio_actividad varchar(200)
)
LANGUAGE sql
AS $$
    SELECT * FROM spReporteActividades(
        p_buscar, p_id_ministerio, p_id_tipo_actividad, p_fechainicio, p_fechafin
    );
$$;

CREATE OR REPLACE FUNCTION spReportePersonasMinisterio(
    p_buscar varchar(100) DEFAULT NULL,
    p_id_ministerio integer DEFAULT NULL,
    p_estado varchar(20) DEFAULT NULL,
    p_fechainicio date DEFAULT NULL,
    p_fechafin date DEFAULT NULL
)
RETURNS TABLE (
    id_usuario_ministerio integer,
    id_ministerio integer,
    id_usuario integer,
    fecha_ingreso date,
    fecha_salida date,
    estado varchar(20),
    observacion varchar(200),
    nombre varchar(100),
    correo varchar(100),
    rol varchar(20),
    descripcion_ministerio varchar(100)
)
LANGUAGE sql
AS $$
    SELECT um.id_usuario_ministerio, um.id_ministerio, um.id_usuario,
           um.fecha_ingreso, um.fecha_salida, um.estado, um.observacion,
           u.nombre, u.correo, r.descripcion AS rol,
           m.descripcion_ministerio
    FROM usuarios_ministerio um
    INNER JOIN usuario u ON um.id_usuario = u.id_usuario
    INNER JOIN ministerio m ON um.id_ministerio = m.id_ministerio
    INNER JOIN rol r ON u.id_rol = r.id_rol
    WHERE (
            p_buscar IS NULL OR p_buscar = ''
            OR u.nombre ILIKE '%' || p_buscar || '%'
            OR u.correo ILIKE '%' || p_buscar || '%'
            OR m.descripcion_ministerio ILIKE '%' || p_buscar || '%'
          )
      AND (p_id_ministerio IS NULL OR um.id_ministerio = p_id_ministerio)
      AND (p_estado IS NULL OR p_estado = '' OR um.estado = p_estado)
      AND (p_fechainicio IS NULL OR um.fecha_ingreso >= p_fechainicio)
      AND (p_fechafin IS NULL OR um.fecha_ingreso <= p_fechafin)
    ORDER BY m.descripcion_ministerio, u.nombre;
$$;


-- =============================================================
-- CAMPAÑAS
-- =============================================================

CREATE OR REPLACE FUNCTION spListarPlantillasCampana()
RETURNS TABLE (
    codigo varchar(30),
    nombre varchar(50),
    descripcion varchar(200),
    icono varchar(50),
    color_encabezado varchar(20),
    activo boolean
)
LANGUAGE sql
AS $$
    SELECT
        cp.codigo,
        cp.nombre,
        cp.descripcion,
        cp.icono,
        cp.color_encabezado,
        cp.activo
    FROM campana_plantilla cp
    WHERE cp.activo = true
    ORDER BY cp.nombre;
$$;


CREATE OR REPLACE FUNCTION spCrearListaDistribucion(
    p_ids_roles integer[] DEFAULT ARRAY[]::integer[],
    p_ids_ministerios integer[] DEFAULT ARRAY[]::integer[],
    p_todos boolean DEFAULT false
)
RETURNS TABLE (
    id_usuario integer,
    nombre varchar(100),
    correo varchar(100),
    id_rol integer,
    rol varchar(20)
)
LANGUAGE plpgsql
AS $$
BEGIN

    -- Evita que una selección vacía sea interpretada como "todos"
    IF COALESCE(p_todos, false) = false
       AND COALESCE(cardinality(p_ids_roles), 0) = 0
       AND COALESCE(cardinality(p_ids_ministerios), 0) = 0
    THEN
        RAISE EXCEPTION
            'Debe seleccionar al menos un rol, un ministerio o la opción Todos.';
    END IF;

    RETURN QUERY

    SELECT DISTINCT
        u.id_usuario,
        u.nombre,
        u.correo,
        u.id_rol,
        r.descripcion AS rol

    FROM usuario u

    INNER JOIN rol r
        ON r.id_rol = u.id_rol

    WHERE u.estado = 'A'

      -- Filtro por rol
      AND (
            COALESCE(p_todos, false) = true

            OR COALESCE(cardinality(p_ids_roles), 0) = 0

            OR u.id_rol = ANY(
                COALESCE(
                    p_ids_roles,
                    ARRAY[]::integer[]
                )
            )
      )

      -- Filtro por ministerio
      AND (
            COALESCE(p_todos, false) = true

            OR COALESCE(cardinality(p_ids_ministerios), 0) = 0

            OR EXISTS (
                SELECT 1

                FROM usuarios_ministerio um

                WHERE um.id_usuario = u.id_usuario

                  AND um.id_ministerio = ANY(
                      COALESCE(
                          p_ids_ministerios,
                          ARRAY[]::integer[]
                      )
                  )

                  AND um.fecha_salida IS NULL

                  AND um.estado = 'Activo'
            )
      )

    ORDER BY u.nombre;

END;
$$;


CREATE OR REPLACE FUNCTION spCrearCampana(
    p_titulo varchar(150),
    p_asunto varchar(200),
    p_contenido text,
    p_plantilla varchar(30),
    p_id_usuario_creador integer
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_campana integer;
BEGIN

    -- =========================================================
    -- VALIDACIONES
    -- =========================================================

    IF p_titulo IS NULL
       OR btrim(p_titulo) = ''
    THEN
        RAISE EXCEPTION
            'Debe ingresar el título de la campaña.';
    END IF;


    IF p_asunto IS NULL
       OR btrim(p_asunto) = ''
    THEN
        RAISE EXCEPTION
            'Debe ingresar el asunto de la campaña.';
    END IF;


    IF p_contenido IS NULL
       OR btrim(p_contenido) = ''
    THEN
        RAISE EXCEPTION
            'Debe ingresar el contenido de la campaña.';
    END IF;


    IF p_plantilla IS NULL
       OR btrim(p_plantilla) = ''
    THEN
        RAISE EXCEPTION
            'Debe seleccionar una plantilla.';
    END IF;


    -- La plantilla debe existir y estar activa
    IF NOT EXISTS (
        SELECT 1
        FROM campana_plantilla cp
        WHERE cp.codigo = p_plantilla
          AND cp.activo = true
    )
    THEN
        RAISE EXCEPTION
            'La plantilla seleccionada no existe o está inactiva.';
    END IF;


    -- El creador debe existir y estar activo
    IF NOT EXISTS (
        SELECT 1
        FROM usuario u
        WHERE u.id_usuario = p_id_usuario_creador
          AND u.estado = 'A'
    )
    THEN
        RAISE EXCEPTION
            'El usuario creador no existe o está inactivo.';
    END IF;


    -- =========================================================
    -- CREAR CAMPAÑA
    -- =========================================================

    INSERT INTO campana (
        titulo,
        asunto,
        contenido,
        plantilla,
        estado,
        fecha_creacion,
        id_usuario_creador
    )
    VALUES (
        btrim(p_titulo),
        btrim(p_asunto),
        p_contenido,
        p_plantilla,
        'Borrador',
        CURRENT_TIMESTAMP,
        p_id_usuario_creador
    )
    RETURNING id_campana
    INTO v_id_campana;


    RETURN v_id_campana;

END;
$$;


CREATE OR REPLACE PROCEDURE spCrearDestinatariosCampana(
    p_id_campana integer,
    p_ids_roles integer[],
    p_ids_ministerios integer[],
    p_todos boolean
)
LANGUAGE sql
AS $$

    INSERT INTO campana_destinatario (
        id_campana,
        id_usuario,
        nombre_destinatario,
        correo_destinatario,
        estado_envio
    )

    SELECT
        p_id_campana,
        d.id_usuario,
        d.nombre,
        d.correo,
        'Pendiente'

    FROM spCrearListaDistribucion(
        p_ids_roles,
        p_ids_ministerios,
        p_todos
    ) d

    ON CONFLICT (
        id_campana,
        correo_destinatario
    )
    DO NOTHING;

$$;


CREATE OR REPLACE PROCEDURE spActualizarEstadoEnvioCampana(
    p_id_campana_destinatario bigint,
    p_estado varchar(20),
    p_detalle_error text DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN

    -- Este SP solamente debe utilizarse después
    -- de intentar enviar el correo.
    IF p_estado NOT IN ('Enviado', 'Error') THEN
        RAISE EXCEPTION
            'El estado del envío debe ser Enviado o Error.';
    END IF;

    UPDATE campana_destinatario

    SET
        estado_envio = p_estado,

        fecha_envio =
            CASE
                WHEN p_estado = 'Enviado'
                    THEN CURRENT_TIMESTAMP
                ELSE NULL
            END,

        detalle_error =
            CASE
                WHEN p_estado = 'Error'
                    THEN p_detalle_error
                ELSE NULL
            END

    WHERE id_campana_destinatario =
          p_id_campana_destinatario;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'No se encontró el destinatario de la campaña.';
    END IF;

END;
$$;


CREATE OR REPLACE FUNCTION fnLogEnvioCampana()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN

    IF NEW.estado_envio IS DISTINCT FROM OLD.estado_envio
       AND NEW.estado_envio IN ('Enviado', 'Error')
    THEN

        INSERT INTO campana_envio_log (
            id_campana,
            id_usuario,
            nombre_destinatario,
            correo_destinatario,
            asunto,
            contenido,
            estado,
            fecha,
            detalle_error
        )

        SELECT
            NEW.id_campana,
            NEW.id_usuario,
            NEW.nombre_destinatario,
            NEW.correo_destinatario,
            c.asunto,
            c.contenido,
            NEW.estado_envio,
            CURRENT_TIMESTAMP,
            NEW.detalle_error

        FROM campana c

        WHERE c.id_campana = NEW.id_campana;

    END IF;

    RETURN NEW;

END;
$$;

-- =============================================================
-- ACTUALIZAR ESTADO GENERAL DE LA CAMPAÑA
-- =============================================================

CREATE OR REPLACE PROCEDURE spActualizarEstadoCampana(
    p_id_campana integer,
    p_estado varchar(20)
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF p_estado NOT IN (
        'Borrador',
        'Procesando',
        'Enviada',
        'Parcial',
        'Error'
    )
    THEN
        RAISE EXCEPTION
            'Estado de campaña no válido.';
    END IF;


    UPDATE campana

    SET
        estado = p_estado,

        fecha_envio =
            CASE
                WHEN p_estado IN (
                    'Enviada',
                    'Parcial',
                    'Error'
                )
                THEN CURRENT_TIMESTAMP

                ELSE fecha_envio
            END

    WHERE id_campana = p_id_campana;


    IF NOT FOUND THEN
        RAISE EXCEPTION
            'No se encontró la campaña indicada.';
    END IF;

END;
$$;


-- =============================================================
-- OBTENER DESTINATARIOS PENDIENTES
-- =============================================================

CREATE OR REPLACE FUNCTION spListarDestinatariosPendientesCampana(
    p_id_campana integer
)
RETURNS TABLE (
    id_campana_destinatario bigint,
    id_usuario integer,
    nombre_destinatario varchar(100),
    correo_destinatario varchar(100)
)
LANGUAGE sql
AS $$
    SELECT
        cd.id_campana_destinatario,
        cd.id_usuario,
        cd.nombre_destinatario,
        cd.correo_destinatario

    FROM campana_destinatario cd

    WHERE cd.id_campana = p_id_campana
      AND cd.estado_envio = 'Pendiente'

    ORDER BY
        cd.nombre_destinatario,
        cd.id_campana_destinatario;
$$;


-- Permite ejecutar nuevamente el archivo de rutinas
-- sin que falle porque el trigger ya existe.
DROP TRIGGER IF EXISTS trgLogEnvioCampana
ON campana_destinatario;


CREATE TRIGGER trgLogEnvioCampana
AFTER UPDATE OF estado_envio
ON campana_destinatario
FOR EACH ROW
EXECUTE FUNCTION fnLogEnvioCampana();

COMMIT;