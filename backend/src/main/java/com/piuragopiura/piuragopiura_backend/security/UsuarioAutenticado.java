package com.piuragopiura.piuragopiura_backend.security;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.User;

import java.util.Collection;

public class UsuarioAutenticado extends User {

    private final Long idUsuario;

    public UsuarioAutenticado(String username, String password,
                              Collection<? extends GrantedAuthority> authorities, Long idUsuario) {
        super(username, password, authorities);
        this.idUsuario = idUsuario;
    }

    public Long getIdUsuario() {
        return idUsuario;
    }
}