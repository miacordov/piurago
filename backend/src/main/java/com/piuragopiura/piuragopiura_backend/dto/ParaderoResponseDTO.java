package com.piuragopiura.piuragopiura_backend.dto;

import com.piuragopiura.piuragopiura_backend.model.Paradero;

import java.math.BigDecimal;

public record ParaderoResponseDTO(
        Long idParadero,
        String nombre,
        BigDecimal latitud,
        BigDecimal longitud,
        Short ordenSecuencial
) {
    public static ParaderoResponseDTO desde(Paradero p) {
        return new ParaderoResponseDTO(
                p.getIdParadero(), p.getNombre(), p.getLatitud(),
                p.getLongitud(), p.getOrdenSecuencial());
    }
}