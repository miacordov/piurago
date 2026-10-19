package com.piuragopiura.piuragopiura_backend.model;

import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "historico_congestion")
public class HistoricoCongestion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_historico")
    private Long idHistorico;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_ruta", nullable = false)
    private Ruta ruta;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_paradero") // nullable: NULL = aplica a toda la ruta
    private Paradero paradero;

    @Column(name = "franja_horaria", nullable = false, length = 20)
    private String franjaHoraria;

    @Column(name = "tiempo_dia", length = 10)
    private String tiempoDia;

    @Column(name = "dia_semana", nullable = false, length = 10)
    private String diaSemana;

    @Column(name = "nivel_congestion", nullable = false, length = 10)
    private String nivelCongestion;

    @Column(name = "demora_promedio", precision = 6, scale = 2)
    private BigDecimal demoraPromedio;

    @Column(name = "velocidad_promedio", precision = 6, scale = 2)
    private BigDecimal velocidadPromedio;

    @Column(name = "cantidad_puntos_criticos")
    private Short cantidadPuntosCriticos;

    @Column(name = "fecha_calculo", nullable = false)
    private LocalDate fechaCalculo = LocalDate.now();

    public Long getIdHistorico() { return idHistorico; }
    public void setIdHistorico(Long idHistorico) { this.idHistorico = idHistorico; }

    public Ruta getRuta() { return ruta; }
    public void setRuta(Ruta ruta) { this.ruta = ruta; }

    public Paradero getParadero() { return paradero; }
    public void setParadero(Paradero paradero) { this.paradero = paradero; }

    public String getFranjaHoraria() { return franjaHoraria; }
    public void setFranjaHoraria(String franjaHoraria) { this.franjaHoraria = franjaHoraria; }

    public String getTiempoDia() { return tiempoDia; }
    public void setTiempoDia(String tiempoDia) { this.tiempoDia = tiempoDia; }

    public String getDiaSemana() { return diaSemana; }
    public void setDiaSemana(String diaSemana) { this.diaSemana = diaSemana; }

    public String getNivelCongestion() { return nivelCongestion; }
    public void setNivelCongestion(String nivelCongestion) { this.nivelCongestion = nivelCongestion; }

    public BigDecimal getDemoraPromedio() { return demoraPromedio; }
    public void setDemoraPromedio(BigDecimal demoraPromedio) { this.demoraPromedio = demoraPromedio; }

    public BigDecimal getVelocidadPromedio() { return velocidadPromedio; }
    public void setVelocidadPromedio(BigDecimal velocidadPromedio) { this.velocidadPromedio = velocidadPromedio; }

    public Short getCantidadPuntosCriticos() { return cantidadPuntosCriticos; }
    public void setCantidadPuntosCriticos(Short cantidadPuntosCriticos) { this.cantidadPuntosCriticos = cantidadPuntosCriticos; }

    public LocalDate getFechaCalculo() { return fechaCalculo; }
    public void setFechaCalculo(LocalDate fechaCalculo) { this.fechaCalculo = fechaCalculo; }
}