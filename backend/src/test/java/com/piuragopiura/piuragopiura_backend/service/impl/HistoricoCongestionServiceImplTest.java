package com.piuragopiura.piuragopiura_backend.service.impl;

import com.piuragopiura.piuragopiura_backend.model.HistoricoCongestion;
import com.piuragopiura.piuragopiura_backend.model.ReporteGps;
import com.piuragopiura.piuragopiura_backend.model.Ruta;
import com.piuragopiura.piuragopiura_backend.model.Usuario;
import com.piuragopiura.piuragopiura_backend.model.UsuarioAnonimo;
import com.piuragopiura.piuragopiura_backend.repository.HistoricoCongestionRepository;
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
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class HistoricoCongestionServiceImplTest {

    @Mock private HistoricoCongestionRepository historicoRepository;
    @Mock private ReporteGpsRepository reporteGpsRepository;
    @Mock private RutaRepository rutaRepository;

    private HistoricoCongestionServiceImpl service;

    @BeforeEach
    void setUp() {
        service = new HistoricoCongestionServiceImpl(historicoRepository, reporteGpsRepository, rutaRepository);
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
}