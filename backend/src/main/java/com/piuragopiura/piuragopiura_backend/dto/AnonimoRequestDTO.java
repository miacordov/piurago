package com.piuragopiura.piuragopiura_backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AnonimoRequestDTO(
        @NotBlank @Size(max = 64) String deviceUuid,
        @Size(max = 20) String tipoDispositivo
) {
}