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
   
USE PFlow;
GO

INSERT INTO EstablecimientoSalud (nombre_establecimiento, tipo_establecimiento, nivel_complejidad) VALUES ('Hospital de Emergencias Lima Centro', 'Hospital', 'Nivel III-1');
INSERT INTO EstablecimientoSalud (nombre_establecimiento, tipo_establecimiento, nivel_complejidad) VALUES ('Hospital Regional del Callao', 'Hospital', 'Nivel II-2');
INSERT INTO EstablecimientoSalud (nombre_establecimiento, tipo_establecimiento, nivel_complejidad) VALUES ('Clínica San Isidro Salud', 'Clínica', 'Nivel II-2');
INSERT INTO EstablecimientoSalud (nombre_establecimiento, tipo_establecimiento, nivel_complejidad) VALUES ('Clínica Surco Médica', 'Clínica', 'Nivel II-1');
INSERT INTO EstablecimientoSalud (nombre_establecimiento, tipo_establecimiento, nivel_complejidad) VALUES ('Centro de Salud Miraflores', 'Centro de Salud', 'Nivel I-3');
INSERT INTO EstablecimientoSalud (nombre_establecimiento, tipo_establecimiento, nivel_complejidad) VALUES ('Policlínico La Molina', 'Policlínico', 'Nivel I-4');
INSERT INTO EstablecimientoSalud (nombre_establecimiento, tipo_establecimiento, nivel_complejidad) VALUES ('Hospital de Villa El Salvador', 'Hospital', 'Nivel II-1');
INSERT INTO EstablecimientoSalud (nombre_establecimiento, tipo_establecimiento, nivel_complejidad) VALUES ('Hospital Materno Infantil San Borja', 'Hospital', 'Nivel II-2');
INSERT INTO EstablecimientoSalud (nombre_establecimiento, tipo_establecimiento, nivel_complejidad) VALUES ('Clínica Jesús María Vital', 'Clínica', 'Nivel II-1');
INSERT INTO EstablecimientoSalud (nombre_establecimiento, tipo_establecimiento, nivel_complejidad) VALUES ('Centro de Salud Barranco', 'Centro de Salud', 'Nivel I-3');
INSERT INTO EstablecimientoSalud (nombre_establecimiento, tipo_establecimiento, nivel_complejidad) VALUES ('Hospital de San Juan de Lurigancho', 'Hospital', 'Nivel II-2');
INSERT INTO EstablecimientoSalud (nombre_establecimiento, tipo_establecimiento, nivel_complejidad) VALUES ('Clínica Pueblo Libre Salud', 'Clínica', 'Nivel I-4');
INSERT INTO EstablecimientoSalud (nombre_establecimiento, tipo_establecimiento, nivel_complejidad) VALUES ('Hospital Nacional de Trauma Rímac', 'Hospital', 'Nivel III-1');
INSERT INTO EstablecimientoSalud (nombre_establecimiento, tipo_establecimiento, nivel_complejidad) VALUES ('Policlínico Los Olivos', 'Policlínico', 'Nivel I-4');
INSERT INTO EstablecimientoSalud (nombre_establecimiento, tipo_establecimiento, nivel_complejidad) VALUES ('Clínica Lince Integral', 'Clínica', 'Nivel II-1');
GO

-- Rol (15 filas)
INSERT INTO Rol (nombre_rol, descripcion) VALUES ('Médico Emergenciólogo', 'Atiende y estabiliza pacientes en el servicio de emergencia.');
INSERT INTO Rol (nombre_rol, descripcion) VALUES ('Médico General', 'Realiza la atención médica inicial durante la guardia.');
INSERT INTO Rol (nombre_rol, descripcion) VALUES ('Enfermero de Triaje', 'Clasifica la prioridad de atención de los pacientes que ingresan.');
INSERT INTO Rol (nombre_rol, descripcion) VALUES ('Enfermero Asistencial', 'Brinda cuidados de enfermería a los pacientes en observación.');
INSERT INTO Rol (nombre_rol, descripcion) VALUES ('Técnico de Enfermería', 'Apoya en procedimientos básicos y traslado de pacientes.');
INSERT INTO Rol (nombre_rol, descripcion) VALUES ('Admisionista', 'Registra el ingreso y los datos administrativos del paciente.');
INSERT INTO Rol (nombre_rol, descripcion) VALUES ('Administrador del Sistema', 'Gestiona usuarios, accesos y configuración de PFlow.');
INSERT INTO Rol (nombre_rol, descripcion) VALUES ('Jefe de Guardia', 'Supervisa la operación del servicio durante el turno.');
INSERT INTO Rol (nombre_rol, descripcion) VALUES ('Coordinador de Camas', 'Gestiona la disponibilidad y asignación de camas y recursos.');
INSERT INTO Rol (nombre_rol, descripcion) VALUES ('Tecnólogo Médico', 'Ejecuta exámenes de laboratorio e imágenes.');
INSERT INTO Rol (nombre_rol, descripcion) VALUES ('Obstetra', 'Atiende emergencias gineco-obstétricas.');
INSERT INTO Rol (nombre_rol, descripcion) VALUES ('Médico Especialista', 'Atiende interconsultas de su especialidad.');
INSERT INTO Rol (nombre_rol, descripcion) VALUES ('Auditor Clínico', 'Revisa la trazabilidad y calidad de las atenciones.');
INSERT INTO Rol (nombre_rol, descripcion) VALUES ('Químico Farmacéutico', 'Dispensa y controla medicamentos de emergencia.');
INSERT INTO Rol (nombre_rol, descripcion) VALUES ('Supervisor de Calidad', 'Monitorea indicadores y tiempos de atención.');
GO

INSERT INTO Paciente (codigo_paciente, tipo_documento, documento_hash, fecha_nacimiento) VALUES ('PAC-0001', 'DNI', 'a7e1ecc6104089c1bf15a121a0957d705d142b1f9c382f93ef2f77527a5c4266', '1965-10-08');
INSERT INTO Paciente (codigo_paciente, tipo_documento, documento_hash, fecha_nacimiento) VALUES ('PAC-0002', 'DNI', '1fadd8dd74019d4ad6ddaa166c7a48e75bd6997e4f33ba3ffdc200c6fc1b4ae2', '1980-05-04');
INSERT INTO Paciente (codigo_paciente, tipo_documento, documento_hash, fecha_nacimiento) VALUES ('PAC-0003', 'DNI', 'ddb8c1e7357c1f387a9550c172508fe536176b33297e565dcdd7b84053810ba0', '2013-02-04');
INSERT INTO Paciente (codigo_paciente, tipo_documento, documento_hash, fecha_nacimiento) VALUES ('PAC-0004', 'DNI', '993a53627cbe01dc4032c917fe325418a3140baae26d1117211947eaea2dc184', '2000-12-13');
INSERT INTO Paciente (codigo_paciente, tipo_documento, documento_hash, fecha_nacimiento) VALUES ('PAC-0005', 'DNI', 'cbc3c3c20c480a3d5a3666abae01be201d883394dabbe3b6fcf5f5eb4a24d624', '1958-11-10');
INSERT INTO Paciente (codigo_paciente, tipo_documento, documento_hash, fecha_nacimiento) VALUES ('PAC-0006', 'DNI', 'ff6101143c632e0da455114ac7f3a99dbab9b766896c78d64ca3b01e986dc8a7', '1962-07-25');
INSERT INTO Paciente (codigo_paciente, tipo_documento, documento_hash, fecha_nacimiento) VALUES ('PAC-0007', 'DNI', '798d199df5f70a1426a26c7d4e9c8c2870d22793f45514ce36916e689f1f1edd', '2023-05-16');
INSERT INTO Paciente (codigo_paciente, tipo_documento, documento_hash, fecha_nacimiento) VALUES ('PAC-0008', 'DNI', '47ee24428116dd5d1cb485cb77aabad23e859a11fce6745757217ab866aa76af', '2012-03-25');
INSERT INTO Paciente (codigo_paciente, tipo_documento, documento_hash, fecha_nacimiento) VALUES ('PAC-0009', 'Pasaporte', 'b5ab4b7eaa8b396fdf915b2fcedb1b24fbfd76809d7be0a01ef58c38186e55f0', '2006-12-03');
INSERT INTO Paciente (codigo_paciente, tipo_documento, documento_hash, fecha_nacimiento) VALUES ('PAC-0010', 'DNI', 'ba36310f356989bddd150b980546ec17c97349dcf90967a0197ed06f6cfd7eb1', '1997-03-18');
INSERT INTO Paciente (codigo_paciente, tipo_documento, documento_hash, fecha_nacimiento) VALUES ('PAC-0011', 'DNI', '31d0f825c1d5f5255a0fd651285a673d36e66c47e3cfd72759f49df5e6efc07f', '2004-11-14');
INSERT INTO Paciente (codigo_paciente, tipo_documento, documento_hash, fecha_nacimiento) VALUES ('PAC-0012', 'DNI', '094818838e7c96539adc2fa3629caa0151c04dc097e2d5bb28a7ca1305489721', '1948-01-17');
INSERT INTO Paciente (codigo_paciente, tipo_documento, documento_hash, fecha_nacimiento) VALUES ('PAC-0013', 'DNI', 'a665edc27a4dc52442b90f1706d25a3da9526d68f8082fe990202872836348d9', '1965-10-20');
INSERT INTO Paciente (codigo_paciente, tipo_documento, documento_hash, fecha_nacimiento) VALUES ('PAC-0014', 'CE', '94bd5101059ba7c7067aeedb9f38654f23ca9d807358d92fbb2e891a5358c9cf', '1952-08-21');
INSERT INTO Paciente (codigo_paciente, tipo_documento, documento_hash, fecha_nacimiento) VALUES ('PAC-0015', 'DNI', '03fde53b53d0ed957cc83107c780b841ccb5e023e497071eb3d671c190105d8e', '1942-03-21');
INSERT INTO Paciente (codigo_paciente, tipo_documento, documento_hash, fecha_nacimiento) VALUES ('PAC-0016', 'Pasaporte', '981d5399314e495ce87ca914bf5c3ab397d0ef91ec0b3668e8280a075facf6d1', '1972-08-12');
INSERT INTO Paciente (codigo_paciente, tipo_documento, documento_hash, fecha_nacimiento) VALUES ('PAC-0017', 'CE', '4590595fdcf222e7017813c665ea75fc884695b5156da874c8180fac12e6b1c1', '1977-11-17');
INSERT INTO Paciente (codigo_paciente, tipo_documento, documento_hash, fecha_nacimiento) VALUES ('PAC-0018', 'CE', '21b3c5897af1fad151fc0fd38cfb95625f80b95fcf50549004cdbe4e062fb9b9', '1975-10-11');
INSERT INTO Paciente (codigo_paciente, tipo_documento, documento_hash, fecha_nacimiento) VALUES ('PAC-0019', 'DNI', '8e2859feec1f567216ca0e7a7f08fd33f524f6e95aa64e7bf4201249428b30d7', '2017-10-20');
INSERT INTO Paciente (codigo_paciente, tipo_documento, documento_hash, fecha_nacimiento) VALUES ('PAC-0020', 'DNI', '55dd72b56c54e64335ee18af4514c34a8ca188c7dfb5fc42eb1bb08faecaf4f9', '1978-03-02');
GO

INSERT INTO AreaAtencion (nombre_area, tipo_area, estado_area, id_establecimiento) VALUES ('Triaje', 'Triaje', 'Activo', 1);
INSERT INTO AreaAtencion (nombre_area, tipo_area, estado_area, id_establecimiento) VALUES ('Shock Trauma', 'Shock Trauma', 'Activo', 2);
INSERT INTO AreaAtencion (nombre_area, tipo_area, estado_area, id_establecimiento) VALUES ('Observación Adultos', 'Observación', 'Activo', 3);
INSERT INTO AreaAtencion (nombre_area, tipo_area, estado_area, id_establecimiento) VALUES ('Observación Pediátrica', 'Observación', 'Activo', 4);
INSERT INTO AreaAtencion (nombre_area, tipo_area, estado_area, id_establecimiento) VALUES ('Tópico de Procedimientos', 'Tópico', 'Activo', 5);
INSERT INTO AreaAtencion (nombre_area, tipo_area, estado_area, id_establecimiento) VALUES ('Sala de Reanimación', 'Reanimación', 'Activo', 6);
INSERT INTO AreaAtencion (nombre_area, tipo_area, estado_area, id_establecimiento) VALUES ('Unidad de Cuidados Intermedios', 'Hospitalización', 'Activo', 7);
INSERT INTO AreaAtencion (nombre_area, tipo_area, estado_area, id_establecimiento) VALUES ('Emergencia Gineco-Obstétrica', 'Observación', 'Activo', 8);
INSERT INTO AreaAtencion (nombre_area, tipo_area, estado_area, id_establecimiento) VALUES ('Triaje', 'Triaje', 'Activo', 9);
INSERT INTO AreaAtencion (nombre_area, tipo_area, estado_area, id_establecimiento) VALUES ('Shock Trauma', 'Shock Trauma', 'Activo', 10);
INSERT INTO AreaAtencion (nombre_area, tipo_area, estado_area, id_establecimiento) VALUES ('Observación Adultos', 'Observación', 'Activo', 11);
INSERT INTO AreaAtencion (nombre_area, tipo_area, estado_area, id_establecimiento) VALUES ('Observación Pediátrica', 'Observación', 'Activo', 12);
INSERT INTO AreaAtencion (nombre_area, tipo_area, estado_area, id_establecimiento) VALUES ('Tópico de Procedimientos', 'Tópico', 'Activo', 13);
INSERT INTO AreaAtencion (nombre_area, tipo_area, estado_area, id_establecimiento) VALUES ('Sala de Reanimación', 'Reanimación', 'Inactivo', 14);
INSERT INTO AreaAtencion (nombre_area, tipo_area, estado_area, id_establecimiento) VALUES ('Unidad de Cuidados Intermedios', 'Hospitalización', 'Activo', 15);
INSERT INTO AreaAtencion (nombre_area, tipo_area, estado_area, id_establecimiento) VALUES ('Emergencia Gineco-Obstétrica', 'Observación', 'Activo', 9);
INSERT INTO AreaAtencion (nombre_area, tipo_area, estado_area, id_establecimiento) VALUES ('Tópico de Procedimientos', 'Tópico', 'Activo', 7);
INSERT INTO AreaAtencion (nombre_area, tipo_area, estado_area, id_establecimiento) VALUES ('Unidad de Cuidados Intermedios', 'Hospitalización', 'Activo', 14);
INSERT INTO AreaAtencion (nombre_area, tipo_area, estado_area, id_establecimiento) VALUES ('Emergencia Gineco-Obstétrica', 'Observación', 'Activo', 10);
INSERT INTO AreaAtencion (nombre_area, tipo_area, estado_area, id_establecimiento) VALUES ('Triaje', 'Triaje', 'Inactivo', 9);
GO

INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-001', 'Camilla', 'Disponible', 1);
INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-002', 'Cuna térmica', 'Disponible', 2);
INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-003', 'Cuna térmica', 'Disponible', 3);
INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-004', 'Cama pediátrica', 'Mantenimiento', 4);
INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-005', 'Cama pediátrica', 'Disponible', 5);
INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-006', 'Cama de observación', 'Disponible', 6);
INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-007', 'Cuna térmica', 'Mantenimiento', 7);
INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-008', 'Cuna térmica', 'Mantenimiento', 8);
INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-009', 'Sillón de procedimientos', 'Ocupada', 9);
INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-010', 'Cuna térmica', 'Mantenimiento', 10);
INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-011', 'Sillón de procedimientos', 'Ocupada', 11);
INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-012', 'Cama pediátrica', 'Mantenimiento', 12);
INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-013', 'Camilla', 'Mantenimiento', 13);
INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-014', 'Cama UCI', 'Ocupada', 14);
INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-015', 'Cama de observación', 'Disponible', 15);
INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-016', 'Cuna térmica', 'Disponible', 16);
INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-017', 'Sillón de procedimientos', 'Mantenimiento', 17);
INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-018', 'Cama UCI', 'Mantenimiento', 18);
INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-019', 'Cama UCI', 'Disponible', 19);
INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-020', 'Cama pediátrica', 'Mantenimiento', 20);
INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-021', 'Cama pediátrica', 'Mantenimiento', 17);
INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-022', 'Cama UCI', 'Disponible', 18);
INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-023', 'Cama de observación', 'Mantenimiento', 11);
INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-024', 'Cama pediátrica', 'Ocupada', 15);
INSERT INTO CamaRecurso (codigo_cama, tipo_cama, estado_cama, id_area) VALUES ('CAMA-025', 'Cuna térmica', 'Mantenimiento', 6);
GO

INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('Carlos', 'Rojas Vega', 'Activo', 'Médico Emergenciólogo', 1, 1);
INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('María', 'Vargas Lima', 'Activo', 'Médico de Guardia', 2, 2);
INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('Jorge', 'Fernández Ruiz', 'Activo', 'Enfermero(a) de Triaje', 3, 3);
INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('Rosa', 'Torres Salas', 'Activo', 'Enfermero(a) de Emergencia', 4, 4);
INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('Luis', 'Castillo Paz', 'Activo', 'Técnico(a) de Enfermería', 5, 5);
INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('Ana', 'Ramírez Díaz', 'Activo', 'Personal de Admisión', 6, 6);
INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('Pedro', 'Mendoza Cruz', 'Activo', 'Administrador de TI', 7, 7);
INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('Carla', 'Salazar Ortiz', 'Activo', 'Jefe de Guardia', 8, 8);
INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('Diego', 'Chávez Rivas', 'Activo', 'Coordinador de Camas', 9, 9);
INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('Fiorella', 'Paredes Soto', 'Activo', 'Tecnólogo Médico', 10, 10);
INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('Miguel', 'Guzmán Flores', 'Activo', 'Obstetra', 11, 11);
INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('Valeria', 'Huamán Quispe', 'Activo', 'Médico Especialista', 12, 12);
INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('Renato', 'Soto Medina', 'Activo', 'Auditor Clínico', 13, 13);
INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('Katherine', 'Quiroz Luna', 'Activo', 'Químico Farmacéutico', 14, 14);
INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('Andrés', 'Núñez Campos', 'Activo', 'Supervisor de Calidad', 15, 15);
INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('Gabriela', 'Herrera Silva', 'Activo', 'Médico Emergenciólogo', 8, 1);
INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('Sofía', 'Cárdenas Rey', 'Activo', 'Médico de Guardia', 2, 2);
INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('Javier', 'Delgado Mora', 'Activo', 'Enfermero(a) de Triaje', 11, 3);
INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('Lucía', 'Ponce Arce', 'Activo', 'Enfermero(a) de Emergencia', 5, 4);
INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('Héctor', 'Vílchez Cano', 'Activo', 'Técnico(a) de Enfermería', 15, 5);
INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('Paola', 'Zegarra Ayala', 'Activo', 'Personal de Admisión', 8, 6);
INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('Ricardo', 'Benites Roca', 'Activo', 'Administrador de TI', 6, 7);
INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('Daniela', 'Arce Palomino', 'Inactivo', 'Jefe de Guardia', 2, 8);
INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('Fernando', 'Lozano Reyes', 'Activo', 'Coordinador de Camas', 4, 9);
INSERT INTO UsuarioPersonalSalud (nombres, apellidos, estado_usuario, cargo, id_establecimiento, id_rol) VALUES ('Milagros', 'Peña Ccori', 'Activo', 'Tecnólogo Médico', 12, 10);
GO

-- AtencionEmergencia (25 filas)
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('Transferido', '20260920 06:50:00', '20260920 18:59:00', 16, 8);
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('Alta médica', '20260920 08:00:00', '20260921 13:39:00', 17, 4);
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('Retiro voluntario', '20260923 01:15:00', '20260923 17:58:00', 15, 10);
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('Alta médica', '20260924 06:30:00', '20260925 09:32:00', 3, 9);
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('Alta médica', '20260924 22:15:00', '20260926 11:14:00', 6, 1);
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('Retiro voluntario', '20260924 23:15:00', '20260925 13:45:00', 15, 14);
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('Transferido', '20260925 10:20:00', '20260926 21:33:00', 1, 3);
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('Alta médica', '20260927 09:00:00', '20260927 22:24:00', 5, 3);
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('Alta médica', '20260929 08:40:00', '20260930 13:35:00', 14, 9);
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('Alta médica', '20261002 02:30:00', '20261002 15:52:00', 13, 5);
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('Hospitalizado', '20261002 06:05:00', '20261003 15:54:00', 9, 8);
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('Transferido', '20261002 08:00:00', '20261002 21:20:00', 10, 8);
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('Transferido', '20261003 10:45:00', '20261003 20:18:00', 16, 8);
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('Alta médica', '20261004 16:05:00', '20261005 00:59:00', 9, 14);
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('Hospitalizado', '20261005 00:50:00', '20261005 08:46:00', 8, 1);
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('Retiro voluntario', '20261005 16:20:00', '20261007 05:10:00', 11, 7);
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('Alta médica', '20261006 00:10:00', '20261007 01:04:00', 6, 1);
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('Alta médica', '20261006 19:40:00', '20261008 07:53:00', 12, 9);
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('Transferido', '20261007 14:30:00', '20261008 10:05:00', 20, 12);
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('Alta médica', '20261009 00:45:00', '20261009 21:21:00', 7, 10);
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('Alta médica', '20261010 04:50:00', '20261010 13:40:00', 18, 3);
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('En proceso', '20261010 22:15:00', NULL, 4, 7);
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('En proceso', '20261011 02:40:00', NULL, 6, 2);
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('En proceso', '20261011 06:05:00', NULL, 2, 13);
INSERT INTO AtencionEmergencia (estado_final, fecha_hora_ingreso, fecha_hora_egreso, id_paciente, id_establecimiento) VALUES ('En proceso', '20261011 08:30:00', NULL, 12, 12);
GO

-- Triaje (25 filas - relación 1:1 con AtencionEmergencia)
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('III', '20260920 06:59:00', 'PA 108/92; FC 98; FR 18; T 36.4; SpO2 94%', 1, 16);
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('II', '20260920 08:09:00', 'PA 127/64; FC 59; FR 20; T 37.6; SpO2 96%', 2, 4);
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('I', '20260923 01:20:00', 'PA 125/61; FC 97; FR 15; T 36.6; SpO2 98%', 3, 10);
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('IV', '20260924 06:44:00', 'PA 153/98; FC 62; FR 28; T 38.5; SpO2 95%', 4, 9);
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('III', '20260924 22:33:00', 'PA 110/103; FC 105; FR 27; T 37.6; SpO2 96%', 5, 1);
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('I', '20260924 23:30:00', 'PA 150/61; FC 94; FR 25; T 38.1; SpO2 94%', 6, 14);
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('IV', '20260925 10:33:00', 'PA 148/80; FC 60; FR 22; T 38.1; SpO2 93%', 7, 3);
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('II', '20260927 09:07:00', 'PA 110/67; FC 62; FR 16; T 38.2; SpO2 99%', 8, 3);
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('III', '20260929 08:44:00', 'PA 169/68; FC 103; FR 20; T 38.4; SpO2 96%', 9, 9);
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('III', '20261002 02:47:00', 'PA 123/68; FC 81; FR 22; T 36.1; SpO2 98%', 10, 19);
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('IV', '20261002 06:17:00', 'PA 113/74; FC 60; FR 14; T 37.7; SpO2 98%', 11, 16);
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('II', '20261002 08:17:00', 'PA 135/68; FC 69; FR 27; T 37.1; SpO2 98%', 12, 8);
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('IV', '20261003 11:05:00', 'PA 128/81; FC 124; FR 26; T 38.0; SpO2 90%', 13, 21);
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('III', '20261004 16:09:00', 'PA 126/90; FC 65; FR 17; T 36.9; SpO2 96%', 14, 14);
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('III', '20261005 01:01:00', 'PA 130/81; FC 83; FR 19; T 38.2; SpO2 97%', 15, 1);
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('IV', '20261005 16:39:00', 'PA 169/79; FC 82; FR 16; T 38.6; SpO2 92%', 16, 7);
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('II', '20261006 00:14:00', 'PA 161/104; FC 110; FR 26; T 36.2; SpO2 92%', 17, 1);
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('II', '20261006 19:53:00', 'PA 164/76; FC 75; FR 25; T 36.6; SpO2 90%', 18, 9);
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('III', '20261007 14:43:00', 'PA 100/85; FC 106; FR 22; T 37.0; SpO2 98%', 19, 12);
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('II', '20261009 00:51:00', 'PA 144/81; FC 91; FR 18; T 36.2; SpO2 99%', 20, 10);
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('II', '20261010 04:59:00', 'PA 132/94; FC 94; FR 19; T 36.8; SpO2 96%', 21, 3);
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('IV', '20261010 22:19:00', 'PA 156/87; FC 103; FR 26; T 37.0; SpO2 98%', 22, 7);
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('II', '20261011 02:49:00', 'PA 164/69; FC 78; FR 14; T 36.7; SpO2 98%', 23, 2);
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('I', '20261011 06:20:00', 'PA 142/79; FC 85; FR 22; T 36.9; SpO2 99%', 24, 13);
INSERT INTO Triaje (prioridad, fecha_hora_triaje, signos_vitales, id_atencion, id_usuario) VALUES ('I', '20261011 08:38:00', 'PA 136/91; FC 71; FR 27; T 36.4; SpO2 96%', 25, 25);
GO

INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20260920 06:50:00', 'Registro de ingreso por emergencia.', 1, NULL, NULL, 21);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20260920 06:59:00', 'Clasificación de prioridad III.', 1, 8, NULL, 16);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20260920 07:39:00', 'Paciente ubicado para observación.', 1, 8, 8, 16);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Solicitud de examen de apoyo', '20260920 09:05:00', 'Se solicita apoyo al diagnóstico.', 1, NULL, NULL, 8);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Referencia a otro establecimiento', '20260920 18:59:00', 'Cierre de la atención de emergencia.', 1, NULL, NULL, 16);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20260920 08:00:00', 'Registro de ingreso por emergencia.', 2, NULL, NULL, 24);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20260920 08:09:00', 'Clasificación de prioridad II.', 2, 4, NULL, 4);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20260920 09:08:00', 'Paciente ubicado para observación.', 2, 4, 4, 4);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Alta médica', '20260921 13:39:00', 'Cierre de la atención de emergencia.', 2, NULL, NULL, 24);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20260923 01:15:00', 'Registro de ingreso por emergencia.', 3, NULL, NULL, 10);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20260923 01:20:00', 'Clasificación de prioridad I.', 3, 19, NULL, 10);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20260923 01:57:00', 'Paciente ubicado para observación.', 3, 10, 10, 10);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Solicitud de examen de apoyo', '20260923 03:49:00', 'Se solicita apoyo al diagnóstico.', 3, NULL, NULL, 10);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Retiro voluntario', '20260923 17:58:00', 'Cierre de la atención de emergencia.', 3, NULL, NULL, 10);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20260924 06:30:00', 'Registro de ingreso por emergencia.', 4, NULL, NULL, 9);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20260924 06:44:00', 'Clasificación de prioridad IV.', 4, 16, NULL, 9);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20260924 07:08:00', 'Paciente ubicado para observación.', 4, 9, 9, 9);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Alta médica', '20260925 09:32:00', 'Cierre de la atención de emergencia.', 4, NULL, NULL, 9);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20260924 22:15:00', 'Registro de ingreso por emergencia.', 5, NULL, NULL, 1);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20260924 22:33:00', 'Clasificación de prioridad III.', 5, 1, NULL, 1);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20260924 23:11:00', 'Paciente ubicado para observación.', 5, 1, 1, 1);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Solicitud de examen de apoyo', '20260925 00:13:00', 'Se solicita apoyo al diagnóstico.', 5, NULL, NULL, 1);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Alta médica', '20260926 11:14:00', 'Cierre de la atención de emergencia.', 5, NULL, NULL, 1);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20260924 23:15:00', 'Registro de ingreso por emergencia.', 6, NULL, NULL, 14);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20260924 23:30:00', 'Clasificación de prioridad I.', 6, 18, NULL, 14);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20260925 00:14:00', 'Paciente ubicado para observación.', 6, 18, 18, 14);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Solicitud de examen de apoyo', '20260925 00:52:00', 'Se solicita apoyo al diagnóstico.', 6, NULL, NULL, 14);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Retiro voluntario', '20260925 13:45:00', 'Cierre de la atención de emergencia.', 6, NULL, NULL, 14);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20260925 10:20:00', 'Registro de ingreso por emergencia.', 7, NULL, NULL, 3);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20260925 10:33:00', 'Clasificación de prioridad IV.', 7, 3, NULL, 3);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20260925 10:44:00', 'Paciente ubicado para observación.', 7, 3, 3, 3);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Referencia a otro establecimiento', '20260926 21:33:00', 'Cierre de la atención de emergencia.', 7, NULL, NULL, 3);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20260927 09:00:00', 'Registro de ingreso por emergencia.', 8, NULL, NULL, 3);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20260927 09:07:00', 'Clasificación de prioridad II.', 8, 3, NULL, 3);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20260927 09:39:00', 'Paciente ubicado para observación.', 8, 3, 3, 3);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Solicitud de examen de apoyo', '20260927 10:50:00', 'Se solicita apoyo al diagnóstico.', 8, NULL, NULL, 3);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Alta médica', '20260927 22:24:00', 'Cierre de la atención de emergencia.', 8, NULL, NULL, 3);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20260929 08:40:00', 'Registro de ingreso por emergencia.', 9, NULL, NULL, 9);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20260929 08:44:00', 'Clasificación de prioridad III.', 9, 16, NULL, 9);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20260929 09:31:00', 'Paciente ubicado para observación.', 9, 9, 9, 9);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Alta médica', '20260930 13:35:00', 'Cierre de la atención de emergencia.', 9, NULL, NULL, 9);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20261002 02:30:00', 'Registro de ingreso por emergencia.', 10, NULL, NULL, 19);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20261002 02:47:00', 'Clasificación de prioridad III.', 10, 5, NULL, 19);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20261002 03:45:00', 'Paciente ubicado para observación.', 10, 5, 5, 5);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Alta médica', '20261002 15:52:00', 'Cierre de la atención de emergencia.', 10, NULL, NULL, 19);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20261002 06:05:00', 'Registro de ingreso por emergencia.', 11, NULL, NULL, 8);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20261002 06:17:00', 'Clasificación de prioridad IV.', 11, 8, NULL, 16);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20261002 06:59:00', 'Paciente ubicado para observación.', 11, 8, 8, 16);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Traslado a hospitalización', '20261003 15:54:00', 'Cierre de la atención de emergencia.', 11, NULL, NULL, 16);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20261002 08:00:00', 'Registro de ingreso por emergencia.', 12, NULL, NULL, 21);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20261002 08:17:00', 'Clasificación de prioridad II.', 12, 8, NULL, 8);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20261002 08:33:00', 'Paciente ubicado para observación.', 12, 8, 8, 8);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Solicitud de examen de apoyo', '20261002 09:21:00', 'Se solicita apoyo al diagnóstico.', 12, NULL, NULL, 16);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Referencia a otro establecimiento', '20261002 21:20:00', 'Cierre de la atención de emergencia.', 12, NULL, NULL, 8);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20261003 10:45:00', 'Registro de ingreso por emergencia.', 13, NULL, NULL, 21);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20261003 11:05:00', 'Clasificación de prioridad IV.', 13, 8, NULL, 21);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20261003 11:51:00', 'Paciente ubicado para observación.', 13, 8, 8, 16);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Referencia a otro establecimiento', '20261003 20:18:00', 'Cierre de la atención de emergencia.', 13, NULL, NULL, 21);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20261004 16:05:00', 'Registro de ingreso por emergencia.', 14, NULL, NULL, 14);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20261004 16:09:00', 'Clasificación de prioridad III.', 14, 14, NULL, 14);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20261004 16:45:00', 'Paciente ubicado para observación.', 14, 14, 14, 14);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Solicitud de examen de apoyo', '20261004 18:38:00', 'Se solicita apoyo al diagnóstico.', 14, NULL, NULL, 14);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Alta médica', '20261005 00:59:00', 'Cierre de la atención de emergencia.', 14, NULL, NULL, 14);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20261005 00:50:00', 'Registro de ingreso por emergencia.', 15, NULL, NULL, 1);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20261005 01:01:00', 'Clasificación de prioridad III.', 15, 1, NULL, 1);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20261005 01:49:00', 'Paciente ubicado para observación.', 15, 1, 1, 1);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Solicitud de examen de apoyo', '20261005 02:50:00', 'Se solicita apoyo al diagnóstico.', 15, NULL, NULL, 1);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Traslado a hospitalización', '20261005 08:46:00', 'Cierre de la atención de emergencia.', 15, NULL, NULL, 1);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20261005 16:20:00', 'Registro de ingreso por emergencia.', 16, NULL, NULL, 7);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20261005 16:39:00', 'Clasificación de prioridad IV.', 16, 17, NULL, 7);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20261005 17:12:00', 'Paciente ubicado para observación.', 16, 7, 7, 7);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Retiro voluntario', '20261007 05:10:00', 'Cierre de la atención de emergencia.', 16, NULL, NULL, 7);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20261006 00:10:00', 'Registro de ingreso por emergencia.', 17, NULL, NULL, 1);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20261006 00:14:00', 'Clasificación de prioridad II.', 17, 1, NULL, 1);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20261006 00:43:00', 'Paciente ubicado para observación.', 17, 1, 1, 1);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Solicitud de examen de apoyo', '20261006 01:55:00', 'Se solicita apoyo al diagnóstico.', 17, NULL, NULL, 1);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Alta médica', '20261007 01:04:00', 'Cierre de la atención de emergencia.', 17, NULL, NULL, 1);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20261006 19:40:00', 'Registro de ingreso por emergencia.', 18, NULL, NULL, 9);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20261006 19:53:00', 'Clasificación de prioridad II.', 18, 16, NULL, 9);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20261006 20:34:00', 'Paciente ubicado para observación.', 18, 20, 20, 9);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Alta médica', '20261008 07:53:00', 'Cierre de la atención de emergencia.', 18, NULL, NULL, 9);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20261007 14:30:00', 'Registro de ingreso por emergencia.', 19, NULL, NULL, 12);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20261007 14:43:00', 'Clasificación de prioridad III.', 19, 12, NULL, 12);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20261007 15:26:00', 'Paciente ubicado para observación.', 19, 12, 12, 25);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Referencia a otro establecimiento', '20261008 10:05:00', 'Cierre de la atención de emergencia.', 19, NULL, NULL, 12);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20261009 00:45:00', 'Registro de ingreso por emergencia.', 20, NULL, NULL, 10);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20261009 00:51:00', 'Clasificación de prioridad II.', 20, 10, NULL, 10);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20261009 01:28:00', 'Paciente ubicado para observación.', 20, 10, 10, 10);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Solicitud de examen de apoyo', '20261009 02:22:00', 'Se solicita apoyo al diagnóstico.', 20, NULL, NULL, 10);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Alta médica', '20261009 21:21:00', 'Cierre de la atención de emergencia.', 20, NULL, NULL, 10);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20261010 04:50:00', 'Registro de ingreso por emergencia.', 21, NULL, NULL, 3);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20261010 04:59:00', 'Clasificación de prioridad II.', 21, 3, NULL, 3);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20261010 05:18:00', 'Paciente ubicado para observación.', 21, 3, 3, 3);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Alta médica', '20261010 13:40:00', 'Cierre de la atención de emergencia.', 21, NULL, NULL, 3);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20261010 22:15:00', 'Registro de ingreso por emergencia.', 22, NULL, NULL, 7);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20261010 22:19:00', 'Clasificación de prioridad IV.', 22, 7, NULL, 7);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20261010 22:40:00', 'Paciente ubicado para observación.', 22, 17, 21, 7);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Solicitud de examen de apoyo', '20261011 00:09:00', 'Se solicita apoyo al diagnóstico.', 22, NULL, NULL, 7);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20261011 02:40:00', 'Registro de ingreso por emergencia.', 23, NULL, NULL, 17);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20261011 02:49:00', 'Clasificación de prioridad II.', 23, 2, NULL, 2);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20261011 03:43:00', 'Paciente ubicado para observación.', 23, 2, 2, 2);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20261011 06:05:00', 'Registro de ingreso por emergencia.', 24, NULL, NULL, 13);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20261011 06:20:00', 'Clasificación de prioridad I.', 24, 13, NULL, 13);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20261011 06:49:00', 'Paciente ubicado para observación.', 24, 13, 13, 13);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Solicitud de examen de apoyo', '20261011 08:18:00', 'Se solicita apoyo al diagnóstico.', 24, NULL, NULL, 13);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Admisión del paciente', '20261011 08:30:00', 'Registro de ingreso por emergencia.', 25, NULL, NULL, 25);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Triaje realizado', '20261011 08:38:00', 'Clasificación de prioridad I.', 25, 12, NULL, 25);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Asignación de cama', '20261011 08:57:00', 'Paciente ubicado para observación.', 25, 12, 12, 12);
INSERT INTO EventoAtencion (tipo_evento, fecha_hora_evento, observacion, id_atencion, id_area, id_cama, id_usuario) VALUES ('Solicitud de examen de apoyo', '20261011 09:24:00', 'Se solicita apoyo al diagnóstico.', 25, NULL, NULL, 12);
GO

INSERT INTO Interconsulta (especialidad_solicitada, fecha_hora_solicitud, fecha_hora_atencion, estado_interconsulta, id_atencion) VALUES ('Medicina Interna', '20260920 07:34:00', '20260920 09:25:00', 'Atendida', 1);
INSERT INTO Interconsulta (especialidad_solicitada, fecha_hora_solicitud, fecha_hora_atencion, estado_interconsulta, id_atencion) VALUES ('Gastroenterología', '20260923 02:35:00', NULL, 'Pendiente', 3);
INSERT INTO Interconsulta (especialidad_solicitada, fecha_hora_solicitud, fecha_hora_atencion, estado_interconsulta, id_atencion) VALUES ('Ginecología', '20260924 07:06:00', NULL, 'Pendiente', 4);
INSERT INTO Interconsulta (especialidad_solicitada, fecha_hora_solicitud, fecha_hora_atencion, estado_interconsulta, id_atencion) VALUES ('Neumología', '20260925 01:13:00', '20260925 01:59:00', 'Atendida', 6);
INSERT INTO Interconsulta (especialidad_solicitada, fecha_hora_solicitud, fecha_hora_atencion, estado_interconsulta, id_atencion) VALUES ('Ginecología', '20260925 12:00:00', '20260925 12:56:00', 'Atendida', 7);
INSERT INTO Interconsulta (especialidad_solicitada, fecha_hora_solicitud, fecha_hora_atencion, estado_interconsulta, id_atencion) VALUES ('Medicina Interna', '20260927 11:14:00', '20260927 11:44:00', 'Atendida', 8);
INSERT INTO Interconsulta (especialidad_solicitada, fecha_hora_solicitud, fecha_hora_atencion, estado_interconsulta, id_atencion) VALUES ('Gastroenterología', '20260929 11:09:00', NULL, 'Pendiente', 9);
INSERT INTO Interconsulta (especialidad_solicitada, fecha_hora_solicitud, fecha_hora_atencion, estado_interconsulta, id_atencion) VALUES ('Neurología', '20261002 04:45:00', NULL, 'Pendiente', 10);
INSERT INTO Interconsulta (especialidad_solicitada, fecha_hora_solicitud, fecha_hora_atencion, estado_interconsulta, id_atencion) VALUES ('Cirugía General', '20261002 06:46:00', '20261002 08:40:00', 'Atendida', 11);
INSERT INTO Interconsulta (especialidad_solicitada, fecha_hora_solicitud, fecha_hora_atencion, estado_interconsulta, id_atencion) VALUES ('Neumología', '20261002 08:57:00', NULL, 'Pendiente', 12);
INSERT INTO Interconsulta (especialidad_solicitada, fecha_hora_solicitud, fecha_hora_atencion, estado_interconsulta, id_atencion) VALUES ('Medicina Interna', '20261005 02:05:00', NULL, 'Pendiente', 15);
INSERT INTO Interconsulta (especialidad_solicitada, fecha_hora_solicitud, fecha_hora_atencion, estado_interconsulta, id_atencion) VALUES ('Gastroenterología', '20261005 18:26:00', '20261005 19:45:00', 'Atendida', 16);
INSERT INTO Interconsulta (especialidad_solicitada, fecha_hora_solicitud, fecha_hora_atencion, estado_interconsulta, id_atencion) VALUES ('Cardiología', '20261006 01:04:00', NULL, 'Cancelada', 17);
INSERT INTO Interconsulta (especialidad_solicitada, fecha_hora_solicitud, fecha_hora_atencion, estado_interconsulta, id_atencion) VALUES ('Traumatología', '20261006 22:03:00', '20261006 23:25:00', 'Atendida', 18);
INSERT INTO Interconsulta (especialidad_solicitada, fecha_hora_solicitud, fecha_hora_atencion, estado_interconsulta, id_atencion) VALUES ('Cirugía General', '20261007 16:32:00', '20261007 18:22:00', 'Atendida', 19);
INSERT INTO Interconsulta (especialidad_solicitada, fecha_hora_solicitud, fecha_hora_atencion, estado_interconsulta, id_atencion) VALUES ('Cirugía General', '20261010 05:33:00', NULL, 'Pendiente', 21);
INSERT INTO Interconsulta (especialidad_solicitada, fecha_hora_solicitud, fecha_hora_atencion, estado_interconsulta, id_atencion) VALUES ('Gastroenterología', '20261011 03:49:00', NULL, 'Pendiente', 23);
INSERT INTO Interconsulta (especialidad_solicitada, fecha_hora_solicitud, fecha_hora_atencion, estado_interconsulta, id_atencion) VALUES ('Urología', '20261011 09:44:00', NULL, 'Pendiente', 25);
GO

INSERT INTO SolicitudServicioApoyo (tipo_servicio, fecha_hora_solicitud, fecha_hora_resultado, estado_solicitud, id_atencion) VALUES ('Ecografía', '20260920 07:25:00', '20260920 10:05:00', 'Resultado entregado', 1);
INSERT INTO SolicitudServicioApoyo (tipo_servicio, fecha_hora_solicitud, fecha_hora_resultado, estado_solicitud, id_atencion) VALUES ('Electrocardiograma', '20260920 09:42:00', '20260920 11:45:00', 'Resultado entregado', 2);
INSERT INTO SolicitudServicioApoyo (tipo_servicio, fecha_hora_solicitud, fecha_hora_resultado, estado_solicitud, id_atencion) VALUES ('Ecografía', '20260923 03:27:00', NULL, 'Pendiente', 3);
INSERT INTO SolicitudServicioApoyo (tipo_servicio, fecha_hora_solicitud, fecha_hora_resultado, estado_solicitud, id_atencion) VALUES ('Banco de Sangre', '20260924 08:18:00', NULL, 'En proceso', 4);
INSERT INTO SolicitudServicioApoyo (tipo_servicio, fecha_hora_solicitud, fecha_hora_resultado, estado_solicitud, id_atencion) VALUES ('Rayos X', '20260924 22:47:00', '20260925 00:33:00', 'Resultado entregado', 5);
INSERT INTO SolicitudServicioApoyo (tipo_servicio, fecha_hora_solicitud, fecha_hora_resultado, estado_solicitud, id_atencion) VALUES ('Laboratorio', '20260924 23:48:00', '20260925 01:53:00', 'Resultado entregado', 6);
INSERT INTO SolicitudServicioApoyo (tipo_servicio, fecha_hora_solicitud, fecha_hora_resultado, estado_solicitud, id_atencion) VALUES ('Tomografía', '20260925 11:11:00', NULL, 'Pendiente', 7);
INSERT INTO SolicitudServicioApoyo (tipo_servicio, fecha_hora_solicitud, fecha_hora_resultado, estado_solicitud, id_atencion) VALUES ('Banco de Sangre', '20260927 09:32:00', '20260927 10:15:00', 'Resultado entregado', 8);
INSERT INTO SolicitudServicioApoyo (tipo_servicio, fecha_hora_solicitud, fecha_hora_resultado, estado_solicitud, id_atencion) VALUES ('Electrocardiograma', '20260929 10:16:00', '20260929 12:06:00', 'Resultado entregado', 9);
INSERT INTO SolicitudServicioApoyo (tipo_servicio, fecha_hora_solicitud, fecha_hora_resultado, estado_solicitud, id_atencion) VALUES ('Rayos X', '20261002 03:19:00', '20261002 05:44:00', 'Resultado entregado', 10);
INSERT INTO SolicitudServicioApoyo (tipo_servicio, fecha_hora_solicitud, fecha_hora_resultado, estado_solicitud, id_atencion) VALUES ('Electrocardiograma', '20261002 07:16:00', NULL, 'En proceso', 11);
INSERT INTO SolicitudServicioApoyo (tipo_servicio, fecha_hora_solicitud, fecha_hora_resultado, estado_solicitud, id_atencion) VALUES ('Rayos X', '20261002 09:01:00', NULL, 'En proceso', 12);
INSERT INTO SolicitudServicioApoyo (tipo_servicio, fecha_hora_solicitud, fecha_hora_resultado, estado_solicitud, id_atencion) VALUES ('Laboratorio', '20261003 12:20:00', '20261003 14:32:00', 'Resultado entregado', 13);
INSERT INTO SolicitudServicioApoyo (tipo_servicio, fecha_hora_solicitud, fecha_hora_resultado, estado_solicitud, id_atencion) VALUES ('Rayos X', '20261004 17:37:00', '20261004 20:34:00', 'Resultado entregado', 14);
INSERT INTO SolicitudServicioApoyo (tipo_servicio, fecha_hora_solicitud, fecha_hora_resultado, estado_solicitud, id_atencion) VALUES ('Banco de Sangre', '20261005 02:16:00', '20261005 03:10:00', 'Resultado entregado', 15);
INSERT INTO SolicitudServicioApoyo (tipo_servicio, fecha_hora_solicitud, fecha_hora_resultado, estado_solicitud, id_atencion) VALUES ('Ecografía', '20261005 17:50:00', NULL, 'Pendiente', 16);
INSERT INTO SolicitudServicioApoyo (tipo_servicio, fecha_hora_solicitud, fecha_hora_resultado, estado_solicitud, id_atencion) VALUES ('Laboratorio', '20261006 01:41:00', NULL, 'Pendiente', 17);
INSERT INTO SolicitudServicioApoyo (tipo_servicio, fecha_hora_solicitud, fecha_hora_resultado, estado_solicitud, id_atencion) VALUES ('Electrocardiograma', '20261006 21:13:00', '20261006 23:16:00', 'Resultado entregado', 18);
INSERT INTO SolicitudServicioApoyo (tipo_servicio, fecha_hora_solicitud, fecha_hora_resultado, estado_solicitud, id_atencion) VALUES ('Ecografía', '20261007 15:04:00', NULL, 'Pendiente', 19);
INSERT INTO SolicitudServicioApoyo (tipo_servicio, fecha_hora_solicitud, fecha_hora_resultado, estado_solicitud, id_atencion) VALUES ('Rayos X', '20261009 02:55:00', '20261009 04:35:00', 'Resultado entregado', 20);
INSERT INTO SolicitudServicioApoyo (tipo_servicio, fecha_hora_solicitud, fecha_hora_resultado, estado_solicitud, id_atencion) VALUES ('Tomografía', '20261010 07:10:00', NULL, 'Pendiente', 21);
INSERT INTO SolicitudServicioApoyo (tipo_servicio, fecha_hora_solicitud, fecha_hora_resultado, estado_solicitud, id_atencion) VALUES ('Electrocardiograma', '20261010 23:19:00', NULL, 'En proceso', 22);
GO

SELECT * FROM EstablecimientoSalud;
SELECT * FROM Rol;
SELECT * FROM Paciente;
SELECT * FROM AreaAtencion;
SELECT * FROM CamaRecurso;
SELECT * FROM UsuarioPersonalSalud;
SELECT * FROM AtencionEmergencia;
SELECT * FROM Triaje;
SELECT * FROM EventoAtencion;
SELECT * FROM Interconsulta;
SELECT * FROM SolicitudServicioApoyo;
GO
