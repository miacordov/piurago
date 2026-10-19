package com.piuragopiura.piuragopiura_backend.dto;

public record EtaResponseDTO(
        Long idRuta,
        Long idParadero,
        Double minutosEstimados,
        Double velocidadPromedioKmh,
        String origen // "REAL" o "SIMULADO"
) {
}