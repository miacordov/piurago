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
  - `001_ruta_datos_servicio.sql`: agrega a `ruta` el tipo de servicio, horario y pasaje.
- `db/seeds/`: datos iniciales.
  - `001_rutas_paraderos_piuratransporta.sql`: las 20 líneas de https://piuratransporta.com/rutas y 170 paraderos **propuestos** con coordenadas de OpenStreetMap (ver `docs/datos/paraderos-propuestos.md`). Se generó a partir de `docs/datos/*.json`.

### Cargar las rutas y paraderos

Con las credenciales de Neon configuradas (archivo local o variables de entorno):

```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=local,carga   # o solo carga, con variables de entorno
```

El perfil `carga` ejecuta la migración y los seeds antes de que Hibernate valide el esquema, no levanta el servidor web y termina solo. Se puede repetir sin riesgo.

| Seed | Qué hace |
|---|---|
| `db/seeds/001_rutas_paraderos_piuratransporta.sql` | Las 20 líneas de piuratransporta.com con paraderos propuestos. Actualiza las rutas por código, inserta las que falten y solo agrega paraderos a las rutas que no tienen. No borra nada. |
| `db/seeds/002_rutas_plan_regulador.sql` | Datos de la Municipalidad (Plan Regulador, O.M. 092-02-CMPP): agrega RD-07, RD-12, RD-13 y RD-17. En las 10 rutas con recorrido oficial guarda ese recorrido y **reemplaza sus paraderos** por los del recorrido oficial (solo si todavía no los tiene). Antes borra el histórico de congestión de los paraderos que se quitan; ese histórico se rehace solo en el siguiente recálculo automático (ver "Cómo se calcula la congestión"). Ver `docs/datos/rutas-plan-regulador.md`. |
- `postman/`: coleccion de pruebas de punta a punta (pendiente de agregar).

## Cómo se calcula el ETA

`GET /api/reportes-gps/eta/{idRuta}` responde cuánto falta para la próxima unidad y su `origen`. Lo calcula `EtaServiceImpl`, igual para todas las rutas:

- **`REAL`:** hay un pasajero de esa línea compartiendo su viaje, con **dos reportes suyos en los últimos 5 minutos**.
  - **Pasajero:** la velocidad se calcula solo con los reportes de ese pasajero; no se mezclan buses distintos de la misma línea.
  - **Destino:** el ETA es al **siguiente paradero**, el más cercano de los paraderos a los que el bus se está acercando. Vale en la ida y en la vuelta.
  - **Velocidad:** la del momento. Si el bus está detenido (menos de 3 km/h) o la medida es ruido del GPS (más de 100 km/h), se usa la velocidad típica de la línea en la franja y el día actuales (`historico_congestion`). Si la línea no tiene histórico, se usan 15 km/h.
- **`SIMULADO`:** nadie comparte su viaje en esa línea ahora. Sale de la frecuencia de la línea y la hora; la app lo indica como "Tiempo estimado".

El resultado se guarda 10 segundos (`CacheConfig`): en cuanto alguien empieza a compartir su viaje, el ETA de esa línea pasa a `REAL`.

**Límites:**
- La distancia al paradero es en línea recta, no por las calles.
- Las horas usan la zona de Piura (`America/Lima`) aunque el servidor esté en otra, como UTC en Render: `PiuragopiuraBackendApplication` la fija al arrancar. No hay que configurar nada en Render.

## Cómo se calcula la congestión

La congestión sale de los mismos reportes GPS de los pasajeros, igual para todas las rutas. Se guarda en `historico_congestion` por franja (`MANANA_PICO` 6-9 h, `MEDIO_DIA` 10-16 h, `TARDE_PICO` 17-20 h, `NOCHE`) y día (`LUN`…`DOM`).

- **Recálculo automático:** cada hora, `RecalculoCongestionProgramado` recalcula todas las rutas activas con los reportes de los últimos 28 días. La primera vez corre 2 minutos después de arrancar. Las rutas sin reportes se saltan.
  - Cada desplazamiento entre dos reportes seguidos de un mismo pasajero da una velocidad. Se descartan los de más de 10 minutos y los de más de 100 km/h.
  - Se guarda un registro por **ruta completa** (`id_paradero` vacío) y uno por cada **tramo entre dos paraderos seguidos** (`id_paradero` = el paradero donde empieza el tramo). Un desplazamiento cuenta para el tramo más cercano, si pasa a menos de 300 m.
  - **Nivel:** `ALTA` por debajo de 10 km/h, `MEDIA` por debajo de 18 km/h y `BAJA` desde ahí. La demora es en minutos por km frente a ir a 25 km/h.
- **Endpoints:**

| Método | Ruta | Quién | Qué hace |
|---|---|---|---|
| GET | `/api/historico-congestion/resumen?franjaHoraria=&diaSemana=` | cualquier usuario con token | Congestión de la ciudad: nivel general, velocidad y demora promedio, nivel de cada franja del día y los 5 tramos más lentos (ruta, paraderos, minutos de más). Sin parámetros usa la franja y el día de ahora. Sin datos, el nivel viene vacío. |
| GET | `/api/historico-congestion/ruta/{idRuta}` | cualquier usuario con token | Todos los registros de una ruta. |
| GET | `/api/historico-congestion/exportar` | cualquier usuario con token | Descarga el histórico en Excel (`congestion-piura-AAAA-MM-DD.xlsx`), con una hoja por ruta y otra por tramo, ordenadas por línea, día y franja. |
| POST | `/api/historico-congestion/recalcular-todas` | solo registrados | Fuerza el recálculo de todas las rutas sin esperar la hora. |
| POST | `/api/historico-congestion/recalcular?idRuta=&franjaHoraria=&diaSemana=` | solo registrados | Recalcula una ruta en una franja y un día. |

El Excel se arma con **Apache POI** (`ExportacionCongestionServiceImpl`). El ancho de las columnas se calcula con el largo del texto y no con `autoSizeColumn`, porque este necesita fuentes del sistema que la imagen de Docker (Alpine) no trae.

Se configura con `piurago.congestion.recalculo-ms` (cada cuánto, por defecto 1 hora), `piurago.congestion.recalculo-inicial-ms` y `piurago.congestion.recalculo-automatico=false` para apagarlo.

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
