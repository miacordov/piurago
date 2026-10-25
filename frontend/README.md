# PiuraGo - Frontend

Aplicación Flutter (móvil y web) de PiuraGo. Mapas con flutter_map + OpenStreetMap.

## Requisitos

- Flutter SDK, canal stable. Verifica con `flutter doctor`.
- Chrome, para probar la versión web.

## Ejecutar

    cd frontend
    flutter pub get
    flutter run -d chrome

## Análisis y pruebas

    flutter analyze
    flutter test

## Estructura

    lib/
      main.dart            punto de entrada
      app.dart             MaterialApp y pantallas
      core/                rutas, tema (colores, textos, estilos) y avisos
      data/                modelo Ruta y repositorio (hoy con datos de prueba)
      features/
        auth/              inicio de sesión
        location/          activar ubicación
        routes/            lista de rutas
        shell/             barra lateral y barra superior
    test/                  pruebas de pantallas y del modelo

Mientras no haya paraderos reales, la app usa `FakeRutasRepository` y muestra la
píldora "Modo demostración". La versión que llama al backend se agrega con la
misma interfaz (`RutasRepository`).

## Referencia de diseño

Ver `docs/diseno/guia-visual.md` y las capturas de `docs/diseno/capturas/`. El
prototipo de Lovable es solo referencia visual: no se reutiliza su código.
