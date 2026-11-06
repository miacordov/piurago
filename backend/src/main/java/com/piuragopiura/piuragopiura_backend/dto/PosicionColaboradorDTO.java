package com.piuragopiura.piuragopiura_backend.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Última posición conocida de un colaborador. A propósito no lleva el id del
 * usuario ni del reporte: solo dónde y cuándo.
 */
public record PosicionColaboradorDTO(
        BigDecimal latitud,
        BigDecimal longitud,
        LocalDateTime fechaHora
) {}
