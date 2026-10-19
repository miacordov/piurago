package com.piuragopiura.piuragopiura_backend.dto;

import com.piuragopiura.piuragopiura_backend.model.HistoricoCongestion;

import java.math.BigDecimal;
import java.time.LocalDate;

public record HistoricoCongestionResponseDTO(
        Long idHistorico,
        Long idRuta,
        Long idParadero,
        String franjaHoraria,
        String tiempoDia,
        String diaSemana,
        String nivelCongestion,
        BigDecimal demoraPromedio,
        BigDecimal velocidadPromedio,
        Short cantidadPuntosCriticos,
        LocalDate fechaCalculo
) {
    public static HistoricoCongestionResponseDTO desde(HistoricoCongestion h) {
        return new HistoricoCongestionResponseDTO(
                h.getIdHistorico(),
                h.getRuta().getIdRuta(),
                h.getParadero() == null ? null : h.getParadero().getIdParadero(),
                h.getFranjaHoraria(), h.getTiempoDia(), h.getDiaSemana(),
                h.getNivelCongestion(), h.getDemoraPromedio(),
                h.getVelocidadPromedio(), h.getCantidadPuntosCriticos(),
                h.getFechaCalculo());
    }
}