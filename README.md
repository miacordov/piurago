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

- Backend: pendiente de migrar a este repositorio.
- Frontend: por construir.

## Cómo ejecutarlo

Se completará al migrar el código. Cada carpeta tendrá su propio README con sus pasos.

## Seguridad

Nunca se suben credenciales al repositorio (contraseñas de la base de datos, claves JWT, tokens). Se configuran con variables de entorno.
