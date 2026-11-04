-- Índice por fecha para la retención de reportes GPS (RNF-08): la tarea diaria
-- borra los reportes con fecha_hora anterior al plazo y, sin este índice, tendría
-- que recorrer toda la tabla. El índice (id_ruta, fecha_hora) no sirve para esa
-- consulta porque no filtra por ruta. Se puede ejecutar más de una vez.
CREATE INDEX IF NOT EXISTS idx_reporte_gps_fecha ON reporte_gps (fecha_hora);
