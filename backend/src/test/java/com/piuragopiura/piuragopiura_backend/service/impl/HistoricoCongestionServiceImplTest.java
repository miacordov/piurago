package com.piuragopiura.piuragopiura_backend.service.impl;

import com.piuragopiura.piuragopiura_backend.dto.ResumenCongestionDTO;
import com.piuragopiura.piuragopiura_backend.model.HistoricoCongestion;
import com.piuragopiura.piuragopiura_backend.model.Paradero;
import com.piuragopiura.piuragopiura_backend.model.ReporteGps;
import com.piuragopiura.piuragopiura_backend.model.Ruta;
import com.piuragopiura.piuragopiura_backend.model.Usuario;
import com.piuragopiura.piuragopiura_backend.model.UsuarioAnonimo;
import com.piuragopiura.piuragopiura_backend.repository.HistoricoCongestionRepository;
import com.piuragopiura.piuragopiura_backend.repository.ParaderoRepository;
import com.piuragopiura.piuragopiura_backend.repository.ReporteGpsRepository;
import com.piuragopiura.piuragopiura_backend.repository.RutaRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Pageable;

import java.math.BigDecimal;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.within;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class HistoricoCongestionServiceImplTest {

    @Mock private HistoricoCongestionRepository historicoRepository;
    @Mock private ReporteGpsRepository reporteGpsRepository;
    @Mock private RutaRepository rutaRepository;
    @Mock private ParaderoRepository paraderoRepository;

    private HistoricoCongestionServiceImpl service;

    @BeforeEach
    void setUp() {
        service = new HistoricoCongestionServiceImpl(historicoRepository, reporteGpsRepository, rutaRepository,
                paraderoRepository);
    }

    // ---------- ayudas ----------

    /** Un lunes ya pasado (siempre dentro de la ventana de 28 días) a la hora indicada. */
    private LocalDateTime lunesAnterior(int hora, int minuto) {
        return LocalDate.now().with(TemporalAdjusters.previous(DayOfWeek.MONDAY)).atTime(hora, minuto);
    }

    private Usuario usuario(long id) {
        UsuarioAnonimo u = new UsuarioAnonimo();
        u.setIdUsuario(id);
        return u;
    }

    private ReporteGps reporte(Usuario usuario, double lat, LocalDateTime fechaHora) {
        ReporteGps r = new ReporteGps();
        r.setUsuario(usuario);
        r.setLatitud(BigDecimal.valueOf(lat));
        r.setLongitud(BigDecimal.valueOf(-80.0));
        r.setFechaHora(fechaHora);
        return r;
    }

    /** Tres reportes de un mismo usuario, un lunes a las 7:00, 7:01 y 7:02, avanzando deltaLat grados por minuto. */
    private ReporteGps[] viajeDeLunes(double deltaLat) {
        Usuario u = usuario(1L);
        return new ReporteGps[]{
                reporte(u, -5.0, lunesAnterior(7, 0)),
                reporte(u, -5.0 - deltaLat, lunesAnterior(7, 1)),
                reporte(u, -5.0 - 2 * deltaLat, lunesAnterior(7, 2))
        };
    }

    private void stubRuta() {
        Ruta ruta = new Ruta();
        ruta.setIdRuta(1L);
        when(rutaRepository.findById(1L)).thenReturn(Optional.of(ruta));
    }

    /** Recibe los reportes en orden cronológico y los entrega como la base de datos: del más nuevo al más viejo. */
    private void stubReportes(ReporteGps... enOrdenCronologico) {
        List<ReporteGps> masNuevoPrimero = new ArrayList<>(Arrays.asList(enOrdenCronologico));
        Collections.reverse(masNuevoPrimero);
        when(reporteGpsRepository.findByRuta_IdRutaAndFechaHoraAfterOrderByFechaHoraDesc(
                eq(1L), any(LocalDateTime.class), any(Pageable.class))).thenReturn(masNuevoPrimero);
    }

    private void stubHistorialVacioYGuardado(String franja, String dia) {
        when(historicoRepository.findByRuta_IdRutaAndFranjaHorariaAndDiaSemanaAndParaderoIsNull(1L, franja, dia))
                .thenReturn(Optional.empty());
        when(historicoRepository.save(any(HistoricoCongestion.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
    }

    // ---------- validaciones ----------

    @Test
    void rechazaUnaFranjaInvalidaAntesDeConsultarNada() {
        assertThatThrownBy(() -> service.recalcularParaRuta(1L, "TARDE", "LUN"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("franjaHoraria inválido");

        verifyNoInteractions(historicoRepository, reporteGpsRepository, rutaRepository);
    }

    @Test
    void rechazaUnDiaInvalidoAntesDeConsultarNada() {
        assertThatThrownBy(() -> service.recalcularParaRuta(1L, "MANANA_PICO", "LUNES"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("diaSemana inválido");

        verifyNoInteractions(historicoRepository, reporteGpsRepository, rutaRepository);
    }

    @Test
    void rechazaUnaRutaInexistente() {
        when(rutaRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.recalcularParaRuta(99L, "MANANA_PICO", "LUN"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("Ruta no encontrada");

        verifyNoInteractions(reporteGpsRepository);
    }

    @Test
    void sinReportesNoHayTramosValidos() {
        stubRuta();
        stubReportes();

        assertThatThrownBy(() -> service.recalcularParaRuta(1L, "MANANA_PICO", "LUN"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("No hay reportes GPS válidos");
    }

    // ---------- cálculo ----------

    @ParameterizedTest
    @CsvSource({
            "0.0036,BAJA,24.02,0.10,0",
            "0.0022,MEDIA,14.68,1.69,0",
            "0.0009,ALTA,6.00,7.59,2"
    })
    void clasificaLaCongestionSegunLaVelocidadPromedio(
            double deltaLat, String nivel, double velocidad, double demora, int tramosCriticos) {
        stubRuta();
        stubReportes(viajeDeLunes(deltaLat));
        stubHistorialVacioYGuardado("MANANA_PICO", "LUN");

        HistoricoCongestion resultado = service.recalcularParaRuta(1L, "MANANA_PICO", "LUN");

        assertThat(resultado.getFranjaHoraria()).isEqualTo("MANANA_PICO");
        assertThat(resultado.getDiaSemana()).isEqualTo("LUN");
        assertThat(resultado.getNivelCongestion()).isEqualTo(nivel);
        assertThat(resultado.getVelocidadPromedio().doubleValue()).isCloseTo(velocidad, within(0.05));
        assertThat(resultado.getDemoraPromedio().doubleValue()).isCloseTo(demora, within(0.05));
        assertThat(resultado.getCantidadPuntosCriticos()).isEqualTo((short) tramosCriticos);
        assertThat(resultado.getParadero()).isNull();
    }

    @ParameterizedTest
    @CsvSource({"NOCHE,LUN", "MANANA_PICO,MAR"})
    void soloCuentaLosTramosDeLaFranjaYElDiaPedidos(String franja, String dia) {
        // Los reportes son de un lunes por la mañana: otra franja u otro día no deben contar.
        stubRuta();
        stubReportes(viajeDeLunes(0.0036));

        assertThatThrownBy(() -> service.recalcularParaRuta(1L, franja, dia))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("No hay reportes GPS válidos");
    }

    @Test
    void descartaTramosSeparadosPorMasDeDiezMinutos() {
        Usuario u = usuario(1L);
        stubRuta();
        stubReportes(
                reporte(u, -5.0, lunesAnterior(7, 0)),
                reporte(u, -5.0036, lunesAnterior(7, 11)));

        assertThatThrownBy(() -> service.recalcularParaRuta(1L, "MANANA_PICO", "LUN"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("No hay reportes GPS válidos");
    }

    @Test
    void descartaVelocidadesImposiblesComoRuidoDeGps() {
        Usuario u = usuario(1L);
        stubRuta();
        // 0.02° en un minuto ≈ 133 km/h, por encima del límite de 100 km/h.
        stubReportes(
                reporte(u, -5.0, lunesAnterior(7, 0)),
                reporte(u, -5.02, lunesAnterior(7, 1)));

        assertThatThrownBy(() -> service.recalcularParaRuta(1L, "MANANA_PICO", "LUN"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("No hay reportes GPS válidos");
    }

    @Test
    void noMezclaReportesDeUsuariosDistintos() {
        stubRuta();
        // Dos usuarios con un solo reporte cada uno: ninguno forma un tramo por sí mismo.
        stubReportes(
                reporte(usuario(1L), -5.0, lunesAnterior(7, 0)),
                reporte(usuario(2L), -5.0036, lunesAnterior(7, 1)));

        assertThatThrownBy(() -> service.recalcularParaRuta(1L, "MANANA_PICO", "LUN"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("No hay reportes GPS válidos");
    }

    @Test
    void siYaExisteElRegistroLoActualizaEnLugarDeDuplicarlo() {
        HistoricoCongestion existente = new HistoricoCongestion();
        existente.setIdHistorico(10L);

        stubRuta();
        stubReportes(viajeDeLunes(0.0036));
        when(historicoRepository.findByRuta_IdRutaAndFranjaHorariaAndDiaSemanaAndParaderoIsNull(1L, "MANANA_PICO", "LUN"))
                .thenReturn(Optional.of(existente));
        when(historicoRepository.save(any(HistoricoCongestion.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        HistoricoCongestion resultado = service.recalcularParaRuta(1L, "MANANA_PICO", "LUN");

        ArgumentCaptor<HistoricoCongestion> captor = ArgumentCaptor.forClass(HistoricoCongestion.class);
        verify(historicoRepository).save(captor.capture());
        assertThat(captor.getValue()).isSameAs(existente);
        assertThat(resultado.getIdHistorico()).isEqualTo(10L);
    }

    @Test
    void aceptaFranjaYDiaEnMinusculas() {
        stubRuta();
        stubReportes(viajeDeLunes(0.0036));
        stubHistorialVacioYGuardado("MANANA_PICO", "LUN");

        HistoricoCongestion resultado = service.recalcularParaRuta(1L, "manana_pico", "lun");

        assertThat(resultado.getFranjaHoraria()).isEqualTo("MANANA_PICO");
        assertThat(resultado.getDiaSemana()).isEqualTo("LUN");
    }

    // ---------- recálculo de todas las rutas, con tramos entre paraderos ----------

    private Ruta rutaActiva(long id) {
        Ruta ruta = new Ruta();
        ruta.setIdRuta(id);
        ruta.setActiva(true);
        return ruta;
    }

    private Paradero paradero(long id, double lat) {
        Paradero p = new Paradero();
        p.setIdParadero(id);
        p.setNombre("Paradero " + id);
        p.setLatitud(BigDecimal.valueOf(lat));
        p.setLongitud(BigDecimal.valueOf(-80.0));
        p.setOrdenSecuencial((short) id);
        return p;
    }

    /** Guarda devolviendo lo mismo y sin registros previos (ni de ruta ni de tramo). */
    private void stubGuardadoSinPrevios() {
        when(historicoRepository.findByRuta_IdRutaAndFranjaHorariaAndDiaSemanaAndParaderoIsNull(
                anyLong(), anyString(), anyString())).thenReturn(Optional.empty());
        lenient().when(historicoRepository.findByRuta_IdRutaAndParadero_IdParaderoAndFranjaHorariaAndDiaSemana(
                anyLong(), anyLong(), anyString(), anyString())).thenReturn(Optional.empty());
        when(historicoRepository.save(any(HistoricoCongestion.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
    }

    @Test
    void recalcularTodasGuardaLaRutaYCadaTramoEntreParaderos() {
        Ruta ruta = rutaActiva(1L);
        when(rutaRepository.findByActivaTrue()).thenReturn(List.of(ruta));
        // 0.005° por minuto (≈33.4 km/h), entre el paradero 1 (-5.000) y el 2 (-5.010).
        stubReportes(viajeDeLunes(0.005));
        when(paraderoRepository.findByRuta_IdRutaOrderByOrdenSecuencialAsc(1L))
                .thenReturn(List.of(paradero(1L, -5.000), paradero(2L, -5.010), paradero(3L, -5.020)));
        stubGuardadoSinPrevios();

        int guardados = service.recalcularTodas();

        ArgumentCaptor<HistoricoCongestion> captor = ArgumentCaptor.forClass(HistoricoCongestion.class);
        verify(historicoRepository, org.mockito.Mockito.times(2)).save(captor.capture());
        HistoricoCongestion deRuta = captor.getAllValues().stream()
                .filter(h -> h.getParadero() == null).findFirst().orElseThrow();
        HistoricoCongestion deTramo = captor.getAllValues().stream()
                .filter(h -> h.getParadero() != null).findFirst().orElseThrow();

        assertThat(guardados).isEqualTo(2);
        assertThat(deRuta.getFranjaHoraria()).isEqualTo("MANANA_PICO");
        assertThat(deRuta.getDiaSemana()).isEqualTo("LUN");
        assertThat(deRuta.getVelocidadPromedio().doubleValue()).isCloseTo(33.36, within(0.05));
        // El tramo empieza en el paradero 1 (va del 1 al 2).
        assertThat(deTramo.getParadero().getIdParadero()).isEqualTo(1L);
        assertThat(deTramo.getVelocidadPromedio().doubleValue()).isCloseTo(33.36, within(0.05));
        assertThat(deTramo.getNivelCongestion()).isEqualTo("BAJA");
    }

    @Test
    void recalcularTodasOmiteLasRutasSinReportesSinFallar() {
        when(rutaRepository.findByActivaTrue()).thenReturn(List.of(rutaActiva(1L)));
        when(reporteGpsRepository.findByRuta_IdRutaAndFechaHoraAfterOrderByFechaHoraDesc(
                eq(1L), any(LocalDateTime.class), any(Pageable.class))).thenReturn(List.of());

        assertThat(service.recalcularTodas()).isZero();

        verify(historicoRepository, never()).save(any(HistoricoCongestion.class));
    }

    @Test
    void unTramoLejosDeLosParaderosCuentaParaLaRutaPeroNoComoTramo() {
        when(rutaRepository.findByActivaTrue()).thenReturn(List.of(rutaActiva(1L)));
        stubReportes(viajeDeLunes(0.005));
        // Paraderos a más de 1 km al este del recorrido de los reportes.
        Paradero lejos1 = paradero(1L, -5.000);
        lejos1.setLongitud(BigDecimal.valueOf(-79.99));
        Paradero lejos2 = paradero(2L, -5.010);
        lejos2.setLongitud(BigDecimal.valueOf(-79.99));
        when(paraderoRepository.findByRuta_IdRutaOrderByOrdenSecuencialAsc(1L)).thenReturn(List.of(lejos1, lejos2));
        stubGuardadoSinPrevios();

        assertThat(service.recalcularTodas()).isEqualTo(1);
        ArgumentCaptor<HistoricoCongestion> captor = ArgumentCaptor.forClass(HistoricoCongestion.class);
        verify(historicoRepository).save(captor.capture());
        assertThat(captor.getValue().getParadero()).isNull();
    }

    @Test
    void elTramoYaCalculadoSeActualizaEnLugarDeDuplicarse() {
        when(rutaRepository.findByActivaTrue()).thenReturn(List.of(rutaActiva(1L)));
        stubReportes(viajeDeLunes(0.005));
        Paradero p1 = paradero(1L, -5.000);
        when(paraderoRepository.findByRuta_IdRutaOrderByOrdenSecuencialAsc(1L))
                .thenReturn(List.of(p1, paradero(2L, -5.010)));
        HistoricoCongestion existente = new HistoricoCongestion();
        existente.setIdHistorico(77L);
        when(historicoRepository.findByRuta_IdRutaAndFranjaHorariaAndDiaSemanaAndParaderoIsNull(
                anyLong(), anyString(), anyString())).thenReturn(Optional.empty());
        when(historicoRepository.findByRuta_IdRutaAndParadero_IdParaderoAndFranjaHorariaAndDiaSemana(
                1L, 1L, "MANANA_PICO", "LUN")).thenReturn(Optional.of(existente));
        when(historicoRepository.save(any(HistoricoCongestion.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        service.recalcularTodas();

        ArgumentCaptor<HistoricoCongestion> captor = ArgumentCaptor.forClass(HistoricoCongestion.class);
        verify(historicoRepository, org.mockito.Mockito.times(2)).save(captor.capture());
        assertThat(captor.getAllValues()).anyMatch(h -> Long.valueOf(77L).equals(h.getIdHistorico()));
    }

    // ---------- resumen de la ciudad ----------

    private Ruta rutaConNombre(long id, String codigo, String nombre) {
        Ruta ruta = rutaActiva(id);
        ruta.setCodigo(codigo);
        ruta.setNombre(nombre);
        return ruta;
    }

    private HistoricoCongestion historico(Ruta ruta, Paradero paradero, String franja,
                                          double velocidad, double demora, int puntosCriticos) {
        HistoricoCongestion h = new HistoricoCongestion();
        h.setRuta(ruta);
        h.setParadero(paradero);
        h.setFranjaHoraria(franja);
        h.setDiaSemana("LUN");
        h.setVelocidadPromedio(BigDecimal.valueOf(velocidad));
        h.setDemoraPromedio(BigDecimal.valueOf(demora));
        h.setNivelCongestion(velocidad < 10 ? "ALTA" : velocidad < 18 ? "MEDIA" : "BAJA");
        h.setCantidadPuntosCriticos((short) puntosCriticos);
        return h;
    }

    @Test
    void elResumenPromediaLasRutasDeLaFranjaYArmaLasCuatroFranjasDelDia() {
        Ruta a = rutaConNombre(1L, "RD-10", "Ruta A");
        Ruta b = rutaConNombre(2L, "RD-12", "Ruta B");
        when(historicoRepository.findByDiaSemana("LUN")).thenReturn(List.of(
                historico(a, null, "MANANA_PICO", 8.0, 5.1, 3),
                historico(b, null, "MANANA_PICO", 14.0, 1.9, 1),
                historico(a, null, "NOCHE", 30.0, 0.0, 0)));

        ResumenCongestionDTO resumen = service.resumenCiudad("manana_pico", "lun");

        assertThat(resumen.franjaHoraria()).isEqualTo("MANANA_PICO");
        assertThat(resumen.diaSemana()).isEqualTo("LUN");
        assertThat(resumen.rutasConDatos()).isEqualTo(2);
        assertThat(resumen.velocidadPromedio().doubleValue()).isEqualTo(11.0);
        assertThat(resumen.demoraPromedio().doubleValue()).isEqualTo(3.5);
        assertThat(resumen.nivelGeneral()).isEqualTo("MEDIA");
        assertThat(resumen.puntosCriticos()).isEqualTo(4);
        assertThat(resumen.porFranja()).extracting(ResumenCongestionDTO.Franja::franjaHoraria)
                .containsExactly("MANANA_PICO", "MEDIO_DIA", "TARDE_PICO", "NOCHE");
        assertThat(resumen.porFranja()).extracting(ResumenCongestionDTO.Franja::nivel)
                .containsExactly("MEDIA", null, null, "BAJA");
    }

    @Test
    void losTramosCriticosVanDelMasLentoAlMasRapidoConElNombreDeSusParaderos() {
        Ruta a = rutaConNombre(1L, "RD-10", "Ruta A");
        Paradero p1 = paradero(1L, -5.000);
        Paradero p2 = paradero(2L, -5.010);
        Paradero p3 = paradero(3L, -5.020);
        p1.setRuta(a);
        p2.setRuta(a);
        p3.setRuta(a);
        when(historicoRepository.findByDiaSemana("LUN")).thenReturn(List.of(
                historico(a, null, "MANANA_PICO", 12.0, 2.6, 2),
                historico(a, p1, "MANANA_PICO", 15.0, 1.6, 0),
                historico(a, p2, "MANANA_PICO", 6.0, 7.6, 2),
                historico(a, p1, "NOCHE", 5.0, 9.6, 1),          // otra franja: no cuenta
                historico(a, p3, "MANANA_PICO", 30.0, 0.0, 0))); // fluido: no es crítico
        when(paraderoRepository.findByRuta_IdRutaOrderByOrdenSecuencialAsc(1L)).thenReturn(List.of(p1, p2, p3));

        ResumenCongestionDTO resumen = service.resumenCiudad("MANANA_PICO", "LUN");

        assertThat(resumen.tramosCriticos()).hasSize(2);
        ResumenCongestionDTO.Tramo masLento = resumen.tramosCriticos().get(0);
        assertThat(masLento.codigoRuta()).isEqualTo("RD-10");
        assertThat(masLento.nombreRuta()).isEqualTo("Ruta A");
        assertThat(masLento.desde()).isEqualTo("Paradero 2");
        assertThat(masLento.hasta()).isEqualTo("Paradero 3");
        assertThat(masLento.nivel()).isEqualTo("ALTA");
        // 7.6 min/km de demora en un tramo de ≈1.11 km.
        assertThat(masLento.demoraMinutos()).isEqualTo(8);
        assertThat(resumen.tramosCriticos().get(1).desde()).isEqualTo("Paradero 1");
    }

    @Test
    void sinDatosElResumenVieneVacioYSinNivel() {
        when(historicoRepository.findByDiaSemana("DOM")).thenReturn(List.of());

        ResumenCongestionDTO resumen = service.resumenCiudad("NOCHE", "DOM");

        assertThat(resumen.nivelGeneral()).isNull();
        assertThat(resumen.velocidadPromedio()).isNull();
        assertThat(resumen.rutasConDatos()).isZero();
        assertThat(resumen.tramosCriticos()).isEmpty();
        assertThat(resumen.porFranja()).hasSize(4).allMatch(f -> f.nivel() == null);
    }

    @Test
    void sinFranjaNiDiaElResumenUsaLaHoraActual() {
        LocalDateTime ahora = LocalDateTime.now();
        when(historicoRepository.findByDiaSemana(FranjaHoraria.diaDe(ahora))).thenReturn(List.of());

        ResumenCongestionDTO resumen = service.resumenCiudad(null, null);

        assertThat(resumen.diaSemana()).isEqualTo(FranjaHoraria.diaDe(ahora));
        assertThat(resumen.franjaHoraria()).isEqualTo(FranjaHoraria.franjaDe(ahora));
    }

    @Test
    void elResumenRechazaUnaFranjaInvalida() {
        assertThatThrownBy(() -> service.resumenCiudad("TARDE", "LUN"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("franjaHoraria inválido");
    }
}
