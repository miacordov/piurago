package com.piuragopiura.piuragopiura_backend.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "usuario_anonimo")
@PrimaryKeyJoinColumn(name = "id_usuario")
@DiscriminatorValue("ANONIMO")
public class UsuarioAnonimo extends Usuario {

    @Column(name = "device_uuid", nullable = false, unique = true, length = 64)
    private String deviceUuid;

    @Column(name = "fecha_ultimo_acceso", nullable = false)
    private LocalDateTime fechaUltimoAcceso = LocalDateTime.now();

    public String getDeviceUuid() { return deviceUuid; }
    public void setDeviceUuid(String deviceUuid) { this.deviceUuid = deviceUuid; }

    public LocalDateTime getFechaUltimoAcceso() { return fechaUltimoAcceso; }
    public void setFechaUltimoAcceso(LocalDateTime fechaUltimoAcceso) { this.fechaUltimoAcceso = fechaUltimoAcceso; }
}