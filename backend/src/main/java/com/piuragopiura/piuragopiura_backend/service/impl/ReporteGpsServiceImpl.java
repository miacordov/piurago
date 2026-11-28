package com.piuragopiura.piuragopiura_backend.service.impl;

import com.piuragopiura.piuragopiura_backend.model.ReporteGps;
import com.piuragopiura.piuragopiura_backend.model.Ruta;
import com.piuragopiura.piuragopiura_backend.model.Usuario;
import com.piuragopiura.piuragopiura_backend.repository.ReporteGpsRepository;
import com.piuragopiura.piuragopiura_backend.repository.RutaRepository;
import com.piuragopiura.piuragopiura_backend.repository.UsuarioRepository;
import com.piuragopiura.piuragopiura_backend.service.ReporteGpsService;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class ReporteGpsServiceImpl implements ReporteGpsService {

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
        CoordenadasPeru.validar(latitud, longitud);

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