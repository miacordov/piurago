# Guía visual del frontend (referencia para Flutter)

Fuente: prototipo de Lovable "Piura Routes Planner" (repo `piura-route-buddy`, app https://piura-route-buddy.lovable.app). Las capturas están en `capturas/` (1366 x 768 px a 1x). Los valores de color y tamaño están **medidos sobre esas capturas**; los marcados "(código)" salen del CSS del repo exportado.

El prototipo es solo diseño: todo es simulado, el mapa es una ilustración y las 9 líneas y sus ETAs son inventados. La app real usa los datos del backend.

## Propósito

Buscar rutas, encontrar transporte a tiempo y ver reportes de tráfico, para poder tomar otra línea que lleve al mismo lugar por otro camino si una ruta está muy congestionada.

## Flujo

1. Inicio de sesión
2. Activa tu ubicación
3. Rutas (buscar tu línea)
4. Mapa: eliges a dónde ir, ves la ruta y seleccionas "Compartir ruta"
5. Confirmación de abordaje
6. Viaje en vivo (se comparte el GPS y se ve el ETA)
7. Viaje finalizado (resumen)
8. Congestión (dashboard alimentado por los viajes confirmados)

Navegación: barra lateral con Rutas, Mapa y Congestión. En móvil (menos de 760 px) la barra lateral pasa a ser un cajón con pestañas (código).

## Paleta

| Uso | Valor |
|---|---|
| Primario (botones, enlaces, ETA, panel del login, pestaña activa, línea de ruta) | `#342EC1` |
| Fondo de página y formulario | `#EFF5FD` |
| Superficies (tarjetas, barra lateral, barra superior) | `#FFFFFF` |
| Texto principal | `#121B2D` |
| Texto secundario (código) | `#5D6A78` |
| Borde (código) | `#CEDDEB` |
| Relleno de campos y píldoras | `#EAF0F8` |
| Primario suave (ítem activo, caja del paradero actual, franja de estadísticas, aviso del modal) | `#CEE1FC` |
| Ficha azul de línea y avatar | `#D4E4FD` |
| Caja "Próxima unidad estimada" | `#DDF1FF` |
| Botón secundario | fondo `#EFF5FD`, borde `#CFDBEC` |
| Pista de la barra de progreso | `#CEDBEC` |
| Verde: ícono, barras y punto "demo" / "Estás aquí" | `#009248` / `#00973F` |
| Ficha verde / círculo de viaje finalizado | `#DEF1E4` / `#C5FDD3` |
| Naranja: ícono / ficha | `#D49224` / `#F8ECDC` |
| Rojo: barras y nivel alto / chip "Alta" (fondo) | `#DF342B` / `#FFE4E0` |
| Botón "Finalizar viaje" | `#DD0012` |
| Fondo atenuado detrás de un modal | negro al 80 % aproximadamente |

Mapa ilustrado del prototipo (no aplica al mapa real): base `#D9F8FF`, manzanas `#FCF8DF`, parques `#A0CA9B`, río `#A4E4F2`, avenidas `#FFFFFF`, ruta `#342EC0`.

**Sobre el color primario:** el brief original pedía `#226CCD` y el CSS del repo exportado dice `#005DBD`, pero lo que se ve en el prototipo publicado, y en las capturas del informe APF2, es `#342EC1`. Se propone usar `#342EC1`. El repo exportado no coincide con la vista previa de Lovable.

## Tipografía y tamaños

- Fuente del prototipo: tipo Arial/Helvetica. En Flutter se usa la fuente por defecto (Roboto).
- Botones y campos: unos 48 px de alto, radio de unos 6 px.
- Formulario del login: 440 px de ancho. Panel izquierdo del login: aprox. 45 % del ancho.
- Barra superior: unos 77 px. Barra lateral: unos 220 px. Panel derecho del mapa: unos 359 px. Modales: unos 440 px de ancho.
- Tarjetas de ruta: 3 columnas en escritorio, 2 hasta 1050 px y 1 hasta 760 px (código).

## Pantallas

### 1. Inicio de sesión (`01-login.png`)
Panel izquierdo de color primario con el logo, el titular "Tu ruta por Piura, más clara y más cerca." y una ilustración de ruta con "Rutas en tiempo real". A la derecha: "BIENVENIDO A PIURAGO", "Inicia sesión", correo, contraseña, botón "Iniciar sesión", "o inicia sesión con:" (Correo institucional / Cuenta de Google), "¿No tienes una cuenta? Regístrate aquí" y "Continuar como pasajero anónimo". En móvil el panel pasa a ser una franja superior y se oculta la ilustración (código).
Backend: `POST /api/auth/login`, `POST /api/auth/registro`, `POST /api/usuarios/anonimo`.

### 2. Activa tu ubicación (`02-activa-ubicacion.png`)
Mismo panel izquierdo. A la derecha: círculo con ícono de ubicación, "UN ÚLTIMO PASO", "Activa tu ubicación", "Te mostraremos los paraderos y líneas más cercanas a ti.", botón "Activar ubicación" y "Continuar sin activar ubicación". Es una pantalla completa, no un cuadro flotante.

### 3. Rutas (`03-rutas.png`)
Barra superior con "Piura, Perú", la píldora "Modo demostración" (con punto verde) y el avatar. Contenido: "TRANSPORTE URBANO", "Encuentra tu ruta", buscador "Buscar línea, zona o paradero", "Rutas cercanas" con contador de líneas. Tarjeta de línea: ficha de color (azul, verde o naranja), nombre, zona, tres paraderos, "Próxima unidad N min" y botón "Ver en mapa". Si no hay resultados: "No encontramos rutas" / "Prueba con otra línea, zona o paradero."
Backend: `GET /api/rutas`. El buscador filtra en la app. Las líneas reales (RD-05, RD-10...) reemplazan a las inventadas.

**Diseño actual** (rediseñado tomando como referencia la lista de líneas de Moovit y https://piuratransporta.com/rutas). El prototipo usaba tarjetas altas en cuadrícula; con 20 líneas había que bajar mucho para encontrar una.

- **Encabezado:** "TRANSPORTE URBANO" y "Encuentra tu ruta".
- **Acceso a Planificar viaje:** "¿No sabes qué línea tomar?", "Dinos a dónde vas y te decimos qué línea te sirve." y el botón **"Planificar viaje"**, que abre el buscador "¿A dónde vas?" del mapa.
- **Buscador:** "Busca una línea, calle o lugar", con un botón para borrar. Busca por código, nombre, zona, empresa, tipo y lugares por los que pasa.
  - No distingue tildes ni mayúsculas.
  - El código vale con o sin guion ("rd05" = "RD-05").
  - Con varias palabras, deben estar todas.
- **Filtros por tipo:** "Todas", "Urbanas", "Reguladas" e "Interurbanas", cada uno con el número de líneas que coinciden con la búsqueda. Debajo, el total: "N líneas".
- **Una fila compacta por línea**, como en Moovit:
  - el código con el color de su tipo (Regulada azul, Urbana verde, Interurbana naranja);
  - el nombre, y la empresa con el tipo;
  - por dónde pasa: los 3 primeros lugares, o "Pasa por {lugar}" (en color) si la búsqueda coincidió con un lugar;
  - a la derecha, "cada ~N min" (o "Fuera de servicio" en rojo) y el pasaje;
  - tocar la fila abre la línea en el mapa.
- **Orden:** primero las líneas en servicio, en el orden de piuratransporta; al final, las que están fuera de servicio.
- **Sin resultados:** "No encontramos rutas", "Prueba con otra línea, calle o lugar." y el botón "Limpiar búsqueda".

La lógica de filtrado está en `frontend/lib/features/routes/filtro_rutas.dart`.

### 4. Mapa con ruta seleccionada (`04-mapa-ruta-seleccionada.png`)
Buscador "¿A dónde quieres ir?" con botón de ubicación, chip del clima (fuera del alcance: se omite), línea de ruta discontinua con halo blanco, paraderos como círculos blancos con borde primario, tarjeta flotante "Línea 10 · El Moradito, 5 paraderos · ETA 4 min", controles de zoom y ubicación, nota "Recorrido ilustrativo · ETA de demostración". Panel derecho: "RUTA SELECCIONADA", nombre y zona, caja "Próxima unidad estimada", lista "Paraderos de la ruta" con el ETA de cada paradero, botón primario "Compartir ruta" (activa el GPS colaborativo) y botón secundario "Marcar como superada" (solo estado local).
Backend: `GET /api/rutas/{id}/paraderos`, `GET /api/reportes-gps/eta/{idRuta}`. Mapa real con `flutter_map` + OpenStreetMap.

### 5. Confirmación de abordaje (`05-confirmar-abordaje.png`)
Modal: "¿Ya estás a bordo de la Línea 10 - El Moradito?", "Al confirmar, podremos mostrar tu avance durante el recorrido.", aviso "Tu ubicación se compartirá de forma anónima con otros usuarios solo mientras dure el viaje.", botones "Cancelar" y "Sí, confirmar abordaje". Al confirmar empieza el envío del GPS.

### 6. Viaje en vivo (`06-viaje-en-vivo.png`)
Panel: "En viaje" con insignia "EN VIVO", "Compartiendo tu ubicación como colaborador", caja "Paradero actual" con "Siguiente" y "Llegas en 00:07" (fuente monoespaciada, color primario) y barra de progreso, lista de paraderos con "Estás aquí" (verde) y el ETA de cada uno, botón rojo "Finalizar viaje" y el pie "Tu ubicación se comparte de forma anónima."
Backend: `POST /api/reportes-gps` con `idRuta`, `latitud` y `longitud` cada 5 a 10 segundos (el usuario sale del token). Se detiene al finalizar.

### 7. Viaje finalizado (`07-viaje-finalizado.png`)
Modal: círculo verde con check, "Viaje finalizado", nombre de la línea, franja con Inicio, Duración y Paraderos (se calculan en la app), aviso "Ya no estás compartiendo tu ubicación.", botón "Volver al mapa" y enlace "Reportar un problema con este viaje".

### 8. Congestión (`08-congestion.png`)
"ESTADO DEL TRÁNSITO", "Congestión en Piura", pestañas Ahora / Mañana / Tarde / Noche, tarjeta "Nivel general" con chip ("Tránsito lento") y barras por hora (6h a 20h) en verde, primario y rojo; tres tarjetas ("Demora promedio", "Velocidad promedio", "Puntos críticos") y la lista "TRAMOS CRÍTICOS" con nivel ("Alta") y demora, y el botón "Ver mapa".
Backend: `GET /api/historico-congestion/ruta/{idRuta}`.

## Planificar viaje ("¿A dónde vas?")

Modo del panel del mapa que responde qué líneas tomar entre dos puntos. Código en `frontend/lib/features/viaje/`. El flujo toma como referencia el buscador de https://piuratransporta.com/: se pide primero el destino, se elige con un solo clic y la búsqueda corre sola.

### Flujo

1. Se abre al entrar por "Mapa" en la barra lateral (sin ruta indicada). El mapa se centra en Piura y no dibuja ninguna línea. Desde el panel "Ruta seleccionada" se llega con el botón "Planificar viaje", sin cambiar de pantalla.
2. **Destino primero** ("Escribe tu destino…") y luego el **origen** ("Escribe el punto de partida…"). Cada lugar se elige con un clic:
   - **Una sugerencia**, como en piuratransporta.com. Es una sola lista de hasta 5 lugares:
     - **Primero, al instante y sin red:** los paraderos y la **base propia de Piura**. La base tiene unas 2470 calles, avenidas, jirones, urbanizaciones, mercados, colegios, hospitales y otros lugares de Piura, Castilla y Veintiséis de Octubre, tomados de OpenStreetMap. Está en `lib/data/lugares/lugares_piura.dart`.
     - **Si faltan para llegar a 5:** desde la 2.ª letra, 300 ms después de la última tecla, se completan con el buscador en línea (Photon, sobre OpenStreetMap), **solo dentro de Piura metropolitana**. Mientras tanto se ve "Buscando más lugares…" y, debajo de esos resultados, "Búsqueda de lugares: Photon · © OpenStreetMap contributors".
     - **Cada lugar** muestra su nombre, dónde queda (por ejemplo, "José María Escrivá de Balaguer, Piura") y un ícono de paradero, calle, zona u otro lugar.
     - **Abreviaturas:** "jr", "jirón" y "calle" valen lo mismo. En OpenStreetMap el Jr. Lima del centro se llama "Calle Lima", y lo mismo pasa con Tacna, Libertad o Ayacucho. "av" = avenida, "psje" = pasaje, "urb" = urbanización.
     - **Cómo se elige:** con un clic del mouse, un toque o las flechas ↑/↓ y Enter. Enter sin resaltar elige la primera sugerencia; Escape cierra la lista.
     - **Al elegir:** el mapa marca el punto y lo centra.
   - **Un destino rápido:** botones con los 6 lugares por los que pasan más líneas. Se muestran mientras el campo activo está vacío.
   - **Un punto del mapa** ("Toca el mapa para fijar tu destino." / "… tu origen."). El punto toma el nombre de la calle conocida más cercana, a menos de 250 m: "Cerca de Calle Lima". Si no hay ninguna, se llama "Punto en el mapa". No usa la red.
   - Al elegir el destino, el foco pasa solo al origen. Hay botones para intercambiar origen y destino y para limpiar.
3. Con el origen y el destino definidos, **la búsqueda corre sola**: no hay botón "Buscar ruta".
   - **Barra resumen:** como en Moovit, los campos se resumen en una barra "Desde … / Hasta …" con intercambiar, limpiar y **"Cambiar"** (vuelve a mostrar los campos). Así queda espacio para los resultados.
   - La mejor línea queda elegida y se dibuja en el mapa con el paradero donde se sube y el de bajada, el origen (verde), el destino (rojo) y las caminatas punteadas.
4. Cada tarjeta, como en Moovit, muestra de arriba abajo:
   - la **duración aproximada** del viaje en grande ("≈ 14 min", con "aprox.") y el **pasaje** a la derecha;
   - la **tira del recorrido**: 🚶 minutos a pie › [🚌 código de la línea, con su color] › 🚶 minutos a pie;
   - la línea, la empresa y el tipo de servicio;
   - "Sube en {paradero} · {m} m a pie ({min} min)" y "Baja en {paradero} · {m} m a pie ({min} min)";
   - "Pasa cada ~{n} min".

   Un clic en otra tarjeta la elige y cambia el mapa. La tarjeta elegida se resalta y muestra el botón **"Iniciar viaje"**.

   **Cómo se estima la duración** (en `busqueda_viaje.dart`; es aproximada):
   - **Caminatas:** 80 m por minuto.
   - **Espera:** la mitad de la frecuencia de la línea; 0 si no se conoce.
   - **Tramo en bus:** la distancia en línea recta entre los dos paraderos × 1.3 (`factorRecorridoBus`), a 300 m por minuto, unos 18 km/h (`velocidadBusMetrosPorMinuto`).
5. **Iniciar viaje** abre una guía de 4 pasos que el pasajero avanza a mano, con una **barra de progreso** de 4 tramos. **No usa el GPS ni comparte la ubicación**, así que el opt-in queda intacto:

   | Paso | Texto | Botón |
   |---|---|---|
   | 1 | "Camina a la parada" | "Ya llegué" |
   | 2 | "Espera el bus {código}" | "Ya subí" |
   | 3 | "Vas a bordo" y "Bájate cerca de {paradero}" | "Ya bajé" |
   | 4 | "Camina a tu destino" | "Ya llegué" |
   | Final | "Llegaste" | "Listo" |

   En todo momento está "Salir del viaje".
6. **Disposición:**
   - **Escritorio** (700 px o más): el mapa y, a la derecha, el panel de 359 px.
   - **Celular:** como en Moovit y piuratransporta, el mapa ocupa toda la pantalla y el panel es una **hoja que se desliza desde abajo**. Empieza a media pantalla y se puede bajar (para ver el mapa) o subir (para ver todos los resultados).
7. El mapa se reencuadra cada vez que cambian el origen, el destino o la línea elegida:
   - con dos o más puntos distintos, se encuadran todos con margen;
   - con un solo punto, o varios casi iguales (a menos de 30 m), se centra con zoom 15.

Mensajes:

| Caso | Mensaje |
|---|---|
| Ninguna línea sirve | "No encontramos una ruta directa" y "Puede que ese tramo no esté registrado todavía. Prueba con un destino cercano o toca un punto en el mapa." |
| Origen y destino a menos de 300 m | "Todo el trayecto es caminando ({m} m)." |
| Falla la carga de las rutas | "No pudimos cargar las rutas." con el botón "Reintentar" |

### Reglas de búsqueda

- **Lugares locales:** primero los paraderos que entrega `RutasRepository`, con nombres únicos sin distinguir mayúsculas ni tildes. Si un nombre se repite, se usa la coordenada del primero.
- **Base propia de Piura:** va después de los paraderos, sin repetir un nombre que ya es paradero. Las calles más importantes van primero.
- **Orden de las sugerencias:** primero los nombres que empiezan con lo escrito, luego los que tienen cada palabra escrita y al final los que la contienen.
- **Buscador en línea:** solo se consulta si los lugares locales no llenan las 5 sugerencias. Es `BuscadorLugares`; ver `docs/diseno/mapa-osm.md`.
  - No repite un nombre que ya está entre los locales.
  - Si el texto empieza con un tipo de vía ("jr lima", "Av. Grau"), busca solo el nombre entre las calles de Piura.
- **Respuestas guardadas:** cada respuesta se guarda por texto, así que volver a escribir lo mismo no hace otra petición.
- **Respuestas tardías:** si llega la respuesta de un texto anterior, se ignora.
- **Si el buscador falla** (sin red, 429 o 5xx), quedan los paraderos y la nota "No pudimos buscar más lugares. Revisa tu conexión."
- **Reintentos:** nunca reintenta solo. Tras un 429 no pide nada durante 5 segundos.
- **Privacidad:** solo se envía el texto escrito, un punto fijo de Piura (-5.1945, -80.6328) y el recuadro de Piura metropolitana. Nunca la ubicación real del usuario.
- **Carga:** los paraderos de todas las rutas se piden en paralelo una sola vez y quedan en memoria.
- **Distancia:** en línea recta, con la fórmula de Haversine.
- **Paraderos de cada ruta:** en cada ruta activa con al menos 2 paraderos se toma el paradero más cercano al origen (sube) y el más cercano al destino (baja).
- **Rutas que sirven:** la ruta sirve si las dos caminatas miden 600 m o menos (`caminataMaximaMetros`) y si sube y baja en paraderos distintos.
- **Tiempo a pie:** 80 m por minuto (`velocidadCaminataMetrosPorMinuto`), redondeado hacia arriba.
- **Sentido:** no se filtra por orden ni por sentido, porque las líneas son de ida y vuelta y el orden de los paraderos es aproximado. Tampoco se muestran las paradas intermedias.
- **Orden de los resultados:** primero por caminata total; a igual caminata, por frecuencia (la menor primero), luego por pasaje (el menor primero) y al final por nombre. Si falta la frecuencia o el pasaje, la ruta va al final.
- **Rutas fuera de servicio:** no se incluyen en los resultados ni en los lugares frecuentes.
- **Destinos rápidos:** los 6 lugares por los que pasan más líneas activas.

### Límites

- **No sigue el recorrido real.** La búsqueda es por cercanía a los paraderos, que hoy son **propuestos** (ver `docs/datos/paraderos-propuestos.md`). Una línea puede salir como resultado aunque su recorrido real no pase por ese tramo.
- **OpenStreetMap en Piura está menos completo que Google.** Faltan negocios y números de puerta, y algunos sitios tienen otro nombre (por ejemplo, "utp" no encuentra la sede de Piura).
- **Un punto por calle.** En la base propia y en Photon cada calle tiene un solo punto, cerca de su centro. Si una calle con el mismo nombre está en zonas separadas, aparece una vez por zona. En una avenida larga, las líneas se buscan alrededor de ese punto, no a lo largo de toda la avenida.
- **Solo Piura metropolitana.** No se sugieren lugares fuera de Piura, Castilla, Veintiséis de Octubre y Catacaos: las líneas no llegan ahí.
- **La base propia es una foto de OpenStreetMap.** Corresponde al 24/10/2026. Para actualizarla se vuelve a correr `frontend/tool/generar_lugares_piura.py`.
- **Servicio de uso justo.** El servicio público de Photon no garantiza disponibilidad. Si falla, la base propia sigue funcionando. Para producción conviene un servidor propio o pasar por el backend.
- **Caminata en línea recta.** No sigue las calles, así que la caminata real es más larga.
- **Una sola línea.** No combina dos líneas (transbordos).
- **Sin "Mi ubicación".** Requiere geolocalización y queda para otra tarea: el origen se elige como el destino.
- **La guía de viaje es manual.** No sigue al bus ni calcula el ETA; el viaje en vivo con GPS colaborativo es otra tarea.
- **Puntos del mapa sin nombre.** Se llaman "Punto en el mapa", porque no se hace geocodificación inversa.

## Diferencias entre el prototipo y el backend (decisiones pendientes)

| Tema | Detalle |
|---|---|
| ETA por paradero | El prototipo muestra los minutos de cada paradero y el RF-05 pide el ETA hacia un paradero; el endpoint solo recibe `idRuta` y devuelve un único ETA |
| Paraderos con coordenadas | Se cargan al final del proyecto: hasta entonces el mapa real no puede dibujar rutas ni ubicar el paradero actual |
| Congestión | Pestañas del prototipo vs franjas del backend (`MANANA_PICO`, `MEDIO_DIA`, `TARDE_PICO`, `NOCHE`); barras por hora vs una por franja; "+18 min" vs `demora_promedio` en minutos por kilómetro; tramos con nombre vs solo `cantidad_puntos_criticos`; "nivel general" de la ciudad vs cálculo por ruta |
| Recálculo de la congestión | Hoy es manual (`POST /api/historico-congestion/recalcular`, solo usuarios registrados) |
| Semáforo | El informe pide verde, amarillo y rojo; el prototipo usa el color primario para el nivel medio |
| Acceso con Google y correo institucional | No están en el RF-01 (solo correo y contraseña) |
| Alertas de tráfico y ruta alternativa | No están en los requerimientos ni en el backend |
| Reportar un problema con el viaje | No está en los requerimientos ni en el backend |
| "Compartir ruta" | Suena a enviar un enlace; aquí significa activar el GPS colaborativo |
| Clima y "Marcar como superada" | Fuera del alcance: se omiten o quedan como estado local |
| GPS en web | En el navegador el GPS funciona normalmente solo con la pestaña abierta: la colaboración confiable es en la app móvil |

Varias de estas diferencias ya están como Issues en GitHub (hitos "APF3 (semana 12)" y "Proyecto final (semana 18)").

## Estrategia para construir

- Un repositorio de datos de prueba intercambiable con el real (misma interfaz), para construir pantallas sin esperar paraderos reales. Mientras use datos de prueba, mostrar la píldora "Modo demostración".
- Orden sugerido: tema (Issue #5), sesión anónima y cliente HTTP (Issue #6), lista de rutas con datos reales del backend, detalle y mapa, viaje en vivo, congestión.
- Backend local: `http://localhost:8080`. En el emulador de Android: `http://10.0.2.2:8080`.
