package com.piuragopiura.piuragopiura_backend.service;

import com.piuragopiura.piuragopiura_backend.model.ReporteComunidad;
import com.piuragopiura.piuragopiura_backend.model.TipoReporteComunidad;

import java.math.BigDecimal;

public interface ReporteComunidadService {

    /**
     * Guarda el reporte de un pasajero. La ruta y la ubicación son opcionales;
     * la ubicación va completa (latitud y longitud) o no va.
     */
    ReporteComunidad registrar(Long idUsuario, TipoReporteComunidad tipo, Long idRuta,
                               String descripcion, BigDecimal latitud, BigDecimal longitud);
}
