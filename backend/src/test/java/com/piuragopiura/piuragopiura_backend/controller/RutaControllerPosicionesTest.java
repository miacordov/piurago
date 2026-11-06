package com.piuragopiura.piuragopiura_backend.controller;

import com.piuragopiura.piuragopiura_backend.dto.PosicionColaboradorDTO;
import com.piuragopiura.piuragopiura_backend.dto.PosicionesRutaResponseDTO;
import com.piuragopiura.piuragopiura_backend.exception.RecursoNoEncontradoException;
import com.piuragopiura.piuragopiura_backend.security.JwtAuthFilter;
import com.piuragopiura.piuragopiura_backend.security.JwtUtil;
import com.piuragopiura.piuragopiura_backend.security.SecurityConfig;
import com.piuragopiura.piuragopiura_backend.service.PosicionesService;
import com.piuragopiura.piuragopiura_backend.service.RutaService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * GET /api/rutas/{id}/posiciones con la seguridad real de la app (SecurityConfig y
 * JwtAuthFilter). El JWT se simula: no hace falta base de datos ni clave de firma.
 */
@WebMvcTest(RutaController.class)
@Import({SecurityConfig.class, JwtAuthFilter.class})
@TestPropertySource(properties = "app.cors.allowed-origin-patterns=http://localhost:*")
class RutaControllerPosicionesTest {

    private static final String TOKEN = "token-de-prueba";

    @Autowired private MockMvc mvc;

    @MockitoBean private RutaService rutaService;
    @MockitoBean private PosicionesService posicionesService;
    @MockitoBean private JwtUtil jwtUtil;
    @MockitoBean private UserDetailsService userDetailsService;

    @BeforeEach
    void tokenValido() {
        when(jwtUtil.esValido(TOKEN)).thenReturn(true);
        when(jwtUtil.extraerEmail(TOKEN)).thenReturn("anon:dispositivo-1");
        when(userDetailsService.loadUserByUsername("anon:dispositivo-1"))
                .thenReturn(User.withUsername("anon:dispositivo-1").password("").roles("ANONIMO").build());
    }

    @Test
    void sinTokenResponde401() throws Exception {
        mvc.perform(get("/api/rutas/7/posiciones"))
                .andExpect(status().isUnauthorized());

        verifyNoInteractions(posicionesService);
    }

    @Test
    void conTokenDevuelveLasPosicionesYLosColaboradoresActivos() throws Exception {
        LocalDateTime hora = LocalDateTime.of(2026, 11, 4, 8, 0, 15);
        when(posicionesService.obtenerPosiciones(7L)).thenReturn(new PosicionesRutaResponseDTO(
                7L, 2, 1,
                List.of(new PosicionColaboradorDTO(new BigDecimal("-5.194500"), new BigDecimal("-80.632800"), hora))));

        mvc.perform(get("/api/rutas/7/posiciones").header("Authorization", "Bearer " + TOKEN))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.idRuta").value(7))
                .andExpect(jsonPath("$.ventanaMinutos").value(2))
                .andExpect(jsonPath("$.colaboradoresActivos").value(1))
                .andExpect(jsonPath("$.posiciones[0].latitud").value(-5.1945))
                .andExpect(jsonPath("$.posiciones[0].longitud").value(-80.6328))
                .andExpect(jsonPath("$.posiciones[0].fechaHora").value("2026-11-04T08:00:15"))
                .andExpect(jsonPath("$.posiciones[0].idUsuario").doesNotExist());
    }

    @Test
    void unaRutaInexistenteResponde404() throws Exception {
        when(posicionesService.obtenerPosiciones(99L))
                .thenThrow(new RecursoNoEncontradoException("Ruta no encontrada: 99"));

        mvc.perform(get("/api/rutas/99/posiciones").header("Authorization", "Bearer " + TOKEN))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").value("Ruta no encontrada: 99"));
    }
}
