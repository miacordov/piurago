# PiuraGo — contexto para Claude Code

## Qué es
App multiplataforma de rutas de transporte urbano en Piura. El GPS colaborativo de los pasajeros calcula el ETA de las combis y alimenta un histórico de congestión ("horas calientes"). Proyecto del curso Integrador I (UTP), equipo de 5 personas. Los documentos están en español.

## Estructura
- backend/  → API REST en Java 21 + Spring Boot (Maven Wrapper, sin instalar Maven)
- frontend/ → Flutter (móvil y web), mapas con flutter_map + OpenStreetMap
- docs/     → informes, diagramas, diseño y evidencias (docs/diseno/guia-visual.md es la referencia del frontend)

## Arquitectura del backend (exigida por el curso)
MVC + DAO + SOLID + TDD. Capas: controller → service (interfaces + impl) → repository → model. Los DTO van separados de las entidades.
- controller no usa repository directamente; depende de las interfaces de service.
- repository solo usa model.
- Para servicios nuevos, escribir primero el test.

## Reglas
- No subir credenciales ni .env. Usar variables de entorno (SPRING_DATASOURCE_URL, SPRING_DATASOURCE_USERNAME, SPRING_DATASOURCE_PASSWORD, JWT_SECRET).
- La app comparte la ubicación solo con consentimiento del usuario (opt-in).
- Todos los usuarios (anónimos y registrados) usan JWT.

## Decisiones tomadas
- Un solo repositorio (monorepo) con backend/, frontend/ y docs/.
- Los datos reales de rutas y paraderos se cargan al final: las rutas de Piura cambian seguido por cierres de avenidas.
- El tema del ETA simulado (cuando no hay colaboradores) se resuelve al final.

## Configuración local del backend
- Las credenciales viven en backend/config/application-local.properties (ignorado por Git; hay una plantilla .example).
- Arrancar: cd backend && ./mvnw spring-boot:run -Dspring-boot.run.profiles=local
- Pruebas unitarias: ./mvnw test -Dtest='JwtUtilTest,*ServiceImplTest'

## Pendiente
- Antes del despliegue: rotar la contraseña de Neon (la cuenta la administra otra persona del equipo) y generar un JWT_SECRET nuevo.
- Al final: datos reales de rutas y paraderos, y la decisión sobre el ETA simulado.

## Flujo de trabajo (detalle en CONTRIBUTING.md)
- Nadie hace push directo a main: cada cambio va en una rama (feature/, fix/, docs/, test/, chore/) y entra por Pull Request con al menos una aprobación.
- Commits en español: tipo(ámbito): descripción. Tipos: feat, fix, docs, test, refactor, chore. Ámbitos: backend, frontend, docs.
- Con TDD: primero el commit test(...) que falla y luego el feat(...) que lo hace pasar.
- Antes de abrir un PR del backend: ./mvnw test -Dtest='JwtUtilTest,*ServiceImplTest'

## Frontend (Flutter)
- Proyecto en frontend/ (web y Android). Ejecutar: cd frontend && flutter run -d chrome. Revisar: flutter analyze y flutter test.
- Referencia visual: docs/diseno/guia-visual.md y docs/diseno/capturas/. El prototipo de Lovable (repo piura-route-buddy) es solo diseño: no se reutiliza su código.
- Color primario propuesto: #342EC1 (el del prototipo). Fuente: la que trae Flutter por defecto.
- Mientras no haya paraderos reales, la app usa un repositorio de datos de prueba intercambiable con el real.
- Backend local: http://localhost:8080 (en el emulador de Android: http://10.0.2.2:8080).

## Seguridad al trabajar con Claude Code
- No leer ni mostrar backend/config/application-local.properties, archivos .env ni ninguna credencial. Si hace falta una, pedírsela a la usuaria.
- Pedir confirmación antes de hacer push, abrir un Pull Request o ejecutar comandos que cambien el repositorio remoto.
