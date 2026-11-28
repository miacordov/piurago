package com.piuragopiura.piuragopiura_backend.dto;

import com.piuragopiura.piuragopiura_backend.model.ReporteComunidad;
import com.piuragopiura.piuragopiura_backend.model.TipoReporteComunidad;

import java.time.LocalDateTime;

public record ReporteComunidadResponseDTO(
        Long idReporteComunidad,
        TipoReporteComunidad tipo,
        Long idRuta,
        String descripcion,
        String estado,
        LocalDateTime fechaHora
) {
    public static ReporteComunidadResponseDTO desde(ReporteComunidad r) {
        return new ReporteComunidadResponseDTO(
                r.getIdReporteComunidad(), r.getTipo(),
                r.getRuta() == null ? null : r.getRuta().getIdRuta(),
                r.getDescripcion(), r.getEstado(), r.getFechaHora());
    }
}
