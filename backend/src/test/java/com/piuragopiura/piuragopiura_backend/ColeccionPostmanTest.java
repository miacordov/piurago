package com.piuragopiura.piuragopiura_backend;

import com.jayway.jsonpath.JsonPath;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.springframework.core.annotation.AnnotatedElementUtils;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.lang.reflect.Method;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * La colección de Postman de backend/postman/ cubre todos los endpoints de los
 * controllers, usa {{baseUrl}} y {{token}} y no trae tokens ni credenciales.
 */
class ColeccionPostmanTest {

    private static final Path COLECCION = Path.of("postman/PiuraGo.postman_collection.json");
    private static final String PAQUETE_CONTROLLERS = "com.piuragopiura.piuragopiura_backend.controller.";
    private static final List<String> CONTROLLERS = List.of(
            "AuthController", "UsuarioController", "RutaController",
            "ReporteGpsController", "HistoricoCongestionController");

    private static String json;

    @BeforeAll
    static void leer() throws IOException {
        json = Files.readString(COLECCION, StandardCharsets.UTF_8);
    }

    /** "GET /api/rutas/{id}" y "GET {{baseUrl}}/api/rutas/{{idRuta}}?x=1" quedan como "GET /api/rutas/*". */
    private static String normalizar(String metodo, String url) {
        String ruta = url.replace("{{baseUrl}}", "").replaceAll("\\?.*$", "");
        ruta = ruta.replaceAll("\\{\\{[^}]+}}", "*").replaceAll("\\{[^}]+}", "*");
        return metodo + " " + ruta;
    }

    private static Set<String> endpointsDeLaColeccion() {
        List<String> metodos = JsonPath.read(json, "$..request.method");
        List<String> urls = JsonPath.read(json, "$..request.url.raw");
        Set<String> endpoints = new TreeSet<>();
        for (int i = 0; i < metodos.size(); i++) {
            endpoints.add(normalizar(metodos.get(i), urls.get(i)));
        }
        return endpoints;
    }

    private static Set<String> endpointsDeLosControllers() throws ClassNotFoundException {
        Set<String> endpoints = new TreeSet<>();
        for (String nombre : CONTROLLERS) {
            Class<?> clase = Class.forName(PAQUETE_CONTROLLERS + nombre);
            assertThat(clase.isAnnotationPresent(RestController.class)).isTrue();
            String prefijo = clase.getAnnotation(RequestMapping.class).value()[0];
            for (Method m : clase.getDeclaredMethods()) {
                RequestMapping mapeo = AnnotatedElementUtils.findMergedAnnotation(m, RequestMapping.class);
                if (mapeo == null) continue;
                String sufijo = mapeo.path().length == 0 ? "" : mapeo.path()[0];
                endpoints.add(normalizar(mapeo.method()[0].name(), prefijo + sufijo));
            }
        }
        return endpoints;
    }

    @Test
    void cubreTodosLosEndpointsDeLosControllers() throws ClassNotFoundException {
        assertThat(endpointsDeLaColeccion()).containsAll(endpointsDeLosControllers());
    }

    @Test
    void incluyeLosEndpointsNuevosYActuator() {
        assertThat(endpointsDeLaColeccion()).contains(
                "GET /api/rutas/*/posiciones",
                "GET /actuator/health",
                "GET /actuator/info");
    }

    @Test
    void todasLasUrlsUsanBaseUrl() {
        List<String> urls = JsonPath.read(json, "$..request.url.raw");
        assertThat(urls).isNotEmpty().allSatisfy(u -> assertThat(u).startsWith("{{baseUrl}}/"));
    }

    @Test
    void elTokenSaleDeLaVariableToken() {
        assertThat((List<Object>) JsonPath.read(json, "$.auth.bearer[?(@.key == 'token')].value"))
                .containsExactly("{{token}}");
        List<String> variables = JsonPath.read(json, "$.variable[*].key");
        assertThat(variables).contains("baseUrl", "token");
    }

    @Test
    void noTraeTokensNiCredencialesReales() {
        // Un JWT empieza con "eyJ" (el encabezado en base64); el token se guarda vacío.
        assertThat(json).doesNotContain("eyJ");
        List<Object> token = JsonPath.read(json, "$.variable[?(@.key == 'token')].value");
        assertThat(token).containsExactly("");
        assertThat(Pattern.compile("(?i)neon\\.tech|jdbc:|JWT_SECRET|password\\s*=").matcher(json).find())
                .isFalse();
    }

    @Test
    void lasPeticionesPublicasNoMandanToken() {
        List<String> sinAuth = new ArrayList<>(JsonPath.read(json,
                "$..item[?(@.request.auth.type == 'noauth')].request.url.raw"));
        assertThat(sinAuth).contains(
                "{{baseUrl}}/api/auth/registro",
                "{{baseUrl}}/api/auth/login",
                "{{baseUrl}}/api/usuarios/anonimo",
                "{{baseUrl}}/actuator/health");
    }
}
