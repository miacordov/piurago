package com.piuragopiura.piuragopiura_backend.service.impl;

import com.google.common.cache.Cache;
import com.google.common.util.concurrent.UncheckedExecutionException;
import com.piuragopiura.piuragopiura_backend.dto.EtaResponseDTO;
import com.piuragopiura.piuragopiura_backend.model.Paradero;
import com.piuragopiura.piuragopiura_backend.model.ReporteGps;
import com.piuragopiura.piuragopiura_backend.model.Ruta;
import com.piuragopiura.piuragopiura_backend.repository.ParaderoRepository;
import com.piuragopiura.piuragopiura_backend.repository.RutaRepository;
import com.piuragopiura.piuragopiura_backend.service.EtaService;
import com.piuragopiura.piuragopiura_backend.service.ReporteGpsService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.List;
import java.util.concurrent.ExecutionException;

@Service
public class EtaServiceImpl implements EtaService {

    private static final Logger log = LoggerFactory.getLogger(EtaServiceImpl.class);
    private static final double RADIO_TIERRA_KM = 6371.0;
    private static final ZoneId ZONA_LIMA = ZoneId.of("America/Lima");

    // SUPUESTOS: no provienen de datos reales, se pueden ajustar.
    private static final int FRECUENCIA_POR_DEFECTO_MIN = 12;
    private static final long MAX_ANTIGUEDAD_REPORTE_MIN = 5;

    private final ReporteGpsService reporteGpsService;
    private final ParaderoRepository paraderoRepository;
    private final RutaRepository rutaRepository;
    private final Cache<Long, EtaResponseDTO> etaCache;

    public EtaServiceImpl(ReporteGpsService reporteGpsService,
                          ParaderoRepository paraderoRepository,
                          RutaRepository rutaRepository,
                          Cache<Long, EtaResponseDTO> etaCache) {
        this.reporteGpsService = reporteGpsService;
        this.paraderoRepository = paraderoRepository;
        this.rutaRepository = rutaRepository;
        this.etaCache = etaCache;
    }

    @Override
    public EtaResponseDTO calcularEtaProximoParadero(Long idRuta) {
        // Se valida fuera de la caché: Guava envuelve las excepciones lanzadas dentro del loader.
        Ruta ruta = rutaRepository.findById(idRuta)
                .orElseThrow(() -> new IllegalArgumentException("Ruta no encontrada: " + idRuta));
        try {
            return etaCache.get(idRuta, () -> calcular(ruta));
        } catch (ExecutionException | UncheckedExecutionException e) {
            log.error("Error calculando ETA real para ruta {}; se devuelve ETA simulado", idRuta, e);
            return simular(ruta);
        }
    }

    private EtaResponseDTO calcular(Ruta ruta) {
        Long idRuta = ruta.getIdRuta();

        List<ReporteGps> ultimos = reporteGpsService.obtenerUltimos(idRuta, 2);
        if (ultimos.size() < 2) {
            return simular(ruta);
        }

        ReporteGps reciente = ultimos.get(0);
        ReporteGps anterior = ultimos.get(1);

        long minutosDesdeUltimo = Duration.between(reciente.getFechaHora(), LocalDateTime.now()).toMinutes();
        if (minutosDesdeUltimo > MAX_ANTIGUEDAD_REPORTE_MIN) {
            return simular(ruta);
        }

        double distanciaRecorridaKm = distanciaHaversine(
                anterior.getLatitud().doubleValue(), anterior.getLongitud().doubleValue(),
                reciente.getLatitud().doubleValue(), reciente.getLongitud().doubleValue());

        double horasTranscurridas = Duration.between(anterior.getFechaHora(), reciente.getFechaHora())
                .toSeconds() / 3600.0;

        double velocidadKmh = (horasTranscurridas > 0) ? distanciaRecorridaKm / horasTranscurridas : 0;

        List<Paradero> paraderos = paraderoRepository.findByRuta_IdRutaOrderByOrdenSecuencialAsc(idRuta);
        if (paraderos.isEmpty() || velocidadKmh <= 0) {
            return simular(ruta);
        }

        // Limitación conocida: se toma el primer paradero como "siguiente".
        Paradero siguiente = paraderos.get(0);
        double distanciaAlParaderoKm = distanciaHaversine(
                reciente.getLatitud().doubleValue(), reciente.getLongitud().doubleValue(),
                siguiente.getLatitud().doubleValue(), siguiente.getLongitud().doubleValue());

        double minutosEstimados = (distanciaAlParaderoKm / velocidadKmh) * 60;

        log.info("ETA REAL ruta {}: {} min al paradero {}", idRuta, minutosEstimados, siguiente.getIdParadero());

        return new EtaResponseDTO(idRuta, siguiente.getIdParadero(), minutosEstimados, velocidadKmh, "REAL");
    }

    private EtaResponseDTO simular(Ruta ruta) {
        int frecuencia = (ruta.getFrecuenciaMinutos() != null && ruta.getFrecuenciaMinutos() > 0)
                ? ruta.getFrecuenciaMinutos()
                : FRECUENCIA_POR_DEFECTO_MIN;

        LocalTime ahora = LocalTime.now(ZONA_LIMA);
        int minutosDelDia = ahora.getHour() * 60 + ahora.getMinute();
        int desfase = (int) (ruta.getIdRuta() % frecuencia); // evita que todas las rutas coincidan
        int minutos = frecuencia - ((minutosDelDia + desfase) % frecuencia);

        log.debug("ETA SIMULADO ruta {}: {} min (frecuencia {} min)", ruta.getIdRuta(), minutos, frecuencia);

        return new EtaResponseDTO(ruta.getIdRuta(), null, (double) minutos, null, "SIMULADO");
    }

    private double distanciaHaversine(double lat1, double lon1, double lat2, double lon2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return RADIO_TIERRA_KM * c;
    }
}