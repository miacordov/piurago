# PiuraGo - Backend

API REST de PiuraGo: rutas y paraderos de transporte urbano en Piura, reportes GPS colaborativos, ETA y congestion por franja horaria.

- Java 21, Spring Boot, Spring Data JPA, Spring Security + JWT
- PostgreSQL alojado en Neon
- Arquitectura MVC + DAO bajo principios SOLID (controller -> service -> repository -> model)

## Requisitos

- JDK 21 (`java -version` debe mostrar 21)
- No hace falta instalar Maven: el proyecto trae el Maven Wrapper (`./mvnw`)

## Credenciales

**Ninguna credencial vive en este repositorio.** Los valores reales se piden al encargado de la base de datos del equipo por un canal privado (nunca por chat publico, correo ni commits).

| Variable | Que es | Notas |
|---|---|---|
| `SPRING_DATASOURCE_URL` | URL JDBC de Neon | Formato `jdbc:postgresql://<host>/neondb?sslmode=require`. En desarrollo usar el endpoint **directo** (host sin `-pooler`) |
| `SPRING_DATASOURCE_USERNAME` | Usuario de la base | Lo da el panel de Neon |
| `SPRING_DATASOURCE_PASSWORD` | Contrasena de la base | Lo da el panel de Neon |
| `JWT_SECRET` | Clave para firmar los tokens | Minimo 32 caracteres, aleatoria, sin comillas |
| `APP_CORS_ALLOWED_ORIGIN_PATTERNS` | Origenes que pueden llamar a la API desde un navegador | Opcional. Por defecto: localhost. En produccion, el dominio real; nunca `*` |

### Opcion A (recomendada en tu laptop): archivo local

```bash
cp config/application-local.properties.example config/application-local.properties
# editar config/application-local.properties y poner los valores reales
./mvnw spring-boot:run -Dspring-boot.run.profiles=local
```

`config/application-local.properties` esta en el `.gitignore`: Git no lo vera. Vive en `config/` (y no en `src/main/resources/`) para que **no se empaquete dentro del .jar**. Antes de cada commit, confirma con `git status` que no aparece.

### Opcion B: variables de entorno

```bash
export SPRING_DATASOURCE_URL='jdbc:postgresql://<host>/neondb?sslmode=require'
export SPRING_DATASOURCE_USERNAME='<usuario>'
export SPRING_DATASOURCE_PASSWORD='<password>'
export JWT_SECRET='<cadena aleatoria>'
./mvnw spring-boot:run
```

Si falta alguna, la app no arranca y el error indica que no pudo resolver `SPRING_DATASOURCE_URL`, `JWT_SECRET`, etc.

## Rotar credenciales

Hay que rotar siempre que una credencial se haya compartido por un medio inseguro o haya llegado a Git. **Borrar la linea de un archivo no basta**: Git conserva el historial, asi que la credencial anterior se considera comprometida y debe reemplazarse.

1. **Contrasena de Neon.** En el panel de Neon, restablecer la contrasena del rol/usuario de la base. Neon muestra la nueva una sola vez: guardarla en un gestor de contrasenas.
2. **`JWT_SECRET`.** Generar una nueva: `openssl rand -base64 36`. Cambiarla invalida los tokens ya emitidos; los usuarios vuelven a iniciar sesion y las apps anonimas piden un token nuevo.
3. **Actualizar los valores** en cada lugar donde se usan: el `application-local.properties` de cada integrante y, cuando exista el despliegue, las variables de entorno del hosting (Render).
4. **Confirmar** que la app arranca con los valores nuevos y que los anteriores ya no funcionan.

## Probar

```bash
./mvnw test -Dtest='JwtUtilTest,*ServiceImplTest'
```

Son las 39 pruebas unitarias (no necesitan conexion a Neon). Si se corre `./mvnw test` sin filtro, tambien se ejecuta `PiuragopiuraBackendApplicationTests`, que levanta la aplicacion completa y **necesita credenciales y conexion a Neon**.

Prueba rapida con la API corriendo (`http://localhost:8080`):

1. `POST /api/usuarios/anonimo` con `{"deviceUuid": "mi-dispositivo-de-prueba-1", "tipoDispositivo": "POSTMAN"}` devuelve un `token`.
2. `GET /api/rutas` con el header `Authorization: Bearer <token>` devuelve las rutas.

## Base de datos

- `db/schema.sql`: esquema completo. En la base compartida de Neon **ya esta aplicado**; no se ejecuta de nuevo ahi.
- `db/migraciones/`: cambios posteriores al esquema, un archivo por cambio.
- `db/seeds/`: datos iniciales (rutas, paraderos). Se cargan al final del proyecto, porque las rutas de Piura cambian seguido por cierres de avenidas.
- `postman/`: coleccion de pruebas de punta a punta (pendiente de agregar).

## Estructura

```
src/main/java/com/piuragopiura/piuragopiura_backend/
  controller/   recibe la peticion y responde con DTOs
  service/      reglas de negocio (interfaces) y service/impl (implementaciones)
  repository/   acceso a la base de datos (DAO)
  model/        entidades JPA = tablas
  dto/          objetos que viajan por la red
  security/     JWT, filtro de autenticacion, CORS
  config/       cache (Guava)
  exception/    manejo global de errores
```
