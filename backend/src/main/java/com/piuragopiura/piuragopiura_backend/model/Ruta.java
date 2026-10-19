package com.piuragopiura.piuragopiura_backend.model;

import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "ruta")
public class Ruta {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_ruta")
    private Long idRuta;

    @Column(name = "codigo", length = 10, unique = true)
    private String codigo;

    @Column(name = "nombre", nullable = false, length = 80)
    private String nombre;

    @Column(name = "empresa", length = 120)
    private String empresa;

    @Column(name = "punto_inicio", length = 120)
    private String puntoInicio;

    @Column(name = "punto_final", length = 120)
    private String puntoFinal;

    @Column(name = "sentido", nullable = false, length = 15)
    private String sentido = "IDA_VUELTA";

    @Column(name = "descripcion", length = 255)
    private String descripcion;

    @Column(name = "recorrido", columnDefinition = "TEXT")
    private String recorrido;

    @Column(name = "activa", nullable = false)
    private Boolean activa = true;

    @Column(name = "tiempo_estimado")
    private Integer tiempoEstimado;

    @Column(name = "frecuencia_minutos")
    private Integer frecuenciaMinutos;

    @OneToMany(mappedBy = "ruta", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Paradero> paraderos = new ArrayList<>();

    public Long getIdRuta() { return idRuta; }
    public void setIdRuta(Long idRuta) { this.idRuta = idRuta; }

    public String getCodigo() { return codigo; }
    public void setCodigo(String codigo) { this.codigo = codigo; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public String getEmpresa() { return empresa; }
    public void setEmpresa(String empresa) { this.empresa = empresa; }

    public String getPuntoInicio() { return puntoInicio; }
    public void setPuntoInicio(String puntoInicio) { this.puntoInicio = puntoInicio; }

    public String getPuntoFinal() { return puntoFinal; }
    public void setPuntoFinal(String puntoFinal) { this.puntoFinal = puntoFinal; }

    public String getSentido() { return sentido; }
    public void setSentido(String sentido) { this.sentido = sentido; }

    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }

    public String getRecorrido() { return recorrido; }
    public void setRecorrido(String recorrido) { this.recorrido = recorrido; }

    public Boolean getActiva() { return activa; }
    public void setActiva(Boolean activa) { this.activa = activa; }

    public Integer getTiempoEstimado() { return tiempoEstimado; }
    public void setTiempoEstimado(Integer tiempoEstimado) { this.tiempoEstimado = tiempoEstimado; }

    public Integer getFrecuenciaMinutos() { return frecuenciaMinutos; }
    public void setFrecuenciaMinutos(Integer frecuenciaMinutos) { this.frecuenciaMinutos = frecuenciaMinutos; }

    public List<Paradero> getParaderos() { return paraderos; }
    public void setParaderos(List<Paradero> paraderos) { this.paraderos = paraderos; }
}