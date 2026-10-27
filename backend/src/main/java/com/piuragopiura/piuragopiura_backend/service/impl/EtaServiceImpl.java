package com.piuragopiura.piuragopiura_backend.service.impl;

import com.google.common.cache.Cache;
import com.google.common.util.concurrent.UncheckedExecutionException;
import com.piuragopiura.piuragopiura_backend.dto.EtaResponseDTO;
import com.piuragopiura.piuragopiura_backend.model.HistoricoCongestion;
import com.piuragopiura.piuragopiura_backend.model.Paradero;
import com.piuragopiura.piuragopiura_backend.model.ReporteGps;
import com.piuragopiura.piuragopiura_backend.model.Ruta;
import com.piuragopiura.piuragopiura_backend.repository.HistoricoCongestionRepository;
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
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@Service
public class EtaServiceImpl implements EtaService {

    private static final Logger log = LoggerFactory.getLogger(EtaServiceImpl.class);
    private static final double RADIO_TIERRA_KM = 6371.0;
    private static final ZoneId ZONA_LIMA = ZoneId.of("America/Lima");

    // SUPUESTOS: no provienen de datos reales, se pueden ajustar.
    private static final int FRECUENCIA_POR_DEFECTO_MIN = 12;
    private static final long MAX_ANTIGUEDAD_REPORTE_MIN = 5;
    /** Por debajo, el bus está detenido (semáforo, paradero, tráfico). */
    static final double VELOCIDAD_MINIMA_KMH = 3.0;
    /** Por encima, es ruido del GPS. */
    static final double VELOCIDAD_MAXIMA_KMH = 100.0;
    /** Velocidad típica de una combi en Piura cuando la línea no tiene histórico. */
    static final double VELOCIDAD_URBANA_POR_DEFECTO_KMH = 15.0;

    private final ReporteGpsService reporteGpsService;
    private final ParaderoRepository paraderoRepository;
    private final RutaRepository rutaRepository;
    private final HistoricoCongestionRepository historicoRepository;
    private final Cache<Long, EtaResponseDTO> etaCache;

    public EtaServiceImpl(ReporteGpsService reporteGpsService,
                          ParaderoRepository paraderoRepository,
                          RutaRepository rutaRepository,
                          HistoricoCongestionRepository historicoRepository,
                          Cache<Long, EtaResponseDTO> etaCache) {
        this.reporteGpsService = reporteGpsService;
        this.paraderoRepository = paraderoRepository;
        this.rutaRepository = rutaRepository;
        this.historicoRepository = historicoRepository;
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

    /**
     * ETA REAL: hace falta que un pasajero de la línea esté compartiendo su viaje
     * (dos reportes suyos en los últimos 5 minutos). Con su posición se elige el
     * siguiente paradero hacia donde va el bus. La velocidad es la del momento; si
     * el bus está detenido o la medida es ruido, la típica de la línea a esta hora
     * (histórico de congestión). Sin pasajeros compartiendo: SIMULADO.
     */
    private EtaResponseDTO calcular(Ruta ruta) {
        Long idRuta = ruta.getIdRuta();

        LocalDateTime desde = LocalDateTime.now().minusMinutes(MAX_ANTIGUEDAD_REPORTE_MIN);
        ReporteGps[] tramo = ultimoTramoDeUnPasajero(reporteGpsService.obtenerRecientes(idRuta, desde));
        if (tramo == null) {
            return simular(ruta);
        }
        ReporteGps reciente = tramo[0];
        ReporteGps anterior = tramo[1];

        List<Paradero> paraderos = paraderoRepository.findByRuta_IdRutaOrderByOrdenSecuencialAsc(idRuta);
        if (paraderos.isEmpty()) {
            return simular(ruta);
        }

        double velocidadKmh = velocidadDelTramo(anterior, reciente);
        if (velocidadKmh < VELOCIDAD_MINIMA_KMH || velocidadKmh > VELOCIDAD_MAXIMA_KMH) {
            velocidadKmh = velocidadHistorica(idRuta);
        }

        Paradero siguiente = siguienteParadero(paraderos, anterior, reciente);
        double minutosEstimados = (distanciaKm(reciente, siguiente) / velocidadKmh) * 60;

        log.info("ETA REAL ruta {}: {} min al paradero {}", idRuta, minutosEstimados, siguiente.getIdParadero());

        return new EtaResponseDTO(idRuta, siguiente.getIdParadero(), minutosEstimados, velocidadKmh, "REAL");
    }

    /**
     * Los dos últimos reportes [reciente, anterior] de un mismo pasajero: el que
     * reportó más recientemente y tiene al menos dos. Los reportes llegan del más
     * nuevo al más viejo. Así no se mezclan buses distintos de la misma línea.
     */
    private ReporteGps[] ultimoTramoDeUnPasajero(List<ReporteGps> reportes) {
        Map<Long, List<ReporteGps>> porPasajero = new LinkedHashMap<>();
        for (ReporteGps r : reportes) {
            porPasajero.computeIfAbsent(r.getUsuario().getIdUsuario(), k -> new ArrayList<>()).add(r);
        }
        for (List<ReporteGps> suyos : porPasajero.values()) {
            if (suyos.size() >= 2) {
                return new ReporteGps[] {suyos.get(0), suyos.get(1)};
            }
        }
        return null;
    }

    private double velocidadDelTramo(ReporteGps anterior, ReporteGps reciente) {
        double horas = Duration.between(anterior.getFechaHora(), reciente.getFechaHora()).toSeconds() / 3600.0;
        if (horas <= 0) {
            return 0;
        }
        return distanciaHaversine(
                anterior.getLatitud().doubleValue(), anterior.getLongitud().doubleValue(),
                reciente.getLatitud().doubleValue(), reciente.getLongitud().doubleValue()) / horas;
    }

    /** Velocidad típica de la línea en la franja y el día actuales, o la urbana por defecto. */
    private double velocidadHistorica(Long idRuta) {
        LocalDateTime ahora = LocalDateTime.now();
        return historicoRepository
                .findByRuta_IdRutaAndFranjaHorariaAndDiaSemanaAndParaderoIsNull(
                        idRuta, FranjaHoraria.franjaDe(ahora), FranjaHoraria.diaDe(ahora))
                .map(HistoricoCongestion::getVelocidadPromedio)
                .map(v -> v.doubleValue())
                .filter(v -> v >= VELOCIDAD_MINIMA_KMH)
                .orElse(VELOCIDAD_URBANA_POR_DEFECTO_KMH);
    }

    /**
     * El paradero más cercano entre aquellos a los que el bus se está acercando
     * (vale en la ida y en la vuelta). Si está detenido, el más cercano.
     */
    private Paradero siguienteParadero(List<Paradero> paraderos, ReporteGps anterior, ReporteGps reciente) {
        Paradero mejor = null;
        for (Paradero p : paraderos) {
            boolean seAcerca = distanciaKm(reciente, p) < distanciaKm(anterior, p);
            if (seAcerca && (mejor == null || distanciaKm(reciente, p) < distanciaKm(reciente, mejor))) {
                mejor = p;
            }
        }
        if (mejor != null) {
            return mejor;
        }
        Paradero cercano = paraderos.get(0);
        for (Paradero p : paraderos) {
            if (distanciaKm(reciente, p) < distanciaKm(reciente, cercano)) {
                cercano = p;
            }
        }
        return cercano;
    }

    private double distanciaKm(ReporteGps r, Paradero p) {
        return distanciaHaversine(
                r.getLatitud().doubleValue(), r.getLongitud().doubleValue(),
                p.getLatitud().doubleValue(), p.getLongitud().doubleValue());
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