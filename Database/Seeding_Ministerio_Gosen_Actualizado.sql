USE [ministerio_gosen];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ============================================================================
   SEEDING COMPLETO Y SEGURO - MINISTERIO GOSEN
   Compatible con DB_Ministerio_Gosen(5).sql

   COMPORTAMIENTO
   - Conserva todos los registros existentes de dbo.Usuario.
   - No reinicia el IDENTITY de dbo.Usuario ni de dbo.Rol.
   - Inserta solamente los usuarios ficticios que todavía no existan.
   - Si coincide la identificación o el correo, conserva el usuario actual.
   - Las contraseñas de los usuarios nuevos se almacenan con BCrypt.
   - Limpia y vuelve a poblar las tablas operativas y de demostración.
   - Genera datos históricos y futuros útiles para Dashboard y Reportes.
   - Respeta Citas.Estado = Pendiente/Atendida.
   - Respeta el horario de citas de 08:00 a 17:00.
   - Maneja Actividad.Estado = Activo/Inactivo.

   CREDENCIALES DE LOS USUARIOS NUEVOS
   - Administrador: ministeriogosen@gmail.com / admin123
   - Usuarios de prueba: usuario123
   ============================================================================ */

BEGIN TRY
    BEGIN TRANSACTION;

    /* ============================================================
       1. VALIDAR TABLAS PRINCIPALES
       ============================================================ */

    IF OBJECT_ID('dbo.Rol', 'U') IS NULL
        THROW 50001, 'La tabla dbo.Rol no existe.', 1;

    IF OBJECT_ID('dbo.Usuario', 'U') IS NULL
        THROW 50002, 'La tabla dbo.Usuario no existe.', 1;

    IF OBJECT_ID('dbo.Error', 'U') IS NULL
        THROW 50003, 'La tabla dbo.Error no existe.', 1;

    IF OBJECT_ID('dbo.Actividad_Usuario', 'U') IS NULL
        THROW 50004, 'La tabla dbo.Actividad_Usuario no existe.', 1;

    IF OBJECT_ID('dbo.Actividades_Ministerio', 'U') IS NULL
        THROW 50005, 'La tabla dbo.Actividades_Ministerio no existe.', 1;

    IF OBJECT_ID('dbo.Usuarios_Ministerio', 'U') IS NULL
        THROW 50006, 'La tabla dbo.Usuarios_Ministerio no existe.', 1;

    IF OBJECT_ID('dbo.Citas', 'U') IS NULL
        THROW 50007, 'La tabla dbo.Citas no existe.', 1;

    IF OBJECT_ID('dbo.Actividad', 'U') IS NULL
        THROW 50008, 'La tabla dbo.Actividad no existe.', 1;

    IF OBJECT_ID('dbo.Tipo_Actividad', 'U') IS NULL
        THROW 50009, 'La tabla dbo.Tipo_Actividad no existe.', 1;

    IF OBJECT_ID('dbo.Ministerio', 'U') IS NULL
        THROW 50010, 'La tabla dbo.Ministerio no existe.', 1;

    /* ============================================================
       2. ASEGURAR TABLA DEL CHATBOT
       ============================================================ */

    IF OBJECT_ID('dbo.Chat_Bot_Opciones', 'U') IS NULL
    BEGIN
        CREATE TABLE dbo.Chat_Bot_Opciones
        (
            Id_Opcion INT IDENTITY(1,1) PRIMARY KEY,
            Texto_Opcion NVARCHAR(200) NOT NULL,
            Respuesta VARCHAR(200) NULL,
            Id_Opcion_Padre INT NULL,
            Orden INT NOT NULL DEFAULT 1,
            Activo BIT NOT NULL DEFAULT 1,
            CONSTRAINT FK_Opcion_Padre
                FOREIGN KEY (Id_Opcion_Padre)
                REFERENCES dbo.Chat_Bot_Opciones (Id_Opcion)
        );
    END;

    /* ============================================================
       2.1 COMPATIBILIDAD CON LA VERSION FINAL DE ACTIVIDAD
       ============================================================ */

    IF COL_LENGTH('dbo.Actividad', 'Estado') IS NULL
    BEGIN
        ALTER TABLE dbo.Actividad
        ADD Estado VARCHAR(20) NOT NULL
            CONSTRAINT DF_Actividad_Estado DEFAULT ('Activo');
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.check_constraints
        WHERE name = 'chk_estado_actividad'
          AND parent_object_id = OBJECT_ID('dbo.Actividad')
    )
    BEGIN
        ALTER TABLE dbo.Actividad WITH CHECK
        ADD CONSTRAINT chk_estado_actividad
            CHECK (Estado IN ('Activo', 'Inactivo'));

        ALTER TABLE dbo.Actividad
        CHECK CONSTRAINT chk_estado_actividad;
    END;

    /* ============================================================
       3. LIMPIAR DATOS OPERATIVOS

       dbo.Usuario y dbo.Rol se conservan completamente.
       ============================================================ */

    DELETE FROM dbo.Chat_Bot_Opciones;
    DELETE FROM dbo.Error;
    DELETE FROM dbo.Actividad_Usuario;
    DELETE FROM dbo.Actividades_Ministerio;
    DELETE FROM dbo.Usuarios_Ministerio;
    DELETE FROM dbo.Citas;
    DELETE FROM dbo.Actividad;
    DELETE FROM dbo.Tipo_Actividad;
    DELETE FROM dbo.Ministerio;

    DBCC CHECKIDENT ('dbo.Chat_Bot_Opciones', RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT ('dbo.Error', RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT ('dbo.Actividad_Usuario', RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT ('dbo.Actividades_Ministerio', RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT ('dbo.Usuarios_Ministerio', RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT ('dbo.Citas', RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT ('dbo.Actividad', RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT ('dbo.Tipo_Actividad', RESEED, 0) WITH NO_INFOMSGS;
    DBCC CHECKIDENT ('dbo.Ministerio', RESEED, 0) WITH NO_INFOMSGS;

    /* ============================================================
       4. ASEGURAR ROLES Y USUARIOS

       Los roles existentes se conservan.
       Solo se insertan los Id_Rol que no existan.
       ============================================================ */

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Rol
        WHERE Id_Rol = 1
    )
    OR NOT EXISTS
    (
        SELECT 1
        FROM dbo.Rol
        WHERE Id_Rol = 2
    )
    BEGIN
        SET IDENTITY_INSERT dbo.Rol ON;

        INSERT INTO dbo.Rol
        (
            Id_Rol,
            Descripcion
        )
        SELECT
            RolesSeed.Id_Rol,
            RolesSeed.Descripcion
        FROM
        (
            VALUES
                (1, 'Admin'),
                (2, 'Usuario')
        ) AS RolesSeed
        (
            Id_Rol,
            Descripcion
        )
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.Rol AS R
            WHERE R.Id_Rol = RolesSeed.Id_Rol
        );

        SET IDENTITY_INSERT dbo.Rol OFF;
    END;

    /* ============================================================
       USUARIOS DEL SEEDING
       ============================================================ */

    DECLARE @UsuariosSeed TABLE
    (
        Identificacion    VARCHAR(30)   NOT NULL,
        Nombre            NVARCHAR(150) NOT NULL,
        Correo            VARCHAR(150)  NOT NULL,
        Contrasena        VARCHAR(200)  NOT NULL,
        Estado            CHAR(1)       NOT NULL,
        Id_Rol            INT           NOT NULL,
        UsaContrasenaTemp BIT           NOT NULL
    );

    INSERT INTO @UsuariosSeed
    (
        Identificacion,
        Nombre,
        Correo,
        Contrasena,
        Estado,
        Id_Rol,
        UsaContrasenaTemp
    )
    VALUES
    ('000000000', N'ADMINISTRADOR MINISTERIO GOSEN', 'ministeriogosen@gmail.com', '$2a$11$hn4PhTdHwTzvhz0WEuAk.e/YnmhJoWzrj8pi7W3tR//H728t0.cfe', 'A', 1, 0),
    ('116700557', N'MARIA FERNANDA FAJARDO TORRES', 'maria.fajardo@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('114560987', N'JONATHAN STEVEN BARRANTES MORA', 'jonathan.barrantes@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('109870654', N'AARON AZOFEIFA SALAZAR', 'aaron.azofeifa@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('112340987', N'YESENIA SALAZAR PEREZ', 'yesenia.salazar@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('116780432', N'CARLOS ANDRES MORA ROJAS', 'carlos.mora@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('120980765', N'ANA LUCIA VARGAS SOLIS', 'ana.vargas@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('107650234', N'JOSE DANIEL CHACON RUIZ', 'jose.chacon@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('115670983', N'DANIELA CASTRO JIMENEZ', 'daniela.castro@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('110980456', N'LUIS FERNANDO BRENES SOTO', 'luis.brenes@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('119870345', N'SOFIA HERNANDEZ ARIAS', 'sofia.hernandez@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('108760543', N'MIGUEL ANGEL ROJAS CAMPOS', 'miguel.rojas@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('117650987', N'VALERIA MONTERO FALLAS', 'valeria.montero@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('113450876', N'GABRIEL NUNEZ ALVARADO', 'gabriel.nunez@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('121340765', N'KATHERINE MORALES VEGA', 'katherine.morales@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('106780912', N'ANDRES SALAS PORRAS', 'andres.salas@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('122450673', N'PAOLA RAMIREZ AGUILAR', 'paola.ramirez@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('105670432', N'ESTEBAN CALDERON LOPEZ', 'esteban.calderon@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('124560981', N'NATALIA SEGURA MENDEZ', 'natalia.segura@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('103450876', N'RICARDO VARGAS ZAMORA', 'ricardo.vargas@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'I', 2, 0),
    ('126780453', N'ELENA JIMENEZ CORDERO', 'elena.jimenez@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 1),
    ('125001001', N'MARIANA SOLANO RIVERA', 'mariana.solano@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001002', N'DIEGO ALVARADO CAMPOS', 'diego.alvarado@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001003', N'LAURA PEREZ MONGE', 'laura.perez@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001004', N'FABIAN SOTO VARGAS', 'fabian.soto@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001005', N'GABRIELA QUESADA ARIAS', 'gabriela.quesada@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001006', N'MAURICIO VARGAS HERRERA', 'mauricio.vargas@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001007', N'ADRIANA MORALES ROJAS', 'adriana.morales@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001008', N'JORGE CASTILLO FALLAS', 'jorge.castillo@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001009', N'MONICA ARIAS SANCHEZ', 'monica.arias@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001010', N'PABLO RODRIGUEZ SALAS', 'pablo.rodriguez@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001011', N'SILVIA MENDEZ CAMPOS', 'silvia.mendez@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001012', N'OSCAR CHAVES BRENES', 'oscar.chaves@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001013', N'KARLA VILLALOBOS SEGURA', 'karla.villalobos@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001014', N'EMMANUEL GOMEZ LOPEZ', 'emmanuel.gomez@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001015', N'JULIANA NAVARRO SOLIS', 'juliana.navarro@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001016', N'HECTOR MORA CORDERO', 'hector.mora@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001017', N'TATIANA AGUILAR PEREIRA', 'tatiana.aguilar@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001018', N'ROBERTO CALDERON NUÑEZ', 'roberto.calderon@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001019', N'MELISSA JIMENEZ VARGAS', 'melissa.jimenez@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001020', N'BRAYAN MURILLO FONSECA', 'brayan.murillo@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001021', N'CAMILA LEIVA ZAMORA', 'camila.leiva@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001022', N'SEBASTIAN COTO VEGA', 'sebastian.coto@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001023', N'MARCELA ARCE PANIAGUA', 'marcela.arce@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001024', N'GERARDO ACUÑA RIVAS', 'gerardo.acuna@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001025', N'PATRICIA BARRANTES ARAYA', 'patricia.barrantes@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001026', N'DAVID CAMPOS RETANA', 'david.campos@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001027', N'ELIANA LOPEZ CASTRO', 'eliana.lopez@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001028', N'SAMUEL ROJAS ALPIZAR', 'samuel.rojas@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001029', N'MARTA SANCHEZ PORRAS', 'marta.sanchez@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0),
    ('125001030', N'ISAAC MONGE VALVERDE', 'isaac.monge@gosen.local', '$2a$11$z5yfPT1sPU9F5rQhy6BpHOoJFXiEwZ4ExsyMA7usJrMBqlWjPd1NS', 'A', 2, 0);

    /* ============================================================
       VALIDAR EL CONTENIDO DEL SEEDING
       ============================================================ */

    IF EXISTS
    (
        SELECT Identificacion
        FROM @UsuariosSeed
        GROUP BY Identificacion
        HAVING COUNT(*) > 1
    )
    BEGIN
        THROW 50003,
              'Existen identificaciones duplicadas dentro del seeding.',
              1;
    END;

    IF EXISTS
    (
        SELECT Correo
        FROM @UsuariosSeed
        GROUP BY Correo
        HAVING COUNT(*) > 1
    )
    BEGIN
        THROW 50004,
              'Existen correos duplicados dentro del seeding.',
              1;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM @UsuariosSeed AS S
        LEFT JOIN dbo.Rol AS R
            ON R.Id_Rol = S.Id_Rol
        WHERE R.Id_Rol IS NULL
    )
    BEGIN
        THROW 50005,
              'Uno o más usuarios del seeding utilizan un rol inexistente.',
              1;
    END;

    /* ============================================================
       INSERTAR SOLAMENTE LOS USUARIOS FALTANTES

       Un usuario se considera existente cuando coincide:
       - La identificación, o
       - El correo electrónico.

       Por tanto, el usuario real con identificación 116700557 se
       conservará aunque su correo actual sea distinto al del seeding.
       ============================================================ */

    DECLARE @TotalAntes INT;
    DECLARE @CantidadInsertada INT;

    DECLARE @UsuariosInsertados TABLE
    (
        Id_Usuario     INT,
        Identificacion VARCHAR(30),
        Nombre         NVARCHAR(150),
        Correo         VARCHAR(150)
    );

    SELECT
        @TotalAntes = COUNT(*)
    FROM dbo.Usuario;

    INSERT INTO dbo.Usuario
    (
        Identificacion,
        Nombre,
        Correo,
        Contrasena,
        Estado,
        Id_Rol,
        UsaContrasenaTemp
    )
    OUTPUT
        INSERTED.Id_Usuario,
        INSERTED.Identificacion,
        INSERTED.Nombre,
        INSERTED.Correo
    INTO @UsuariosInsertados
    (
        Id_Usuario,
        Identificacion,
        Nombre,
        Correo
    )
    SELECT
        S.Identificacion,
        S.Nombre,
        S.Correo,
        S.Contrasena,
        S.Estado,
        S.Id_Rol,
        S.UsaContrasenaTemp
    FROM @UsuariosSeed AS S
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.Usuario AS U
        WHERE U.Identificacion = S.Identificacion
           OR U.Correo = S.Correo
    );

    SET @CantidadInsertada = @@ROWCOUNT;

    /* ============================================================
       5. IDENTIFICAR LOS USUARIOS QUE PARTICIPAN EN LOS DATOS DEMO

       Solo se relacionan usuarios incluidos en @UsuariosSeed. Así,
       otros usuarios reales que existan en el futuro no recibirán
       ministerios, actividades o citas ficticias.
       ============================================================ */

    DECLARE @IdsUsuariosSeed TABLE
    (
        UsuarioSeedId INT PRIMARY KEY
    );

    INSERT INTO @IdsUsuariosSeed (UsuarioSeedId)
    SELECT DISTINCT U.Id_Usuario
    FROM dbo.Usuario AS U
    WHERE EXISTS
    (
        SELECT 1
        FROM @UsuariosSeed AS S
        WHERE S.Identificacion = U.Identificacion
           OR S.Correo = U.Correo
    );

    DECLARE @IdAdmin INT;

    SELECT TOP (1)
        @IdAdmin = U.Id_Usuario
    FROM dbo.Usuario AS U
    WHERE U.Identificacion = '000000000'
       OR U.Correo = 'ministeriogosen@gmail.com'
    ORDER BY
        CASE
            WHEN U.Identificacion = '000000000' THEN 0
            ELSE 1
        END,
        U.Id_Usuario;

    IF @IdAdmin IS NULL
        THROW 50011, 'No fue posible localizar o crear el usuario administrador.', 1;

    /* ============================================================
       6. TIPOS DE ACTIVIDAD
       ============================================================ */

    INSERT INTO dbo.Tipo_Actividad
    (
        Nombre_Tipo
    )
    VALUES
    ('Culto'),
    ('Reunion'),
    ('Taller'),
    ('Capacitacion'),
    ('Visita'),
    ('Ayuda social'),
    ('Oracion'),
    ('Servicio comunitario');

    /* ============================================================
       7. MINISTERIOS
       ============================================================ */

    INSERT INTO dbo.Ministerio
    (
        Descripcion_Ministerio,
        Observaciones_Ministerio
    )
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

    /* ============================================================
       8. USUARIOS POR MINISTERIO
       - Relación principal activa para todos los usuarios demo.
       - Algunos usuarios tienen un segundo ministerio activo.
       - Se agregan relaciones históricas inactivas para probar reportes.
       ============================================================ */

    DECLARE @TotalMinisterios INT =
    (
        SELECT COUNT(*)
        FROM dbo.Ministerio
    );

    ;WITH Usuarios AS
    (
        SELECT
            UBase.Id_Usuario,
            ROW_NUMBER() OVER (ORDER BY UBase.Id_Usuario) AS RN
        FROM dbo.Usuario AS UBase
        INNER JOIN @IdsUsuariosSeed AS IDS
            ON IDS.UsuarioSeedId = UBase.Id_Usuario
        WHERE UBase.Id_Rol = 2
    ),
    Ministerios AS
    (
        SELECT
            Id_Ministerio,
            ROW_NUMBER() OVER (ORDER BY Id_Ministerio) AS RN
        FROM dbo.Ministerio
    )
    INSERT INTO dbo.Usuarios_Ministerio
    (
        Id_Ministerio,
        Id_Usuario,
        Fecha_Ingreso,
        Fecha_Salida,
        Estado,
        Observacion
    )
    SELECT
        M.Id_Ministerio,
        U.Id_Usuario,
        DATEADD(DAY, -((U.RN * 7) % 330) - 30, CAST(GETDATE() AS DATE)),
        CASE WHEN U.RN % 13 = 0
             THEN DATEADD(DAY, -((U.RN * 3) % 45) - 10, CAST(GETDATE() AS DATE))
             ELSE NULL
        END,
        CASE WHEN U.RN % 13 = 0 THEN 'Inactivo' ELSE 'Activo' END,
        CASE WHEN U.RN % 13 = 0
             THEN 'Participación histórica finalizada.'
             ELSE 'Miembro activo del ministerio.'
        END
    FROM Usuarios U
    INNER JOIN Ministerios M
        ON M.RN = ((U.RN - 1) % @TotalMinisterios) + 1;

    ;WITH Usuarios AS
    (
        SELECT
            UBase.Id_Usuario,
            ROW_NUMBER() OVER (ORDER BY UBase.Id_Usuario) AS RN
        FROM dbo.Usuario AS UBase
        INNER JOIN @IdsUsuariosSeed AS IDS
            ON IDS.UsuarioSeedId = UBase.Id_Usuario
        WHERE UBase.Id_Rol = 2
          AND UBase.Estado = 'A'
    ),
    Ministerios AS
    (
        SELECT
            Id_Ministerio,
            ROW_NUMBER() OVER (ORDER BY Id_Ministerio) AS RN
        FROM dbo.Ministerio
    )
    INSERT INTO dbo.Usuarios_Ministerio
    (
        Id_Ministerio,
        Id_Usuario,
        Fecha_Ingreso,
        Fecha_Salida,
        Estado,
        Observacion
    )
    SELECT
        M.Id_Ministerio,
        U.Id_Usuario,
        DATEADD(DAY, -((U.RN * 5) % 180), CAST(GETDATE() AS DATE)),
        NULL,
        'Activo',
        'Apoyo adicional en actividades del ministerio.'
    FROM Usuarios U
    INNER JOIN Ministerios M
        ON M.RN = ((U.RN + 2) % @TotalMinisterios) + 1
    WHERE U.RN % 4 = 0
      AND NOT EXISTS
      (
          SELECT 1
          FROM dbo.Usuarios_Ministerio UM
          WHERE UM.Id_Usuario = U.Id_Usuario
            AND UM.Id_Ministerio = M.Id_Ministerio
            AND UM.Fecha_Salida IS NULL
      );

    /* ============================================================
       9. ACTIVIDADES Y RELACION CON MINISTERIOS
       Se distribuyen en los últimos 12 meses y en fechas futuras.
       ============================================================ */

    DECLARE @ActividadesSeed TABLE
    (
        Nombre_Actividad VARCHAR(100),
        DiasDesdeHoy INT,
        DiasDuracion INT,
        Lugar VARCHAR(100),
        Hora_Ini TIME(7),
        Hora_Fin TIME(7),
        Nombre_Tipo VARCHAR(50),
        Ministerio VARCHAR(100),
        Observacion VARCHAR(200),
        Estado VARCHAR(20)
    );

    INSERT INTO @ActividadesSeed
    (
        Nombre_Actividad,
        DiasDesdeHoy,
        DiasDuracion,
        Lugar,
        Hora_Ini,
        Hora_Fin,
        Nombre_Tipo,
        Ministerio,
        Observacion,
        Estado
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

    INSERT INTO dbo.Actividad
    (
        Nombre_Actividad,
        Fecha_Ini,
        Fecha_Fin,
        Lugar,
        Hora_Ini,
        Hora_Fin,
        Id_Tipo_Actividad,
        Estado
    )
    SELECT
        S.Nombre_Actividad,
        DATEADD(DAY, S.DiasDesdeHoy, CAST(GETDATE() AS DATE)),
        DATEADD(DAY, S.DiasDesdeHoy + S.DiasDuracion, CAST(GETDATE() AS DATE)),
        S.Lugar,
        S.Hora_Ini,
        S.Hora_Fin,
        TA.Id_Tipo_Actividad,
        S.Estado
    FROM @ActividadesSeed S
    INNER JOIN dbo.Tipo_Actividad TA
        ON TA.Nombre_Tipo = S.Nombre_Tipo;

    INSERT INTO dbo.Actividades_Ministerio
    (
        Id_Actividad,
        Id_Ministerio,
        Fecha,
        Observacion
    )
    SELECT
        A.Id_Actividad,
        M.Id_Ministerio,
        A.Fecha_Ini,
        S.Observacion
    FROM @ActividadesSeed S
    INNER JOIN dbo.Actividad A
        ON A.Nombre_Actividad = S.Nombre_Actividad
    INNER JOIN dbo.Ministerio M
        ON M.Descripcion_Ministerio = S.Ministerio;

    /* ============================================================
       10. PARTICIPACION DE USUARIOS EN ACTIVIDADES
       ============================================================ */

    DECLARE @TotalUsuarios INT =
    (
        SELECT COUNT(*)
        FROM dbo.Usuario AS UBase
        INNER JOIN @IdsUsuariosSeed AS IDS
            ON IDS.UsuarioSeedId = UBase.Id_Usuario
        WHERE Id_Rol = 2
          AND Estado = 'A'
    );

    ;WITH Actividades AS
    (
        SELECT
            Id_Actividad,
            Fecha_Ini,
            Hora_Ini,
            ROW_NUMBER() OVER (ORDER BY Id_Actividad) AS RN
        FROM dbo.Actividad
    ),
    Usuarios AS
    (
        SELECT
            Id_Usuario,
            ROW_NUMBER() OVER (ORDER BY Id_Usuario) AS RN
        FROM dbo.Usuario AS UBase
        INNER JOIN @IdsUsuariosSeed AS IDS
            ON IDS.UsuarioSeedId = UBase.Id_Usuario
        WHERE Id_Rol = 2
          AND Estado = 'A'
    )
    INSERT INTO dbo.Actividad_Usuario
    (
        Id_Actividad,
        Id_Usuario,
        Fecha,
        Hora
    )
    SELECT
        A.Id_Actividad,
        U.Id_Usuario,
        A.Fecha_Ini,
        A.Hora_Ini
    FROM Actividades A
    INNER JOIN Usuarios U
        ON U.RN = ((A.RN * 2 - 1) % @TotalUsuarios) + 1
        OR U.RN = ((A.RN * 2 + 7) % @TotalUsuarios) + 1
        OR U.RN = ((A.RN * 2 + 15) % @TotalUsuarios) + 1;

/* ============================================================
   11. CITAS
   - Atendidas: fechas pasadas.
   - Pendientes: fechas futuras.
   - Horario permitido por la BD: 08:00 a 17:00.
   ============================================================ */

;WITH Usuarios AS
(
    SELECT
        UBase.Id_Usuario,
        ROW_NUMBER() OVER (ORDER BY UBase.Id_Usuario) AS RN
    FROM dbo.Usuario AS UBase
    INNER JOIN @IdsUsuariosSeed AS IDS
        ON IDS.UsuarioSeedId = UBase.Id_Usuario
    WHERE UBase.Id_Rol = 2
      AND UBase.Estado = 'A'
),
Numeros AS
(
    SELECT TOP (40)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
    FROM sys.all_objects
),
DatosCitas AS
(
    SELECT
        N.N AS RN,
        U.Id_Usuario AS Id_Usuario_Cita,
        CASE
            WHEN N.N % 4 = 0 THEN @IdAdmin
            ELSE E.Id_Usuario
        END AS Id_Usuario_Encargado,
        CASE
            WHEN N.N <= 24
                THEN DATEADD(DAY, -(N.N * 4), CAST(GETDATE() AS DATE))
            ELSE DATEADD(DAY, (N.N - 24) * 2, CAST(GETDATE() AS DATE))
        END AS Fecha_Cita,
        CAST(
            DATEADD(
                HOUR,
                ((N.N - 1) % 10),
                CAST('08:00:00' AS DATETIME)
            ) AS TIME(0)
        ) AS Hora_Cita,
        CASE
            WHEN N.N <= 24 THEN 'Atendida'
            ELSE 'Pendiente'
        END AS Estado
    FROM Numeros N
    INNER JOIN Usuarios U
        ON U.RN = ((N.N - 1) % @TotalUsuarios) + 1
    INNER JOIN Usuarios E
        ON E.RN = ((N.N + 6) % @TotalUsuarios) + 1
)
INSERT INTO dbo.Citas
(
    Fecha_Cita,
    Hora_Cita,
    Id_Usuario_Cita,
    Id_Usuario_Encargado,
    Observacion_Inicial,
    Detalle_Cita,
    Estado
)
SELECT
    D.Fecha_Cita,
    D.Hora_Cita,
    D.Id_Usuario_Cita,
    D.Id_Usuario_Encargado,
    CASE D.RN % 6
        WHEN 0 THEN 'Solicitud de apoyo familiar.'
        WHEN 1 THEN 'Consulta sobre participación en un ministerio.'
        WHEN 2 THEN 'Solicitud de acompañamiento espiritual.'
        WHEN 3 THEN 'Consulta sobre actividades disponibles.'
        WHEN 4 THEN 'Solicitud de orientación general.'
        ELSE 'Solicitud de seguimiento personal.'
    END,
    CASE
        WHEN D.Estado = 'Atendida'
            THEN 'Cita atendida. Se registró seguimiento y observaciones.'
        ELSE
            'Cita pendiente de atención y confirmación administrativa.'
    END,
    D.Estado
FROM DatosCitas D;

    /* ============================================================
       12. ERRORES DE EJEMPLO
       ============================================================ */

    INSERT INTO dbo.Error
    (
        Mensaje,
        Lugar,
        FechaHora,
        Id_Usuario
    )
    VALUES
    ('Intento de acceso con contraseña incorrecta.', 'Home/IniciarSesion', DATEADD(DAY, -5, GETDATE()), @IdAdmin),
    ('Validacion de formulario incompleta.', 'Usuario/Crear', DATEADD(DAY, -4, GETDATE()), @IdAdmin),
    ('Error controlado al consultar citas.', 'Citas/Listar', DATEADD(DAY, -3, GETDATE()), @IdAdmin),
    ('Parametro requerido no recibido.', 'Actividad/Crear', DATEADD(DAY, -2, GETDATE()), @IdAdmin),
    ('Consulta sin resultados disponibles.', 'Reportes/Index', DATEADD(DAY, -1, GETDATE()), @IdAdmin);

    /* ============================================================
       13. CHATBOT
       Mantener respuestas cortas porque Respuesta es VARCHAR(200)
       ============================================================ */

    DECLARE @IdInfo INT;
    DECLARE @IdMinisterios INT;
    DECLARE @IdActividades INT;
    DECLARE @IdCitas INT;
    DECLARE @IdHorarios INT;
    DECLARE @IdContacto INT;
    DECLARE @IdUsuarioAcceso INT;
    DECLARE @IdUbicacion INT;
    DECLARE @IdAgendar INT;

    INSERT INTO dbo.Chat_Bot_Opciones
    (
        Texto_Opcion,
        Respuesta,
        Id_Opcion_Padre,
        Orden,
        Activo
    )
    VALUES
    (N'Informacion general', 'Seleccione la informacion que desea consultar.', NULL, 1, 1);
    SET @IdInfo = SCOPE_IDENTITY();

    INSERT INTO dbo.Chat_Bot_Opciones
    (Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
    VALUES
    (N'Ministerios', 'Seleccione el ministerio sobre el que desea informacion.', NULL, 2, 1);
    SET @IdMinisterios = SCOPE_IDENTITY();

    INSERT INTO dbo.Chat_Bot_Opciones
    (Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
    VALUES
    (N'Actividades', 'Seleccione una opcion relacionada con actividades.', NULL, 3, 1);
    SET @IdActividades = SCOPE_IDENTITY();

    INSERT INTO dbo.Chat_Bot_Opciones
    (Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
    VALUES
    (N'Citas', 'Seleccione una opcion relacionada con citas.', NULL, 4, 1);
    SET @IdCitas = SCOPE_IDENTITY();

    INSERT INTO dbo.Chat_Bot_Opciones
    (Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
    VALUES
    (N'Horarios', 'Seleccione el horario que desea consultar.', NULL, 5, 1);
    SET @IdHorarios = SCOPE_IDENTITY();

    INSERT INTO dbo.Chat_Bot_Opciones
    (Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
    VALUES
    (N'Contacto', 'Seleccione el medio por el cual desea comunicarse.', NULL, 6, 1);
    SET @IdContacto = SCOPE_IDENTITY();

    INSERT INTO dbo.Chat_Bot_Opciones
    (Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
    VALUES
    (N'Usuario y acceso', 'Seleccione una opcion relacionada con su usuario.', NULL, 7, 1);
    SET @IdUsuarioAcceso = SCOPE_IDENTITY();

    INSERT INTO dbo.Chat_Bot_Opciones
    (Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
    VALUES
    (N'Que es Ministerio Gosen', 'Ministerio Gosen brinda acompañamiento espiritual, actividades comunitarias y apoyo a familias.', @IdInfo, 1, 1),
    (N'Quien puede usar el sistema', 'El sistema puede ser usado por usuarios registrados y administradores autorizados.', @IdInfo, 2, 1),
    (N'Ubicacion', 'Seleccione la informacion de ubicacion que desea consultar.', @IdInfo, 3, 1);

    SELECT @IdUbicacion = Id_Opcion
    FROM dbo.Chat_Bot_Opciones
    WHERE Texto_Opcion = N'Ubicacion'
      AND Id_Opcion_Padre = @IdInfo;

    INSERT INTO dbo.Chat_Bot_Opciones
    (Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
    VALUES
    (N'Direccion', 'El Ministerio Gosen se ubica en La Fila de Mora, Puriscal.', @IdUbicacion, 1, 1),
    (N'Como llegar', 'Solicite indicaciones a la administracion o revise la ubicacion oficial compartida.', @IdUbicacion, 2, 1),

    (N'Ver ministerios disponibles', 'Puede consultar los ministerios desde la opcion Ministerios del menu principal.', @IdMinisterios, 1, 1),
    (N'Participar en un ministerio', 'Comuniquese con la administracion o consulte el ministerio de su interes.', @IdMinisterios, 2, 1),
    (N'Ministerio de Niños', 'Realiza actividades formativas y recreativas para niños.', @IdMinisterios, 3, 1),
    (N'Ministerio de Jovenes', 'Promueve reuniones, talleres y actividades para jovenes.', @IdMinisterios, 4, 1),
    (N'Ministerio de Ayuda Social', 'Organiza visitas, entregas y apoyo comunitario.', @IdMinisterios, 5, 1),
    (N'Ministerio de Oracion', 'Brinda acompañamiento espiritual y seguimiento a solicitudes.', @IdMinisterios, 6, 1),

    (N'Proximas actividades', 'Las actividades disponibles se consultan en la seccion Actividades.', @IdActividades, 1, 1),
    (N'Inscribirme en una actividad', 'Revise la actividad y comuniquese con la administracion para confirmar participacion.', @IdActividades, 2, 1),
    (N'Tipos de actividades', 'El sistema registra cultos, reuniones, talleres, visitas y servicio comunitario.', @IdActividades, 3, 1),

    (N'Agendar una cita', 'Ingrese a Agendar Cita, complete la informacion solicitada y espere confirmacion.', @IdCitas, 1, 1);

    SET @IdAgendar = SCOPE_IDENTITY();

    INSERT INTO dbo.Chat_Bot_Opciones
    (Texto_Opcion, Respuesta, Id_Opcion_Padre, Orden, Activo)
    VALUES
    (N'Consultar una cita', 'Puede revisar sus citas desde la seccion Citas o solicitar apoyo a la administracion.', @IdCitas, 2, 1),
    (N'Cancelar una cita', 'Para cancelar una cita, comuniquese con la administracion con anticipacion.', @IdCitas, 3, 1),
    (N'Datos necesarios', 'Para agendar se requiere nombre, motivo de cita y disponibilidad de fecha.', @IdAgendar, 1, 1),
    (N'Confirmacion de cita', 'La cita queda sujeta a revision y confirmacion de la administracion.', @IdAgendar, 2, 1),

    (N'Horario de atencion', 'El horario de atencion depende de la disponibilidad de la administracion.', @IdHorarios, 1, 1),
    (N'Horario de actividades', 'Los horarios varian segun el ministerio y la programacion semanal.', @IdHorarios, 2, 1),
    (N'Atencion en feriados', 'La atencion en feriados depende de la programacion oficial.', @IdHorarios, 3, 1),

    (N'Telefono', 'Puede comunicarse con la administracion al numero oficial del Ministerio Gosen.', @IdContacto, 1, 1),
    (N'Correo electronico', 'Puede escribir al correo ministeriogosen@gmail.com.', @IdContacto, 2, 1),
    (N'Solicitar ayuda', 'Para solicitar ayuda, registre una cita o comuniquese con la administracion.', @IdContacto, 3, 1),

    (N'Cambiar contraseña', 'Ingrese a Configuracion y actualice su contraseña desde su perfil.', @IdUsuarioAcceso, 1, 1),
    (N'Actualizar mi perfil', 'Ingrese a Configuracion para actualizar su informacion personal.', @IdUsuarioAcceso, 2, 1),
    (N'No puedo ingresar', 'Solicite apoyo a la administracion para revisar su usuario.', @IdUsuarioAcceso, 3, 1);


    COMMIT TRANSACTION;

    PRINT 'Carga completa ejecutada correctamente.';
    PRINT 'Los usuarios existentes fueron conservados.';
    PRINT CONCAT('Usuarios nuevos insertados: ', @CantidadInsertada);

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    BEGIN TRY
        SET IDENTITY_INSERT dbo.Rol OFF;
    END TRY
    BEGIN CATCH
        -- No se requiere ninguna acción adicional.
    END CATCH;

    PRINT 'Error ejecutando la carga completa de datos.';
    PRINT ERROR_MESSAGE();

    THROW;

END CATCH;
GO

/* ============================================================
   14. SP DEL CHATBOT CON ALIAS PARA MODELOS C#
   ============================================================ */

CREATE OR ALTER PROCEDURE dbo.SP_ConsultarChatbot
    @Id_Opcion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id_Opcion AS IdOpcion,
        Texto_Opcion AS TextoOpcion,
        Respuesta,
        Id_Opcion_Padre AS IdOpcionPadre,
        Orden,
        Activo
    FROM dbo.Chat_Bot_Opciones
    WHERE Id_Opcion = @Id_Opcion
      AND Activo = 1;

    SELECT
        Id_Opcion AS IdOpcion,
        Texto_Opcion AS TextoOpcion,
        Respuesta,
        Id_Opcion_Padre AS IdOpcionPadre,
        Orden,
        Activo
    FROM dbo.Chat_Bot_Opciones
    WHERE Activo = 1
      AND
      (
          (@Id_Opcion IS NULL AND Id_Opcion_Padre IS NULL)
          OR
          (@Id_Opcion IS NOT NULL AND Id_Opcion_Padre = @Id_Opcion)
      )
    ORDER BY
        Orden,
        Texto_Opcion;

    SELECT
        Padre.Id_Opcion AS IdOpcion,
        Padre.Texto_Opcion AS TextoOpcion,
        Padre.Respuesta,
        Padre.Id_Opcion_Padre AS IdOpcionPadre,
        Padre.Orden,
        Padre.Activo
    FROM dbo.Chat_Bot_Opciones AS Hijo
    INNER JOIN dbo.Chat_Bot_Opciones AS Padre
        ON Padre.Id_Opcion = Hijo.Id_Opcion_Padre
    WHERE Hijo.Id_Opcion = @Id_Opcion
      AND Padre.Activo = 1;
END;
GO

/* ============================================================
   15. VALIDACION RAPIDA
   ============================================================ */

SELECT 'Rol' AS Tabla, COUNT(*) AS Total FROM dbo.Rol
UNION ALL SELECT 'Usuario', COUNT(*) FROM dbo.Usuario
UNION ALL SELECT 'Ministerio', COUNT(*) FROM dbo.Ministerio
UNION ALL SELECT 'Tipo_Actividad', COUNT(*) FROM dbo.Tipo_Actividad
UNION ALL SELECT 'Actividad', COUNT(*) FROM dbo.Actividad
UNION ALL SELECT 'Actividad_Usuario', COUNT(*) FROM dbo.Actividad_Usuario
UNION ALL SELECT 'Actividades_Ministerio', COUNT(*) FROM dbo.Actividades_Ministerio
UNION ALL SELECT 'Usuarios_Ministerio', COUNT(*) FROM dbo.Usuarios_Ministerio
UNION ALL SELECT 'Citas', COUNT(*) FROM dbo.Citas
UNION ALL SELECT 'Error', COUNT(*) FROM dbo.Error
UNION ALL SELECT 'Chat_Bot_Opciones', COUNT(*) FROM dbo.Chat_Bot_Opciones;
GO

SELECT Estado, COUNT(*) AS Total
FROM dbo.Citas
GROUP BY Estado
ORDER BY Estado;
GO

SELECT Estado, COUNT(*) AS Total
FROM dbo.Actividad
GROUP BY Estado
ORDER BY Estado;
GO

EXEC dbo.spConsultarDashboard;
GO
