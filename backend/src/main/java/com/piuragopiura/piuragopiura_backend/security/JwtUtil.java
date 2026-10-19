package com.piuragopiura.piuragopiura_backend.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Component
public class JwtUtil {

    public static final String PREFIJO_ANONIMO = "anon:";

    private final SecretKey key;
    private final long expirationMs;

    public JwtUtil(@Value("${jwt.secret}") String secret,
                   @Value("${jwt.expiration-ms}") long expirationMs) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.expirationMs = expirationMs;
    }

    public String generarToken(String email, Long idUsuario) {
        return construir(email, idUsuario, "REGISTRADO");
    }

    public String generarTokenAnonimo(String deviceUuid, Long idUsuario) {
        return construir(PREFIJO_ANONIMO + deviceUuid, idUsuario, "ANONIMO");
    }

    private String construir(String subject, Long idUsuario, String tipo) {
        Date ahora = new Date();
        Date expiracion = new Date(ahora.getTime() + expirationMs);

        return Jwts.builder()
                .subject(subject)
                .claim("idUsuario", idUsuario)
                .claim("tipo", tipo)
                .issuedAt(ahora)
                .expiration(expiracion)
                .signWith(key)
                .compact();
    }

    // Devuelve el "subject" del token: el email (registrado) o "anon:<deviceUuid>" (anónimo).
    public String extraerEmail(String token) {
        return extraerClaims(token).getSubject();
    }

    public boolean esValido(String token) {
        try {
            extraerClaims(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private Claims extraerClaims(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}