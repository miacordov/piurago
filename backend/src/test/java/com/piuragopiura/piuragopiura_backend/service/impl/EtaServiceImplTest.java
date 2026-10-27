package com.piuragopiura.piuragopiura_backend.service.impl;

import com.google.common.cache.Cache;
import com.google.common.cache.CacheBuilder;
import com.piuragopiura.piuragopiura_backend.dto.EtaResponseDTO;
import com.piuragopiura.piuragopiura_backend.model.HistoricoCongestion;
import com.piuragopiura.piuragopiura_backend.model.Paradero;
import com.piuragopiura.piuragopiura_backend.model.ReporteGps;
import com.piuragopiura.piuragopiura_backend.model.Ruta;
import com.piuragopiura.piuragopiura_backend.model.UsuarioAnonimo;
import com.piuragopiura.piuragopiura_backend.repository.HistoricoCongestionRepository;
import com.piuragopiura.piuragopiura_backend.repository.ParaderoRepository;
import com.piuragopiura.piuragopiura_backend.repository.RutaRepository;
import com.piuragopiura.piuragopiura_backend.service.ReporteGpsService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.within;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class EtaServiceImplTest {

    @Mock private ReporteGpsService reporteGpsService;
    @Mock private ParaderoRepository paraderoRepository;
    @Mock private RutaRepository rutaRepository;
    @Mock private HistoricoCongestionRepository historicoRepository;

    private EtaServiceImpl service;

    @BeforeEach
    void setUp() {
        // Caché real y vacía en cada test, para que un test no contamine a otro.
        Cache<Long, EtaResponseDTO> cache = CacheBuilder.newBuilder().build();
        service = new EtaServiceImpl(reporteGpsService, paraderoRepository, rutaRepository,
                historicoRepository, cache);
    }

    // ---------- ayudas ----------

    private Ruta ruta(Integer frecuenciaMinutos) {
        Ruta ruta = new Ruta();
        ruta.setIdRuta(1L);
        ruta.setFrecuenciaMinutos(frecuenciaMinutos);
        return ruta;
    }

    private ReporteGps reporte(long idUsuario, double lat, LocalDateTime fechaHora) {
        UsuarioAnonimo usuario = new UsuarioAnonimo();
        usuario.setIdUsuario(idUsuario);
        ReporteGps r = new ReporteGps();
        r.setUsuario(usuario);
        r.setLatitud(BigDecimal.valueOf(lat));
        r.setLongitud(BigDecimal.valueOf(-80.0));
        r.setFechaHora(fechaHora);
        return r;
    }

    private Paradero paradero(long id, double lat) {
        Paradero p = new Paradero();
        p.setIdParadero(id);
        p.setLatitud(BigDecimal.valueOf(lat));
        p.setLongitud(BigDecimal.valueOf(-80.0));
        return p;
    }

    /**
     * Reportes de un mismo pasajero, del más nuevo al más viejo (como los entrega el
     * servicio): el reciente hace 10 s y el anterior 60 s antes.
     */
    private List<ReporteGps> viaje(double latAnterior, double latReciente) {
        LocalDateTime reciente = LocalDateTime.now().minusSeconds(10);
        return List.of(
                reporte(5L, latReciente, reciente),
                reporte(5L, latAnterior, reciente.minusSeconds(60)));
    }

    private void conReportes(List<ReporteGps> reportes) {
        when(reporteGpsService.obtenerRecientes(eq(1L), any(LocalDateTime.class))).thenReturn(reportes);
    }

    private void conParaderos(Paradero... paraderos) {
        when(paraderoRepository.findByRuta_IdRutaOrderByOrdenSecuencialAsc(1L)).thenReturn(List.of(paraderos));
    }

    private void conHistorico(Double velocidadKmh) {
        Optional<HistoricoCongestion> historico = Optional.empty();
        if (velocidadKmh != null) {
            HistoricoCongestion h = new HistoricoCongestion();
            h.setVelocidadPromedio(BigDecimal.valueOf(velocidadKmh));
            historico = Optional.of(h);
        }
        when(historicoRepository.findByRuta_IdRutaAndFranjaHorariaAndDiaSemanaAndParaderoIsNull(
                eq(1L), anyString(), anyString())).thenReturn(historico);
    }

    // ---------- sin datos en vivo: SIMULADO ----------

    @Test
    void rutaInexistenteLanzaErrorSinConsultarReportes() {
        when(rutaRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.calcularEtaProximoParadero(99L))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Ruta no encontrada");

        verifyNoInteractions(reporteGpsService, paraderoRepository, historicoRepository);
    }

    @Test
    void sinReportesDevuelveEtaSimuladoConLaFrecuenciaPorDefecto() {
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(ruta(null)));
        conReportes(List.of());

        EtaResponseDTO eta = service.calcularEtaProximoParadero(1L);

        assertThat(eta.origen()).isEqualTo("SIMULADO");
        assertThat(eta.idParadero()).isNull();
        assertThat(eta.velocidadPromedioKmh()).isNull();
        assertThat(eta.minutosEstimados()).isBetween(1.0, 12.0);
    }

    @Test
    void laFrecuenciaDeLaRutaTienePrioridadSobreLaFrecuenciaPorDefecto() {
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(ruta(5)));
        conReportes(List.of());

        EtaResponseDTO eta = service.calcularEtaProximoParadero(1L);

        assertThat(eta.origen()).isEqualTo("SIMULADO");
        assertThat(eta.minutosEstimados()).isBetween(1.0, 5.0);
    }

    @Test
    void soloPideLosReportesDeLosUltimosCincoMinutos() {
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(ruta(null)));
        conReportes(List.of());

        service.calcularEtaProximoParadero(1L);

        ArgumentCaptor<LocalDateTime> desde = ArgumentCaptor.forClass(LocalDateTime.class);
        verify(reporteGpsService).obtenerRecientes(eq(1L), desde.capture());
        long minutos = Duration.between(desde.getValue(), LocalDateTime.now()).toMinutes();
        assertThat(minutos).isBetween(4L, 5L);
    }

    @Test
    void conUnSoloReporteDevuelveEtaSimulado() {
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(ruta(null)));
        conReportes(List.of(reporte(5L, -5.0, LocalDateTime.now())));

        assertThat(service.calcularEtaProximoParadero(1L).origen()).isEqualTo("SIMULADO");
    }

    @Test
    void conUnReporteDeCadaPasajeroDevuelveEtaSimulado() {
        // Dos pasajeros en buses distintos, un reporte cada uno: no se mezclan.
        LocalDateTime ahora = LocalDateTime.now();
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(ruta(null)));
        conReportes(List.of(reporte(5L, -5.01, ahora), reporte(6L, -5.30, ahora.minusSeconds(30))));

        assertThat(service.calcularEtaProximoParadero(1L).origen()).isEqualTo("SIMULADO");
    }

    @Test
    void sinParaderosDevuelveEtaSimuladoAunqueHayaReportesRecientes() {
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(ruta(null)));
        conReportes(viaje(-5.00, -5.01));
        conParaderos();

        assertThat(service.calcularEtaProximoParadero(1L).origen()).isEqualTo("SIMULADO");
    }

    // ---------- con un bus compartiendo su viaje: REAL ----------

    @Test
    void conReportesRecientesYParaderosCalculaElEtaReal() {
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(ruta(null)));
        // Recorre 0.01° de latitud (≈1.112 km) en 60 s => ≈66.72 km/h.
        conReportes(viaje(-5.00, -5.01));
        // El paradero está a otros 0.01°: tarda lo mismo que el tramo anterior (1 minuto).
        conParaderos(paradero(7L, -5.02));

        EtaResponseDTO eta = service.calcularEtaProximoParadero(1L);

        assertThat(eta.origen()).isEqualTo("REAL");
        assertThat(eta.idParadero()).isEqualTo(7L);
        assertThat(eta.velocidadPromedioKmh()).isCloseTo(66.72, within(0.1));
        assertThat(eta.minutosEstimados()).isCloseTo(1.0, within(0.01));
    }

    @Test
    void calculaHastaElSiguienteParaderoYNoHastaElPrimero() {
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(ruta(null)));
        // El bus va hacia el sur (de -5.00 a -5.01): el paradero 1 ya quedó atrás.
        conReportes(viaje(-5.00, -5.01));
        conParaderos(paradero(1L, -4.99), paradero(2L, -5.02), paradero(3L, -5.05));

        EtaResponseDTO eta = service.calcularEtaProximoParadero(1L);

        assertThat(eta.idParadero()).isEqualTo(2L);
        assertThat(eta.minutosEstimados()).isCloseTo(1.0, within(0.01));
    }

    @Test
    void enElViajeDeVueltaEligeElParaderoHaciaDondeVa() {
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(ruta(null)));
        // Mismos paraderos, pero el bus va hacia el norte (de -5.04 a -5.03).
        conReportes(viaje(-5.04, -5.03));
        conParaderos(paradero(1L, -4.99), paradero(2L, -5.02), paradero(3L, -5.05));

        assertThat(service.calcularEtaProximoParadero(1L).idParadero()).isEqualTo(2L);
    }

    @Test
    void noMezclaLosReportesDeDistintosPasajeros() {
        LocalDateTime ahora = LocalDateTime.now().minusSeconds(10);
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(ruta(null)));
        // Entre los dos reportes del pasajero 5 se cuela el del pasajero 6, en otro bus
        // muy lejos: antes se tomaban los dos últimos de la ruta y la velocidad salía absurda.
        conReportes(List.of(
                reporte(5L, -5.01, ahora),
                reporte(6L, -5.40, ahora.minusSeconds(20)),
                reporte(5L, -5.00, ahora.minusSeconds(60))));
        conParaderos(paradero(7L, -5.02));

        EtaResponseDTO eta = service.calcularEtaProximoParadero(1L);

        assertThat(eta.origen()).isEqualTo("REAL");
        assertThat(eta.velocidadPromedioKmh()).isCloseTo(66.72, within(0.1));
    }

    @Test
    void conElBusDetenidoUsaLaVelocidadHistoricaDeLaLinea() {
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(ruta(null)));
        // Mismo punto en ambos reportes: la combi está detenida (semáforo, paradero).
        conReportes(viaje(-5.01, -5.01));
        conParaderos(paradero(7L, -5.02));
        conHistorico(20.0);

        EtaResponseDTO eta = service.calcularEtaProximoParadero(1L);

        // Antes caía en SIMULADO; ahora la posición sigue siendo real.
        assertThat(eta.origen()).isEqualTo("REAL");
        assertThat(eta.idParadero()).isEqualTo(7L);
        assertThat(eta.velocidadPromedioKmh()).isCloseTo(20.0, within(0.001));
        // 1.112 km a 20 km/h => ≈3.34 min.
        assertThat(eta.minutosEstimados()).isCloseTo(3.34, within(0.01));
    }

    @Test
    void sinHistoricoUsaLaVelocidadUrbanaPorDefecto() {
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(ruta(null)));
        conReportes(viaje(-5.01, -5.01));
        conParaderos(paradero(7L, -5.02));
        conHistorico(null);

        EtaResponseDTO eta = service.calcularEtaProximoParadero(1L);

        assertThat(eta.origen()).isEqualTo("REAL");
        assertThat(eta.velocidadPromedioKmh()).isEqualTo(EtaServiceImpl.VELOCIDAD_URBANA_POR_DEFECTO_KMH);
    }

    @Test
    void unaVelocidadImposibleSeReemplazaPorLaHistorica() {
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(ruta(null)));
        // 0.1° (≈11 km) en 60 s => ≈667 km/h: ruido del GPS.
        conReportes(viaje(-4.91, -5.01));
        conParaderos(paradero(7L, -5.02));
        conHistorico(20.0);

        assertThat(service.calcularEtaProximoParadero(1L).velocidadPromedioKmh())
                .isCloseTo(20.0, within(0.001));
    }

    @Test
    void laSegundaConsultaSeResuelveDesdeLaCacheSinVolverACalcular() {
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(ruta(null)));
        conReportes(List.of());

        service.calcularEtaProximoParadero(1L);
        service.calcularEtaProximoParadero(1L);

        verify(reporteGpsService, times(1)).obtenerRecientes(eq(1L), any(LocalDateTime.class));
    }
}
