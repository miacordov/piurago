package com.piuragopiura.piuragopiura_backend.dto;

import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

public record ReporteGpsRequestDTO(
        @NotNull Long idRuta,
        @NotNull BigDecimal latitud,
        @NotNull BigDecimal longitud
) {
}