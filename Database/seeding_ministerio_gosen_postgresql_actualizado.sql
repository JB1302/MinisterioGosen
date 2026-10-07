-- ============================================================================
-- SEEDING POSTGRESQL - MINISTERIO GOSEN
-- Actualizado para ministerio_gosen_postgresql_base.sql
--
--
-- Credenciales de usuarios nuevos del seeding:
--   Administrador: ministeriogosen@gmail.com / admin123
--   Usuarios de prueba: usuario123
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. VALIDACIONES DE ESTRUCTURA
-- ============================================================================
DO $$
DECLARE
    v_tabla text;
BEGIN
    FOREACH v_tabla IN ARRAY ARRAY[
        'rol', 'usuario', 'error', 'actividad_usuario',
        'actividades_ministerio', 'usuarios_ministerio', 'citas',
        'actividad', 'tipo_actividad', 'ministerio', 'chat_bot_opciones'
    ]
    LOOP
        IF to_regclass('public.' || v_tabla) IS NULL THEN
            RAISE EXCEPTION 'La tabla public.% no existe.', v_tabla;
        END IF;
    END LOOP;
END $$;

-- ============================================================================
-- 2. COMPATIBILIDAD CON LA VERSION FINAL DE ACTIVIDAD
--    El script base suministrado no contiene Estado; el proyecto/rutinas sí.
-- ============================================================================
ALTER TABLE actividad
    ADD COLUMN IF NOT EXISTS estado varchar(20) NOT NULL DEFAULT 'Activo';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_estado_actividad'
          AND conrelid = 'public.actividad'::regclass
    ) THEN
        ALTER TABLE actividad
            ADD CONSTRAINT chk_estado_actividad
            CHECK (estado IN ('Activo', 'Inactivo'));
    END IF;
END $$;

-- ============================================================================
-- 3. LIMPIAR DATOS OPERATIVOS
--    usuario y rol se conservan.
-- ============================================================================
TRUNCATE TABLE
    chat_bot_opciones,
    error,
    actividad_usuario,
    actividades_ministerio,
    usuarios_ministerio,
    citas,
    actividad,
    tipo_actividad,
    ministerio
RESTART IDENTITY;

-- ============================================================================
-- 4. ASEGURAR ROLES: Admin, Usuario, Miembro
-- ============================================================================
INSERT INTO rol (id_rol, descripcion)
VALUES
    (1, 'Admin'),
    (2, 'Usuario'),
    (3, 'Miembro')
ON CONFLICT (id_rol) DO UPDATE
SET descripcion = EXCLUDED.descripcion;

SELECT setval(
    pg_get_serial_sequence('rol', 'id_rol'),
    GREATEST((SELECT COALESCE(MAX(id_rol), 1) FROM rol), 1),
    true
);

-- ============================================================================
-- 5. USUARIOS DEL SEEDING
-- ============================================================================
CREATE TEMP TABLE tmp_usuarios_seed
(
    identificacion       varchar(20)  NOT NULL,
    nombre               varchar(100) NOT NULL,
    correo               varchar(100) NOT NULL,
    contrasena           varchar(255) NOT NULL,
    estado               char(1)      NOT NULL,
    id_rol               integer      NOT NULL,
    usa_contrasena_temp  boolean      NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_usuarios_seed
(
    identificacion,
    nombre,
    correo,
    contrasena,
    estado,
    id_rol,
    usa_contrasena_temp
)
VALUES
('000000000', 'ADMINISTRADOR MINISTERIO GOSE', 'ministeriogosen@gmail.com', '$2a$11$hn4PhTdHwTzvhz0WEuAk.e/YnmhJoWzrj8pi7W3tR//H728t0.cfe', 'A', 1, false),
    ('116700557', 'MARIA FERNANDA FAJARDO TORRES', 'maria.fajardo@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('114560987', 'JONATHAN STEVEN BARRANTES MORA', 'jonathan.barrantes@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('109870654', 'AARON AZOFEIFA SALAZAR', 'aaron.azofeifa@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('112340987', 'YESENIA SALAZAR PEREZ', 'yesenia.salazar@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('116780432', 'CARLOS ANDRES MORA ROJAS', 'carlos.mora@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('120980765', 'ANA LUCIA VARGAS SOLIS', 'ana.vargas@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('107650234', 'JOSE DANIEL CHACON RUIZ', 'jose.chacon@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('115670983', 'DANIELA CASTRO JIMENEZ', 'daniela.castro@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('110980456', 'LUIS FERNANDO BRENES SOTO', 'luis.brenes@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('119870345', 'SOFIA HERNANDEZ ARIAS', 'sofia.hernandez@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('108760543', 'MIGUEL ANGEL ROJAS CAMPOS', 'miguel.rojas@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('117650987', 'VALERIA MONTERO FALLAS', 'valeria.montero@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('113450876', 'GABRIEL NUNEZ ALVARADO', 'gabriel.nunez@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('121340765', 'KATHERINE MORALES VEGA', 'katherine.morales@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('106780912', 'ANDRES SALAS PORRAS', 'andres.salas@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('122450673', 'PAOLA RAMIREZ AGUILAR', 'paola.ramirez@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('105670432', 'ESTEBAN CALDERON LOPEZ', 'esteban.calderon@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('124560981', 'NATALIA SEGURA MENDEZ', 'natalia.segura@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('103450876', 'RICARDO VARGAS ZAMORA', 'ricardo.vargas@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'I', 2, false),
    ('126780453', 'ELENA JIMENEZ CORDERO', 'elena.jimenez@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, true),
    ('125001001', 'MARIANA SOLANO RIVERA', 'mariana.solano@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001002', 'DIEGO ALVARADO CAMPOS', 'diego.alvarado@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001003', 'LAURA PEREZ MONGE', 'laura.perez@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001004', 'FABIAN SOTO VARGAS', 'fabian.soto@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001005', 'GABRIELA QUESADA ARIAS', 'gabriela.quesada@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001006', 'MAURICIO VARGAS HERRERA', 'mauricio.vargas@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001007', 'ADRIANA MORALES ROJAS', 'adriana.morales@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001008', 'JORGE CASTILLO FALLAS', 'jorge.castillo@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001009', 'MONICA ARIAS SANCHEZ', 'monica.arias@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001010', 'PABLO RODRIGUEZ SALAS', 'pablo.rodriguez@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001011', 'SILVIA MENDEZ CAMPOS', 'silvia.mendez@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001012', 'OSCAR CHAVES BRENES', 'oscar.chaves@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001013', 'KARLA VILLALOBOS SEGURA', 'karla.villalobos@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001014', 'EMMANUEL GOMEZ LOPEZ', 'emmanuel.gomez@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001015', 'JULIANA NAVARRO SOLIS', 'juliana.navarro@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001016', 'HECTOR MORA CORDERO', 'hector.mora@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001017', 'TATIANA AGUILAR PEREIRA', 'tatiana.aguilar@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001018', 'ROBERTO CALDERON NUÑEZ', 'roberto.calderon@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001019', 'MELISSA JIMENEZ VARGAS', 'melissa.jimenez@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001020', 'BRAYAN MURILLO FONSECA', 'brayan.murillo@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001021', 'CAMILA LEIVA ZAMORA', 'camila.leiva@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001022', 'SEBASTIAN COTO VEGA', 'sebastian.coto@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001023', 'MARCELA ARCE PANIAGUA', 'marcela.arce@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001024', 'GERARDO ACUÑA RIVAS', 'gerardo.acuna@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001025', 'PATRICIA BARRANTES ARAYA', 'patricia.barrantes@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001026', 'DAVID CAMPOS RETANA', 'david.campos@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001027', 'ELIANA LOPEZ CASTRO', 'eliana.lopez@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001028', 'SAMUEL ROJAS ALPIZAR', 'samuel.rojas@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001029', 'MARTA SANCHEZ PORRAS', 'marta.sanchez@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false),
    ('125001030', 'ISAAC MONGE VALVERDE', 'isaac.monge@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, false);

DO $$
BEGIN
    IF EXISTS (
        SELECT identificacion
        FROM tmp_usuarios_seed
        GROUP BY identificacion
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'Existen identificaciones duplicadas dentro del seeding.';
    END IF;

    IF EXISTS (
        SELECT correo
        FROM tmp_usuarios_seed
        GROUP BY correo
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'Existen correos duplicados dentro del seeding.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM tmp_usuarios_seed s
        LEFT JOIN rol r ON r.id_rol = s.id_rol
        WHERE r.id_rol IS NULL
    ) THEN
        RAISE EXCEPTION 'Uno o más usuarios del seeding utilizan un rol inexistente.';
    END IF;
END $$;

-- Inserta solo usuarios que no coincidan ni por identificación ni por correo.
INSERT INTO usuario
(
    identificacion,
    nombre,
    correo,
    contrasena,
    estado,
    id_rol,
    usa_contrasena_temp
)
SELECT
    s.identificacion,
    s.nombre,
    s.correo,
    s.contrasena,
    s.estado,
    s.id_rol,
    s.usa_contrasena_temp
FROM tmp_usuarios_seed s
WHERE NOT EXISTS (
    SELECT 1
    FROM usuario u
    WHERE u.identificacion = s.identificacion
       OR u.correo = s.correo
);

-- IDs reales de los usuarios que pertenecen al seeding.
CREATE TEMP TABLE tmp_ids_usuarios_seed
(
    id_usuario integer PRIMARY KEY
) ON COMMIT DROP;

INSERT INTO tmp_ids_usuarios_seed (id_usuario)
SELECT DISTINCT u.id_usuario
FROM usuario u
WHERE EXISTS (
    SELECT 1
    FROM tmp_usuarios_seed s
    WHERE s.identificacion = u.identificacion
       OR s.correo = u.correo
);

-- Como las membresías operativas se regeneran desde cero, normalizamos solo
-- usuarios demo no-admin a Usuario (2). El trigger volverá a convertir a
-- Miembro (3) a quienes tengan una membresía activa.
UPDATE usuario u
SET id_rol = 2
FROM tmp_ids_usuarios_seed ids
WHERE ids.id_usuario = u.id_usuario
  AND u.id_rol <> 1;

-- Localizar administrador.
CREATE TEMP TABLE tmp_config_seed
(
    id_admin integer NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_config_seed (id_admin)
SELECT u.id_usuario
FROM usuario u
WHERE u.identificacion = '000000000'
   OR u.correo = 'ministeriogosen@gmail.com'
ORDER BY CASE WHEN u.identificacion = '000000000' THEN 0 ELSE 1 END,
         u.id_usuario
LIMIT 1;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tmp_config_seed) THEN
        RAISE EXCEPTION 'No fue posible localizar o crear el usuario administrador.';
    END IF;
END $$;

-- ============================================================================
-- 6. TIPOS DE ACTIVIDAD
-- ============================================================================
INSERT INTO tipo_actividad (nombre_tipo)
VALUES
    ('Culto'),
    ('Reunion'),
    ('Taller'),
    ('Capacitacion'),
    ('Visita'),
    ('Ayuda social'),
    ('Oracion'),
    ('Servicio comunitario');

-- ============================================================================
-- 7. MINISTERIOS
-- ============================================================================
INSERT INTO ministerio (descripcion_ministerio, observaciones_ministerio)
VALUES
    ('Ministerio de Niños', 'Atencion, enseñanza y actividades para poblacion infantil.'),
    ('Ministerio de Jovenes', 'Formacion, integracion y acompañamiento para jovenes.'),
    ('Ministerio de Mujeres', 'Reuniones, talleres y acompañamiento espiritual para mujeres.'),
    ('Ministerio de Adultos', 'Enseñanza, seguimiento y participacion comunitaria de adultos.'),
    ('Ministerio de Musica', 'Coordinacion musical y apoyo en reuniones y actividades especiales.'),
    ('Ministerio de Ayuda Social', 'Apoyo a familias, visitas y acompañamiento comunitario.'),
    ('Ministerio de Oracion', 'Oracion, acompañamiento espiritual y seguimiento a solicitudes.'),
    ('Ministerio de Evangelismo', 'Actividades de alcance comunitario y evangelismo.'),
    ('Ministerio de Multimedia', 'Apoyo tecnico, sonido, proyeccion y comunicacion.'),
    ('Ministerio de Bienvenida', 'Recibimiento, orientacion y apoyo a visitantes.');

-- ============================================================================
-- 8. USUARIOS POR MINISTERIO
-- ============================================================================
WITH usuarios_demo AS (
    SELECT
        u.id_usuario,
        u.estado,
        row_number() OVER (ORDER BY u.id_usuario) AS rn
    FROM usuario u
    JOIN tmp_ids_usuarios_seed ids ON ids.id_usuario = u.id_usuario
    WHERE u.id_rol <> 1
),
ministerios_demo AS (
    SELECT
        id_ministerio,
        row_number() OVER (ORDER BY id_ministerio) AS rn,
        count(*) OVER () AS total
    FROM ministerio
)
INSERT INTO usuarios_ministerio
(
    id_ministerio,
    id_usuario,
    fecha_ingreso,
    fecha_salida,
    estado,
    observacion
)
SELECT
    m.id_ministerio,
    u.id_usuario,
    current_date - (((u.rn * 7) % 330) + 30)::integer,
    CASE
        WHEN u.rn % 13 = 0
            THEN current_date - (((u.rn * 3) % 45) + 10)::integer
        ELSE NULL
    END,
    CASE WHEN u.rn % 13 = 0 THEN 'Inactivo' ELSE 'Activo' END,
    CASE
        WHEN u.rn % 13 = 0 THEN 'Participación histórica finalizada.'
        ELSE 'Miembro activo del ministerio.'
    END
FROM usuarios_demo u
JOIN ministerios_demo m
  ON m.rn = ((u.rn - 1) % m.total) + 1;

-- Segunda membresía activa para algunos usuarios demo activos.
WITH usuarios_demo AS (
    SELECT
        u.id_usuario,
        row_number() OVER (ORDER BY u.id_usuario) AS rn
    FROM usuario u
    JOIN tmp_ids_usuarios_seed ids ON ids.id_usuario = u.id_usuario
    WHERE u.id_rol <> 1
      AND u.estado = 'A'
),
ministerios_demo AS (
    SELECT
        id_ministerio,
        row_number() OVER (ORDER BY id_ministerio) AS rn,
        count(*) OVER () AS total
    FROM ministerio
),
relaciones AS (
    SELECT
        u.id_usuario,
        u.rn,
        m.id_ministerio
    FROM usuarios_demo u
    JOIN ministerios_demo m
      ON m.rn = ((u.rn + 2) % m.total) + 1
    WHERE u.rn % 4 = 0
)
INSERT INTO usuarios_ministerio
(
    id_ministerio,
    id_usuario,
    fecha_ingreso,
    fecha_salida,
    estado,
    observacion
)
SELECT
    r.id_ministerio,
    r.id_usuario,
    current_date - ((r.rn * 5) % 180)::integer,
    NULL,
    'Activo',
    'Apoyo adicional en actividades del ministerio.'
FROM relaciones r
WHERE NOT EXISTS (
    SELECT 1
    FROM usuarios_ministerio um
    WHERE um.id_usuario = r.id_usuario
      AND um.id_ministerio = r.id_ministerio
      AND um.fecha_salida IS NULL
);

-- ============================================================================
-- 9. ACTIVIDADES Y RELACION CON MINISTERIOS
-- ============================================================================
CREATE TEMP TABLE tmp_actividades_seed
(
    nombre_actividad varchar(100),
    dias_desde_hoy integer,
    dias_duracion integer,
    lugar varchar(100),
    hora_ini time,
    hora_fin time,
    nombre_tipo varchar(50),
    ministerio varchar(100),
    observacion varchar(200),
    estado varchar(20)
) ON COMMIT DROP;

INSERT INTO tmp_actividades_seed
(
    nombre_actividad,
    dias_desde_hoy,
    dias_duracion,
    lugar,
    hora_ini,
    hora_fin,
    nombre_tipo,
    ministerio,
    observacion,
    estado
)
VALUES
('Culto de aniversario', -330, 0, 'Templo principal', '18:00', '20:00', 'Culto', 'Ministerio de Musica', 'Celebración especial de aniversario.', 'Activo'),
    ('Jornada de ayuda comunitaria', -305, 0, 'Centro comunitario', '08:00', '12:00', 'Ayuda social', 'Ministerio de Ayuda Social', 'Entrega de alimentos y artículos de primera necesidad.', 'Activo'),
    ('Taller de liderazgo juvenil', -282, 0, 'Aula principal', '14:00', '17:00', 'Taller', 'Ministerio de Jovenes', 'Formación de líderes juveniles.', 'Activo'),
    ('Encuentro de mujeres', -260, 0, 'Salon multiuso', '15:00', '17:00', 'Reunion', 'Ministerio de Mujeres', 'Encuentro mensual y espacio de convivencia.', 'Activo'),
    ('Capacitacion de sonido', -238, 0, 'Cabina tecnica', '16:00', '18:00', 'Capacitacion', 'Ministerio de Multimedia', 'Capacitación técnica para sonido y proyección.', 'Activo'),
    ('Visita a familias', -215, 0, 'La Fila de Mora', '08:00', '12:00', 'Visita', 'Ministerio de Ayuda Social', 'Visitas programadas a familias de la comunidad.', 'Activo'),
    ('Actividad recreativa infantil', -193, 0, 'Area verde', '09:00', '12:00', 'Servicio comunitario', 'Ministerio de Niños', 'Juegos y actividades recreativas para niños.', 'Activo'),
    ('Noche de oracion', -171, 0, 'Templo principal', '18:00', '20:00', 'Oracion', 'Ministerio de Oracion', 'Actividad congregacional de oración.', 'Activo'),
    ('Salida evangelistica', -148, 0, 'Comunidad cercana', '08:00', '12:00', 'Visita', 'Ministerio de Evangelismo', 'Actividad de alcance comunitario.', 'Activo'),
    ('Reunion de servidores', -126, 0, 'Salon multiuso', '18:00', '20:00', 'Reunion', 'Ministerio de Bienvenida', 'Coordinación de equipos de servicio.', 'Activo'),
    ('Culto juvenil especial', -104, 0, 'Templo principal', '18:00', '20:30', 'Culto', 'Ministerio de Jovenes', 'Culto especial organizado por jóvenes.', 'Activo'),
    ('Taller para padres', -82, 0, 'Aula de niños', '14:00', '16:00', 'Taller', 'Ministerio de Niños', 'Taller de acompañamiento para familias.', 'Activo'),
    ('Campaña de donacion', -61, 1, 'Centro comunitario', '09:00', '15:00', 'Ayuda social', 'Ministerio de Ayuda Social', 'Recolección y clasificación de donaciones.', 'Activo'),
    ('Practica de alabanza', -45, 0, 'Templo principal', '17:00', '19:00', 'Reunion', 'Ministerio de Musica', 'Ensayo general del equipo de música.', 'Activo'),
    ('Taller de apoyo emocional', -31, 0, 'Aula principal', '14:00', '16:30', 'Taller', 'Ministerio de Adultos', 'Taller de acompañamiento familiar.', 'Activo'),
    ('Reunion de intercesion', -18, 0, 'Templo principal', '19:00', '20:30', 'Oracion', 'Ministerio de Oracion', 'Reunión de intercesión.', 'Activo'),
    ('Escuela dominical infantil', -10, 0, 'Aula de niños', '09:00', '10:30', 'Taller', 'Ministerio de Niños', 'Clase dominical para niños.', 'Activo'),
    ('Reunion general de jovenes', -5, 0, 'Salon multiuso', '17:00', '19:00', 'Reunion', 'Ministerio de Jovenes', 'Reunión general de jóvenes.', 'Activo'),

    ('Culto dominical familiar', 2, 0, 'Templo principal', '09:00', '11:00', 'Culto', 'Ministerio de Musica', 'Apoyo musical en culto dominical.', 'Activo'),
    ('Reunion de jovenes', 4, 0, 'Salon multiuso', '17:00', '19:00', 'Reunion', 'Ministerio de Jovenes', 'Reunión semanal de jóvenes.', 'Activo'),
    ('Taller para padres y niños', 7, 0, 'Aula de niños', '14:00', '16:00', 'Taller', 'Ministerio de Niños', 'Taller formativo para familias.', 'Activo'),
    ('Visita comunitaria', 10, 0, 'La Fila de Mora', '08:00', '12:00', 'Visita', 'Ministerio de Ayuda Social', 'Visitas programadas a familias.', 'Activo'),
    ('Capacitacion de servidores', 12, 0, 'Aula principal', '13:00', '16:00', 'Capacitacion', 'Ministerio de Adultos', 'Capacitación general de servidores.', 'Activo'),
    ('Entrega de viveres', 15, 0, 'Centro comunitario', '09:00', '12:00', 'Servicio comunitario', 'Ministerio de Ayuda Social', 'Entrega comunitaria de víveres.', 'Activo'),
    ('Noche especial de oracion', 18, 0, 'Templo principal', '18:30', '20:00', 'Oracion', 'Ministerio de Oracion', 'Noche de oración congregacional.', 'Activo'),
    ('Reunion mensual de mujeres', 20, 0, 'Salon multiuso', '15:00', '17:00', 'Reunion', 'Ministerio de Mujeres', 'Reunión mensual de mujeres.', 'Activo'),
    ('Ensayo de alabanza', 21, 0, 'Templo principal', '16:00', '18:00', 'Reunion', 'Ministerio de Musica', 'Ensayo previo al culto.', 'Activo'),
    ('Taller juvenil de liderazgo', 24, 0, 'Aula principal', '14:00', '17:00', 'Taller', 'Ministerio de Jovenes', 'Taller formativo para jóvenes.', 'Activo'),
    ('Tarde recreativa infantil', 28, 0, 'Area verde', '09:00', '11:30', 'Servicio comunitario', 'Ministerio de Niños', 'Actividad recreativa infantil.', 'Activo'),
    ('Charla de apoyo familiar', 30, 0, 'Salon multiuso', '14:00', '16:00', 'Taller', 'Ministerio de Adultos', 'Charla abierta para familias.', 'Activo'),
    ('Culto de alabanza', 32, 0, 'Templo principal', '18:00', '20:00', 'Culto', 'Ministerio de Musica', 'Actividad de alabanza y adoración.', 'Activo'),
    ('Jornada de limpieza comunitaria', 35, 0, 'Comunidad La Fila', '08:00', '11:00', 'Servicio comunitario', 'Ministerio de Evangelismo', 'Servicio comunitario local.', 'Activo'),
    ('Reunion de equipo multimedia', 36, 0, 'Cabina tecnica', '18:00', '19:30', 'Reunion', 'Ministerio de Multimedia', 'Coordinación técnica semanal.', 'Activo'),
    ('Capacitacion de bienvenida', 38, 0, 'Recepcion', '10:00', '12:00', 'Capacitacion', 'Ministerio de Bienvenida', 'Capacitación para equipo de bienvenida.', 'Activo'),
    ('Encuentro de parejas', 42, 0, 'Salon multiuso', '18:00', '20:00', 'Taller', 'Ministerio de Adultos', 'Actividad de apoyo familiar.', 'Activo'),
    ('Campaña solidaria', 45, 1, 'Centro comunitario', '09:00', '15:00', 'Ayuda social', 'Ministerio de Ayuda Social', 'Campaña solidaria para la comunidad.', 'Activo'),
    ('Planificacion de evangelismo', 47, 0, 'Aula principal', '18:00', '20:00', 'Reunion', 'Ministerio de Evangelismo', 'Planificación de actividades comunitarias.', 'Activo'),
    ('Practica de sonido y proyeccion', 49, 0, 'Templo principal', '17:00', '19:00', 'Capacitacion', 'Ministerio de Multimedia', 'Práctica de sonido y proyección.', 'Activo'),
    ('Devocional de mujeres', 52, 0, 'Salon multiuso', '16:00', '18:00', 'Oracion', 'Ministerio de Mujeres', 'Devocional y seguimiento espiritual.', 'Activo'),
    ('Convivio juvenil', 55, 0, 'Area verde', '15:00', '18:00', 'Servicio comunitario', 'Ministerio de Jovenes', 'Convivio e integración de jóvenes.', 'Activo'),
    ('Taller de acompañamiento familiar', 58, 0, 'Aula principal', '14:00', '16:30', 'Taller', 'Ministerio de Adultos', 'Taller de acompañamiento familiar.', 'Activo'),
    ('Visita de seguimiento espiritual', 60, 0, 'Comunidad La Fila', '09:00', '12:00', 'Visita', 'Ministerio de Oracion', 'Seguimiento a solicitudes de oración.', 'Activo'),
    ('Reunion de coordinadores', 62, 0, 'Templo principal', '18:30', '20:30', 'Reunion', 'Ministerio de Bienvenida', 'Coordinación general de servidores.', 'Activo'),
    ('Culto juvenil de cierre', 65, 0, 'Templo principal', '18:00', '20:30', 'Culto', 'Ministerio de Jovenes', 'Culto especial organizado por jóvenes.', 'Activo'),
    ('Clase de musica basica', 68, 0, 'Salon de musica', '14:00', '16:00', 'Capacitacion', 'Ministerio de Musica', 'Formación musical básica.', 'Activo'),
    ('Taller de redes sociales', 78, 0, 'Aula multimedia', '15:00', '17:00', 'Capacitacion', 'Ministerio de Multimedia', 'Capacitación de comunicación digital.', 'Activo'),
    ('Actividad cancelada de prueba', 85, 0, 'Salon multiuso', '14:00', '16:00', 'Reunion', 'Ministerio de Adultos', 'Registro inactivo para pruebas de interfaz.', 'Inactivo');

INSERT INTO actividad
(
    nombre_actividad,
    fecha_ini,
    fecha_fin,
    lugar,
    hora_ini,
    hora_fin,
    id_tipo_actividad,
    estado
)
SELECT
    s.nombre_actividad,
    current_date + s.dias_desde_hoy,
    current_date + s.dias_desde_hoy + s.dias_duracion,
    s.lugar,
    s.hora_ini,
    s.hora_fin,
    ta.id_tipo_actividad,
    s.estado
FROM tmp_actividades_seed s
JOIN tipo_actividad ta ON ta.nombre_tipo = s.nombre_tipo;

INSERT INTO actividades_ministerio
(
    id_actividad,
    id_ministerio,
    fecha,
    observacion
)
SELECT
    a.id_actividad,
    m.id_ministerio,
    a.fecha_ini,
    s.observacion
FROM tmp_actividades_seed s
JOIN actividad a ON a.nombre_actividad = s.nombre_actividad
JOIN ministerio m ON m.descripcion_ministerio = s.ministerio;

-- ============================================================================
-- 10. PARTICIPACION DE USUARIOS EN ACTIVIDADES
-- ============================================================================
WITH actividades_demo AS (
    SELECT
        id_actividad,
        fecha_ini,
        hora_ini,
        row_number() OVER (ORDER BY id_actividad) AS rn
    FROM actividad
),
usuarios_demo AS (
    SELECT
        u.id_usuario,
        row_number() OVER (ORDER BY u.id_usuario) AS rn,
        count(*) OVER () AS total
    FROM usuario u
    JOIN tmp_ids_usuarios_seed ids ON ids.id_usuario = u.id_usuario
    WHERE u.id_rol <> 1
      AND u.estado = 'A'
)
INSERT INTO actividad_usuario
(
    id_actividad,
    id_usuario,
    fecha,
    hora
)
SELECT DISTINCT
    a.id_actividad,
    u.id_usuario,
    a.fecha_ini,
    a.hora_ini
FROM actividades_demo a
JOIN usuarios_demo u
  ON u.rn = ((a.rn * 2 - 1) % u.total) + 1
  OR u.rn = ((a.rn * 2 + 7) % u.total) + 1
  OR u.rn = ((a.rn * 2 + 15) % u.total) + 1;

-- ============================================================================
-- 11. CITAS
-- ============================================================================
WITH usuarios_demo AS (
    SELECT
        u.id_usuario,
        row_number() OVER (ORDER BY u.id_usuario) AS rn,
        count(*) OVER () AS total
    FROM usuario u
    JOIN tmp_ids_usuarios_seed ids ON ids.id_usuario = u.id_usuario
    WHERE u.id_rol <> 1
      AND u.estado = 'A'
),
numeros AS (
    SELECT generate_series(1, 40)::integer AS n
),
datos_citas AS (
    SELECT
        n.n AS rn,
        uc.id_usuario AS id_usuario_cita,
        CASE
            WHEN n.n % 4 = 0 THEN (SELECT id_admin FROM tmp_config_seed LIMIT 1)
            ELSE ue.id_usuario
        END AS id_usuario_encargado,
        CASE
            WHEN n.n <= 24 THEN current_date - (n.n * 4)
            ELSE current_date + ((n.n - 24) * 2)
        END AS fecha_cita,
        (time '08:00:00' + (((n.n - 1) % 10) * interval '1 hour'))::time(0) AS hora_cita,
        CASE WHEN n.n <= 24 THEN 'Atendida' ELSE 'Pendiente' END AS estado
    FROM numeros n
    JOIN usuarios_demo uc ON uc.rn = ((n.n - 1) % uc.total) + 1
    JOIN usuarios_demo ue ON ue.rn = ((n.n + 6) % ue.total) + 1
)
INSERT INTO citas
(
    fecha_cita,
    hora_cita,
    id_usuario_cita,
    id_usuario_encargado,
    observacion_inicial,
    detalle_cita,
    estado
)
SELECT
    d.fecha_cita,
    d.hora_cita,
    d.id_usuario_cita,
    d.id_usuario_encargado,
    CASE d.rn % 6
        WHEN 0 THEN 'Solicitud de apoyo familiar.'
        WHEN 1 THEN 'Consulta sobre participación en un ministerio.'
        WHEN 2 THEN 'Solicitud de acompañamiento espiritual.'
        WHEN 3 THEN 'Consulta sobre actividades disponibles.'
        WHEN 4 THEN 'Solicitud de orientación general.'
        ELSE 'Solicitud de seguimiento personal.'
    END,
    CASE
        WHEN d.estado = 'Atendida'
            THEN 'Cita atendida. Se registró seguimiento y observaciones.'
        ELSE 'Cita pendiente de atención y confirmación administrativa.'
    END,
    d.estado
FROM datos_citas d;

-- ============================================================================
-- 12. ERRORES DE EJEMPLO
-- ============================================================================
INSERT INTO error (mensaje, lugar, fechahora, id_usuario)
VALUES
    ('Intento de acceso con contraseña incorrecta.', 'Home/IniciarSesion', current_timestamp - interval '5 days', (SELECT id_admin FROM tmp_config_seed LIMIT 1)),
    ('Validacion de formulario incompleta.', 'Usuario/Crear', current_timestamp - interval '4 days', (SELECT id_admin FROM tmp_config_seed LIMIT 1)),
    ('Error controlado al consultar citas.', 'Citas/Listar', current_timestamp - interval '3 days', (SELECT id_admin FROM tmp_config_seed LIMIT 1)),
    ('Parametro requerido no recibido.', 'Actividad/Crear', current_timestamp - interval '2 days', (SELECT id_admin FROM tmp_config_seed LIMIT 1)),
    ('Consulta sin resultados disponibles.', 'Reportes/Index', current_timestamp - interval '1 day', (SELECT id_admin FROM tmp_config_seed LIMIT 1));

-- ============================================================================
-- 13. CHATBOT
-- ============================================================================
DO $$
DECLARE
    v_id_info integer;
    v_id_ministerios integer;
    v_id_actividades integer;
    v_id_citas integer;
    v_id_horarios integer;
    v_id_contacto integer;
    v_id_usuario_acceso integer;
    v_id_ubicacion integer;
    v_id_agendar integer;
BEGIN
    INSERT INTO chat_bot_opciones (texto_opcion, respuesta, id_opcion_padre, orden, activo)
    VALUES ('Informacion general', 'Seleccione la informacion que desea consultar.', NULL, 1, true)
    RETURNING id_opcion INTO v_id_info;

    INSERT INTO chat_bot_opciones (texto_opcion, respuesta, id_opcion_padre, orden, activo)
    VALUES ('Ministerios', 'Seleccione el ministerio sobre el que desea informacion.', NULL, 2, true)
    RETURNING id_opcion INTO v_id_ministerios;

    INSERT INTO chat_bot_opciones (texto_opcion, respuesta, id_opcion_padre, orden, activo)
    VALUES ('Actividades', 'Seleccione una opcion relacionada con actividades.', NULL, 3, true)
    RETURNING id_opcion INTO v_id_actividades;

    INSERT INTO chat_bot_opciones (texto_opcion, respuesta, id_opcion_padre, orden, activo)
    VALUES ('Citas', 'Seleccione una opcion relacionada con citas.', NULL, 4, true)
    RETURNING id_opcion INTO v_id_citas;

    INSERT INTO chat_bot_opciones (texto_opcion, respuesta, id_opcion_padre, orden, activo)
    VALUES ('Horarios', 'Seleccione el horario que desea consultar.', NULL, 5, true)
    RETURNING id_opcion INTO v_id_horarios;

    INSERT INTO chat_bot_opciones (texto_opcion, respuesta, id_opcion_padre, orden, activo)
    VALUES ('Contacto', 'Seleccione el medio por el cual desea comunicarse.', NULL, 6, true)
    RETURNING id_opcion INTO v_id_contacto;

    INSERT INTO chat_bot_opciones (texto_opcion, respuesta, id_opcion_padre, orden, activo)
    VALUES ('Usuario y acceso', 'Seleccione una opcion relacionada con su usuario.', NULL, 7, true)
    RETURNING id_opcion INTO v_id_usuario_acceso;

    INSERT INTO chat_bot_opciones (texto_opcion, respuesta, id_opcion_padre, orden, activo)
    VALUES
        ('Que es Ministerio Gosen', 'Ministerio Gosen brinda acompañamiento espiritual, actividades comunitarias y apoyo a familias.', v_id_info, 1, true),
        ('Quien puede usar el sistema', 'El sistema puede ser usado por usuarios registrados y administradores autorizados.', v_id_info, 2, true),
        ('Ubicacion', 'Seleccione la informacion de ubicacion que desea consultar.', v_id_info, 3, true);

    SELECT id_opcion INTO v_id_ubicacion
    FROM chat_bot_opciones
    WHERE texto_opcion = 'Ubicacion'
      AND id_opcion_padre = v_id_info
    LIMIT 1;

    INSERT INTO chat_bot_opciones (texto_opcion, respuesta, id_opcion_padre, orden, activo)
    VALUES
        ('Direccion', 'El Ministerio Gosen se ubica en La Fila de Mora, Puriscal.', v_id_ubicacion, 1, true),
        ('Como llegar', 'Solicite indicaciones a la administracion o revise la ubicacion oficial compartida.', v_id_ubicacion, 2, true),
        ('Ver ministerios disponibles', 'Puede consultar los ministerios desde la opcion Ministerios del menu principal.', v_id_ministerios, 1, true),
        ('Participar en un ministerio', 'Comuniquese con la administracion o consulte el ministerio de su interes.', v_id_ministerios, 2, true),
        ('Ministerio de Niños', 'Realiza actividades formativas y recreativas para niños.', v_id_ministerios, 3, true),
        ('Ministerio de Jovenes', 'Promueve reuniones, talleres y actividades para jovenes.', v_id_ministerios, 4, true),
        ('Ministerio de Ayuda Social', 'Organiza visitas, entregas y apoyo comunitario.', v_id_ministerios, 5, true),
        ('Ministerio de Oracion', 'Brinda acompañamiento espiritual y seguimiento a solicitudes.', v_id_ministerios, 6, true),
        ('Proximas actividades', 'Las actividades disponibles se consultan en la seccion Actividades.', v_id_actividades, 1, true),
        ('Inscribirme en una actividad', 'Revise la actividad y comuniquese con la administracion para confirmar participacion.', v_id_actividades, 2, true),
        ('Tipos de actividades', 'El sistema registra cultos, reuniones, talleres, visitas y servicio comunitario.', v_id_actividades, 3, true);

    INSERT INTO chat_bot_opciones (texto_opcion, respuesta, id_opcion_padre, orden, activo)
    VALUES ('Agendar una cita', 'Ingrese a Agendar Cita, complete la informacion solicitada y espere confirmacion.', v_id_citas, 1, true)
    RETURNING id_opcion INTO v_id_agendar;

    INSERT INTO chat_bot_opciones (texto_opcion, respuesta, id_opcion_padre, orden, activo)
    VALUES
        ('Consultar una cita', 'Puede revisar sus citas desde la seccion Citas o solicitar apoyo a la administracion.', v_id_citas, 2, true),
        ('Cancelar una cita', 'Para cancelar una cita, comuniquese con la administracion con anticipacion.', v_id_citas, 3, true),
        ('Datos necesarios', 'Para agendar se requiere nombre, motivo de cita y disponibilidad de fecha.', v_id_agendar, 1, true),
        ('Confirmacion de cita', 'La cita queda sujeta a revision y confirmacion de la administracion.', v_id_agendar, 2, true),
        ('Horario de atencion', 'El horario de atencion depende de la disponibilidad de la administracion.', v_id_horarios, 1, true),
        ('Horario de actividades', 'Los horarios varian segun el ministerio y la programacion semanal.', v_id_horarios, 2, true),
        ('Atencion en feriados', 'La atencion en feriados depende de la programacion oficial.', v_id_horarios, 3, true),
        ('Telefono', 'Puede comunicarse con la administracion al numero oficial del Ministerio Gosen.', v_id_contacto, 1, true),
        ('Correo electronico', 'Puede escribir al correo ministeriogosen@gmail.com.', v_id_contacto, 2, true),
        ('Solicitar ayuda', 'Para solicitar ayuda, registre una cita o comuniquese con la administracion.', v_id_contacto, 3, true),
        ('Cambiar contraseña', 'Ingrese a Configuracion y actualice su contraseña desde su perfil.', v_id_usuario_acceso, 1, true),
        ('Actualizar mi perfil', 'Ingrese a Configuracion para actualizar su informacion personal.', v_id_usuario_acceso, 2, true),
        ('No puedo ingresar', 'Solicite apoyo a la administracion para revisar su usuario.', v_id_usuario_acceso, 3, true);
END $$;

-- ============================================================================
-- 14. AJUSTAR SECUENCIAS
-- ============================================================================
SELECT setval(pg_get_serial_sequence('usuario','id_usuario'), COALESCE((SELECT MAX(id_usuario) FROM usuario), 1), true);
SELECT setval(pg_get_serial_sequence('ministerio','id_ministerio'), COALESCE((SELECT MAX(id_ministerio) FROM ministerio), 1), true);
SELECT setval(pg_get_serial_sequence('tipo_actividad','id_tipo_actividad'), COALESCE((SELECT MAX(id_tipo_actividad) FROM tipo_actividad), 1), true);
SELECT setval(pg_get_serial_sequence('actividad','id_actividad'), COALESCE((SELECT MAX(id_actividad) FROM actividad), 1), true);
SELECT setval(pg_get_serial_sequence('actividad_usuario','id_actividad_usuario'), COALESCE((SELECT MAX(id_actividad_usuario) FROM actividad_usuario), 1), true);
SELECT setval(pg_get_serial_sequence('actividades_ministerio','id_minis_actividad'), COALESCE((SELECT MAX(id_minis_actividad) FROM actividades_ministerio), 1), true);
SELECT setval(pg_get_serial_sequence('usuarios_ministerio','id_usuario_ministerio'), COALESCE((SELECT MAX(id_usuario_ministerio) FROM usuarios_ministerio), 1), true);
SELECT setval(pg_get_serial_sequence('citas','id_cita'), COALESCE((SELECT MAX(id_cita) FROM citas), 1), true);
SELECT setval(pg_get_serial_sequence('error','consecutivo'), COALESCE((SELECT MAX(consecutivo) FROM error), 1), true);
SELECT setval(pg_get_serial_sequence('chat_bot_opciones','id_opcion'), COALESCE((SELECT MAX(id_opcion) FROM chat_bot_opciones), 1), true);

COMMIT;

-- ============================================================================
-- 15. campania_plantilla
-- ============================================================================

-- ============================================================================
-- 14. PLANTILLAS DE CAMPAÑA
-- ============================================================================

INSERT INTO campana_plantilla (
    codigo,
    nombre,
    descripcion,
    icono,
    color_encabezado,
    activo
)
VALUES
(
    'General',
    'General',
    'Comunicaciones generales del Ministerio.',
    'bi-envelope-paper-fill',
    '#064442',
    true
),
(
    'Informativa',
    'Informativa',
    'Noticias, avisos y comunicados.',
    'bi-info-circle-fill',
    '#235c77',
    true
),
(
    'Recordatorio',
    'Recordatorio',
    'Reuniones, actividades y fechas importantes.',
    'bi-bell-fill',
    '#765720',
    true
)
ON CONFLICT (codigo) DO UPDATE
SET
    nombre = EXCLUDED.nombre,
    descripcion = EXCLUDED.descripcion,
    icono = EXCLUDED.icono,
    color_encabezado = EXCLUDED.color_encabezado,
    activo = EXCLUDED.activo;

-- ============================================================================
-- 16. VALIDACION RAPIDA
-- ============================================================================
SELECT 'rol' AS tabla, COUNT(*) AS total FROM rol
UNION ALL SELECT 'usuario', COUNT(*) FROM usuario
UNION ALL SELECT 'ministerio', COUNT(*) FROM ministerio
UNION ALL SELECT 'tipo_actividad', COUNT(*) FROM tipo_actividad
UNION ALL SELECT 'actividad', COUNT(*) FROM actividad
UNION ALL SELECT 'actividad_usuario', COUNT(*) FROM actividad_usuario
UNION ALL SELECT 'actividades_ministerio', COUNT(*) FROM actividades_ministerio
UNION ALL SELECT 'usuarios_ministerio', COUNT(*) FROM usuarios_ministerio
UNION ALL SELECT 'citas', COUNT(*) FROM citas
UNION ALL SELECT 'error', COUNT(*) FROM error
UNION ALL SELECT 'chat_bot_opciones', COUNT(*) FROM chat_bot_opciones
ORDER BY tabla;

SELECT estado, COUNT(*) AS total
FROM citas
GROUP BY estado
ORDER BY estado;

SELECT estado, COUNT(*) AS total
FROM actividad
GROUP BY estado
ORDER BY estado;

SELECT r.descripcion AS rol, COUNT(*) AS total
FROM usuario u
JOIN rol r ON r.id_rol = u.id_rol
GROUP BY r.descripcion
ORDER BY r.descripcion;

