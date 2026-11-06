package com.piuragopiura.piuragopiura_backend.security;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Reglas de SecurityConfig para Actuator: /actuator/health es público (para un monitor
 * externo como UptimeRobot) y el resto pide token. Los endpoints se simulan con un
 * controller de prueba; la configuración real de Actuator se revisa en
 * ActuatorConfiguracionTest y a mano contra una base local.
 */
@WebMvcTest(controllers = ActuatorSeguridadTest.ActuatorSimulado.class)
@Import({SecurityConfig.class, JwtAuthFilter.class, ActuatorSeguridadTest.ActuatorSimulado.class})
@TestPropertySource(properties = "app.cors.allowed-origin-patterns=http://localhost:*")
class ActuatorSeguridadTest {

    @RestController
    static class ActuatorSimulado {
        @GetMapping("/actuator/health")
        Map<String, String> health() {
            return Map.of("status", "UP");
        }

        @GetMapping("/actuator/health/liveness")
        Map<String, String> liveness() {
            return Map.of("status", "UP");
        }

        @GetMapping("/actuator/info")
        Map<String, String> info() {
            return Map.of();
        }
    }

    @Autowired private MockMvc mvc;

    @MockitoBean private JwtUtil jwtUtil;
    @MockitoBean private UserDetailsService userDetailsService;

    @Test
    void healthEsPublico() throws Exception {
        mvc.perform(get("/actuator/health")).andExpect(status().isOk());
    }

    @Test
    void losGruposDeHealthTambienSonPublicos() throws Exception {
        mvc.perform(get("/actuator/health/liveness")).andExpect(status().isOk());
    }

    @Test
    void infoPideToken() throws Exception {
        mvc.perform(get("/actuator/info")).andExpect(status().isUnauthorized());
    }
}
