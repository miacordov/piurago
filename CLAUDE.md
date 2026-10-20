# PiuraGo — contexto para Claude Code

## Qué es
App multiplataforma de rutas de transporte urbano en Piura. El GPS colaborativo de los pasajeros calcula el ETA de las combis y alimenta un histórico de congestión ("horas calientes"). Proyecto del curso Integrador I (UTP), equipo de 5 personas. Los documentos están en español.

## Estructura
- backend/  → API REST en Java 21 + Spring Boot (Maven Wrapper, sin instalar Maven)
- frontend/ → Flutter (móvil y web), mapas con flutter_map + OpenStreetMap
- docs/     → informes, diagramas, diseño y evidencias

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
- Convención de ramas, commits y Pull Requests.
- Antes del despliegue: rotar la contraseña de Neon (la cuenta la administra otra persona del equipo) y generar un JWT_SECRET nuevo.
- Al final: datos reales de rutas y paraderos, y la decisión sobre el ETA simulado.
