package com.piuragopiura.piuragopiura_backend.service;

import com.piuragopiura.piuragopiura_backend.model.ReporteGps;

import java.math.BigDecimal;
import java.util.List;

public interface ReporteGpsService {
    ReporteGps registrarReporte(Long idUsuario, Long idRuta, BigDecimal latitud, BigDecimal longitud);
    List<ReporteGps> obtenerUltimos(Long idRuta, int limite);
}
