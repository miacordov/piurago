package com.piuragopiura.piuragopiura_backend.service.impl;

import com.piuragopiura.piuragopiura_backend.model.UsuarioAnonimo;
import com.piuragopiura.piuragopiura_backend.model.UsuarioRegistrado;
import com.piuragopiura.piuragopiura_backend.repository.UsuarioAnonimoRepository;
import com.piuragopiura.piuragopiura_backend.repository.UsuarioRegistradoRepository;
import com.piuragopiura.piuragopiura_backend.service.UsuarioService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import static org.mockito.Mockito.when;

import java.time.LocalDateTime;

@Service
public class UsuarioServiceImpl implements UsuarioService {

    private final UsuarioAnonimoRepository usuarioAnonimoRepository;
    private final UsuarioRegistradoRepository usuarioRegistradoRepository;
    private final PasswordEncoder passwordEncoder;

    public UsuarioServiceImpl(UsuarioAnonimoRepository usuarioAnonimoRepository,
                               UsuarioRegistradoRepository usuarioRegistradoRepository,
                               PasswordEncoder passwordEncoder) {
        this.usuarioAnonimoRepository = usuarioAnonimoRepository;
        this.usuarioRegistradoRepository = usuarioRegistradoRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public UsuarioAnonimo registrarAnonimo(String deviceUuid, String tipoDispositivo) {
    return usuarioAnonimoRepository.findByDeviceUuid(deviceUuid)
            .map(existente -> {
                existente.setFechaUltimoAcceso(LocalDateTime.now());
                return usuarioAnonimoRepository.save(existente);
            })
            .orElseGet(() -> {
                UsuarioAnonimo nuevo = new UsuarioAnonimo();
                nuevo.setDeviceUuid(deviceUuid);
                nuevo.setTipoDispositivo(tipoDispositivo);
                return usuarioAnonimoRepository.save(nuevo);
            });
    }

    @Override
    public UsuarioRegistrado registrar(String nombre, String email, String passwordPlano) {
        if (usuarioRegistradoRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("El email ya está registrado");
        }
        UsuarioRegistrado nuevo = new UsuarioRegistrado();
        nuevo.setNombre(nombre);
        nuevo.setEmail(email);
        nuevo.setPasswordHash(passwordEncoder.encode(passwordPlano));
        return usuarioRegistradoRepository.save(nuevo);
    }
    
    @Test
    void buscaUnUsuarioRegistradoPorEmail() {
        UsuarioRegistrado usuario = new UsuarioRegistrado();
        usuario.setEmail("ana@example.com");
        when(usuarioRegistradoRepository.findByEmail("ana@example.com")).thenReturn(Optional.of(usuario));

        assertThat(service.buscarPorEmail("ana@example.com")).isSameAs(usuario);
    }

    @Test
    void rechazaUnEmailQueNoExiste() {
        when(usuarioRegistradoRepository.findByEmail("nadie@example.com")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.buscarPorEmail("nadie@example.com"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("no encontrado");
    }
    
    @Override
    public UsuarioRegistrado buscarPorEmail(String email) {
        return usuarioRegistradoRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Usuario no encontrado"));
    }
}