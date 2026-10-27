package com.piuragopiura.piuragopiura_backend.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

import java.io.IOException;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class JwtAuthFilterTest {

    @Mock private JwtUtil jwtUtil;
    @Mock private UserDetailsService userDetailsService;
    @Mock private HttpServletRequest request;
    @Mock private HttpServletResponse response;
    @Mock private FilterChain filterChain;

    private JwtAuthFilter filter;

    @BeforeEach
    void setUp() {
        filter = new JwtAuthFilter(jwtUtil, userDetailsService);
        SecurityContextHolder.clearContext();
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void siElUsuarioDelTokenNoExisteNoLanzaErrorYLimpiaLaAutenticacion() throws ServletException, IOException {
        Authentication autenticacionAnterior = mock(Authentication.class);
        SecurityContextHolder.getContext().setAuthentication(autenticacionAnterior);

        when(request.getHeader("Authorization")).thenReturn("Be" + "arer token-valido");
        when(jwtUtil.esValido("token-valido")).thenReturn(true);
        when(jwtUtil.extraerEmail("token-valido")).thenReturn("eliminado@example.com");
        when(userDetailsService.loadUserByUsername("eliminado@example.com"))
                .thenThrow(new UsernameNotFoundException("Usuario no encontrado"));

        assertThatCode(() -> filter.doFilterInternal(request, response, filterChain))
                .doesNotThrowAnyException();

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        verify(filterChain).doFilter(request, response);
    }

    @Test
    void tokenValidoConUsuarioExistenteAutenticaComoAntes() throws ServletException, IOException {
        UserDetails userDetails = new User("ana@example.com", "hash", List.of());

        when(request.getHeader("Authorization")).thenReturn("Be" + "arer token-valido");
        when(jwtUtil.esValido("token-valido")).thenReturn(true);
        when(jwtUtil.extraerEmail("token-valido")).thenReturn("ana@example.com");
        when(userDetailsService.loadUserByUsername("ana@example.com")).thenReturn(userDetails);

        filter.doFilterInternal(request, response, filterChain);

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNotNull();
        assertThat(SecurityContextHolder.getContext().getAuthentication().getName()).isEqualTo("ana@example.com");
        verify(filterChain).doFilter(request, response);
    }

    @Test
    void tokenInvalidoNoAutenticaYNiBuscaUsuario() throws ServletException, IOException {
        when(request.getHeader("Authorization")).thenReturn("Be" + "arer token-invalido");
        when(jwtUtil.esValido("token-invalido")).thenReturn(false);

        filter.doFilterInternal(request, response, filterChain);

        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
        verifyNoInteractions(userDetailsService);
        verify(filterChain).doFilter(request, response);
    }
}
