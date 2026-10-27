# Guía de contribución

Reglas de trabajo del equipo de PiuraGo para ramas, commits y Pull Requests.

## Flujo de trabajo

1. **Actualiza `main`:** `git switch main && git pull`
2. **Crea una rama** para tu tarea: `git switch -c feature/backend-cobertura-colaboradores`
3. **Trabaja con commits pequeños** (ver convención más abajo).
4. **Sube la rama:** `git push -u origin feature/backend-cobertura-colaboradores`
5. **Abre un Pull Request** hacia `main` (en la web de GitHub o con `gh pr create`).
6. **Pide revisión** a otro integrante. Se necesita **al menos una aprobación** antes de unir.
7. **Une el PR con "Create a merge commit"** (no "Squash"), para conservar los commits del ciclo TDD (primero el test que falla, luego el código que lo hace pasar).
8. **Borra la rama** ya unida.

> **Nadie hace push directo a `main`.** Si GitHub no permite proteger `main` en repositorios privados con el plan actual, esta regla se cumple por acuerdo del equipo.

## Nombres de rama

`tipo/ambito-descripcion-corta`, en minúsculas y con guiones.

| Prefijo | Para qué | Ejemplo |
|---|---|---|
| `feature/` | Funcionalidad nueva | `feature/backend-cobertura-colaboradores` |
| `fix/` | Corrección de un error | `fix/backend-jwt-filter-401` |
| `docs/` | Solo documentación | `docs/actualizar-guia-backend` |
| `test/` | Solo pruebas | `test/backend-historico-congestion` |
| `chore/` | Mantenimiento (configuración, dependencias, limpieza) | `chore/actualizar-dependencias` |

## Mensajes de commit

Formato: `tipo(ámbito): descripción`, en español, en presente y sin punto final.

- **Tipos:** `feat`, `fix`, `docs`, `test`, `refactor`, `chore`.
- **Ámbitos:** `backend`, `frontend`, `docs`.

Ejemplos:

```
feat(backend): agrega endpoint de cobertura de colaboradores por ruta
fix(backend): responde 401 cuando el usuario del token ya no existe
docs(docs): actualiza el diagrama entidad-relación
test(backend): cubre el calculo de cobertura con 0 colaboradores
```

**Con TDD**, deja el rastro en el historial: primero un commit `test(...)` con la prueba que falla (rojo) y después un commit `feat(...)` o `fix(...)` que la hace pasar (verde). Sirve como evidencia para el curso.

## Antes de abrir un Pull Request

- **Backend:** corre las pruebas unitarias desde `backend/`:
  `./mvnw test -Dtest='JwtUtilTest,*ServiceImplTest'`
- **Secretos:** revisa con `git status` que no aparezcan `application-local.properties`, archivos `.env`, `logs/` ni ninguna contraseña o clave en el cambio.
- Mantén el PR **pequeño y con un solo propósito**. Es más fácil de revisar y de deshacer.
- Si tu rama quedó atrás de `main`, actualízala antes de pedir revisión: `git switch tu-rama && git merge main` y resuelve los conflictos en tu rama.

## Tareas

Las tareas pendientes se llevan como **Issues** de GitHub. En la descripción del Pull Request escribe `Closes #número` para que el Issue se cierre solo al unir.

## Seguridad

Nunca se suben credenciales (contraseñas de la base de datos, claves JWT, tokens). Ver `backend/README.md`.

### Dependencias

- Las versiones exactas quedan fijas en `backend/pom.xml` y en `frontend/pubspec.lock` (el `pubspec.yaml` da rangos), y Maven se usa con el Wrapper (`./mvnw`).
- **Dependabot** (`.github/dependabot.yml`) revisa cada lunes las dependencias de Maven y de Flutter, y cada mes las acciones del CI. Abre un PR cuando hay una versión nueva o una falla de seguridad conocida. Las versiones menores y de parche llegan juntas en un solo PR.
- Esos PR se revisan como cualquier otro: el CI tiene que pasar antes de unirlos. Una versión mayor puede romper el código, así que hay que probarla.
