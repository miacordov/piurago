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
