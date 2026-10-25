-- =====================================================================
-- PiuraGo - Esquema de la base de datos (PostgreSQL)
-- Consolidado a partir del Apendice A de la guia del backend: la tabla
-- RUTA ya incluye las columnas que antes se agregaban con ALTER TABLE.
--
-- OJO: en la base compartida de Neon este esquema YA esta aplicado.
-- No lo ejecutes de nuevo ahi. Sirve para recrear la base desde cero
-- (por ejemplo, una base local de pruebas).
-- Los datos de rutas y paraderos se cargan aparte (db/seeds/).
-- =====================================================================

-- Tabla padre: todo usuario es ANONIMO o REGISTRADO (generalizacion total y disjunta)
CREATE TABLE usuario (
    id_usuario        BIGSERIAL PRIMARY KEY,
    tipo_usuario      VARCHAR(10) NOT NULL
                       CHECK (tipo_usuario IN ('ANONIMO', 'REGISTRADO')),
    tipo_dispositivo  VARCHAR(20),
    activo            BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_creacion    TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE usuario_registrado (
    id_usuario     BIGINT PRIMARY KEY
                   REFERENCES usuario (id_usuario) ON DELETE CASCADE,
    nombre         VARCHAR(120) NOT NULL,
    email          VARCHAR(160) NOT NULL UNIQUE,
    password_hash  VARCHAR(255) NOT NULL
);

CREATE TABLE usuario_anonimo (
    id_usuario            BIGINT PRIMARY KEY
                          REFERENCES usuario (id_usuario) ON DELETE CASCADE,
    device_uuid           VARCHAR(64) NOT NULL UNIQUE,
    fecha_ultimo_acceso   TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE ruta (
    id_ruta             BIGSERIAL PRIMARY KEY,
    codigo              VARCHAR(10),
    nombre              VARCHAR(80) NOT NULL,
    empresa             VARCHAR(120),
    punto_inicio        VARCHAR(120),
    punto_final         VARCHAR(120),
    sentido             VARCHAR(15) NOT NULL DEFAULT 'IDA_VUELTA',
    descripcion         VARCHAR(255),
    recorrido           TEXT,
    activa              BOOLEAN NOT NULL DEFAULT TRUE,
    tiempo_estimado     INTEGER,
    frecuencia_minutos  INTEGER,
    tipo_servicio       VARCHAR(15),
    horario             VARCHAR(20),
    pasaje              DECIMAL(5,2),
    pasaje_estudiante   DECIMAL(5,2)
);

CREATE UNIQUE INDEX ux_ruta_codigo ON ruta (codigo);

CREATE TABLE paradero (
    id_paradero        BIGSERIAL PRIMARY KEY,
    id_ruta            BIGINT NOT NULL
                       REFERENCES ruta (id_ruta) ON DELETE CASCADE,
    nombre             VARCHAR(100) NOT NULL,
    latitud            DECIMAL(9,6) NOT NULL,
    longitud           DECIMAL(9,6) NOT NULL,
    orden_secuencial   SMALLINT NOT NULL,
    UNIQUE (id_ruta, orden_secuencial)
);

CREATE TABLE reporte_gps (
    id_reporte   BIGSERIAL PRIMARY KEY,
    id_usuario   BIGINT NOT NULL
                 REFERENCES usuario (id_usuario) ON DELETE CASCADE,
    id_ruta      BIGINT NOT NULL
                 REFERENCES ruta (id_ruta) ON DELETE CASCADE,
    latitud      DECIMAL(9,6) NOT NULL,
    longitud     DECIMAL(9,6) NOT NULL,
    fecha_hora   TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reporte_gps_ruta_fecha ON reporte_gps (id_ruta, fecha_hora DESC);
CREATE INDEX idx_reporte_gps_usuario    ON reporte_gps (id_usuario);

CREATE TABLE historico_congestion (
    id_historico             BIGSERIAL PRIMARY KEY,
    id_ruta                  BIGINT NOT NULL
                             REFERENCES ruta (id_ruta) ON DELETE CASCADE,
    id_paradero              BIGINT
                             REFERENCES paradero (id_paradero) ON DELETE SET NULL,
    franja_horaria           VARCHAR(20) NOT NULL,
    tiempo_dia               VARCHAR(10),
    dia_semana               VARCHAR(10) NOT NULL,
    nivel_congestion         VARCHAR(10) NOT NULL,
    demora_promedio          DECIMAL(6,2),
    velocidad_promedio       DECIMAL(6,2),
    cantidad_puntos_criticos SMALLINT,
    fecha_calculo            DATE NOT NULL DEFAULT CURRENT_DATE
);

-- Evita duplicar el mismo calculo (por paradero / a nivel de ruta completa)
CREATE UNIQUE INDEX ux_historico_con_paradero
    ON historico_congestion (id_ruta, id_paradero, franja_horaria, dia_semana)
    WHERE id_paradero IS NOT NULL;
CREATE UNIQUE INDEX ux_historico_sin_paradero
    ON historico_congestion (id_ruta, franja_horaria, dia_semana)
    WHERE id_paradero IS NULL;
CREATE INDEX idx_historico_congestion_consulta
    ON historico_congestion (id_ruta, dia_semana, franja_horaria);
