package com.piuragopiura.piuragopiura_backend.dto;

import com.piuragopiura.piuragopiura_backend.model.Ruta;

import java.math.BigDecimal;

public record RutaResponseDTO(
        Long idRuta,
        String codigo,
        String nombre,
        String empresa,
        String puntoInicio,
        String puntoFinal,
        String sentido,
        String descripcion,
        String recorrido,
        Boolean activa,
        Integer tiempoEstimado,
        Integer frecuenciaMinutos,
        String tipoServicio,
        String horario,
        BigDecimal pasaje,
        BigDecimal pasajeEstudiante
) {
    public static RutaResponseDTO desde(Ruta r) {
        return new RutaResponseDTO(
                r.getIdRuta(), r.getCodigo(), r.getNombre(), r.getEmpresa(),
                r.getPuntoInicio(), r.getPuntoFinal(), r.getSentido(),
                r.getDescripcion(), r.getRecorrido(), r.getActiva(),
                r.getTiempoEstimado(), r.getFrecuenciaMinutos(),
                r.getTipoServicio(), r.getHorario(), r.getPasaje(),
                r.getPasajeEstudiante());
    }
}