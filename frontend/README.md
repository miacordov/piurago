# PiuraGo - Frontend

Aplicación Flutter (móvil y web) de PiuraGo. Mapas con flutter_map + OpenStreetMap.

## Requisitos

- Flutter SDK, canal stable. Verifica con `flutter doctor`.
- Chrome, para probar la versión web.

## Ejecutar

    cd frontend
    flutter pub get
    flutter run -d chrome

### Opciones

- `--dart-define=DATOS_PRUEBA=true`: el buscador de lugares no usa la red (busca
  entre unos pocos lugares de Piura).
- `--dart-define=GEOCODER_URL=https://...`: otro servidor compatible con Photon
  (por defecto, `https://photon.komoot.io/api/`).

    flutter run -d chrome --dart-define=DATOS_PRUEBA=true

## Análisis y pruebas

    flutter analyze
    flutter test

## Estructura

    lib/
      main.dart            punto de entrada
      app.dart             MaterialApp y pantallas
      core/                rutas, tema (colores, textos, estilos) y avisos
      data/                modelos (Ruta, Paradero, Lugar) y repositorio de
                           rutas (hoy con datos de prueba)
        lugares/           base propia de Piura (lugares_piura.dart), índice
                           de búsqueda y BuscadorLugares: Photon (en línea)
                           y uno de prueba sin red
      features/
        auth/              inicio de sesión
        location/          activar ubicación
        map/               mapa (OpenStreetMap) y panel de la ruta seleccionada
        routes/            lista de rutas
        shell/             barra lateral y barra superior
        viaje/             Planificar viaje ("¿A dónde vas?"):
          busqueda_viaje.dart      lógica pura (distancias, catálogo, búsqueda)
          planificador_viaje.dart  estado (ChangeNotifier)
          planificar_panel.dart    panel: campos, sugerencias, resultados y guía
          sugerencias_lugares.dart sugerencias mientras se escribe (espera,
                                   caché, fallos y flechas)
          opcion_viaje_card.dart   tarjeta de un resultado
          mapa_viaje.dart          mapa con origen, destino y caminatas
    tool/                  scripts de datos (OpenStreetMap):
                           generar_lugares_piura.py: base propia de lugares;
                           trazados_oficiales.py: trazado y paraderos de las
                           rutas con recorrido oficial de la Municipalidad
    test/                  pruebas de pantallas, del modelo y de la búsqueda
      viaje/               lógica y estado de Planificar viaje, con un
                           repositorio de prueba propio (no usa los datos reales)

El mapa abre en el modo Planificar viaje si se entra desde la barra lateral, y
en el modo Ruta seleccionada si se llega desde "Ver en mapa". Las reglas de la
búsqueda están en `docs/diseno/guia-visual.md`, sección "Planificar viaje".

Mientras no haya paraderos reales, la app usa `FakeRutasRepository` y muestra la
píldora "Modo demostración". La versión que llama al backend se agrega con la
misma interfaz (`RutasRepository`).

## Referencia de diseño

Ver `docs/diseno/guia-visual.md` y las capturas de `docs/diseno/capturas/`. El
prototipo de Lovable es solo referencia visual: no se reutiliza su código.
