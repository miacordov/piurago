# PiuraGo — Guía del backend

> Documento para el equipo. Explica cómo está construido el backend, por qué se organizó así, qué hace cada archivo y qué falta por hacer.
> Actualizado: 16 de octubre de 2026.
>
> **Nota (19 de octubre de 2026):** la configuración de credenciales cambió después de esta guía: ya no se escriben en `application.properties`. Ver `backend/README.md` (archivo local en `backend/config/`, ignorado por Git).

---

## Índice

1. [Qué es PiuraGo y qué hace este backend](#1-qué-es-piuragopiura-y-qué-hace-este-backend)
2. [Tecnologías y versiones](#2-tecnologías-y-versiones)
3. [Cómo correr el backend en tu computadora](#3-cómo-correr-el-backend-en-tu-computadora)
4. [Cómo está organizado y por qué](#4-cómo-está-organizado-y-por-qué)
5. [Base de datos](#5-base-de-datos)
6. [Detalle por paquete y archivo](#6-detalle-por-paquete-y-archivo)
7. [Seguridad: quién puede llamar a qué](#7-seguridad-quién-puede-llamar-a-qué)
8. [Reglas de negocio y constantes](#8-reglas-de-negocio-y-constantes)
9. [Códigos de respuesta y errores](#9-códigos-de-respuesta-y-errores)
10. [Pruebas](#10-pruebas)
11. [Cómo agregar una funcionalidad nueva](#11-cómo-agregar-una-funcionalidad-nueva)
12. [Estado actual](#12-estado-actual)
13. [Lo que falta y por qué](#13-lo-que-falta-y-por-qué)
14. [Glosario](#14-glosario)
15. [Apéndice A: SQL de la base de datos](#apéndice-a-sql-de-la-base-de-datos)

---

## 1. Qué es PiuraGo y qué hace este backend

**PiuraGo** es una plataforma multiplataforma de rutas de transporte urbano en Piura, basada en GPS colaborativo: los pasajeros comparten su posición mientras viajan y el sistema calcula cuánto falta para que llegue una combi.

El proyecto se compone de tres piezas:

| Pieza | Estado |
|---|---|
| **Backend** (Spring Boot, este documento) | Construido y probado |
| **Base de datos** (PostgreSQL en Neon) | Creada, con las 10 rutas reales cargadas |
| **Cliente móvil** (Flutter) | Por construir. El diseño visual de referencia es un mockup hecho en Lovable |

**Qué hace el backend:**

- Entrega las **rutas reales** de combis y buses de Piura (hoy 10: RD-05, RD-10, RD-11, RD-12, RD-14, RD-16, RD-17, RD-19, RD-20 y RD-21), con su empresa, punto inicial, punto final y recorrido por avenidas.
- Recibe **reportes GPS** de los pasajeros que deciden compartir su ubicación.
- Calcula el **ETA** (tiempo estimado de llegada):
  - **REAL**, si hay reportes GPS recientes.
  - **SIMULADO**, si no los hay. Es una cuenta regresiva basada en la frecuencia de la ruta, pensada para quien solo quiere ver sus rutas sin compartir ubicación. Siempre se marca como `SIMULADO` para no presentar un dato inventado como si fuera real.
- Calcula y guarda un **historial de congestión** por ruta, franja horaria y día de la semana, para un dashboard de "horas calientes".
- Maneja dos tipos de usuario: **anónimos** (identificados por el UUID de su dispositivo) y **registrados** (email y contraseña). **Todos** deben llevar un token JWT para usar la API.

**Condiciones del curso:** arquitectura MVC + DAO + SOLID + TDD, equipo de 5 personas, 18 semanas con entregas APF1 (semana 4), APF2 (semana 8), APF3 (semana 12) y proyecto final (semana 18).

---

## 2. Tecnologías y versiones

| Capa | Tecnología |
|---|---|
| Lenguaje | Java 21 |
| Framework | Spring Boot 4.1.1 (Spring Web MVC, Spring Data JPA, Spring Security, Validation, DevTools) |
| Compilación | Maven, con Maven Wrapper (`mvnw.cmd`): no hace falta instalar Maven |
| Base de datos | PostgreSQL alojado en Neon (región São Paulo) |
| ORM | JPA con Hibernate |
| Seguridad | Spring Security, JWT con JJWT 0.12.6, contraseñas con BCrypt |
| Librerías del sílabo | Guava 33.3.1 (caché), Apache Commons Lang3 3.17.0 (validación), Logback (logs) |
| Pruebas | JUnit 5, Mockito, AssertJ (unitarias); Postman (punta a punta) |

---

## 3. Cómo correr el backend en tu computadora

### 3.1 Requisitos

- **JDK 21** (`java -version` debe mostrar 21).
- **Git**.
- **VS Code** con la extensión de Java (o el IDE que prefieras).
- **Postman** para probar los endpoints.
- **pgAdmin** (opcional, para mirar la base de datos).

### 3.2 Credenciales

El backend se conecta a una base de datos compartida en Neon. **Pide los datos de conexión a Isa** (host, usuario, contraseña). Nunca los subas a Git ni los pegues en chats o documentos.

### 3.3 `application.properties`

Archivo: `src/main/resources/application.properties`. Plantilla (reemplaza los valores entre `< >`):

```properties
spring.application.name=piuragopiura-backend

# Conexión a Neon: usar el endpoint DIRECTO (el host SIN "-pooler") en desarrollo
spring.datasource.url=jdbc:postgresql://<HOST_DE_NEON>/neondb?sslmode=require
spring.datasource.username=<USUARIO_DE_NEON>
spring.datasource.password=<PASSWORD_DE_NEON>
spring.datasource.driver-class-name=org.postgresql.Driver

spring.jpa.hibernate.ddl-auto=validate
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect
spring.jpa.show-sql=true

# Clave para firmar los tokens: mínimo 32 caracteres, aleatoria
jwt.secret=<CADENA_ALEATORIA_DE_48_CARACTERES>
jwt.expiration-ms=86400000

# Orígenes que pueden llamar a la API desde un navegador (CORS)
app.cors.allowed-origin-patterns=http://localhost:*,http://127.0.0.1:*
```

Para generar una `jwt.secret` aleatoria (PowerShell):

```powershell
-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 48 | ForEach-Object {[char]$_})
```

> No escribas comillas alrededor del valor de `jwt.secret`: en un archivo `.properties` las comillas se toman como parte del texto.

### 3.4 Arrancar

En PowerShell, dentro de la carpeta del proyecto:

```powershell
.\mvnw.cmd spring-boot:run
```

Espera la línea `Started PiuragopiuraBackendApplication`. Deja esa terminal abierta: si la cierras, el backend se detiene. La API queda en `http://localhost:8080`.

### 3.5 Prueba rápida

1. `POST http://localhost:8080/api/usuarios/anonimo` con el cuerpo JSON `{"deviceUuid": "mi-dispositivo-de-prueba-1", "tipoDispositivo": "POSTMAN"}`. Debe devolver un `token`.
2. `GET http://localhost:8080/api/rutas` con el header `Authorization: Bearer <token>`. Debe devolver las 10 rutas.

### 3.6 Ejecutar las pruebas

```powershell
.\mvnw.cmd test "-Dtest=JwtUtilTest,*ServiceImplTest"
```

Las comillas son necesarias en PowerShell. Si corres `.\mvnw.cmd test` sin filtro, también se ejecuta la prueba por defecto de Spring, que levanta la aplicación completa y necesita conexión a Neon.

### 3.7 Errores típicos al arrancar

| Mensaje | Causa |
|---|---|
| `Failed to determine a suitable driver class` / `'url' attribute is not specified` | Falta la sección `spring.datasource` en `application.properties` |
| `password authentication failed` | La contraseña de Neon no coincide |
| `Schema-validation: missing column ...` | La base de datos no tiene una columna que la entidad espera (ver sección 5.4) |
| `WeakKeyException` | `jwt.secret` tiene menos de 32 caracteres |
| `file does not contain class ...` | El archivo `.java` no se llama igual que su clase (revisa la extensión oculta `.java.txt` en Windows) |
| `ECONNREFUSED` en Postman | El backend no está corriendo |

---

## 4. Cómo está organizado y por qué

### 4.1 Arquitectura por capas

El código se divide en capas. Cada una tiene **un solo trabajo** y solo habla con la capa de al lado:

```
Cliente (Flutter / Postman)
        │  HTTP + JSON
        ▼
┌──────────────────────────────────────────────┐
│ security   JwtAuthFilter + SecurityConfig    │  ¿Quién eres? ¿Puedes entrar?
└──────────────────────────────────────────────┘
        ▼
┌──────────────────────────────────────────────┐
│ controller  recibe la petición, valida el    │  "El mesero": toma el pedido
│             JSON y responde con un DTO       │  y entrega la respuesta
└──────────────────────────────────────────────┘
        ▼
┌──────────────────────────────────────────────┐
│ service     reglas de negocio                │  "La cocina": decide y calcula
└──────────────────────────────────────────────┘
        ▼
┌──────────────────────────────────────────────┐
│ repository  acceso a la base de datos (DAO)  │  "La despensa": guarda y busca
└──────────────────────────────────────────────┘
        ▼
┌──────────────────────────────────────────────┐
│ model       entidades = tablas de Neon       │
└──────────────────────────────────────────────┘
```

Esto es **MVC + DAO**, que es lo que exige el curso. La "vista" (V) es la app Flutter; este backend es el modelo y los controladores.

### 4.2 Por qué se dividió así

1. **Responsabilidad única.** Si hay un error de cálculo, se busca en `service`. Si hay un error de permisos, en `security`. Nadie tiene que leer todo el proyecto para encontrar algo.
2. **Cambiar una capa sin romper las otras.** Si mañana la base de datos cambia, solo se tocan `repository` y `model`; los controllers ni se enteran.
3. **Poder probar la lógica sola.** Como el `service` depende de interfaces, en los tests se reemplazan los repositories por simulaciones (mocks) y se prueba el cálculo sin conectar a Neon. Por eso las pruebas unitarias corren en segundos.
4. **Interfaces en `service` (principio de inversión de dependencias de SOLID).** El controller depende de `EtaService` (el contrato), no de `EtaServiceImpl` (la implementación). Se puede cambiar o simular la implementación sin tocar al controller.
5. **DTOs separados de las entidades.** Lo que viaja por la red no es la tabla de la base de datos. Así no se exponen campos internos y se evita un ciclo infinito al convertir a JSON (`Ruta` contiene `Paradero` y `Paradero` apunta de vuelta a `Ruta`).
6. **Seguridad desacoplada.** La autenticación vive en su propio paquete y se aplica antes de llegar a cualquier controller; ningún controller tiene que preocuparse por validar tokens.

### 4.3 Reglas de dependencia

| Capa | Puede usar | No debe usar |
|---|---|---|
| `controller` | `service` (interfaces), `dto`, `security` (solo `UsuarioAutenticado` y `JwtUtil` para emitir tokens) | `repository` |
| `service/impl` | `repository`, `model`, otros `service` | `controller`, `dto` de entrada |
| `repository` | `model` | `service`, `controller` |
| `model` | nada del proyecto | todo lo demás |

> **Excepción conocida:** `AuthController` consulta `UsuarioRegistradoRepository` directamente para buscar al usuario después del login. Lo correcto sería mover esa búsqueda a `UsuarioService`. Está en la lista de mejoras (sección 13).

### 4.4 Recorrido de una petición

Ejemplo: un pasajero envía su posición.

1. La app llama a `POST /api/reportes-gps` con el header `Authorization: Bearer <token>`.
2. `JwtAuthFilter` valida el token y deja identificado al usuario.
3. `SecurityConfig` comprueba que ese endpoint exige estar autenticado.
4. `ReporteGpsController` recibe el JSON, lo valida (`@Valid`) y **toma el id del usuario del token**, no del JSON.
5. `ReporteGpsServiceImpl` valida que las coordenadas estén dentro de Perú y que usuario y ruta existan.
6. `ReporteGpsRepository` guarda el registro en Neon.
7. El controller responde con un `ReporteGpsResponseDTO`.
8. Si algo falla en el camino, `GlobalExceptionHandler` convierte el error en una respuesta JSON clara.

### 4.5 Estructura de carpetas

```
piuragopiura-backend/
├── pom.xml                              dependencias del proyecto
├── mvnw / mvnw.cmd                      Maven Wrapper
└── src/
    ├── main/
    │   ├── java/com/piuragopiura/piuragopiura_backend/
    │   │   ├── PiuragopiuraBackendApplication.java
    │   │   ├── model/
    │   │   │   ├── Usuario.java
    │   │   │   ├── UsuarioRegistrado.java
    │   │   │   ├── UsuarioAnonimo.java
    │   │   │   ├── Ruta.java
    │   │   │   ├── Paradero.java
    │   │   │   ├── ReporteGps.java
    │   │   │   └── HistoricoCongestion.java
    │   │   ├── repository/
    │   │   │   ├── UsuarioRepository.java
    │   │   │   ├── UsuarioRegistradoRepository.java
    │   │   │   ├── UsuarioAnonimoRepository.java
    │   │   │   ├── RutaRepository.java
    │   │   │   ├── ParaderoRepository.java
    │   │   │   ├── ReporteGpsRepository.java
    │   │   │   └── HistoricoCongestionRepository.java
    │   │   ├── service/
    │   │   │   ├── UsuarioService.java
    │   │   │   ├── RutaService.java
    │   │   │   ├── ReporteGpsService.java
    │   │   │   ├── EtaService.java
    │   │   │   ├── HistoricoCongestionService.java
    │   │   │   └── impl/
    │   │   │       ├── UsuarioServiceImpl.java
    │   │   │       ├── RutaServiceImpl.java
    │   │   │       ├── ReporteGpsServiceImpl.java
    │   │   │       ├── EtaServiceImpl.java
    │   │   │       └── HistoricoCongestionServiceImpl.java
    │   │   ├── controller/
    │   │   │   ├── AuthController.java
    │   │   │   ├── UsuarioController.java
    │   │   │   ├── RutaController.java
    │   │   │   ├── ReporteGpsController.java
    │   │   │   └── HistoricoCongestionController.java
    │   │   ├── dto/
    │   │   │   ├── LoginRequestDTO.java
    │   │   │   ├── RegistroRequestDTO.java
    │   │   │   ├── AnonimoRequestDTO.java
    │   │   │   ├── ReporteGpsRequestDTO.java
    │   │   │   ├── AuthResponseDTO.java
    │   │   │   ├── AnonimoResponseDTO.java
    │   │   │   ├── RutaResponseDTO.java
    │   │   │   ├── ParaderoResponseDTO.java
    │   │   │   ├── ReporteGpsResponseDTO.java
    │   │   │   ├── EtaResponseDTO.java
    │   │   │   └── HistoricoCongestionResponseDTO.java
    │   │   ├── security/
    │   │   │   ├── JwtUtil.java
    │   │   │   ├── JwtAuthFilter.java
    │   │   │   ├── CustomUserDetailsService.java
    │   │   │   ├── UsuarioAutenticado.java
    │   │   │   └── SecurityConfig.java
    │   │   ├── config/
    │   │   │   └── CacheConfig.java
    │   │   └── exception/
    │   │       └── GlobalExceptionHandler.java
    │   └── resources/
    │       ├── application.properties
    │       └── logback-spring.xml
    └── test/java/com/piuragopiura/piuragopiura_backend/
        ├── security/JwtUtilTest.java
        └── service/impl/
            ├── UsuarioServiceImplTest.java
            ├── ReporteGpsServiceImplTest.java
            ├── EtaServiceImplTest.java
            └── HistoricoCongestionServiceImplTest.java
```

**Por qué hay un `src/test` aparte:** Maven mantiene dos árboles paralelos. Lo de `src/main` se empaqueta en la aplicación que se despliega; lo de `src/test` nunca se incluye. Los tests repiten los mismos nombres de paquete para quedar "al lado" de la clase que prueban.

---

## 5. Base de datos

### 5.1 Relaciones

```
usuario (padre) ──┬── usuario_registrado   (1 a 1, comparten id)
                  └── usuario_anonimo      (1 a 1, comparten id)
usuario  1 ──── N  reporte_gps  N ──── 1  ruta
ruta     1 ──── N  paradero
ruta     1 ──── N  historico_congestion  N ──── 0..1  paradero
```

### 5.2 Tablas

**`usuario`**: tabla padre; todo usuario es anónimo o registrado, nunca ambos.

| Columna | Tipo | Notas |
|---|---|---|
| `id_usuario` | BIGSERIAL, PK | |
| `tipo_usuario` | VARCHAR(10) | `ANONIMO` o `REGISTRADO` (lo llena Hibernate) |
| `tipo_dispositivo` | VARCHAR(20) | Opcional, por ejemplo `ANDROID` |
| `activo` | BOOLEAN | Por defecto `true` |
| `fecha_creacion` | TIMESTAMP | |

**`usuario_registrado`**: `id_usuario` (PK y FK a `usuario`), `nombre`, `email` (único), `password_hash` (BCrypt; nunca la contraseña en texto plano).

**`usuario_anonimo`**: `id_usuario` (PK y FK), `device_uuid` (único, 64 caracteres máx.), `fecha_ultimo_acceso` (se actualiza cada vez que el dispositivo pide token).

**`ruta`**

| Columna | Notas |
|---|---|
| `id_ruta` | PK |
| `codigo` | Único, por ejemplo `RD-11` |
| `nombre` | Por ejemplo `RD-11 Los Almendros – Aguilar Santisteban` |
| `empresa` | Empresa de transporte |
| `punto_inicio`, `punto_final` | Extremos de la ruta |
| `sentido` | `IDA_VUELTA` o `SOLO_IDA` (RD-20 es solo ida) |
| `descripcion` | Resumen corto |
| `recorrido` | Texto largo con las avenidas del recorrido |
| `activa` | Solo las activas se listan |
| `tiempo_estimado` | Minutos del recorrido completo (hoy sin usar, vacío) |
| `frecuencia_minutos` | Cada cuántos minutos pasa una unidad; vacío = se usa 12 por defecto |

**`paradero`**: `id_paradero`, `id_ruta` (FK), `nombre`, `latitud`, `longitud` (DECIMAL(9,6)), `orden_secuencial`. La combinación (`id_ruta`, `orden_secuencial`) es única. **Hoy la tabla está vacía:** el texto de las rutas solo trae nombres de calles, no coordenadas.

**`reporte_gps`**: `id_reporte`, `id_usuario` (FK), `id_ruta` (FK), `latitud`, `longitud`, `fecha_hora`. Tiene índices por (`id_ruta`, `fecha_hora` descendente) y por `id_usuario`.

**`historico_congestion`**

| Columna | Notas |
|---|---|
| `id_historico` | PK |
| `id_ruta` | FK |
| `id_paradero` | FK **opcional**. `NULL` significa "aplica a toda la ruta" (es lo que se usa hoy) |
| `franja_horaria` | `MANANA_PICO`, `MEDIO_DIA`, `TARDE_PICO` o `NOCHE` |
| `tiempo_dia` | Sin usar hoy |
| `dia_semana` | `LUN`, `MAR`, `MIE`, `JUE`, `VIE`, `SAB` o `DOM` |
| `nivel_congestion` | `ALTA`, `MEDIA` o `BAJA` |
| `demora_promedio` | Minutos extra por kilómetro respecto a la velocidad sin tráfico |
| `velocidad_promedio` | km/h |
| `cantidad_puntos_criticos` | Cantidad de tramos a menos de 10 km/h |
| `fecha_calculo` | Fecha del último recálculo |

Tiene dos índices únicos parciales: uno para registros por paradero y otro para registros de ruta completa (`id_paradero IS NULL`). Así no se duplica el mismo cálculo.

### 5.3 Cómo se modela el usuario (herencia)

Un usuario es anónimo **o** registrado. En Java, `Usuario` es una clase abstracta y `UsuarioRegistrado` y `UsuarioAnonimo` la extienden. En la base de datos, cada clase tiene su propia tabla y comparten el mismo `id_usuario` (estrategia JPA `JOINED`). Una columna llamada `tipo_usuario` le dice a Hibernate qué subclase instanciar al leer una fila.

La base de datos **no** impide insertar un `usuario` marcado `REGISTRADO` que tenga fila en `usuario_anonimo`. Esa consistencia la garantiza el código de `UsuarioServiceImpl`, que siempre crea el usuario a través de la subclase correcta.

### 5.4 Regla de oro: `ddl-auto=validate`

Hibernate **no crea ni modifica tablas**: solo comprueba al arrancar que las entidades Java coincidan con las tablas reales y falla si no. Por eso, **cualquier cambio de estructura se hace en este orden**:

1. Primero el SQL (`ALTER TABLE`, `CREATE TABLE`) en pgAdmin sobre Neon.
2. Después la entidad Java.
3. Reiniciar el backend.

Si lo haces al revés, el backend no arranca.

---

## 6. Detalle por paquete y archivo

Todos los paquetes viven bajo `com.piuragopiura.piuragopiura_backend`.

> **Importante:** el paquete base se llama `piuragopiura_backend` (con guion bajo), no `backend`. Spring solo detecta clases anotadas dentro del paquete de la clase principal y sus subpaquetes. Un archivo con otro nombre de paquete compila, pero Spring no lo encuentra y los endpoints no existen.

### 6.1 Raíz

**`PiuragopiuraBackendApplication`**: punto de arranque (`main`). Lleva `@SpringBootApplication`. Antes de arrancar, fija la **zona horaria por defecto en `America/Lima`**. Es importante porque la franja horaria y el día de la congestión se calculan con la hora guardada en `reporte_gps`; un servidor en la nube suele estar en UTC y un reporte de las 7 am quedaría como mediodía.

### 6.2 `model/`: entidades

Cada clase es una tabla. Usan anotaciones JPA (`@Entity`, `@Table`, `@Column`, `@Id`).

| Archivo | Qué contiene |
|---|---|
| `Usuario` | Clase **abstracta** padre. Campos: `idUsuario`, `tipoDispositivo`, `activo`, `fechaCreacion`. Usa `@Inheritance(JOINED)` y `@DiscriminatorColumn("tipo_usuario")` |
| `UsuarioRegistrado` | Hereda de `Usuario`. Campos: `nombre`, `email`, `passwordHash`. Valor discriminador `REGISTRADO` |
| `UsuarioAnonimo` | Hereda de `Usuario`. Campos: `deviceUuid`, `fechaUltimoAcceso`. Valor discriminador `ANONIMO` |
| `Ruta` | Todos los campos de la tabla `ruta` (sección 5.2) y la lista `paraderos` (relación uno a muchos) |
| `Paradero` | Campos de la tabla y una relación muchos a uno con `Ruta` (carga perezosa) |
| `ReporteGps` | Relaciones muchos a uno con `Usuario` y `Ruta` (carga perezosa), más latitud, longitud y `fechaHora` |
| `HistoricoCongestion` | Relaciones con `Ruta` y `Paradero` (esta última puede ser nula) y los campos del cálculo |

**Carga perezosa (`LAZY`):** la relación no se trae de la base de datos hasta que se usa. Evita consultas innecesarias.

### 6.3 `repository/`: acceso a datos (DAO)

Son **interfaces** que extienden `JpaRepository`. Spring genera la implementación solo; no se escribe SQL. Los nombres de los métodos le dicen a Spring qué consulta armar (por ejemplo, `findByEmail`).

| Archivo | Métodos propios | Para qué |
|---|---|---|
| `UsuarioRepository` | (los básicos) | Buscar un usuario por id sin importar el tipo |
| `UsuarioRegistradoRepository` | `findByEmail`, `existsByEmail` | Login y comprobar emails repetidos |
| `UsuarioAnonimoRepository` | `findByDeviceUuid` | Reconocer un dispositivo ya registrado |
| `RutaRepository` | `findByActivaTrue` | Listar solo las rutas activas |
| `ParaderoRepository` | `findByRuta_IdRutaOrderByOrdenSecuencialAsc` | Paraderos de una ruta, en orden |
| `ReporteGpsRepository` | `findByRuta_IdRutaOrderByFechaHoraDesc(idRuta, Pageable)`, `findByRuta_IdRutaAndFechaHoraAfterOrderByFechaHoraDesc(idRuta, desde, Pageable)`, `findByUsuario_IdUsuarioOrderByFechaHoraDesc` | Últimos reportes de una ruta (ETA), reportes de una ventana de tiempo (congestión) y reportes de un usuario |
| `HistoricoCongestionRepository` | `findByRuta_IdRutaOrderByFechaCalculoDesc`, `findByRuta_IdRutaAndFranjaHorariaAndDiaSemanaAndParaderoIsNull` | Historial de una ruta y búsqueda de un registro por ruta, franja y día (para actualizarlo en vez de duplicarlo) |

`Pageable` permite pedir "solo los primeros N resultados" (por ejemplo, los 2 últimos reportes), en vez de traer toda la tabla.

### 6.4 `dto/`: lo que entra y sale por la API

Un DTO define exactamente qué datos viajan por la red. Las clases con `record` son inmutables y generan solas el constructor y los getters.

**DTOs de entrada** (llevan validaciones; si fallan, la API responde 400):

| Archivo | Campos y validaciones |
|---|---|
| `LoginRequestDTO` | `email` (obligatorio, formato de email), `password` (obligatorio) |
| `RegistroRequestDTO` | `nombre` (obligatorio), `email` (obligatorio, formato de email), `password` (obligatorio, mínimo 8 caracteres) |
| `AnonimoRequestDTO` | `deviceUuid` (obligatorio, máx. 64), `tipoDispositivo` (opcional, máx. 20) |
| `ReporteGpsRequestDTO` | `idRuta`, `latitud`, `longitud` (los tres obligatorios). **No incluye `idUsuario`**: el usuario sale del token |

**DTOs de salida:**

| Archivo | Campos |
|---|---|
| `AuthResponseDTO` | `token`, `email` |
| `AnonimoResponseDTO` | `token`, `idUsuario`, `deviceUuid` |
| `RutaResponseDTO` | `idRuta`, `codigo`, `nombre`, `empresa`, `puntoInicio`, `puntoFinal`, `sentido`, `descripcion`, `recorrido`, `activa`, `tiempoEstimado`, `frecuenciaMinutos` (**sin** la lista de paraderos) |
| `ParaderoResponseDTO` | `idParadero`, `nombre`, `latitud`, `longitud`, `ordenSecuencial` |
| `ReporteGpsResponseDTO` | `idReporte`, `idUsuario`, `idRuta`, `latitud`, `longitud`, `fechaHora` |
| `EtaResponseDTO` | `idRuta`, `idParadero`, `minutosEstimados`, `velocidadPromedioKmh`, `origen` (`REAL` o `SIMULADO`) |
| `HistoricoCongestionResponseDTO` | `idHistorico`, `idRuta`, `idParadero` (puede ser `null`), `franjaHoraria`, `tiempoDia`, `diaSemana`, `nivelCongestion`, `demoraPromedio`, `velocidadPromedio`, `cantidadPuntosCriticos`, `fechaCalculo` |

Cada DTO de salida tiene un método estático `desde(entidad)` que convierte la entidad en DTO.

### 6.5 `service/` e `impl/`: reglas de negocio

La interfaz define **qué** se puede hacer y `impl` define **cómo**.

#### `UsuarioService` / `UsuarioServiceImpl`

- `registrar(nombre, email, passwordPlano)`: si el email ya existe, lanza error ("El email ya está registrado"). Si no, **hashea la contraseña con BCrypt** y guarda al `UsuarioRegistrado`. La contraseña en texto plano nunca se guarda.
- `registrarAnonimo(deviceUuid, tipoDispositivo)`: busca el dispositivo por `deviceUuid`. Si ya existe, actualiza su `fechaUltimoAcceso` y lo devuelve (mismo usuario). Si no existe, crea uno nuevo. Es **idempotente**: repetir la llamada no crea usuarios duplicados.

#### `RutaService` / `RutaServiceImpl`

- `listarActivas()`: rutas con `activa = true`.
- `obtenerPorId(id)`: lanza error "Ruta no encontrada" si no existe.
- `obtenerParaderos(idRuta)`: paraderos de la ruta ordenados por `orden_secuencial`.

#### `ReporteGpsService` / `ReporteGpsServiceImpl`

- `registrarReporte(idUsuario, idRuta, latitud, longitud)`:
  1. Valida que la latitud esté entre −18,5 y 0,0 y la longitud entre −81,5 y −68,5 (aproximadamente, territorio peruano), con `Range` de Apache Commons Lang3. Descarta lecturas corruptas o falsas.
  2. Verifica que el usuario y la ruta existan.
  3. Guarda el reporte.
- `obtenerUltimos(idRuta, limite)`: los últimos N reportes de una ruta, del más nuevo al más viejo.

#### `EtaService` / `EtaServiceImpl`: el ETA

`calcularEtaProximoParadero(idRuta)`:

1. **Valida que la ruta exista** (fuera de la caché, porque Guava envuelve las excepciones que se lanzan dentro de ella y el manejador de errores no las reconocería). Si no existe, error 400.
2. Consulta la **caché de Guava** (10 segundos por ruta). Si hay un resultado reciente, lo devuelve sin recalcular.
3. Si no, calcula. Usa el ETA **REAL** solo si se cumplen **todas** estas condiciones:
   - hay al menos 2 reportes GPS de la ruta;
   - el último reporte tiene menos de 5 minutos;
   - la ruta tiene paraderos;
   - la velocidad calculada es mayor que 0.
4. **Cálculo real:** con la fórmula de **Haversine** (distancia entre dos coordenadas sobre la esfera terrestre) calcula la distancia entre los dos últimos reportes, de ahí la velocidad (km/h), y luego el tiempo hasta el paradero: `minutos = distancia al paradero / velocidad × 60`.
5. Si falta cualquier condición, devuelve el ETA **SIMULADO**: una cuenta regresiva `minutos = frecuencia − ((minuto del día + desfase) mod frecuencia)`. La frecuencia es la de la ruta (`frecuencia_minutos`) o 12 por defecto; el desfase (`idRuta mod frecuencia`) evita que todas las rutas "lleguen" a la vez. El resultado siempre está entre 1 y la frecuencia, y se marca `origen = "SIMULADO"`.

Si el cálculo real lanza una excepción inesperada, se registra en el log y se devuelve el simulado.

> **Limitaciones conocidas del ETA real:** toma el **primer paradero** de la ruta como "el siguiente", y mezcla las posiciones si varias combis de la misma ruta reportan a la vez, porque usa los dos últimos reportes de la ruta sin importar quién los envió.

#### `HistoricoCongestionService` / `HistoricoCongestionServiceImpl`: la congestión

- `obtenerPorRuta(idRuta)`: historial guardado, del más reciente al más antiguo.
- `recalcularParaRuta(idRuta, franjaHoraria, diaSemana)`:
  1. Normaliza los parámetros (quita espacios y pasa a mayúsculas) y los valida contra las listas permitidas. Si no coinciden, error 400 con los valores válidos.
  2. Verifica que la ruta exista.
  3. Trae los reportes de la ruta de los últimos **28 días** (máximo 5000).
  4. **Agrupa por usuario** y los ordena por hora, para no mezclar combis distintas.
  5. Recorre cada par de reportes consecutivos del mismo usuario (un "tramo"). Cuenta el tramo solo si cumple todo esto:
     - su franja y día (según el **segundo** reporte) coinciden con los pedidos;
     - los dos reportes están separados por entre 1 segundo y 10 minutos (más tiempo se considera otro viaje);
     - la velocidad es de 100 km/h o menos (más es ruido de GPS).
  6. Si no queda ningún tramo válido, error 400 "No hay reportes GPS válidos...".
  7. Con los tramos válidos calcula:
     - **velocidad promedio**;
     - **demora** = `60 / velocidad − 60 / 25` minutos por kilómetro (nunca negativa);
     - **nivel**: `ALTA` si la velocidad es menor a 10 km/h, `MEDIA` si es menor a 18, `BAJA` en otro caso;
     - **puntos críticos**: cuántos tramos van a menos de 10 km/h.
  8. **Actualiza** el registro existente de esa ruta, franja y día si ya hay uno (no duplica), o crea uno nuevo. Siempre con `id_paradero = NULL` (ruta completa) y `fecha_calculo` de hoy.

### 6.6 `controller/`: los endpoints

Todos devuelven JSON. Salvo `/api/auth/**` y `/api/usuarios/anonimo`, **todos requieren** el header `Authorization: Bearer <token>`.

#### `AuthController` (`/api/auth`)

**`POST /api/auth/registro`** (público)

```json
// Pedido
{ "nombre": "Ana", "email": "ana@example.com", "password": "password123" }
// Respuesta 200
{ "token": "eyJhbGciOiJIUzI1NiJ9...", "email": "ana@example.com" }
```

Errores: 400 si el email ya existe o si algún campo no cumple las validaciones (por ejemplo `{"password": "La password debe tener al menos 8 caracteres"}`).

**`POST /api/auth/login`** (público)

```json
// Pedido
{ "email": "ana@example.com", "password": "password123" }
// Respuesta 200: igual que el registro
```

Error 401 con `{"error": "Credenciales inválidas"}` si la contraseña es incorrecta. El login lo valida el `AuthenticationManager` de Spring Security, que usa `CustomUserDetailsService` y BCrypt.

#### `UsuarioController` (`/api/usuarios`)

**`POST /api/usuarios/anonimo`** (público)

```json
// Pedido
{ "deviceUuid": "a3f1c2d4-9b7e-4e55-8a10-0c2b6d1f7e90", "tipoDispositivo": "ANDROID" }
// Respuesta 200
{ "token": "eyJ...", "idUsuario": 5, "deviceUuid": "a3f1c2d4-9b7e-4e55-8a10-0c2b6d1f7e90" }
```

La app genera un UUID aleatorio **una sola vez**, lo guarda en el dispositivo y lo reutiliza siempre. Si el token vence (24 h), la app vuelve a llamar a este endpoint con el mismo UUID y recibe un token nuevo del **mismo usuario**.

#### `RutaController` (`/api/rutas`)

| Endpoint | Devuelve |
|---|---|
| `GET /api/rutas` | Lista de `RutaResponseDTO` (rutas activas) |
| `GET /api/rutas/{id}` | Una `RutaResponseDTO`; 400 si no existe |
| `GET /api/rutas/{id}/paraderos` | Lista de `ParaderoResponseDTO` en orden (vacía hoy) |

#### `ReporteGpsController` (`/api/reportes-gps`)

**`POST /api/reportes-gps`**

```json
// Pedido (NO se envía idUsuario)
{ "idRuta": 1, "latitud": -5.19, "longitud": -80.63 }
// Respuesta 200
{ "idReporte": 12, "idUsuario": 5, "idRuta": 1, "latitud": -5.19, "longitud": -80.63, "fechaHora": "2026-10-16T08:15:30" }
```

El `idUsuario` de la respuesta siempre es el dueño del token. Si el cliente manda un `idUsuario` en el JSON, se ignora: así nadie puede publicar reportes a nombre de otro. 400 si las coordenadas están fuera de Perú o faltan campos.

**`GET /api/reportes-gps/eta/{idRuta}`**

```json
// Respuesta 200 (simulado)
{ "idRuta": 1, "idParadero": null, "minutosEstimados": 7.0, "velocidadPromedioKmh": null, "origen": "SIMULADO" }
```

#### `HistoricoCongestionController` (`/api/historico-congestion`)

| Endpoint | Quién | Qué hace |
|---|---|---|
| `GET /api/historico-congestion/ruta/{idRuta}` | Cualquier token | Lista el historial de la ruta |
| `POST /api/historico-congestion/recalcular?idRuta=1&franjaHoraria=MANANA_PICO&diaSemana=LUN` | **Solo registrados** | Recalcula y guarda la congestión |

Los parámetros de `recalcular` van **en la URL**, no en el cuerpo. Un anónimo recibe 403.

### 6.7 `security/`: seguridad

| Archivo | Qué hace |
|---|---|
| `JwtUtil` | Crea y valida los tokens. `generarToken(email, idUsuario)` para registrados y `generarTokenAnonimo(deviceUuid, idUsuario)` para anónimos (el "sujeto" del token es `anon:<deviceUuid>`). Cada token lleva: sujeto, `idUsuario`, `tipo` (`REGISTRADO` o `ANONIMO`), fecha de emisión y expiración. Firma con HMAC usando `jwt.secret`. `esValido(token)` devuelve `false` si el token está alterado, vencido, firmado con otra clave o no es un token |
| `JwtAuthFilter` | Filtro que corre **en cada petición**. Lee `Authorization: Bearer <token>`. Si el token es válido, carga al usuario con `CustomUserDetailsService` y lo deja autenticado en esa petición. Si no hay token o es inválido, deja pasar la petición sin autenticar; después `SecurityConfig` decide si la rechaza |
| `CustomUserDetailsService` | Puente entre la base de datos y Spring Security. Si el nombre empieza con `anon:`, busca el dispositivo por `deviceUuid` y le da el rol `ROLE_ANONIMO`. Si no, busca por email y le da `ROLE_REGISTRADO`. Devuelve un `UsuarioAutenticado` |
| `UsuarioAutenticado` | Extiende el `User` de Spring Security y agrega `idUsuario`. Los controllers lo reciben con `@AuthenticationPrincipal` para saber quién hace la petición sin confiar en el JSON |
| `SecurityConfig` | Reglas generales: sesiones sin estado (sin cookies), BCrypt como codificador de contraseñas, CORS con orígenes configurables, 401 cuando no hay autenticación, qué endpoints son públicos y registro del filtro JWT |

### 6.8 `config/`

**`CacheConfig`**: crea la caché de Guava `Cache<Long, EtaResponseDTO>` usada por `EtaServiceImpl`. Cada entrada expira 10 segundos después de escribirse y se guardan como máximo 200 rutas. Sin caché, una app que consulta el ETA cada pocos segundos recalcularía lo mismo una y otra vez.

### 6.9 `exception/`

**`GlobalExceptionHandler`**: atrapa errores de los controllers y los convierte en respuestas JSON limpias (`@RestControllerAdvice`):

| Error | Respuesta |
|---|---|
| `IllegalArgumentException` (reglas de negocio: ruta inexistente, email repetido, franja inválida...) | 400 con `{"error": "mensaje"}` |
| `MethodArgumentNotValidException` (falla `@Valid` en un DTO) | 400 con `{"campo": "mensaje"}` por cada campo inválido |
| `BadCredentialsException` (contraseña incorrecta) | 401 con `{"error": "Credenciales inválidas"}` |

Los errores que ocurren **dentro de un filtro** (como `JwtAuthFilter`) no pasan por este manejador.

### 6.10 `resources/`

**`application.properties`**

| Propiedad | Para qué sirve |
|---|---|
| `spring.datasource.*` | Conexión a Neon |
| `spring.jpa.hibernate.ddl-auto=validate` | Hibernate solo valida, no modifica tablas (sección 5.4) |
| `spring.jpa.show-sql=true` | Imprime el SQL en consola (útil en desarrollo; **quitar en producción**) |
| `jwt.secret` | Clave de firma de tokens (mínimo 32 caracteres) |
| `jwt.expiration-ms` | Vida del token: 86400000 ms = 24 horas |
| `app.cors.allowed-origin-patterns` | Orígenes que pueden llamar a la API desde un navegador |

**`logback-spring.xml`**: logs en consola y en un archivo rotado diariamente (`logs/piuragopiura-backend.log`, 14 días de historial).

> **Corrección pendiente:** el archivo configura el nivel `DEBUG` para el paquete `com.piuragopiura.backend`, que **no coincide** con el paquete real (`com.piuragopiura.piuragopiura_backend`). Por eso los mensajes `log.debug` del proyecto no aparecen. Para arreglarlo, cambia ese nombre de paquete en la línea `<logger name="..." level="DEBUG"/>`. Agrega también `logs/` al `.gitignore`.

---

## 7. Seguridad: quién puede llamar a qué

Todo usuario necesita un token. La única forma de obtener uno es registrarse, hacer login o registrar el dispositivo como anónimo.

| Endpoint | Sin token | Anónimo | Registrado |
|---|---|---|---|
| `POST /api/auth/registro`, `POST /api/auth/login` | ✅ | ✅ | ✅ |
| `POST /api/usuarios/anonimo` | ✅ | ✅ | ✅ |
| `GET /api/rutas`, `/{id}`, `/{id}/paraderos` | 401 | ✅ | ✅ |
| `POST /api/reportes-gps`, `GET /api/reportes-gps/eta/{id}` | 401 | ✅ | ✅ |
| `GET /api/historico-congestion/ruta/{id}` | 401 | ✅ | ✅ |
| `POST /api/historico-congestion/recalcular` | 401 | **403** | ✅ |

**401 y 403, la diferencia:**

- **401 (no autenticado):** "no sé quién eres". No hay token, está alterado o venció. La app debe pedir uno nuevo.
- **403 (prohibido):** "sé quién eres, pero no tienes permiso". Un token nuevo no lo arregla.

Otros detalles:

- El token dura **24 horas**. Un token anónimo se renueva solo (la app vuelve a llamar a `/api/usuarios/anonimo`); un registrado debe volver a hacer login, porque no existe refresh token.
- No existe un rol de administrador: "registrado" es el único nivel por encima de anónimo.
- **CORS** solo importa si pruebas Flutter en el navegador (`flutter run -d chrome`). Las apps de Android e iOS y Postman no pasan por CORS. Los orígenes permitidos se configuran en `app.cors.allowed-origin-patterns`; en producción hay que poner el dominio real y **nunca `*`**.

---

## 8. Reglas de negocio y constantes

Los valores marcados como **supuesto** no vienen de datos reales: son decisiones de diseño que se pueden ajustar.

| Regla | Valor | Archivo |
|---|---|---|
| Vigencia del JWT | 24 h | `application.properties` |
| Rango de latitud válido | −18,5 a 0,0 | `ReporteGpsServiceImpl` |
| Rango de longitud válido | −81,5 a −68,5 | `ReporteGpsServiceImpl` |
| Caché de ETA | 10 s, máximo 200 rutas | `CacheConfig` |
| Frecuencia de paso por defecto | 12 min (**supuesto**) | `EtaServiceImpl` |
| Antigüedad máxima de un reporte para ETA real | 5 min (**supuesto**) | `EtaServiceImpl` |
| Franja `MANANA_PICO` | 06:00 a 09:59 | `HistoricoCongestionServiceImpl` |
| Franja `MEDIO_DIA` | 10:00 a 16:59 | idem |
| Franja `TARDE_PICO` | 17:00 a 20:59 | idem |
| Franja `NOCHE` | 21:00 a 05:59 | idem |
| Velocidad sin tráfico | 25 km/h (**supuesto**) | idem |
| Congestión ALTA | velocidad < 10 km/h (**supuesto**) | idem |
| Congestión MEDIA | velocidad < 18 km/h (**supuesto**) | idem |
| Separación máxima entre reportes de un tramo | 10 min | idem |
| Velocidad máxima plausible | 100 km/h | idem |
| Ventana de análisis | 28 días, máximo 5000 reportes | idem |
| Zona horaria | `America/Lima` | `PiuragopiuraBackendApplication`, `EtaServiceImpl` |

---

## 9. Códigos de respuesta y errores

| Código | Significado en este proyecto | Cuándo ocurre |
|---|---|---|
| 200 | Todo bien | |
| 400 | Datos mal enviados o regla de negocio incumplida | Campo inválido, ruta inexistente, email repetido, franja inválida, coordenadas fuera de Perú, "No hay reportes GPS válidos" |
| 401 | No autenticado | Sin token, token alterado o vencido; contraseña incorrecta en el login |
| 403 | Autenticado pero sin permiso | Un anónimo llama a `recalcular`; origen CORS no permitido |
| 500 | Error inesperado del servidor | Un fallo no controlado; revisar el log |

---

## 10. Pruebas

### 10.1 Pruebas unitarias (JUnit 5 + Mockito + AssertJ): 39 pruebas

No se conectan a Neon ni levantan Spring: usan simulaciones (mocks) de los repositories, así que corren en segundos.

| Archivo | Qué protege | Pruebas |
|---|---|---|
| `JwtUtilTest` | Token válido; token alterado, vencido o firmado con otra clave se rechaza | 6 |
| `UsuarioServiceImplTest` | Email repetido, contraseña hasheada, anónimo nuevo y existente | 4 |
| `ReporteGpsServiceImplTest` | Coordenadas fuera de Perú, usuario o ruta inexistentes, guardado correcto | 6 |
| `EtaServiceImplTest` | ETA real y simulado, cuándo se cae al simulado, caché | 9 |
| `HistoricoCongestionServiceImplTest` | Filtro por franja y día, cálculo por usuario, datos descartados, actualización sin duplicar | 14 |

Comando: `.\mvnw.cmd test "-Dtest=JwtUtilTest,*ServiceImplTest"`.

**Sobre TDD:** estas pruebas se escribieron **después** del código (*test-after*), no antes. El ciclo TDD completo es: escribir un test que falla (rojo), escribir el mínimo código para que pase (verde) y limpiar (refactor). Para la evidencia del curso, muestra el ciclo con una prueba: rompe a propósito una regla (por ejemplo, comenta la comprobación de email repetido en `UsuarioServiceImpl.registrar`), corre el test, toma captura del fallo, restaura el código y toma captura de que vuelve a pasar. Para cada servicio **nuevo**, escribe el test primero.

### 10.2 Pruebas de punta a punta (Postman): 30 requests, 58 comprobaciones

Archivo: `PiuraGo_E2E.postman_collection.json` (se importa en Postman y se ejecuta con **Run collection**). Recorre registro, login, usuario anónimo, rutas, reportes GPS (incluida la suplantación bloqueada), ETA, congestión y seguridad/CORS, pasando tokens e ids solos de un paso al siguiente.

Antes de ejecutarla:

1. Backend corriendo en `http://localhost:8080`.
2. Las 10 rutas cargadas en Neon.
3. Sin paradero de prueba en RD-11 (`DELETE FROM paradero WHERE nombre = 'PRUEBA';`).
4. Los datos semilla de congestión (reportes de un lunes a las 7:00 y un sábado a las 22:00) insertados en `reporte_gps`. Pídeselos a Isa o consúltalos en la carpeta `05` de la colección.

Orden obligatorio: las carpetas dependen unas de otras. Cada ejecución crea un usuario registrado y uno anónimo con prefijo `e2e`, que se pueden borrar al terminar.

### 10.3 Pruebas de controllers y de seguridad

No hay pruebas unitarias para los controllers, `JwtAuthFilter`, `SecurityConfig` ni `GlobalExceptionHandler`: se cubren con la colección de Postman. Tampoco hay medición de cobertura de código (si el docente la pide, se agrega JaCoCo al `pom.xml`).

---

## 11. Cómo agregar una funcionalidad nueva

Sigue siempre este orden. Cada paso depende del anterior:

1. **Base de datos.** Si hace falta una tabla o columna nueva, escribe el SQL y ejecútalo en pgAdmin **antes** de tocar Java (sección 5.4).
2. **Entidad** en `model/`, con el mismo nombre de columnas que la tabla.
3. **Repository** en `repository/`: una interfaz que extienda `JpaRepository`. Agrega solo los métodos de búsqueda que necesites.
4. **Service**: la interfaz en `service/` y la implementación en `service/impl/`. Aquí van las validaciones y los cálculos. Si algo está mal, lanza `IllegalArgumentException("mensaje claro")` y el handler lo convierte en 400.
5. **DTOs** en `dto/`: uno de entrada (con validaciones) y uno de salida (con `desde(entidad)`). Nunca devuelvas una entidad desde un controller.
6. **Controller** en `controller/`: recibe el DTO, llama al service y devuelve un DTO. Para saber quién llama, usa `@AuthenticationPrincipal UsuarioAutenticado`; no recibas `idUsuario` en el JSON.
7. **Seguridad.** Por defecto, todo endpoint nuevo exige token. Si debe restringirse a registrados, agrega una regla en `SecurityConfig`.
8. **Pruebas.** Un test unitario del service (ideal: escrito primero) y una petición con comprobaciones en la colección de Postman.
9. **Documentación.** Actualiza este archivo.

**Errores frecuentes:**

- El nombre del archivo `.java` debe ser **idéntico** al de la clase pública (mayúsculas incluidas).
- Todo archivo debe declarar el paquete `com.piuragopiura.piuragopiura_backend...` y estar en la carpeta que le corresponde.
- Si agregas un campo a una entidad sin agregar la columna en Neon, el backend no arranca.

---

## 12. Estado actual

| Área | Estado |
|---|---|
| Modelo de datos (7 tablas) y 10 rutas reales cargadas | ✅ |
| Capas model, repository, service, controller, dto | ✅ |
| Seguridad JWT (registrados y anónimos), roles, 401/403, CORS | ✅ probado manualmente en Postman |
| ETA real y simulado, caché Guava | ✅ |
| Congestión por franja, día y usuario | ✅ |
| Librerías del sílabo: Guava, Commons, Logback | ✅ |
| Diagrama BPM | ✅ |
| Mockup UX/UI en Lovable | ✅ |
| 39 pruebas unitarias | Entregadas; ejecutarlas con el comando de la sección 10.1 y guardar la evidencia |
| Colección Postman E2E (58 comprobaciones) | Entregada; ejecutarla y guardar la captura del Runner |
| Cliente Flutter | ❌ |
| Despliegue | ❌ |

---

## 13. Lo que falta y por qué

### 13.1 Cliente Flutter

**Por qué falta:** el backend ya está listo, pero el pasajero no usa Postman; usa la app. Sin cliente no hay producto, y es donde el equipo de frontend puede avanzar ya mismo sin esperar nada del backend.

**Qué hacer:**

- Sacar los colores y la tipografía exactos de `src/styles.css` del repositorio del mockup de Lovable y crear el tema de Flutter (`ThemeData`). El código React **no** se reutiliza: se reconstruye cada pantalla con widgets de Flutter usando el mockup como referencia visual.
- Pantallas mínimas (un MVP razonable): entrar como anónimo con un solo toque, lista de rutas, detalle de ruta con su ETA.
- Después: login con cuenta, compartir ubicación (siempre de forma opt-in), y las pantallas del dashboard de congestión.
- Flujo de sesión en la app:
  1. En el primer arranque, generar un UUID y guardarlo (por ejemplo, con `flutter_secure_storage`).
  2. Llamar a `POST /api/usuarios/anonimo` y guardar el token.
  3. Enviar `Authorization: Bearer <token>` en cada petición.
  4. Si una respuesta es **401**, renovar el token y reintentar.
- URL base: `http://10.0.2.2:8080` desde el emulador de Android (`localhost` dentro del emulador es el propio emulador). Con `flutter run -d chrome` sí sirve `http://localhost:8080`, y el CORS ya acepta cualquier puerto de localhost.
- Mostrar `origen` en el ETA: si es `SIMULADO`, indicarlo en pantalla ("estimado") para no engañar al usuario.

### 13.2 Datos reales: paraderos y frecuencias

**Por qué faltan:** el texto de las rutas solo trae nombres de calles, no coordenadas, y no trae cada cuántos minutos pasa una unidad. No se pueden inventar.

**Por qué importan:** sin paraderos con coordenadas, el ETA **real** nunca se activa (necesita un paradero destino): el sistema siempre devuelve el simulado. Y mientras no haya frecuencias reales, la cuenta regresiva simulada usa 12 minutos para todas las rutas.

**Qué hacer:** sacar las coordenadas de cada paradero desde Google Maps, insertarlas en `paradero` (con su `orden_secuencial`) y, si se consiguen, cargar `frecuencia_minutos` por ruta (`UPDATE ruta SET frecuencia_minutos = ... WHERE codigo = '...'`).

### 13.3 Despliegue

**Por qué falta:** hoy el backend solo corre cuando alguien ejecuta `mvnw spring-boot:run` en su laptop. Desplegar lo deja disponible 24/7 con una URL pública, para que cualquier teléfono lo use.

**Qué hacer, en orden:**

1. **`.gitignore` y secretos.** Antes de subir a GitHub, `application.properties` **no puede llevar credenciales reales**. Pasar a variables de entorno: `spring.datasource.url`, `username`, `password`, `jwt.secret` y `app.cors.allowed-origin-patterns`. Spring las lee de variables con estos nombres: `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`, `JWT_SECRET`, `APP_CORS_ALLOWED_ORIGIN_PATTERNS`. Excluir también `target/` y `logs/`.
2. **Rotar la contraseña de Neon.** La actual quedó escrita en una conversación; hay que cambiarla desde el panel de Neon antes de publicar.
3. **Dockerfile.** Render **no tiene entorno nativo de Java** (sus entornos nativos son Node, Python, Ruby, Go, Rust y Elixir): una aplicación Java se despliega como contenedor Docker. Hay que escribir un `Dockerfile` en la raíz del proyecto. Una propuesta estándar, **aún no probada** en este proyecto:

   ```dockerfile
   FROM eclipse-temurin:21-jdk AS build
   WORKDIR /app
   COPY . .
   RUN chmod +x mvnw && ./mvnw -DskipTests clean package

   FROM eclipse-temurin:21-jre
   WORKDIR /app
   COPY --from=build /app/target/*.jar app.jar
   EXPOSE 8080
   ENTRYPOINT ["java", "-jar", "app.jar"]
   ```

   Además, Render indica el puerto con la variable `PORT`: conviene agregar `server.port=${PORT:8080}` a `application.properties`.
4. **Render.** Crear un Web Service desde el repositorio de GitHub con ese Dockerfile y cargar las variables de entorno en su panel.
5. **CORS en producción.** Poner en `app.cors.allowed-origin-patterns` solo el dominio real del cliente web, si lo hay. Las apps móviles no lo necesitan.
6. **Limpieza de configuración.** Quitar `spring.jpa.show-sql=true` y, si se agregó, `logging.level.org.springframework.security=DEBUG`.
7. **Opcional:** GitHub Actions para compilar y correr las pruebas unitarias en cada subida, como evidencia de automatización para el sílabo.

### 13.4 Limitaciones del diseño actual

| Limitación | Por qué importa | Posible solución |
|---|---|---|
| El ETA real toma el primer paradero como "siguiente" | Para una combi que ya avanzó varios tramos, el tiempo estimado es incorrecto | Determinar el paradero más cercano por delante, o guardar el último paradero visitado |
| El ETA real mezcla combis de la misma ruta | Dos unidades reportando a la vez producen una velocidad sin sentido | Agrupar los reportes por usuario o por viaje, como ya se hace en la congestión |
| La congestión es por ruta completa y no distingue ida y vuelta | El tráfico de ida y de vuelta puede ser muy distinto | Agregar `sentido` a `paradero`, `reporte_gps` e `historico_congestion` (cambia 4 tablas y los cálculos; solo vale la pena con paraderos reales) |
| No hay refresh token | Un usuario registrado debe volver a loguearse cada 24 h | Agregar un token de renovación de larga vida |
| No hay rol de administrador | Cualquier usuario registrado puede recalcular la congestión | Agregar una columna de rol y una regla en `SecurityConfig` |
| `JwtAuthFilter` no captura `UsernameNotFoundException` | Si se borra un usuario y su token sigue vigente, la petición puede dar 500 en vez de 401 | Capturar la excepción en el filtro y continuar sin autenticar |
| `AuthController` usa un repository directamente | Rompe la regla de dependencias entre capas (sección 4.3) | Mover esa búsqueda a `UsuarioService` |
| `logback-spring.xml` apunta a un paquete que no existe | Los `log.debug` del proyecto no se ven | Corregir el nombre del paquete (sección 6.10) |
| Columnas `tiempo_dia` y `tiempo_estimado` sin uso | Datos que parecen significar algo y no se llenan | Usarlas o quitarlas |

### 13.5 Opcional

- **Exportar el dashboard con Apache POI** (librería del sílabo): se dejó pendiente a propósito hasta tener la pantalla del dashboard que la necesite.
- **Medición de cobertura** (JaCoCo) y pruebas unitarias de controllers, si el docente las pide.
- **Documentación de la API** con OpenAPI/Swagger, útil para que el equipo de Flutter vea los endpoints sin leer este documento.

### 13.6 Entregables académicos

Ejecutar las 39 pruebas unitarias y la colección de Postman y **guardar las capturas**, preparar la evidencia del ciclo rojo-verde (sección 10.1) y mantener este documento actualizado para el informe.

---

## 14. Glosario

| Término | Significado |
|---|---|
| **API REST** | Servicio web que expone datos mediante URLs y verbos HTTP (`GET` consulta, `POST` crea) |
| **Endpoint** | Una URL concreta de la API, por ejemplo `GET /api/rutas` |
| **JSON** | Formato de texto con el que la app y el servidor intercambian datos |
| **Entidad** | Clase Java que representa una tabla de la base de datos |
| **DTO** | Clase que define qué datos entran o salen por la API; separa lo que ve el cliente de cómo se guarda |
| **DAO / Repository** | Capa que aísla el acceso a la base de datos |
| **ORM (JPA / Hibernate)** | Traduce clases Java a tablas, para trabajar sin escribir SQL a mano |
| **Inyección de dependencias** | Spring entrega a cada clase los objetos que necesita en el constructor, en vez de que ella los cree |
| **Bean** | Objeto creado y administrado por Spring (los `@Service`, `@Repository`, `@Controller` y `@Configuration`) |
| **JWT** | Token firmado que el servidor entrega al iniciar sesión; la app lo muestra en cada petición y el servidor no guarda sesiones |
| **BCrypt** | Algoritmo de hash pensado para contraseñas: no se puede revertir |
| **Stateless** | El servidor no recuerda sesiones; cada petición trae su propio token |
| **Autenticación vs. autorización** | Probar quién eres vs. qué se te permite hacer |
| **CORS** | Regla del navegador que bloquea llamadas a otro origen salvo que el servidor las autorice |
| **Haversine** | Fórmula que calcula la distancia entre dos coordenadas sobre la esfera terrestre |
| **Idempotente** | Una operación que, repetida con los mismos datos, deja el mismo resultado |
| **Mock** | Objeto falso que reemplaza a una dependencia real para probar una clase aislada |
| **TDD** | Escribir el test primero, verlo fallar, hacerlo pasar y limpiar |
| **MVP** | Versión mínima de un producto que ya es útil para un usuario real |
| **PaaS** | Servicio que aloja y ejecuta tu aplicación sin que administres el servidor (Render) |

---

## Apéndice A: SQL de la base de datos

Solo hace falta si se quiere recrear la base desde cero (por ejemplo, en una base local). En la base compartida de Neon **ya está aplicado**: no lo ejecutes de nuevo.

```sql
-- Tabla padre: todo usuario es ANONIMO o REGISTRADO
CREATE TABLE usuario (
    id_usuario        BIGSERIAL PRIMARY KEY,
    tipo_usuario      VARCHAR(10) NOT NULL
                       CHECK (tipo_usuario IN ('ANONIMO', 'REGISTRADO')),
    tipo_dispositivo  VARCHAR(20),
    activo            BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_creacion    TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE usuario_registrado (
    id_usuario     BIGINT PRIMARY KEY
                   REFERENCES usuario (id_usuario) ON DELETE CASCADE,
    nombre         VARCHAR(120) NOT NULL,
    email          VARCHAR(160) NOT NULL UNIQUE,
    password_hash  VARCHAR(255) NOT NULL
);

CREATE TABLE usuario_anonimo (
    id_usuario            BIGINT PRIMARY KEY
                          REFERENCES usuario (id_usuario) ON DELETE CASCADE,
    device_uuid           VARCHAR(64) NOT NULL UNIQUE,
    fecha_ultimo_acceso   TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE ruta (
    id_ruta          BIGSERIAL PRIMARY KEY,
    nombre           VARCHAR(80) NOT NULL,
    descripcion      VARCHAR(255),
    activa           BOOLEAN NOT NULL DEFAULT TRUE,
    tiempo_estimado  INTEGER
);

-- Columnas agregadas después para los datos reales de las rutas
ALTER TABLE ruta
    ADD COLUMN codigo             VARCHAR(10),
    ADD COLUMN empresa            VARCHAR(120),
    ADD COLUMN punto_inicio       VARCHAR(120),
    ADD COLUMN punto_final        VARCHAR(120),
    ADD COLUMN sentido            VARCHAR(15) NOT NULL DEFAULT 'IDA_VUELTA',
    ADD COLUMN recorrido          TEXT,
    ADD COLUMN frecuencia_minutos INTEGER;

CREATE UNIQUE INDEX ux_ruta_codigo ON ruta (codigo);

CREATE TABLE paradero (
    id_paradero        BIGSERIAL PRIMARY KEY,
    id_ruta            BIGINT NOT NULL
                       REFERENCES ruta (id_ruta) ON DELETE CASCADE,
    nombre             VARCHAR(100) NOT NULL,
    latitud            DECIMAL(9,6) NOT NULL,
    longitud           DECIMAL(9,6) NOT NULL,
    orden_secuencial   SMALLINT NOT NULL,
    UNIQUE (id_ruta, orden_secuencial)
);

CREATE TABLE reporte_gps (
    id_reporte   BIGSERIAL PRIMARY KEY,
    id_usuario   BIGINT NOT NULL
                 REFERENCES usuario (id_usuario) ON DELETE CASCADE,
    id_ruta      BIGINT NOT NULL
                 REFERENCES ruta (id_ruta) ON DELETE CASCADE,
    latitud      DECIMAL(9,6) NOT NULL,
    longitud     DECIMAL(9,6) NOT NULL,
    fecha_hora   TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reporte_gps_ruta_fecha ON reporte_gps (id_ruta, fecha_hora DESC);
CREATE INDEX idx_reporte_gps_usuario    ON reporte_gps (id_usuario);

CREATE TABLE historico_congestion (
    id_historico             BIGSERIAL PRIMARY KEY,
    id_ruta                  BIGINT NOT NULL
                             REFERENCES ruta (id_ruta) ON DELETE CASCADE,
    id_paradero              BIGINT
                             REFERENCES paradero (id_paradero) ON DELETE SET NULL,
    franja_horaria           VARCHAR(20) NOT NULL,
    tiempo_dia               VARCHAR(10),
    dia_semana               VARCHAR(10) NOT NULL,
    nivel_congestion         VARCHAR(10) NOT NULL,
    demora_promedio          DECIMAL(6,2),
    velocidad_promedio       DECIMAL(6,2),
    cantidad_puntos_criticos SMALLINT,
    fecha_calculo            DATE NOT NULL DEFAULT CURRENT_DATE
);

-- Evita duplicar el mismo cálculo (por paradero / a nivel de ruta completa)
CREATE UNIQUE INDEX ux_historico_con_paradero
    ON historico_congestion (id_ruta, id_paradero, franja_horaria, dia_semana)
    WHERE id_paradero IS NOT NULL;
CREATE UNIQUE INDEX ux_historico_sin_paradero
    ON historico_congestion (id_ruta, franja_horaria, dia_semana)
    WHERE id_paradero IS NULL;
CREATE INDEX idx_historico_congestion_consulta
    ON historico_congestion (id_ruta, dia_semana, franja_horaria);
```

Los datos de las 10 rutas (código, empresa, puntos inicial y final, sentido, recorrido) están cargados en la base compartida con un script `INSERT INTO ruta ...`; pídeselo a Isa si necesitas recrearlos.
