package com.piuragopiura.piuragopiura_backend.service.impl;

import com.piuragopiura.piuragopiura_backend.model.HistoricoCongestion;
import com.piuragopiura.piuragopiura_backend.model.ReporteGps;
import com.piuragopiura.piuragopiura_backend.model.Ruta;
import com.piuragopiura.piuragopiura_backend.repository.HistoricoCongestionRepository;
import com.piuragopiura.piuragopiura_backend.repository.ReporteGpsRepository;
import com.piuragopiura.piuragopiura_backend.repository.RutaRepository;
import com.piuragopiura.piuragopiura_backend.service.HistoricoCongestionService;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
public class HistoricoCongestionServiceImpl implements HistoricoCongestionService {

    private static final double RADIO_TIERRA_KM = 6371.0;

    private static final List<String> FRANJAS = FranjaHoraria.FRANJAS;
    private static final List<String> DIAS = FranjaHoraria.DIAS;

    // SUPUESTOS: no provienen de datos reales, se pueden ajustar.
    private static final double VELOCIDAD_LIBRE_KMH = 25.0;           // velocidad sin tráfico
    private static final double UMBRAL_TRAMO_CRITICO_KMH = 10.0;      // por debajo: congestión ALTA / tramo crítico
    private static final double UMBRAL_CONGESTION_MEDIA_KMH = 18.0;   // por debajo: congestión MEDIA
    private static final double MAX_VELOCIDAD_PLAUSIBLE_KMH = 100.0;  // por encima: ruido de GPS, se descarta
    private static final long MAX_SEGUNDOS_ENTRE_REPORTES = 600;      // más separación: son viajes distintos
    private static final int VENTANA_DIAS = 28;
    private static final int MAX_REPORTES_A_ANALIZAR = 5000;

    private final HistoricoCongestionRepository historicoRepository;
    private final ReporteGpsRepository reporteGpsRepository;
    private final RutaRepository rutaRepository;

    public HistoricoCongestionServiceImpl(HistoricoCongestionRepository historicoRepository,
                                          ReporteGpsRepository reporteGpsRepository,
                                          RutaRepository rutaRepository) {
        this.historicoRepository = historicoRepository;
        this.reporteGpsRepository = reporteGpsRepository;
        this.rutaRepository = rutaRepository;
    }

    @Override
    public List<HistoricoCongestion> obtenerPorRuta(Long idRuta) {
        return historicoRepository.findByRuta_IdRutaOrderByFechaCalculoDesc(idRuta);
    }

    @Override
    public HistoricoCongestion recalcularParaRuta(Long idRuta, String franjaHoraria, String diaSemana) {
        String franja = normalizar(franjaHoraria, FRANJAS, "franjaHoraria");
        String dia = normalizar(diaSemana, DIAS, "diaSemana");

        Ruta ruta = rutaRepository.findById(idRuta)
                .orElseThrow(() -> new IllegalArgumentException("Ruta no encontrada: " + idRuta));

        LocalDateTime desde = LocalDateTime.now().minusDays(VENTANA_DIAS);
        List<ReporteGps> reportes = reporteGpsRepository.findByRuta_IdRutaAndFechaHoraAfterOrderByFechaHoraDesc(
                idRuta, desde, PageRequest.of(0, MAX_REPORTES_A_ANALIZAR));

        // Agrupa por usuario en orden cronológico (la lista llega del más nuevo al más viejo).
        Map<Long, List<ReporteGps>> porUsuario = new HashMap<>();
        for (int i = reportes.size() - 1; i >= 0; i--) {
            ReporteGps r = reportes.get(i);
            porUsuario.computeIfAbsent(r.getUsuario().getIdUsuario(), k -> new ArrayList<>()).add(r);
        }

        double sumaVelocidad = 0;
        int tramos = 0;
        int tramosCriticos = 0;

        for (List<ReporteGps> lista : porUsuario.values()) {
            for (int i = 1; i < lista.size(); i++) {
                ReporteGps anterior = lista.get(i - 1);
                ReporteGps actual = lista.get(i);

                // El tramo pertenece a la franja y al día de su segundo reporte.
                if (!FranjaHoraria.franjaDe(actual.getFechaHora()).equals(franja)
                        || !FranjaHoraria.diaDe(actual.getFechaHora()).equals(dia)) {
                    continue;
                }

                long segundos = Duration.between(anterior.getFechaHora(), actual.getFechaHora()).toSeconds();
                if (segundos <= 0 || segundos > MAX_SEGUNDOS_ENTRE_REPORTES) {
                    continue;
                }

                double km = distanciaHaversine(
                        anterior.getLatitud().doubleValue(), anterior.getLongitud().doubleValue(),
                        actual.getLatitud().doubleValue(), actual.getLongitud().doubleValue());
                double velocidad = km / (segundos / 3600.0);

                if (velocidad > MAX_VELOCIDAD_PLAUSIBLE_KMH) {
                    continue;
                }

                sumaVelocidad += velocidad;
                tramos++;
                if (velocidad < UMBRAL_TRAMO_CRITICO_KMH) {
                    tramosCriticos++;
                }
            }
        }

        if (tramos == 0) {
            throw new IllegalArgumentException("No hay reportes GPS válidos para la ruta " + idRuta
                    + " en " + dia + " / " + franja + " (últimos " + VENTANA_DIAS + " días)");
        }

        double velocidadPromedio = sumaVelocidad / tramos;
        // Minutos extra por kilómetro respecto a la velocidad sin tráfico.
        double demoraMinPorKm = Math.max(0,
                60.0 / Math.max(velocidadPromedio, 1.0) - 60.0 / VELOCIDAD_LIBRE_KMH);

        HistoricoCongestion registro = historicoRepository
                .findByRuta_IdRutaAndFranjaHorariaAndDiaSemanaAndParaderoIsNull(idRuta, franja, dia)
                .orElseGet(HistoricoCongestion::new);

        registro.setRuta(ruta);
        registro.setParadero(null); // a nivel de ruta completa
        registro.setFranjaHoraria(franja);
        registro.setDiaSemana(dia);
        registro.setNivelCongestion(clasificarNivel(velocidadPromedio));
        registro.setVelocidadPromedio(redondear(velocidadPromedio));
        registro.setDemoraPromedio(redondear(demoraMinPorKm));
        registro.setCantidadPuntosCriticos((short) tramosCriticos);
        registro.setFechaCalculo(LocalDate.now());

        return historicoRepository.save(registro);
    }

    private String normalizar(String valor, List<String> validos, String campo) {
        String v = (valor == null) ? "" : valor.trim().toUpperCase(Locale.ROOT);
        if (!validos.contains(v)) {
            throw new IllegalArgumentException(campo + " inválido: '" + valor
                    + "'. Valores permitidos: " + validos);
        }
        return v;
    }



    private String clasificarNivel(double velocidadKmh) {
        if (velocidadKmh < UMBRAL_TRAMO_CRITICO_KMH) return "ALTA";
        if (velocidadKmh < UMBRAL_CONGESTION_MEDIA_KMH) return "MEDIA";
        return "BAJA";
    }

    private BigDecimal redondear(double valor) {
        return BigDecimal.valueOf(valor).setScale(2, RoundingMode.HALF_UP);
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