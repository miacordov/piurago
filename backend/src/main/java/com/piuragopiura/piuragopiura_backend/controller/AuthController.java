package com.piuragopiura.piuragopiura_backend.controller;

import com.piuragopiura.piuragopiura_backend.dto.AuthResponseDTO;
import com.piuragopiura.piuragopiura_backend.dto.LoginRequestDTO;
import com.piuragopiura.piuragopiura_backend.dto.RegistroRequestDTO;
import com.piuragopiura.piuragopiura_backend.model.UsuarioRegistrado;
import com.piuragopiura.piuragopiura_backend.security.JwtUtil;
import com.piuragopiura.piuragopiura_backend.service.UsuarioService;
import jakarta.validation.Valid;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final UsuarioService usuarioService;
    private final AuthenticationManager authenticationManager;
    private final JwtUtil jwtUtil;

    public AuthController(UsuarioService usuarioService,
                           AuthenticationManager authenticationManager,
                           JwtUtil jwtUtil) {
        this.usuarioService = usuarioService;
        this.authenticationManager = authenticationManager;
        this.jwtUtil = jwtUtil;
    }

    @PostMapping("/registro")
    public AuthResponseDTO registrar(@Valid @RequestBody RegistroRequestDTO request) {
        UsuarioRegistrado creado = usuarioService.registrar(
            request.getNombre(), request.getEmail(), request.getPassword()
        );
        String token = jwtUtil.generarToken(creado.getEmail(), creado.getIdUsuario());
        return new AuthResponseDTO(token, creado.getEmail());
    }

    @PostMapping("/login")
    public AuthResponseDTO login(@Valid @RequestBody LoginRequestDTO request) {
        authenticationManager.authenticate(
            new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
        );

        UsuarioRegistrado usuario = usuarioService.buscarPorEmail(request.getEmail());

        String token = jwtUtil.generarToken(usuario.getEmail(), usuario.getIdUsuario());
        return new AuthResponseDTO(token, usuario.getEmail());
    }
}