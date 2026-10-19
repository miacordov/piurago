package com.piuragopiura.piuragopiura_backend.model;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "paradero", uniqueConstraints = @UniqueConstraint(columnNames = {"id_ruta", "orden_secuencial"}))
public class Paradero {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_paradero")
    private Long idParadero;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_ruta", nullable = false)
    private Ruta ruta;

    @Column(name = "nombre", nullable = false, length = 100)
    private String nombre;

    @Column(name = "latitud", nullable = false, precision = 9, scale = 6)
    private BigDecimal latitud;

    @Column(name = "longitud", nullable = false, precision = 9, scale = 6)
    private BigDecimal longitud;

    @Column(name = "orden_secuencial", nullable = false)
    private Short ordenSecuencial;

    public Long getIdParadero() { return idParadero; }
    public void setIdParadero(Long idParadero) { this.idParadero = idParadero; }

    public Ruta getRuta() { return ruta; }
    public void setRuta(Ruta ruta) { this.ruta = ruta; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public BigDecimal getLatitud() { return latitud; }
    public void setLatitud(BigDecimal latitud) { this.latitud = latitud; }

    public BigDecimal getLongitud() { return longitud; }
    public void setLongitud(BigDecimal longitud) { this.longitud = longitud; }

    public Short getOrdenSecuencial() { return ordenSecuencial; }
    public void setOrdenSecuencial(Short ordenSecuencial) { this.ordenSecuencial = ordenSecuencial; }
}