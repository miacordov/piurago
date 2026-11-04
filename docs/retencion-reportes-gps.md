# Retención de los reportes GPS (RNF-08)

> Decisión del equipo de backend. Fecha: 4 de noviembre de 2026.

## Qué se decidió

Los reportes GPS (la ubicación exacta que comparte un pasajero mientras viaja, tabla `reporte_gps`) se guardan **30 días**. Todos los días, a las **03:30 de Lima**, una tarea programada borra los que tienen más de 30 días.

| Propiedad (`application.properties`) | Valor por defecto | Para qué |
|---|---|---|
| `piurago.gps.retencion-dias` | `30` | Días que se guarda cada reporte. **Mínimo 28**: con menos, el backend no arranca |
| `piurago.gps.retencion-cron` | `0 30 3 * * *` | Cuándo corre la tarea (hora de Lima) |
| `piurago.gps.retencion-automatica` | `true` | `false` apaga la tarea (por ejemplo, para una prueba de carga) |

## Por qué 30 días

RNF-08 pide guardar la ubicación exacta el **menor tiempo posible**. Pero el dashboard de "horas calientes" (`HistoricoCongestionServiceImpl`) calcula la congestión con los reportes de los **últimos 28 días**: cuatro semanas, para tener al menos cuatro lunes, cuatro martes, etc., en cada franja horaria.

- Con **menos de 28 días**, la congestión se calcularía con semanas incompletas y el histórico perdería sentido. Por eso el backend rechaza un plazo menor (el mínimo sale de la misma constante `VENTANA_DIAS` que usa la congestión, así que si un día se cambia esa ventana, la regla la sigue).
- **30 días** deja dos días de margen sobre esos 28. Así, si la tarea de retención o el recálculo de la congestión fallan una noche, o el servidor está apagado, ningún reporte que todavía necesita la congestión se borra antes de tiempo.
- Más de 30 días no aporta nada: ningún cálculo usa reportes más viejos.

Lo que **sí** se guarda sin plazo es el resultado agregado (`historico_congestion`): velocidades promedio y niveles por ruta, franja y día, **sin** posiciones ni usuarios.

## Qué más protege la privacidad

- `GET /api/rutas/{id}/posiciones` muestra solo la última posición de cada colaborador de los últimos minutos, sin su id.
- La app comparte la ubicación solo con consentimiento (opt-in).

## Cómo funciona

- `RetencionGpsProgramada` (paquete `tarea`) llama a `RetencionGpsService.borrarReportesAntiguos()`. Si una ejecución falla (por ejemplo, la base no responde), lo anota en el log y la siguiente corre normalmente.
- El borrado es un solo `DELETE ... WHERE fecha_hora < límite` (no carga los reportes uno por uno), apoyado en el índice `idx_reporte_gps_fecha`.
- El índice se crea con `backend/db/migraciones/002_indice_reporte_gps_fecha.sql`. Se puede ejecutar más de una vez y también lo aplica el perfil `carga`. En una base nueva ya viene en `db/schema.sql`.

## Antes de desplegar

Hay que ejecutar la migración 002 en la base de producción (con pgAdmin o con el perfil `carga`). La primera noche, la tarea borrará de una vez todos los reportes de más de 30 días que ya existan.
