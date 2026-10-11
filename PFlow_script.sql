/* =========================================================================
   Caso: PFlow - Gestion de Atenciones de Emergencia
   Script SQL Server (SSMS): creacion de base de datos, tablas y
   restricciones (PK, FK, UNIQUE, DEFAULT, NOT NULL) segun modelo fisico.
   ========================================================================= */

/* =========================================================================
   1. CREACION DE LA BASE DE DATOS
   ========================================================================= */
IF DB_ID(N'PFlow') IS NOT NULL
BEGIN
    ALTER DATABASE PFlow SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE PFlow;
END
GO

CREATE DATABASE PFlow;
GO

USE PFlow;
GO

/* =========================================================================
   2. CREACION DE TABLAS
   ========================================================================= */

CREATE TABLE EstablecimientoSalud (
    id_establecimiento      INT             IDENTITY(1,1) NOT NULL,
    nombre_establecimiento  VARCHAR(150)    NOT NULL,
    tipo_establecimiento    VARCHAR(50)     NOT NULL,
    nivel_complejidad       VARCHAR(30)     NOT NULL,
    CONSTRAINT PK_EstablecimientoSalud PRIMARY KEY (id_establecimiento)
);
GO

CREATE TABLE Rol (
    id_rol          INT             IDENTITY(1,1) NOT NULL,
    nombre_rol      VARCHAR(50)     NOT NULL,
    descripcion     VARCHAR(200)    NOT NULL,
    CONSTRAINT PK_Rol PRIMARY KEY (id_rol),
    CONSTRAINT UQ_Rol_nombre_rol UNIQUE (nombre_rol)
);
GO

CREATE TABLE Paciente (
    id_paciente         INT             IDENTITY(1,1) NOT NULL,
    codigo_paciente     VARCHAR(30)     NOT NULL,
    tipo_documento      VARCHAR(20)     NOT NULL,
    documento_hash      VARCHAR(255)    NOT NULL,
    fecha_nacimiento    DATE            NOT NULL,
    CONSTRAINT PK_Paciente PRIMARY KEY (id_paciente),
    CONSTRAINT UQ_Paciente_codigo_paciente UNIQUE (codigo_paciente),
    CONSTRAINT UQ_Paciente_documento_hash UNIQUE (documento_hash)
);
GO

CREATE TABLE AreaAtencion (
    id_area             INT             IDENTITY(1,1) NOT NULL,
    nombre_area         VARCHAR(100)    NOT NULL,
    tipo_area           VARCHAR(50)     NOT NULL,
    estado_area         VARCHAR(20)     NOT NULL
        CONSTRAINT DF_AreaAtencion_estado DEFAULT ('Activo'),
    id_establecimiento  INT             NOT NULL,
    CONSTRAINT PK_AreaAtencion PRIMARY KEY (id_area),
    CONSTRAINT FK_AreaAtencion_Establecimiento FOREIGN KEY (id_establecimiento)
        REFERENCES EstablecimientoSalud (id_establecimiento)
);
GO

CREATE TABLE CamaRecurso (
    id_cama         INT             IDENTITY(1,1) NOT NULL,
    codigo_cama     VARCHAR(30)     NOT NULL,
    tipo_cama       VARCHAR(30)     NOT NULL,
    estado_cama     VARCHAR(30)     NOT NULL
        CONSTRAINT DF_CamaRecurso_estado DEFAULT ('Disponible'),
    id_area         INT             NOT NULL,
    CONSTRAINT PK_CamaRecurso PRIMARY KEY (id_cama),
    CONSTRAINT UQ_CamaRecurso_codigo_cama UNIQUE (codigo_cama),
    CONSTRAINT FK_CamaRecurso_Area FOREIGN KEY (id_area)
        REFERENCES AreaAtencion (id_area)
);
GO

CREATE TABLE UsuarioPersonalSalud (
    id_usuario          INT             IDENTITY(1,1) NOT NULL,
    nombres             VARCHAR(100)    NOT NULL,
    apellidos           VARCHAR(100)    NOT NULL,
    estado_usuario      VARCHAR(20)     NOT NULL
        CONSTRAINT DF_Usuario_estado DEFAULT ('Activo'),
    cargo               VARCHAR(80)     NOT NULL,
    id_establecimiento  INT             NOT NULL,
    id_rol              INT             NOT NULL,
    CONSTRAINT PK_UsuarioPersonalSalud PRIMARY KEY (id_usuario),
    CONSTRAINT FK_Usuario_Establecimiento FOREIGN KEY (id_establecimiento)
        REFERENCES EstablecimientoSalud (id_establecimiento),
    CONSTRAINT FK_Usuario_Rol FOREIGN KEY (id_rol)
        REFERENCES Rol (id_rol)
);
GO

CREATE TABLE AtencionEmergencia (
    id_atencion         INT             IDENTITY(1,1) NOT NULL,
    estado_final        VARCHAR(40)     NOT NULL
        CONSTRAINT DF_Atencion_estado DEFAULT ('En proceso'),
    fecha_hora_ingreso  DATETIME        NOT NULL,
    fecha_hora_egreso   DATETIME        NULL,
    id_paciente         INT             NOT NULL,
    id_establecimiento  INT             NOT NULL,
    CONSTRAINT PK_AtencionEmergencia PRIMARY KEY (id_atencion),
    CONSTRAINT FK_Atencion_Paciente FOREIGN KEY (id_paciente)
        REFERENCES Paciente (id_paciente),
    CONSTRAINT FK_Atencion_Establecimiento FOREIGN KEY (id_establecimiento)
        REFERENCES EstablecimientoSalud (id_establecimiento)
);
GO

-- Relacion 1:1 con AtencionEmergencia (segun el diagrama): UNIQUE en id_atencion
CREATE TABLE Triaje (
    id_triaje           INT             IDENTITY(1,1) NOT NULL,
    prioridad           VARCHAR(10)     NOT NULL,
    fecha_hora_triaje   DATETIME        NOT NULL,
    signos_vitales      VARCHAR(255)    NOT NULL,
    id_atencion         INT             NOT NULL,
    id_usuario          INT             NOT NULL,
    CONSTRAINT PK_Triaje PRIMARY KEY (id_triaje),
    CONSTRAINT UQ_Triaje_id_atencion UNIQUE (id_atencion),
    CONSTRAINT FK_Triaje_Atencion FOREIGN KEY (id_atencion)
        REFERENCES AtencionEmergencia (id_atencion),
    CONSTRAINT FK_Triaje_Usuario FOREIGN KEY (id_usuario)
        REFERENCES UsuarioPersonalSalud (id_usuario)
);
GO

CREATE TABLE EventoAtencion (
    id_evento           INT             IDENTITY(1,1) NOT NULL,
    tipo_evento         VARCHAR(80)     NOT NULL,
    fecha_hora_evento   DATETIME        NOT NULL,
    observacion         VARCHAR(255)    NULL,
    id_atencion         INT             NOT NULL,
    id_area             INT             NULL,
    id_cama             INT             NULL,
    id_usuario          INT             NOT NULL,
    CONSTRAINT PK_EventoAtencion PRIMARY KEY (id_evento),
    CONSTRAINT FK_Evento_Atencion FOREIGN KEY (id_atencion)
        REFERENCES AtencionEmergencia (id_atencion),
    CONSTRAINT FK_Evento_Area FOREIGN KEY (id_area)
        REFERENCES AreaAtencion (id_area),
    CONSTRAINT FK_Evento_Cama FOREIGN KEY (id_cama)
        REFERENCES CamaRecurso (id_cama),
    CONSTRAINT FK_Evento_Usuario FOREIGN KEY (id_usuario)
        REFERENCES UsuarioPersonalSalud (id_usuario)
);
GO

CREATE TABLE Interconsulta (
    id_interconsulta        INT             IDENTITY(1,1) NOT NULL,
    especialidad_solicitada VARCHAR(80)     NOT NULL,
    fecha_hora_solicitud    DATETIME        NOT NULL,
    fecha_hora_atencion     DATETIME        NULL,
    estado_interconsulta    VARCHAR(30)     NOT NULL
        CONSTRAINT DF_Interconsulta_estado DEFAULT ('Pendiente'),
    id_atencion             INT             NOT NULL,
    CONSTRAINT PK_Interconsulta PRIMARY KEY (id_interconsulta),
    CONSTRAINT FK_Interconsulta_Atencion FOREIGN KEY (id_atencion)
        REFERENCES AtencionEmergencia (id_atencion)
);
GO

CREATE TABLE SolicitudServicioApoyo (
    id_solicitud            INT             IDENTITY(1,1) NOT NULL,
    tipo_servicio           VARCHAR(50)     NOT NULL,
    fecha_hora_solicitud    DATETIME        NOT NULL,
    fecha_hora_resultado    DATETIME        NULL,
    estado_solicitud        VARCHAR(30)     NOT NULL
        CONSTRAINT DF_Solicitud_estado DEFAULT ('Pendiente'),
    id_atencion             INT             NOT NULL,
    CONSTRAINT PK_SolicitudServicioApoyo PRIMARY KEY (id_solicitud),
    CONSTRAINT FK_Solicitud_Atencion FOREIGN KEY (id_atencion)
        REFERENCES AtencionEmergencia (id_atencion)
);
GO
