# PiuraGo

Aplicación multiplataforma de rutas de transporte urbano en Piura. Usa el GPS colaborativo de los propios pasajeros para estimar el tiempo de llegada (ETA) de las combis y detectar las horas y tramos de mayor congestión, sin depender de hardware instalado en las unidades.

Proyecto del curso Integrador I (UTP).

## Estructura del repositorio

    backend/    API REST (Spring Boot + PostgreSQL en Neon)
    frontend/   Aplicación Flutter (móvil y web)
    docs/       Informes, diagramas, diseño y evidencias de pruebas

## Tecnologías

| Parte | Tecnología |
|---|---|
| Backend | Java 21, Spring Boot, Spring Security + JWT, JPA/Hibernate |
| Base de datos | PostgreSQL alojado en Neon |
| Frontend | Flutter, flutter_map + OpenStreetMap |
| Pruebas | JUnit 5, Mockito, AssertJ, Postman |

Arquitectura del backend: MVC + DAO bajo principios SOLID, desarrollado con TDD.

## Estado

- Backend: importado y funcionando. Las 39 pruebas unitarias pasan y la API conecta a Neon.
- Frontend: por construir.
- Despliegue: pendiente.

## Cómo ejecutarlo

- Backend: ver [`backend/README.md`](backend/README.md). Las credenciales se guardan en `backend/config/application-local.properties`, que Git ignora.
- Frontend: se completará al crear el proyecto Flutter.

## Documentación

- [`docs/guia-backend.md`](docs/guia-backend.md): guía técnica del backend.
- `docs/informes/`: avances del proyecto (APF1, APF2), cronograma y presentación.
- `docs/diagramas/`: diagrama entidad-relación.
- `docs/diseno/`: wireframe y referencia del prototipo.

## Seguridad

Nunca se suben credenciales al repositorio (contraseñas de la base de datos, claves JWT, tokens). Se configuran con variables de entorno o con un archivo local ignorado por Git.
