# Reporte de Implementación: Permiso de Ubicación y GPS Real en Vivo

> **Proyecto:** PiuraGo — Integrador I (UTP)  
> **Responsable:** Quezada (`Ivan26-c`)  
> **Rama de trabajo:** `feature/frontend-permiso-ubicacion`  
> **Estado:** Completado, probado y subido a GitHub (Listo para Pull Request).

---

## 1. Resumen de la Implementación

En cumplimiento con el documento oficial de distribución del equipo (**PiuraGo Reparto v5**), se completó la integración real de geolocalización en el frontend de PiuraGo, sustituyendo las rutas simuladas por el sensor GPS y la solicitud activa de permisos al usuario.

### Componentes Desarrollados

| Componente | Archivo | Descripción |
|---|---|---|
| **Dependencia GPS** | `frontend/pubspec.yaml` | Agregado `geolocator: ^14.1.2`. |
| **Permisos Android** | `frontend/android/app/src/main/AndroidManifest.xml` | Declarados `ACCESS_FINE_LOCATION` y `ACCESS_COARSE_LOCATION`. |
| **Arquitectura de Ubicación** | `frontend/lib/data/ubicacion/servicio_ubicacion.dart` | Interfaz abstracta `ServicioUbicacion` con implementación real `GeolocatorServicioUbicacion` y doble de prueba `FakeServicioUbicacion`. |
| **Pantalla de Activación** | `frontend/lib/features/location/location_page.dart` | Solicita permiso real del dispositivo al pulsar *"Activar ubicación"* antes de permitir el ingreso. |
| **Viaje en Vivo y Telemetría** | `frontend/lib/features/map/viaje_en_vivo_panel.dart` | Escucha el stream de posiciones GPS en tiempo real y dispara el callback de reporte. |
| **Coordinación en Mapa** | `frontend/lib/features/map/map_page.dart` y `app.dart` | Conecta el stream GPS con `_reportarCoordenadasGps` (`POST /api/reportes-gps`). |

---

## 2. Pruebas y Validación de Calidad

Siguiendo la metodología TDD:

1. **Pruebas Unitarias (`test/data/servicio_ubicacion_test.dart`):**
   - Estado de permisos (`denied`, `granted`).
   - Solicitud de permisos reactiva.
   - Emisión de flujo de coordenadas (`Stream<PosicionGps>`).
2. **Pruebas de Widgets (`test/features/location_page_test.dart`):**
   - Verificación de renderizado de la pantalla de permisos.
   - Comportamiento ante aprobación de permisos y navegación hacia la pantalla de rutas.
3. **Análisis Estático y Suite General:**
   - `flutter analyze`: **0 problemas encontrados**.
   - `flutter test`: **191 / 191 pruebas pasando exitosamente** (100% de la suite de PiuraGo).

---

## 3. Commits Realizados

1. `test(frontend): agrega pruebas para servicio de ubicacion y solicitud de permiso` (Commit `2762178`)
2. `feat(frontend): integra geolocator para permiso real y telemetria GPS` (Commit `5713f47`)

---

## 4. Enlace para Generar el Pull Request

La rama ya está publicada en el repositorio remoto:
👉 **[Crear Pull Request en GitHub](https://github.com/miacordov/piurago/pull/new/feature/frontend-permiso-ubicacion)**
