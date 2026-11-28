-- Reportes de los pasajeros sobre rutas y paraderos desactualizados (botón
-- "Reportar" de la app). Se puede ejecutar más de una vez.
-- IMPORTANTE: aplicarla en la base ANTES de desplegar el backend que trae la
-- entidad ReporteComunidad: con ddl-auto=validate, sin esta tabla el backend
-- no arranca.
CREATE TABLE IF NOT EXISTS reporte_comunidad (
    id_reporte_comunidad BIGSERIAL PRIMARY KEY,
    id_usuario           BIGINT NOT NULL
                         REFERENCES usuario (id_usuario) ON DELETE CASCADE,
    id_ruta              BIGINT
                         REFERENCES ruta (id_ruta) ON DELETE SET NULL,
    tipo                 VARCHAR(25) NOT NULL
                         CHECK (tipo IN ('RUTA_CAMBIO', 'PARADERO_NUEVO',
                                         'PARADERO_NO_EXISTE', 'OTRO')),
    descripcion          VARCHAR(500) NOT NULL,
    latitud              DECIMAL(9,6),
    longitud             DECIMAL(9,6),
    estado               VARCHAR(15) NOT NULL DEFAULT 'PENDIENTE',
    fecha_hora           TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reporte_comunidad_estado_fecha
    ON reporte_comunidad (estado, fecha_hora DESC);
