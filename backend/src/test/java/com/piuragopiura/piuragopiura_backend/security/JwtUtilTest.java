package com.piuragopiura.piuragopiura_backend.security;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class JwtUtilTest {

    private static final String SECRET = "clave-de-prueba-con-mas-de-32-caracteres-123456";
    private static final long UNA_HORA_MS = 3_600_000L;

    private final JwtUtil jwtUtil = new JwtUtil(SECRET, UNA_HORA_MS);

    @Test
    void tokenDeRegistradoEsValidoYGuardaElEmail() {
        String token = jwtUtil.generarToken("ana@example.com", 7L);

        assertThat(jwtUtil.esValido(token)).isTrue();
        assertThat(jwtUtil.extraerEmail(token)).isEqualTo("ana@example.com");
    }

    @Test
    void tokenAnonimoUsaElPrefijoAnonYElUuid() {
        String token = jwtUtil.generarTokenAnonimo("uuid-123", 9L);

        assertThat(jwtUtil.esValido(token)).isTrue();
        assertThat(jwtUtil.extraerEmail(token)).isEqualTo("anon:uuid-123");
    }

    @Test
    void tokenAlteradoNoEsValido() {
        String token = jwtUtil.generarToken("ana@example.com", 7L);

        // Se cambia el primer carácter de la firma, que sí afecta a los bytes firmados.
        int inicioFirma = token.lastIndexOf('.') + 1;
        char original = token.charAt(inicioFirma);
        char cambiado = (original == 'A') ? 'B' : 'A';
        String alterado = token.substring(0, inicioFirma) + cambiado + token.substring(inicioFirma + 1);

        assertThat(jwtUtil.esValido(alterado)).isFalse();
    }

    @Test
    void tokenFirmadoConOtraClaveNoEsValido() {
        JwtUtil otro = new JwtUtil("otra-clave-totalmente-distinta-de-mas-de-32-caracteres", UNA_HORA_MS);
        String token = otro.generarToken("ana@example.com", 7L);

        assertThat(jwtUtil.esValido(token)).isFalse();
    }

    @Test
    void tokenVencidoNoEsValido() {
        JwtUtil conExpiracionPasada = new JwtUtil(SECRET, -1000L);
        String token = conExpiracionPasada.generarToken("ana@example.com", 7L);

        assertThat(jwtUtil.esValido(token)).isFalse();
    }

    @Test
    void textoQueNoEsUnTokenNoEsValido() {
        assertThat(jwtUtil.esValido("esto-no-es-un-token")).isFalse();
    }
}