package com.piuragopiura.piuragopiura_backend.service.impl;

import com.piuragopiura.piuragopiura_backend.dto.ResumenCongestionDTO;
import com.piuragopiura.piuragopiura_backend.model.HistoricoCongestion;
import com.piuragopiura.piuragopiura_backend.model.Paradero;
import com.piuragopiura.piuragopiura_backend.model.ReporteGps;
import com.piuragopiura.piuragopiura_backend.model.Ruta;
import com.piuragopiura.piuragopiura_backend.repository.HistoricoCongestionRepository;
import com.piuragopiura.piuragopiura_backend.repository.ParaderoRepository;
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
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.function.Function;

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
    private static final double MAX_METROS_AL_TRAMO = 300.0;          // más lejos: el reporte no cae en ningún tramo
    private static final int MAX_TRAMOS_CRITICOS = 5;

    private final HistoricoCongestionRepository historicoRepository;
    private final ReporteGpsRepository reporteGpsRepository;
    private final RutaRepository rutaRepository;
    private final ParaderoRepository paraderoRepository;

    public HistoricoCongestionServiceImpl(HistoricoCongestionRepository historicoRepository,
                                          ReporteGpsRepository reporteGpsRepository,
                                          RutaRepository rutaRepository,
                                          ParaderoRepository paraderoRepository) {
        this.historicoRepository = historicoRepository;
        this.reporteGpsRepository = reporteGpsRepository;
        this.rutaRepository = rutaRepository;
        this.paraderoRepository = paraderoRepository;
    }

    /** Desplazamiento entre dos reportes seguidos de un mismo pasajero. */
    private record TramoGps(ReporteGps anterior, ReporteGps actual, double velocidad) {
        // El tramo pertenece a la franja y al día de su segundo reporte.
        String franja() { return FranjaHoraria.franjaDe(actual.getFechaHora()); }
        String dia() { return FranjaHoraria.diaDe(actual.getFechaHora()); }
    }

    private record Clave(String franja, String dia, int indiceParadero) {}

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

        List<TramoGps> tramos = tramosValidos(idRuta).stream()
                .filter(t -> t.franja().equals(franja) && t.dia().equals(dia))
                .toList();

        if (tramos.isEmpty()) {
            throw new IllegalArgumentException("No hay reportes GPS válidos para la ruta " + idRuta
                    + " en " + dia + " / " + franja + " (últimos " + VENTANA_DIAS + " días)");
        }

        return guardar(ruta, null, franja, dia, tramos);
    }

    @Override
    public int recalcularTodas() {
        int guardados = 0;
        for (Ruta ruta : rutaRepository.findByActivaTrue()) {
            List<TramoGps> tramos = tramosValidos(ruta.getIdRuta());
            if (tramos.isEmpty()) {
                continue;
            }
            List<Paradero> paraderos = paraderoRepository.findByRuta_IdRutaOrderByOrdenSecuencialAsc(ruta.getIdRuta());

            // Una sola pasada: cada tramo GPS suma a la ruta y, si cae sobre ella, a su tramo entre paraderos.
            Map<Clave, List<TramoGps>> grupos = new LinkedHashMap<>();
            for (TramoGps t : tramos) {
                grupos.computeIfAbsent(new Clave(t.franja(), t.dia(), -1), k -> new ArrayList<>()).add(t);
                int indice = tramoDeParaderos(t, paraderos);
                if (indice >= 0) {
                    grupos.computeIfAbsent(new Clave(t.franja(), t.dia(), indice), k -> new ArrayList<>()).add(t);
                }
            }

            for (Map.Entry<Clave, List<TramoGps>> grupo : grupos.entrySet()) {
                Clave clave = grupo.getKey();
                Paradero desde = clave.indiceParadero() < 0 ? null : paraderos.get(clave.indiceParadero());
                guardar(ruta, desde, clave.franja(), clave.dia(), grupo.getValue());
                guardados++;
            }
        }
        return guardados;
    }

    @Override
    public ResumenCongestionDTO resumenCiudad(String franjaHoraria, String diaSemana) {
        LocalDateTime ahora = LocalDateTime.now();
        String franja = vacio(franjaHoraria) ? FranjaHoraria.franjaDe(ahora)
                : normalizar(franjaHoraria, FRANJAS, "franjaHoraria");
        String dia = vacio(diaSemana) ? FranjaHoraria.diaDe(ahora)
                : normalizar(diaSemana, DIAS, "diaSemana");

        List<HistoricoCongestion> delDia = historicoRepository.findByDiaSemana(dia);
        List<HistoricoCongestion> deRutas = delDia.stream().filter(h -> h.getParadero() == null).toList();

        List<ResumenCongestionDTO.Franja> porFranja = new ArrayList<>();
        for (String f : FRANJAS) {
            List<HistoricoCongestion> deLaFranja = deRutas.stream().filter(h -> f.equals(h.getFranjaHoraria())).toList();
            if (deLaFranja.isEmpty()) {
                porFranja.add(new ResumenCongestionDTO.Franja(f, null, null));
            } else {
                double velocidad = promedio(deLaFranja, HistoricoCongestion::getVelocidadPromedio);
                porFranja.add(new ResumenCongestionDTO.Franja(f, clasificarNivel(velocidad), redondear(velocidad)));
            }
        }

        List<HistoricoCongestion> actuales = deRutas.stream().filter(h -> franja.equals(h.getFranjaHoraria())).toList();
        List<ResumenCongestionDTO.Tramo> tramosCriticos = tramosCriticos(delDia, franja);

        if (actuales.isEmpty()) {
            return new ResumenCongestionDTO(franja, dia, null, null, null, 0, 0, porFranja, tramosCriticos);
        }

        double velocidad = promedio(actuales, HistoricoCongestion::getVelocidadPromedio);
        double demora = promedio(actuales, HistoricoCongestion::getDemoraPromedio);
        int puntosCriticos = actuales.stream()
                .mapToInt(h -> h.getCantidadPuntosCriticos() == null ? 0 : h.getCantidadPuntosCriticos())
                .sum();

        return new ResumenCongestionDTO(franja, dia, clasificarNivel(velocidad), redondear(velocidad),
                redondear(demora), actuales.size(), puntosCriticos, porFranja, tramosCriticos);
    }

    /** Los tramos más lentos de la franja (por debajo de congestión media), con los nombres de sus paraderos. */
    private List<ResumenCongestionDTO.Tramo> tramosCriticos(List<HistoricoCongestion> delDia, String franja) {
        Map<Long, List<Paradero>> paraderosPorRuta = new HashMap<>();

        return delDia.stream()
                .filter(h -> h.getParadero() != null && franja.equals(h.getFranjaHoraria()))
                .filter(h -> h.getVelocidadPromedio() != null
                        && h.getVelocidadPromedio().doubleValue() < UMBRAL_CONGESTION_MEDIA_KMH)
                .sorted(Comparator.comparing(HistoricoCongestion::getVelocidadPromedio))
                .limit(MAX_TRAMOS_CRITICOS)
                .map(h -> {
                    Ruta ruta = h.getRuta();
                    List<Paradero> paraderos = paraderosPorRuta.computeIfAbsent(ruta.getIdRuta(),
                            paraderoRepository::findByRuta_IdRutaOrderByOrdenSecuencialAsc);
                    Paradero desde = h.getParadero();
                    Paradero hasta = siguiente(paraderos, desde);

                    double km = hasta == null ? 0 : distanciaHaversine(
                            desde.getLatitud().doubleValue(), desde.getLongitud().doubleValue(),
                            hasta.getLatitud().doubleValue(), hasta.getLongitud().doubleValue());
                    double demora = h.getDemoraPromedio() == null ? 0 : h.getDemoraPromedio().doubleValue();
                    double velocidad = h.getVelocidadPromedio().doubleValue();

                    return new ResumenCongestionDTO.Tramo(ruta.getCodigo(), ruta.getNombre(), desde.getNombre(),
                            hasta == null ? null : hasta.getNombre(), redondear(velocidad),
                            clasificarNivel(velocidad), Math.round(demora * km));
                })
                .toList();
    }

    private Paradero siguiente(List<Paradero> paraderos, Paradero paradero) {
        for (int i = 0; i < paraderos.size() - 1; i++) {
            if (paraderos.get(i).getIdParadero().equals(paradero.getIdParadero())) {
                return paraderos.get(i + 1);
            }
        }
        return null;
    }

    /** Lee los reportes de la ventana y devuelve los desplazamientos válidos de cada pasajero. */
    private List<TramoGps> tramosValidos(Long idRuta) {
        LocalDateTime desde = LocalDateTime.now().minusDays(VENTANA_DIAS);
        List<ReporteGps> reportes = reporteGpsRepository.findByRuta_IdRutaAndFechaHoraAfterOrderByFechaHoraDesc(
                idRuta, desde, PageRequest.of(0, MAX_REPORTES_A_ANALIZAR));

        // Agrupa por usuario en orden cronológico (la lista llega del más nuevo al más viejo).
        Map<Long, List<ReporteGps>> porUsuario = new HashMap<>();
        for (int i = reportes.size() - 1; i >= 0; i--) {
            ReporteGps r = reportes.get(i);
            porUsuario.computeIfAbsent(r.getUsuario().getIdUsuario(), k -> new ArrayList<>()).add(r);
        }

        List<TramoGps> tramos = new ArrayList<>();
        for (List<ReporteGps> lista : porUsuario.values()) {
            for (int i = 1; i < lista.size(); i++) {
                ReporteGps anterior = lista.get(i - 1);
                ReporteGps actual = lista.get(i);

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
                tramos.add(new TramoGps(anterior, actual, velocidad));
            }
        }
        return tramos;
    }

    /**
     * Índice k del tramo entre paraderos (k → k+1) más cercano al punto medio del desplazamiento,
     * o -1 si queda a más de MAX_METROS_AL_TRAMO de todos.
     */
    private int tramoDeParaderos(TramoGps t, List<Paradero> paraderos) {
        double lat = (t.anterior().getLatitud().doubleValue() + t.actual().getLatitud().doubleValue()) / 2;
        double lon = (t.anterior().getLongitud().doubleValue() + t.actual().getLongitud().doubleValue()) / 2;

        int mejor = -1;
        double mejorMetros = MAX_METROS_AL_TRAMO;
        for (int k = 0; k < paraderos.size() - 1; k++) {
            double metros = metrosAlSegmento(lat, lon, paraderos.get(k), paraderos.get(k + 1));
            if (metros <= mejorMetros) {
                mejorMetros = metros;
                mejor = k;
            }
        }
        return mejor;
    }

    /** Distancia de un punto al segmento a–b, en una proyección plana local (suficiente a escala de ciudad). */
    private double metrosAlSegmento(double lat, double lon, Paradero a, Paradero b) {
        double metrosPorGradoLat = 110_540.0;
        double metrosPorGradoLon = 111_320.0 * Math.cos(Math.toRadians(lat));

        double ax = (a.getLongitud().doubleValue() - lon) * metrosPorGradoLon;
        double ay = (a.getLatitud().doubleValue() - lat) * metrosPorGradoLat;
        double bx = (b.getLongitud().doubleValue() - lon) * metrosPorGradoLon;
        double by = (b.getLatitud().doubleValue() - lat) * metrosPorGradoLat;

        double dx = bx - ax;
        double dy = by - ay;
        double largo2 = dx * dx + dy * dy;
        double t = largo2 == 0 ? 0 : Math.max(0, Math.min(1, -(ax * dx + ay * dy) / largo2));
        double px = ax + t * dx;
        double py = ay + t * dy;
        return Math.sqrt(px * px + py * py);
    }

    /** Guarda (o actualiza) el registro de la ruta completa (paradero null) o de un tramo. */
    private HistoricoCongestion guardar(Ruta ruta, Paradero paradero, String franja, String dia, List<TramoGps> tramos) {
        double velocidadPromedio = tramos.stream().mapToDouble(TramoGps::velocidad).average().orElse(0);
        long tramosCriticos = tramos.stream().filter(t -> t.velocidad() < UMBRAL_TRAMO_CRITICO_KMH).count();
        // Minutos extra por kilómetro respecto a la velocidad sin tráfico.
        double demoraMinPorKm = Math.max(0,
                60.0 / Math.max(velocidadPromedio, 1.0) - 60.0 / VELOCIDAD_LIBRE_KMH);

        HistoricoCongestion registro = (paradero == null
                ? historicoRepository.findByRuta_IdRutaAndFranjaHorariaAndDiaSemanaAndParaderoIsNull(
                        ruta.getIdRuta(), franja, dia)
                : historicoRepository.findByRuta_IdRutaAndParadero_IdParaderoAndFranjaHorariaAndDiaSemana(
                        ruta.getIdRuta(), paradero.getIdParadero(), franja, dia))
                .orElseGet(HistoricoCongestion::new);

        registro.setRuta(ruta);
        registro.setParadero(paradero); // null: ruta completa
        registro.setFranjaHoraria(franja);
        registro.setDiaSemana(dia);
        registro.setNivelCongestion(clasificarNivel(velocidadPromedio));
        registro.setVelocidadPromedio(redondear(velocidadPromedio));
        registro.setDemoraPromedio(redondear(demoraMinPorKm));
        registro.setCantidadPuntosCriticos((short) Math.min(tramosCriticos, Short.MAX_VALUE));
        registro.setFechaCalculo(LocalDate.now());

        return historicoRepository.save(registro);
    }

    private boolean vacio(String valor) {
        return valor == null || valor.isBlank();
    }

    private double promedio(List<HistoricoCongestion> registros,
                            Function<HistoricoCongestion, BigDecimal> campo) {
        return registros.stream().map(campo).filter(v -> v != null)
                .mapToDouble(BigDecimal::doubleValue).average().orElse(0);
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