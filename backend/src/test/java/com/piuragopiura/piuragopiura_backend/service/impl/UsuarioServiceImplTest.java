package com.piuragopiura.piuragopiura_backend.service.impl;

import com.piuragopiura.piuragopiura_backend.model.UsuarioAnonimo;
import com.piuragopiura.piuragopiura_backend.model.UsuarioRegistrado;
import com.piuragopiura.piuragopiura_backend.repository.UsuarioAnonimoRepository;
import com.piuragopiura.piuragopiura_backend.repository.UsuarioRegistradoRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UsuarioServiceImplTest {

    @Mock private UsuarioAnonimoRepository usuarioAnonimoRepository;
    @Mock private UsuarioRegistradoRepository usuarioRegistradoRepository;
    @Mock private PasswordEncoder passwordEncoder;

    private UsuarioServiceImpl service;

    @BeforeEach
    void setUp() {
        service = new UsuarioServiceImpl(usuarioAnonimoRepository, usuarioRegistradoRepository, passwordEncoder);
    }

    @Test
    void rechazaUnEmailYaRegistrado() {
        when(usuarioRegistradoRepository.existsByEmail("ana@example.com")).thenReturn(true);

        assertThatThrownBy(() -> service.registrar("Ana", "ana@example.com", "password123"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("ya está registrado");

        verify(usuarioRegistradoRepository, never()).save(any());
        verifyNoInteractions(passwordEncoder);
    }

    @Test
    void guardaLaContrasenaHasheadaYNuncaEnTextoPlano() {
        when(usuarioRegistradoRepository.existsByEmail("ana@example.com")).thenReturn(false);
        when(passwordEncoder.encode("password123")).thenReturn("HASH-BCRYPT");
        when(usuarioRegistradoRepository.save(any(UsuarioRegistrado.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        UsuarioRegistrado creado = service.registrar("Ana", "ana@example.com", "password123");

        assertThat(creado.getNombre()).isEqualTo("Ana");
        assertThat(creado.getEmail()).isEqualTo("ana@example.com");
        assertThat(creado.getPasswordHash()).isEqualTo("HASH-BCRYPT").isNotEqualTo("password123");
    }

    @Test
    void creaUnAnonimoNuevoCuandoElDispositivoNoExiste() {
        when(usuarioAnonimoRepository.findByDeviceUuid("uuid-1")).thenReturn(Optional.empty());
        when(usuarioAnonimoRepository.save(any(UsuarioAnonimo.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        UsuarioAnonimo creado = service.registrarAnonimo("uuid-1", "ANDROID");

        assertThat(creado.getDeviceUuid()).isEqualTo("uuid-1");
        assertThat(creado.getTipoDispositivo()).isEqualTo("ANDROID");
    }

    @Test
    void siElDispositivoYaExisteDevuelveElMismoUsuarioYActualizaElUltimoAcceso() {
        UsuarioAnonimo existente = new UsuarioAnonimo();
        existente.setIdUsuario(5L);
        existente.setDeviceUuid("uuid-1");
        LocalDateTime antes = LocalDateTime.now().minusDays(2);
        existente.setFechaUltimoAcceso(antes);

        when(usuarioAnonimoRepository.findByDeviceUuid("uuid-1")).thenReturn(Optional.of(existente));
        when(usuarioAnonimoRepository.save(any(UsuarioAnonimo.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        UsuarioAnonimo resultado = service.registrarAnonimo("uuid-1", "ANDROID");

        assertThat(resultado.getIdUsuario()).isEqualTo(5L);
        assertThat(resultado.getFechaUltimoAcceso()).isAfter(antes);
    }
}