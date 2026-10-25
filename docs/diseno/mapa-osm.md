# Mapa con OpenStreetMap

El mapa de PiuraGo usa `flutter_map` con las teselas públicas de OpenStreetMap
(`https://tile.openstreetmap.org/{z}/{x}/{y}.png`). No necesita clave de API.
La conexión está en `frontend/lib/features/map/ruta_map.dart`.

## Qué muestra

- Mapa base de OpenStreetMap centrado en la ruta (o en Piura si no hay paraderos).
- Recorrido como línea discontinua con halo blanco, y paraderos numerados.
- Botones de acercar, alejar y centrar la ruta. Rotación desactivada (norte arriba).
- Aviso "Recorrido ilustrativo · ETA de demostración" mientras se usen datos de prueba.

## Política de uso de las teselas de OpenStreetMap

Las teselas públicas **no son de uso libre sin condiciones**. La política de la
Fundación OpenStreetMap (https://operations.osmfoundation.org/policies/tiles/)
exige, entre otras cosas:

- Identificar la aplicación con un User-Agent válido (no el genérico de la librería).
  Aquí se hace con `userAgentPackageName: 'com.piurago.piurago'`.
- Mostrar la atribución de la licencia. Aquí: "© OpenStreetMap contributors",
  visible abajo a la izquierda del mapa.
- Usar la URL HTTPS indicada, sin descargar teselas en masa ni para uso sin conexión.
- No hacer uso intensivo: distribuir una aplicación que genere mucho tráfico requiere
  permiso previo.

Para el piloto del curso el uso es bajo. **Si la aplicación crece**, hay que cambiar
de proveedor de teselas (un servicio de pago, o un servidor propio con datos de
OpenStreetMap). Solo habría que cambiar `RutaMap.urlTeselas`.

## Pendiente

- Ubicación del usuario en el mapa (necesita el paquete `geolocator` y permisos del
  dispositivo): llega con la pantalla de viaje en vivo.
- Paraderos reales con coordenadas: se cargan al final del proyecto. Las 20 líneas ya
  están cargadas (datos de https://piuratransporta.com/rutas, copia en
  `docs/datos/rutas-piuratransporta.json`), con paraderos PROPUESTOS y coordenadas de
  OpenStreetMap (ver `docs/datos/paraderos-propuestos.md`). El recorrido une los
  paraderos en línea recta: no sigue las calles.
- Android: la aplicación necesita el permiso de internet en
  `android/app/src/main/AndroidManifest.xml`.
