package com.piuragopiura.piuragopiura_backend.service.impl;

import com.piuragopiura.piuragopiura_backend.model.ReporteGps;
import com.piuragopiura.piuragopiura_backend.model.Ruta;
import com.piuragopiura.piuragopiura_backend.model.Usuario;
import com.piuragopiura.piuragopiura_backend.repository.ReporteGpsRepository;
import com.piuragopiura.piuragopiura_backend.repository.RutaRepository;
import com.piuragopiura.piuragopiura_backend.repository.UsuarioRepository;
import com.piuragopiura.piuragopiura_backend.service.ReporteGpsService;
import org.apache.commons.lang3.Range;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class ReporteGpsServiceImpl implements ReporteGpsService {

    // Rango aproximado del territorio peruano — descarta reportes GPS claramente corruptos o falsificados.
    private static final Range<Double> LATITUD_PERU = Range.of(-18.5, 0.0);
    private static final Range<Double> LONGITUD_PERU = Range.of(-81.5, -68.5);

    private final ReporteGpsRepository reporteGpsRepository;
    private final UsuarioRepository usuarioRepository;
    private final RutaRepository rutaRepository;

    public ReporteGpsServiceImpl(ReporteGpsRepository reporteGpsRepository,
                                  UsuarioRepository usuarioRepository,
                                  RutaRepository rutaRepository) {
        this.reporteGpsRepository = reporteGpsRepository;
        this.usuarioRepository = usuarioRepository;
        this.rutaRepository = rutaRepository;
    }

    @Override
    public ReporteGps registrarReporte(Long idUsuario, Long idRuta, BigDecimal latitud, BigDecimal longitud) {
        validarCoordenadas(latitud, longitud);

        Usuario usuario = usuarioRepository.findById(idUsuario)
            .orElseThrow(() -> new IllegalArgumentException("Usuario no encontrado: " + idUsuario));
        Ruta ruta = rutaRepository.findById(idRuta)
            .orElseThrow(() -> new IllegalArgumentException("Ruta no encontrada: " + idRuta));

        ReporteGps reporte = new ReporteGps();
        reporte.setUsuario(usuario);
        reporte.setRuta(ruta);
        reporte.setLatitud(latitud);
        reporte.setLongitud(longitud);
        return reporteGpsRepository.save(reporte);
    }

    private void validarCoordenadas(BigDecimal latitud, BigDecimal longitud) {
        if (!LATITUD_PERU.contains(latitud.doubleValue())) {
            throw new IllegalArgumentException("Latitud fuera de rango esperado: " + latitud);
        }
        if (!LONGITUD_PERU.contains(longitud.doubleValue())) {
            throw new IllegalArgumentException("Longitud fuera de rango esperado: " + longitud);
        }
    }

    @Override
    public List<ReporteGps> obtenerUltimos(Long idRuta, int limite) {
        return reporteGpsRepository.findByRuta_IdRutaOrderByFechaHoraDesc(idRuta, PageRequest.of(0, limite));
    }

    /** Tope defensivo de reportes que se leen para calcular el ETA de una ruta. */
    static final int MAX_REPORTES_RECIENTES = 200;

    @Override
    public List<ReporteGps> obtenerRecientes(Long idRuta, LocalDateTime desde) {
        return reporteGpsRepository.findByRuta_IdRutaAndFechaHoraAfterOrderByFechaHoraDesc(
                idRuta, desde, PageRequest.of(0, MAX_REPORTES_RECIENTES));
    }
}