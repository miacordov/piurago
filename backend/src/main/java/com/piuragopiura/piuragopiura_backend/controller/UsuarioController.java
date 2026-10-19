package com.piuragopiura.piuragopiura_backend.controller;

import com.piuragopiura.piuragopiura_backend.dto.AnonimoRequestDTO;
import com.piuragopiura.piuragopiura_backend.dto.AnonimoResponseDTO;
import com.piuragopiura.piuragopiura_backend.model.UsuarioAnonimo;
import com.piuragopiura.piuragopiura_backend.security.JwtUtil;
import com.piuragopiura.piuragopiura_backend.service.UsuarioService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/usuarios")
public class UsuarioController {

    private final UsuarioService usuarioService;
    private final JwtUtil jwtUtil;

    public UsuarioController(UsuarioService usuarioService, JwtUtil jwtUtil) {
        this.usuarioService = usuarioService;
        this.jwtUtil = jwtUtil;
    }

    @PostMapping("/anonimo")
    public AnonimoResponseDTO registrarAnonimo(@Valid @RequestBody AnonimoRequestDTO request) {
        UsuarioAnonimo anonimo = usuarioService.registrarAnonimo(request.deviceUuid(), request.tipoDispositivo());
        String token = jwtUtil.generarTokenAnonimo(anonimo.getDeviceUuid(), anonimo.getIdUsuario());
        return new AnonimoResponseDTO(token, anonimo.getIdUsuario(), anonimo.getDeviceUuid());
    }
}