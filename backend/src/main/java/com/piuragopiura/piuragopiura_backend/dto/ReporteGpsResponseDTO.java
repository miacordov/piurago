package com.piuragopiura.piuragopiura_backend.dto;

import com.piuragopiura.piuragopiura_backend.model.ReporteGps;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record ReporteGpsResponseDTO(
        Long idReporte,
        Long idUsuario,
        Long idRuta,
        BigDecimal latitud,
        BigDecimal longitud,
        LocalDateTime fechaHora
) {
    public static ReporteGpsResponseDTO desde(ReporteGps r) {
        return new ReporteGpsResponseDTO(
                r.getIdReporte(), r.getUsuario().getIdUsuario(), r.getRuta().getIdRuta(),
                r.getLatitud(), r.getLongitud(), r.getFechaHora());
    }
}