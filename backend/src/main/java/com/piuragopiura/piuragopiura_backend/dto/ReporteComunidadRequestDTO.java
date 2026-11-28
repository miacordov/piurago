package com.piuragopiura.piuragopiura_backend.dto;

import com.piuragopiura.piuragopiura_backend.model.TipoReporteComunidad;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public record ReporteComunidadRequestDTO(
        @NotNull TipoReporteComunidad tipo,
        Long idRuta,
        @NotBlank @Size(max = 500) String descripcion,
        BigDecimal latitud,
        BigDecimal longitud
) {
}
