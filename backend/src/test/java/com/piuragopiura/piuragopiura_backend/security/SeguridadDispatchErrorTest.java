package com.piuragopiura.piuragopiura_backend.security;

import jakarta.servlet.DispatcherType;
import jakarta.servlet.RequestDispatcher;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.web.FilterChainProxy;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.web.bind.annotation.RestController;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Cuando un endpoint responde con error (403 por falta de rol, 404 si no existe), Tomcat
 * hace un segundo pase interno a /error (dispatch de tipo ERROR). Como la API no tiene
 * sesión, ese pase llega sin autenticación: si SecurityConfig lo exige, el cliente recibe
 * 401 en lugar del error real.
 *
 * MockMvc no pasa la cadena de seguridad en un dispatch ERROR, así que se llama directo
 * al FilterChainProxy de Spring Security, como lo hace Tomcat.
 */
@WebMvcTest(controllers = SeguridadDispatchErrorTest.SinEndpoints.class)
@Import({SecurityConfig.class, JwtAuthFilter.class, SeguridadDispatchErrorTest.SinEndpoints.class})
@TestPropertySource(properties = "app.cors.allowed-origin-patterns=http://localhost:*")
class SeguridadDispatchErrorTest {

    /** Solo para que el slice web no cargue los controllers reales (y sus servicios). */
    @RestController
    static class SinEndpoints {
    }

    @Autowired private FilterChainProxy cadenaDeSeguridad;

    @MockitoBean private JwtUtil jwtUtil;
    @MockitoBean private UserDetailsService userDetailsService;

    private record Resultado(MockHttpServletResponse respuesta, MockFilterChain siguiente) {
        boolean llegoAlControlador() {
            return siguiente.getRequest() != null;
        }
    }

    private Resultado pasar(DispatcherType tipo, Integer estadoOriginal, String rutaOriginal) throws Exception {
        MockHttpServletRequest pedido = new MockHttpServletRequest("GET", "/error");
        pedido.setDispatcherType(tipo);
        if (estadoOriginal != null) {
            pedido.setAttribute(RequestDispatcher.ERROR_STATUS_CODE, estadoOriginal);
            pedido.setAttribute(RequestDispatcher.ERROR_REQUEST_URI, rutaOriginal);
        }
        MockHttpServletResponse respuesta = new MockHttpServletResponse();
        MockFilterChain siguiente = new MockFilterChain();
        cadenaDeSeguridad.doFilter(pedido, respuesta, siguiente);
        return new Resultado(respuesta, siguiente);
    }

    @Test
    void elPaseDeErrorDeUn403LlegaAlControladorDeErroresYNoSeVuelve401() throws Exception {
        Resultado r = pasar(DispatcherType.ERROR, 403, "/api/historico-congestion/recalcular");

        assertThat(r.llegoAlControlador()).isTrue();
        assertThat(r.respuesta().getStatus()).isNotEqualTo(401);
    }

    @Test
    void elPaseDeErrorDeUn404LlegaAlControladorDeErroresYNoSeVuelve401() throws Exception {
        Resultado r = pasar(DispatcherType.ERROR, 404, "/api/no-existe");

        assertThat(r.llegoAlControlador()).isTrue();
        assertThat(r.respuesta().getStatus()).isNotEqualTo(401);
    }

    @Test
    void pedirErrorDirectamenteSinTokenSigueDando401() throws Exception {
        // Solo se libera el pase interno de Tomcat, no una petición normal a /error.
        Resultado r = pasar(DispatcherType.REQUEST, null, null);

        assertThat(r.llegoAlControlador()).isFalse();
        assertThat(r.respuesta().getStatus()).isEqualTo(401);
    }
}
