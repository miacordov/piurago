package com.piuragopiura.piuragopiura_backend.service.impl;

import com.piuragopiura.piuragopiura_backend.dto.PosicionColaboradorDTO;
import com.piuragopiura.piuragopiura_backend.dto.PosicionesRutaResponseDTO;
import com.piuragopiura.piuragopiura_backend.exception.RecursoNoEncontradoException;
import com.piuragopiura.piuragopiura_backend.model.ReporteGps;
import com.piuragopiura.piuragopiura_backend.repository.ReporteGpsRepository;
import com.piuragopiura.piuragopiura_backend.repository.RutaRepository;
import com.piuragopiura.piuragopiura_backend.service.PosicionesService;
import org.apache.commons.lang3.Range;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class PosicionesServiceImpl implements PosicionesService {

    /** Una ventana de más de una hora ya no es "reciente". */
    private static final Range<Integer> VENTANA_VALIDA_MIN = Range.of(1, 60);

    private final ReporteGpsRepository reporteGpsRepository;
    private final RutaRepository rutaRepository;
    private final int ventanaMinutos;
    private final Clock reloj;

    @Autowired
    public PosicionesServiceImpl(ReporteGpsRepository reporteGpsRepository,
                                 RutaRepository rutaRepository,
                                 @Value("${piurago.posiciones.ventana-minutos:2}") int ventanaMinutos) {
        // Los reportes se guardan con la hora local del servidor (LocalDateTime.now()).
        this(reporteGpsRepository, rutaRepository, ventanaMinutos, Clock.systemDefaultZone());
    }

    PosicionesServiceImpl(ReporteGpsRepository reporteGpsRepository,
                          RutaRepository rutaRepository,
                          int ventanaMinutos,
                          Clock reloj) {
        if (!VENTANA_VALIDA_MIN.contains(ventanaMinutos)) {
            throw new IllegalArgumentException(
                    "La ventana de posiciones debe estar entre 1 y 60 minutos: " + ventanaMinutos);
        }
        this.reporteGpsRepository = reporteGpsRepository;
        this.rutaRepository = rutaRepository;
        this.ventanaMinutos = ventanaMinutos;
        this.reloj = reloj;
    }

    @Override
    public PosicionesRutaResponseDTO obtenerPosiciones(Long idRuta) {
        if (!rutaRepository.existsById(idRuta)) {
            throw new RecursoNoEncontradoException("Ruta no encontrada: " + idRuta);
        }
        LocalDateTime desde = LocalDateTime.now(reloj).minusMinutes(ventanaMinutos);
        List<ReporteGps> ultimos = reporteGpsRepository.findUltimaPorColaborador(idRuta, desde);

        // La consulta ya trae el último reporte de cada colaborador; si dos empatan en
        // la hora, se queda uno solo para no contarlo dos veces.
        Map<Long, ReporteGps> porColaborador = new LinkedHashMap<>();
        for (ReporteGps r : ultimos) {
            porColaborador.putIfAbsent(r.getUsuario().getIdUsuario(), r);
        }
        List<PosicionColaboradorDTO> posiciones = porColaborador.values().stream()
                .sorted(Comparator.comparing(ReporteGps::getFechaHora).reversed())
                .map(r -> new PosicionColaboradorDTO(r.getLatitud(), r.getLongitud(), r.getFechaHora()))
                .toList();
        return new PosicionesRutaResponseDTO(idRuta, ventanaMinutos, posiciones.size(), posiciones);
    }
}
