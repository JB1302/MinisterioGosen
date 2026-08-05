/*procedimientos nuevos actividadUsuario*/
USE [master]
GO

use ministerio_gosen
GO

drop procedure spListarActividadUsuario
go

CREATE PROCEDURE [dbo].[spListarActividadUsuario]
AS
BEGIN
    SELECT 
        AU.Id_Actividad_Usuario,
        AU.Id_Actividad,
        A.Nombre_Actividad AS NombreActividad, -- ✅ alias correcto
        AU.Id_Usuario,
        U.Identificacion AS IdentificacionUsuario,
        U.Nombre AS NombreUsuario,
        AU.Fecha,
        AU.Hora
    FROM dbo.Actividad_Usuario AU
    INNER JOIN dbo.Actividad A 
        ON AU.Id_Actividad = A.Id_Actividad
    INNER JOIN dbo.Usuario U 
        ON AU.Id_Usuario = U.Id_Usuario
    ORDER BY AU.Fecha DESC, AU.Hora ASC;
END;
GO

CREATE OR ALTER PROCEDURE [dbo].[spObtenerActividadUsuario]
    @Id_Actividad_Usuario INT
AS
BEGIN
    SELECT 
        AU.Id_Actividad_Usuario,
        AU.Id_Actividad,
        A.Nombre_Actividad AS NombreActividad,
        AU.Id_Usuario,
        U.Identificacion AS IdentificacionUsuario,
        U.Nombre AS NombreUsuario,
        AU.Fecha,
        AU.Hora
    FROM dbo.Actividad_Usuario AU
    INNER JOIN dbo.Actividad A 
        ON AU.Id_Actividad = A.Id_Actividad
    INNER JOIN dbo.Usuario U 
        ON AU.Id_Usuario = U.Id_Usuario
    WHERE AU.Id_Actividad_Usuario = @Id_Actividad_Usuario;
END;
GO

DROP PROCEDURE spCrearActividadUsuario
GO

CREATE PROCEDURE [dbo].[spCrearActividadUsuario]
    @Id_Actividad INT,
    @Id_Usuario INT,
    @Fecha DATE,
    @Hora TIME(7)
AS
BEGIN
    INSERT INTO Actividad_Usuario (Id_Actividad, Id_Usuario, Fecha, Hora)
    VALUES (@Id_Actividad, @Id_Usuario, @Fecha, @Hora);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS Id_Actividad_Usuario;
END;
GO

/*actividaes_ministerio*/
drop procedure spListarActividadMinisterio;
GO

CREATE PROCEDURE [dbo].[spListarActividadMinisterio]
AS
BEGIN
    SELECT 
        AM.Id_Minis_Actividad,
        AM.Id_Actividad,
        A.Nombre_Actividad AS NombreActividad,   
        AM.Id_Ministerio,
        M.Descripcion_Ministerio AS NombreMinisterio, 
        AM.Fecha,
        AM.Observacion
    FROM dbo.Actividades_Ministerio AM
    INNER JOIN dbo.Actividad A 
        ON AM.Id_Actividad = A.Id_Actividad
    INNER JOIN dbo.Ministerio M 
        ON AM.Id_Ministerio = M.Id_Ministerio
    ORDER BY AM.Fecha DESC, AM.Id_Minis_Actividad ASC;
END;
GO

drop procedure spObtenerActividadesMinisterio;
GO

create OR ALTER PROCEDURE [dbo].[spObtenerActividadMinisterio]
    @Id_Minis_Actividad INT
AS
BEGIN
    SELECT 
        AM.Id_Minis_Actividad,
        AM.Id_Actividad,
        A.Nombre_Actividad AS NombreActividad,   
        AM.Id_Ministerio,
        M.Descripcion_Ministerio AS NombreMinisterio,
        AM.Fecha,
        AM.Observacion AS Observacion
    FROM dbo.Actividades_Ministerio AM
    INNER JOIN dbo.Actividad A 
        ON AM.Id_Actividad = A.Id_Actividad
    INNER JOIN dbo.Ministerio M 
        ON AM.Id_Ministerio = M.Id_Ministerio
    WHERE AM.Id_Minis_Actividad = @Id_Minis_Actividad;
END;

drop procedure speliminaractividadesMinisterio;
GO

CREATE OR ALTER PROCEDURE [dbo].[spEliminarActividadMinisterio]
    @Id_Minis_Actividad INT
AS
BEGIN
    DELETE FROM Actividades_Ministerio
    WHERE Id_Minis_Actividad = @Id_Minis_Actividad;
END;
GO

drop procedure spCrearActividadesMinisterio;
GO

CREATE PROCEDURE [dbo].[spCrearActividadesMinisterio]
    @Id_Actividad INT,
    @Id_Ministerio INT,
    @Fecha DATE,
    @Observacion VARCHAR(200)
AS
BEGIN
    INSERT INTO Actividades_Ministerio (Id_Actividad, Id_Ministerio, Fecha, Observacion)
    VALUES (@Id_Actividad, @Id_Ministerio, @Fecha, @Observacion);

    -- Devolver el ID recién insertado
    SELECT CAST(SCOPE_IDENTITY() AS INT) AS Id_Minis_Actividad;
END;

drop procedure spListarActividadUsuario;
GO

CREATE OR ALTER PROCEDURE [dbo].[spListarActividadUsuario]
    @Id_Usuario INT = NULL,
    @Id_Actividad INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        AU.Id_Actividad_Usuario,
        AU.Id_Actividad,
        A.Nombre_Actividad AS NombreActividad, -- ✅ alias correcto
        AU.Id_Usuario,
        U.Identificacion AS IdentificacionUsuario,
        U.Nombre AS NombreUsuario,
        AU.Fecha,
        AU.Hora
    FROM dbo.Actividad_Usuario AU
    INNER JOIN dbo.Actividad A 
        ON AU.Id_Actividad = A.Id_Actividad
    INNER JOIN dbo.Usuario U 
        ON AU.Id_Usuario = U.Id_Usuario
    WHERE (@Id_Usuario IS NULL OR AU.Id_Usuario = @Id_Usuario)
      AND (@Id_Actividad IS NULL OR AU.Id_Actividad = @Id_Actividad)
    ORDER BY AU.Fecha DESC, AU.Hora ASC;
END;
GO

ALTER PROCEDURE [dbo].[spListarActividadMinisterio]
    @Id_Ministerio INT = NULL,
    @Id_Actividad INT = NULL
AS
BEGIN
    SELECT 
        AM.Id_Minis_Actividad,
        AM.Id_Actividad,
        A.Nombre_Actividad AS NombreActividad,   
        AM.Id_Ministerio,
        M.Descripcion_Ministerio AS NombreMinisterio, 
        AM.Fecha,
        AM.Observacion
    FROM dbo.Actividades_Ministerio AM
    INNER JOIN dbo.Actividad A 
        ON AM.Id_Actividad = A.Id_Actividad
    INNER JOIN dbo.Ministerio M 
        ON AM.Id_Ministerio = M.Id_Ministerio
    WHERE (@Id_Ministerio IS NULL OR AM.Id_Ministerio = @Id_Ministerio)
      AND (@Id_Actividad IS NULL OR AM.Id_Actividad = @Id_Actividad)
    ORDER BY AM.Fecha DESC, AM.Id_Minis_Actividad ASC;
END;
GO

ALTER PROCEDURE [dbo].[spObtenerActividadMinisterio]
    @Id_Minis_Actividad INT
AS
BEGIN
    SELECT 
        AM.Id_Minis_Actividad,
        AM.Id_Actividad,
        A.Nombre_Actividad AS NombreActividad,   
        AM.Id_Ministerio AS IdentificacionMinisterio,
        M.Descripcion_Ministerio AS NombreMinisterio,
        AM.Fecha,
        AM.Observacion AS Observacion
    FROM dbo.Actividades_Ministerio AM
    INNER JOIN dbo.Actividad A 
        ON AM.Id_Actividad = A.Id_Actividad
    INNER JOIN dbo.Ministerio M 
        ON AM.Id_Ministerio = M.Id_Ministerio
    WHERE AM.Id_Minis_Actividad = @Id_Minis_Actividad;
END;
GO 

ALTER PROCEDURE [dbo].[spListarActividadMinisterio]
    @Id_Ministerio INT = NULL,
    @Id_Actividad INT = NULL
AS
BEGIN
    SELECT 
        AM.Id_Minis_Actividad,
        AM.Id_Actividad,
        A.Nombre_Actividad AS NombreActividad,   
        AM.Id_Ministerio,
        M.Descripcion_Ministerio AS NombreMinisterio, 
        AM.Fecha,
        AM.Observacion
    FROM dbo.Actividades_Ministerio AM
    INNER JOIN dbo.Actividad A 
        ON AM.Id_Actividad = A.Id_Actividad
    INNER JOIN dbo.Ministerio M 
        ON AM.Id_Ministerio = M.Id_Ministerio
    WHERE (@Id_Ministerio IS NULL OR AM.Id_Ministerio = @Id_Ministerio)
      AND (@Id_Actividad IS NULL OR AM.Id_Actividad = @Id_Actividad)
    ORDER BY AM.Fecha DESC, AM.Id_Minis_Actividad ASC;
END;
GO

ALTER PROCEDURE [dbo].[spObtenerActividadMinisterio]
    @Id_Minis_Actividad INT
AS
BEGIN
    SELECT 
        AM.Id_Minis_Actividad,
        AM.Id_Actividad,
        A.Nombre_Actividad AS NombreActividad,   
        AM.Id_Ministerio,
        M.Descripcion_Ministerio AS NombreMinisterio,
        AM.Fecha,
        AM.Observacion
    FROM dbo.Actividades_Ministerio AM
    INNER JOIN dbo.Actividad A 
        ON AM.Id_Actividad = A.Id_Actividad
    INNER JOIN dbo.Ministerio M 
        ON AM.Id_Ministerio = M.Id_Ministerio
    WHERE AM.Id_Minis_Actividad = @Id_Minis_Actividad;
END;
GO
