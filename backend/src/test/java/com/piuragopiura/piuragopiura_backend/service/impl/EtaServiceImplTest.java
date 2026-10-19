package com.piuragopiura.piuragopiura_backend.service.impl;

import com.google.common.cache.Cache;
import com.google.common.cache.CacheBuilder;
import com.piuragopiura.piuragopiura_backend.dto.EtaResponseDTO;
import com.piuragopiura.piuragopiura_backend.model.Paradero;
import com.piuragopiura.piuragopiura_backend.model.ReporteGps;
import com.piuragopiura.piuragopiura_backend.model.Ruta;
import com.piuragopiura.piuragopiura_backend.repository.ParaderoRepository;
import com.piuragopiura.piuragopiura_backend.repository.RutaRepository;
import com.piuragopiura.piuragopiura_backend.service.ReporteGpsService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.within;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class EtaServiceImplTest {

    @Mock private ReporteGpsService reporteGpsService;
    @Mock private ParaderoRepository paraderoRepository;
    @Mock private RutaRepository rutaRepository;

    private EtaServiceImpl service;

    @BeforeEach
    void setUp() {
        // Caché real y vacía en cada test, para que un test no contamine a otro.
        Cache<Long, EtaResponseDTO> cache = CacheBuilder.newBuilder().build();
        service = new EtaServiceImpl(reporteGpsService, paraderoRepository, rutaRepository, cache);
    }

    // ---------- ayudas ----------

    private Ruta ruta(Integer frecuenciaMinutos) {
        Ruta ruta = new Ruta();
        ruta.setIdRuta(1L);
        ruta.setFrecuenciaMinutos(frecuenciaMinutos);
        return ruta;
    }

    private ReporteGps reporte(double lat, double lon, LocalDateTime fechaHora) {
        ReporteGps r = new ReporteGps();
        r.setLatitud(BigDecimal.valueOf(lat));
        r.setLongitud(BigDecimal.valueOf(lon));
        r.setFechaHora(fechaHora);
        return r;
    }

    private Paradero paradero(long id, double lat, double lon) {
        Paradero p = new Paradero();
        p.setIdParadero(id);
        p.setLatitud(BigDecimal.valueOf(lat));
        p.setLongitud(BigDecimal.valueOf(lon));
        return p;
    }

    /** Devuelve [reciente, anterior] como los entrega el servicio: reciente hace 10 s y anterior 60 s antes. */
    private List<ReporteGps> parRecienteYAnterior(double latAnterior, double latReciente) {
        LocalDateTime reciente = LocalDateTime.now().minusSeconds(10);
        return List.of(
                reporte(latReciente, -80.0, reciente),
                reporte(latAnterior, -80.0, reciente.minusSeconds(60)));
    }

    // ---------- pruebas ----------

    @Test
    void rutaInexistenteLanzaErrorSinConsultarReportes() {
        when(rutaRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.calcularEtaProximoParadero(99L))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Ruta no encontrada");

        verifyNoInteractions(reporteGpsService, paraderoRepository);
    }

    @Test
    void sinReportesDevuelveEtaSimuladoConLaFrecuenciaPorDefecto() {
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(ruta(null)));
        when(reporteGpsService.obtenerUltimos(1L, 2)).thenReturn(List.of());

        EtaResponseDTO eta = service.calcularEtaProximoParadero(1L);

        assertThat(eta.origen()).isEqualTo("SIMULADO");
        assertThat(eta.idParadero()).isNull();
        assertThat(eta.velocidadPromedioKmh()).isNull();
        assertThat(eta.minutosEstimados()).isBetween(1.0, 12.0);
    }

    @Test
    void laFrecuenciaDeLaRutaTienePrioridadSobreLaFrecuenciaPorDefecto() {
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(ruta(5)));
        when(reporteGpsService.obtenerUltimos(1L, 2)).thenReturn(List.of());

        EtaResponseDTO eta = service.calcularEtaProximoParadero(1L);

        assertThat(eta.origen()).isEqualTo("SIMULADO");
        assertThat(eta.minutosEstimados()).isBetween(1.0, 5.0);
    }

    @Test
    void conUnSoloReporteDevuelveEtaSimulado() {
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(ruta(null)));
        when(reporteGpsService.obtenerUltimos(1L, 2))
                .thenReturn(List.of(reporte(-5.0, -80.0, LocalDateTime.now())));

        assertThat(service.calcularEtaProximoParadero(1L).origen()).isEqualTo("SIMULADO");
    }

    @Test
    void conReportesViejosDevuelveEtaSimulado() {
        LocalDateTime viejo = LocalDateTime.now().minusMinutes(30);
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(ruta(null)));
        when(reporteGpsService.obtenerUltimos(1L, 2))
                .thenReturn(List.of(
                        reporte(-5.01, -80.0, viejo),
                        reporte(-5.00, -80.0, viejo.minusSeconds(60))));

        assertThat(service.calcularEtaProximoParadero(1L).origen()).isEqualTo("SIMULADO");
    }

    @Test
    void sinParaderosDevuelveEtaSimuladoAunqueHayaReportesRecientes() {
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(ruta(null)));
        when(reporteGpsService.obtenerUltimos(1L, 2)).thenReturn(parRecienteYAnterior(-5.00, -5.01));
        when(paraderoRepository.findByRuta_IdRutaOrderByOrdenSecuencialAsc(1L)).thenReturn(List.of());

        assertThat(service.calcularEtaProximoParadero(1L).origen()).isEqualTo("SIMULADO");
    }

    @Test
    void conVelocidadCeroDevuelveEtaSimulado() {
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(ruta(null)));
        // Mismo punto en ambos reportes: la combi no se movió.
        when(reporteGpsService.obtenerUltimos(1L, 2)).thenReturn(parRecienteYAnterior(-5.01, -5.01));
        when(paraderoRepository.findByRuta_IdRutaOrderByOrdenSecuencialAsc(1L))
                .thenReturn(List.of(paradero(7L, -5.02, -80.0)));

        assertThat(service.calcularEtaProximoParadero(1L).origen()).isEqualTo("SIMULADO");
    }

    @Test
    void conReportesRecientesYParaderosCalculaElEtaReal() {
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(ruta(null)));
        // Recorre 0.01° de latitud (≈1.112 km) en 60 s => ≈66.72 km/h.
        when(reporteGpsService.obtenerUltimos(1L, 2)).thenReturn(parRecienteYAnterior(-5.00, -5.01));
        // El paradero está a otros 0.01°: tarda lo mismo que el tramo anterior (1 minuto).
        when(paraderoRepository.findByRuta_IdRutaOrderByOrdenSecuencialAsc(1L))
                .thenReturn(List.of(paradero(7L, -5.02, -80.0)));

        EtaResponseDTO eta = service.calcularEtaProximoParadero(1L);

        assertThat(eta.origen()).isEqualTo("REAL");
        assertThat(eta.idParadero()).isEqualTo(7L);
        assertThat(eta.velocidadPromedioKmh()).isCloseTo(66.72, within(0.1));
        assertThat(eta.minutosEstimados()).isCloseTo(1.0, within(0.01));
    }

    @Test
    void laSegundaConsultaSeResuelveDesdeLaCacheSinVolverACalcular() {
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(ruta(null)));
        when(reporteGpsService.obtenerUltimos(1L, 2)).thenReturn(List.of());

        service.calcularEtaProximoParadero(1L);
        service.calcularEtaProximoParadero(1L);

        verify(reporteGpsService, times(1)).obtenerUltimos(1L, 2);
    }
}
