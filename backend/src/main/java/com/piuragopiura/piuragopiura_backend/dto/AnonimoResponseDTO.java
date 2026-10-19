package com.piuragopiura.piuragopiura_backend.dto;

public record AnonimoResponseDTO(
        String token,
        Long idUsuario,
        String deviceUuid
) {
}