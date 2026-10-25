-- Datos de servicio de cada ruta (tipo, horario y pasaje), tomados del Plan
-- Regulador de Rutas que publica PiuraTransporta. Se puede ejecutar más de una
-- vez: solo agrega las columnas que falten.
ALTER TABLE ruta ADD COLUMN IF NOT EXISTS tipo_servicio VARCHAR(15);
ALTER TABLE ruta ADD COLUMN IF NOT EXISTS horario VARCHAR(20);
ALTER TABLE ruta ADD COLUMN IF NOT EXISTS pasaje DECIMAL(5,2);
ALTER TABLE ruta ADD COLUMN IF NOT EXISTS pasaje_estudiante DECIMAL(5,2);
