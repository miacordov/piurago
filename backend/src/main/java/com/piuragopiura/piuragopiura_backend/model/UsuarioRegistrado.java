package com.piuragopiura.piuragopiura_backend.model;

import jakarta.persistence.*;

@Entity
@Table(name = "usuario_registrado")
@PrimaryKeyJoinColumn(name = "id_usuario")
@DiscriminatorValue("REGISTRADO")
public class UsuarioRegistrado extends Usuario {

    @Column(name = "nombre", nullable = false, length = 120)
    private String nombre;

    @Column(name = "email", nullable = false, unique = true, length = 160)
    private String email;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPasswordHash() { return passwordHash; }
    public void setPasswordHash(String passwordHash) { this.passwordHash = passwordHash; }
}