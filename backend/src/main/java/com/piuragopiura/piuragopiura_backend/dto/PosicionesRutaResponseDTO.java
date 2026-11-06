package com.piuragopiura.piuragopiura_backend.dto;

import java.util.List;

/**
 * Posiciones de los colaboradores de una ruta en la ventana reciente (RF-06) y
 * cuántos están activos en ella (RF-08). Hay una posición por colaborador, de la
 * más nueva a la más vieja.
 */
public record PosicionesRutaResponseDTO(
        Long idRuta,
        int ventanaMinutos,
        int colaboradoresActivos,
        List<PosicionColaboradorDTO> posiciones
) {}
