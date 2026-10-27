package com.piuragopiura.piuragopiura_backend.dto;

import java.math.BigDecimal;
import java.util.List;

/** Congestión de toda la ciudad en una franja y un día, armada con el histórico de todas las rutas. */
public record ResumenCongestionDTO(
        String franjaHoraria,
        String diaSemana,
        String nivelGeneral,
        BigDecimal velocidadPromedio,
        BigDecimal demoraPromedio,
        int rutasConDatos,
        int puntosCriticos,
        List<Franja> porFranja,
        List<Tramo> tramosCriticos
) {
    /** Nivel de una franja del mismo día (para las barras por hora). */
    public record Franja(String franjaHoraria, String nivel, BigDecimal velocidadPromedio) {}

    /** Tramo entre dos paraderos consecutivos de una ruta. */
    public record Tramo(
            String codigoRuta,
            String nombreRuta,
            String desde,
            String hasta,
            BigDecimal velocidadPromedio,
            String nivel,
            long demoraMinutos
    ) {}
}
