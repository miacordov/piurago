package com.piuragopiura.piuragopiura_backend.service;

import com.piuragopiura.piuragopiura_backend.model.UsuarioAnonimo;
import com.piuragopiura.piuragopiura_backend.model.UsuarioRegistrado;

public interface UsuarioService {
    UsuarioAnonimo registrarAnonimo(String deviceUuid, String tipoDispositivo);
    UsuarioRegistrado registrar(String nombre, String email, String passwordPlano); // antes: passwordHash
}