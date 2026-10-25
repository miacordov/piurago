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

## Buscador de lugares (base propia + Photon)

Funciona como piuratransporta.com: tiene una **base propia de lugares de Piura**
y un buscador externo como respaldo.

- **Base propia:** `frontend/lib/data/lugares/lugares_piura.dart` tiene unas 2470 calles,
  zonas y lugares conocidos de Piura, Castilla y Veintiséis de Octubre, sacados de
  OpenStreetMap (© colaboradores de OpenStreetMap, ODbL). La genera
  `frontend/tool/generar_lugares_piura.py` con la consulta
  `frontend/tool/lugares_piura.overpassql`; los pasos están en el script. Al buscar
  **no se consulta ningún servicio**: las sugerencias salen al instante y sin red.
- **Respaldo:** solo si la base no llena las 5 sugerencias, se completan con
  Photon. Más abajo se detalla.

El respaldo en línea es Photon
(https://photon.komoot.io), un geocodificador de OpenStreetMap hecho para sugerir
mientras se escribe. No necesita clave. El código está en
`frontend/lib/data/lugares/photon_buscador_lugares.dart`, detrás de la interfaz
`BuscadorLugares`, así que se puede cambiar de servicio.

- **Qué se envía:**
  - solo el texto escrito, con las abreviaturas completas (por ejemplo "av" -> "avenida");
  - un **punto fijo de Piura** (`lat=-5.1945`, `lon=-80.6328`) para ordenar los lugares cercanos;
  - el **recuadro de Piura metropolitana** (`bbox=-80.8,-5.35,-80.5,-5.05`): lo de fuera no sirve para las líneas;
  - además, `limit=6`, `zoom=12` y `location_bias_scale=0.1`.

  Si el texto empieza con un tipo de vía ("jr lima"), se envía solo el nombre
  ("lima") con `osm_tag=highway`, porque en OpenStreetMap el Jr. Lima es "Calle Lima". **Nunca se envía la ubicación real del
  usuario.** Fuera de la web se identifica con el User-Agent
  `PiuraGo/0.1 (com.piurago.piurago)`; en la web el navegador no lo permite.
- **Cuánto se pide:** desde la 2.ª letra y solo si la base propia no llena las
  sugerencias, una petición 300 ms después de la última tecla. Cada respuesta se guarda por texto mientras la pantalla esté abierta. No
  hay reintentos automáticos, y tras un 429 no se pide nada durante 5 segundos.
- **Uso justo:** el servicio público de Photon es de uso justo y no garantiza
  disponibilidad. Para producción conviene levantar un Photon propio (o pasar por
  el backend con caché) y apuntar la app con `--dart-define=GEOCODER_URL=...`.
- **Atribución:** debajo de las sugerencias se muestra "Búsqueda de lugares:
  Photon · © OpenStreetMap contributors".
- **Sin red:** con `--dart-define=DATOS_PRUEBA=true` se usa un buscador local que no
  usa la red. Las pruebas automáticas usan un cliente HTTP falso.

## Pendiente

- Ubicación del usuario en el mapa (necesita el paquete `geolocator` y permisos del
  dispositivo): llega con la pantalla de viaje en vivo.
- Paraderos reales con coordenadas: se cargan al final del proyecto. Las 20 líneas ya
  están cargadas (datos de https://piuratransporta.com/rutas, copia en
  `docs/datos/rutas-piuratransporta.json`), con paraderos PROPUESTOS y coordenadas de
  OpenStreetMap (ver `docs/datos/paraderos-propuestos.md`). El recorrido une los
  paraderos en línea recta: no sigue las calles.
- Android: el permiso de internet ya está en
  `android/app/src/main/AndroidManifest.xml` (mapa y buscador de lugares).
