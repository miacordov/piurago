package com.piuragopiura.piuragopiura_backend.service.impl;

import com.piuragopiura.piuragopiura_backend.dto.PosicionColaboradorDTO;
import com.piuragopiura.piuragopiura_backend.dto.PosicionesRutaResponseDTO;
import com.piuragopiura.piuragopiura_backend.exception.RecursoNoEncontradoException;
import com.piuragopiura.piuragopiura_backend.model.ReporteGps;
import com.piuragopiura.piuragopiura_backend.model.Ruta;
import com.piuragopiura.piuragopiura_backend.model.Usuario;
import com.piuragopiura.piuragopiura_backend.model.UsuarioAnonimo;
import com.piuragopiura.piuragopiura_backend.repository.ReporteGpsRepository;
import com.piuragopiura.piuragopiura_backend.repository.RutaRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Arrays;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PosicionesServiceImplTest {

    private static final ZoneId ZONA_LIMA = ZoneId.of("America/Lima");
    /** 4 de noviembre de 2026, 08:00 en Piura. */
    private static final LocalDateTime AHORA = LocalDateTime.of(2026, 11, 4, 8, 0);
    private static final Clock RELOJ = Clock.fixed(AHORA.atZone(ZONA_LIMA).toInstant(), ZONA_LIMA);

    @Mock private ReporteGpsRepository reporteGpsRepository;
    @Mock private RutaRepository rutaRepository;

    private PosicionesServiceImpl service;

    @BeforeEach
    void setUp() {
        service = new PosicionesServiceImpl(reporteGpsRepository, rutaRepository, 2, RELOJ);
    }

    private static ReporteGps reporte(long idUsuario, String lat, String lng, LocalDateTime hora) {
        Usuario usuario = new UsuarioAnonimo();
        usuario.setIdUsuario(idUsuario);
        Ruta ruta = new Ruta();
        ruta.setIdRuta(7L);
        ReporteGps r = new ReporteGps();
        r.setUsuario(usuario);
        r.setRuta(ruta);
        r.setLatitud(new BigDecimal(lat));
        r.setLongitud(new BigDecimal(lng));
        r.setFechaHora(hora);
        return r;
    }

    @Test
    void unaRutaInexistenteLanzaRecursoNoEncontradoSinConsultarReportes() {
        when(rutaRepository.existsById(99L)).thenReturn(false);

        assertThatThrownBy(() -> service.obtenerPosiciones(99L))
                .isInstanceOf(RecursoNoEncontradoException.class)
                .hasMessageContaining("Ruta no encontrada: 99");

        verify(reporteGpsRepository, never()).findUltimaPorColaborador(anyLong(), any());
    }

    @Test
    void consultaLaVentanaDeDosMinutosPorDefecto() {
        when(rutaRepository.existsById(7L)).thenReturn(true);
        when(reporteGpsRepository.findUltimaPorColaborador(7L, AHORA.minusMinutes(2)))
                .thenReturn(List.of());

        PosicionesRutaResponseDTO respuesta = service.obtenerPosiciones(7L);

        assertThat(respuesta.idRuta()).isEqualTo(7L);
        assertThat(respuesta.ventanaMinutos()).isEqualTo(2);
        assertThat(respuesta.colaboradoresActivos()).isZero();
        assertThat(respuesta.posiciones()).isEmpty();
    }

    @Test
    void laVentanaSeConfigura() {
        service = new PosicionesServiceImpl(reporteGpsRepository, rutaRepository, 5, RELOJ);
        when(rutaRepository.existsById(7L)).thenReturn(true);
        when(reporteGpsRepository.findUltimaPorColaborador(7L, AHORA.minusMinutes(5)))
                .thenReturn(List.of());

        assertThat(service.obtenerPosiciones(7L).ventanaMinutos()).isEqualTo(5);
    }

    @Test
    void devuelveUnaPosicionPorColaboradorDeLaMasNuevaALaMasVieja() {
        when(rutaRepository.existsById(7L)).thenReturn(true);
        when(reporteGpsRepository.findUltimaPorColaborador(7L, AHORA.minusMinutes(2))).thenReturn(List.of(
                reporte(1L, "-5.194500", "-80.632800", AHORA.minusSeconds(90)),
                reporte(2L, "-5.190000", "-80.630000", AHORA.minusSeconds(10)),
                reporte(3L, "-5.180000", "-80.640000", AHORA.minusSeconds(45))));

        PosicionesRutaResponseDTO respuesta = service.obtenerPosiciones(7L);

        assertThat(respuesta.colaboradoresActivos()).isEqualTo(3);
        assertThat(respuesta.posiciones()).extracting(PosicionColaboradorDTO::fechaHora).containsExactly(
                AHORA.minusSeconds(10), AHORA.minusSeconds(45), AHORA.minusSeconds(90));
        PosicionColaboradorDTO primera = respuesta.posiciones().get(0);
        assertThat(primera.latitud()).isEqualByComparingTo("-5.19");
        assertThat(primera.longitud()).isEqualByComparingTo("-80.63");
    }

    @Test
    void siUnColaboradorTieneDosReportesALaMismaHoraCuentaUnaSolaVez() {
        when(rutaRepository.existsById(7L)).thenReturn(true);
        when(reporteGpsRepository.findUltimaPorColaborador(7L, AHORA.minusMinutes(2))).thenReturn(List.of(
                reporte(1L, "-5.194500", "-80.632800", AHORA.minusSeconds(30)),
                reporte(1L, "-5.194600", "-80.632900", AHORA.minusSeconds(30)),
                reporte(2L, "-5.190000", "-80.630000", AHORA.minusSeconds(20))));

        PosicionesRutaResponseDTO respuesta = service.obtenerPosiciones(7L);

        assertThat(respuesta.colaboradoresActivos()).isEqualTo(2);
        assertThat(respuesta.posiciones()).hasSize(2);
    }

    @Test
    void laPosicionNoTraeDatosQueIdentifiquenAlUsuario() {
        assertThat(Arrays.stream(PosicionColaboradorDTO.class.getRecordComponents())
                .map(c -> c.getName()))
                .containsExactly("latitud", "longitud", "fechaHora");
        assertThat(Arrays.stream(PosicionesRutaResponseDTO.class.getRecordComponents())
                .map(c -> c.getName()))
                .containsExactly("idRuta", "ventanaMinutos", "colaboradoresActivos", "posiciones");
    }

    @Test
    void rechazaUnaVentanaFueraDeRango() {
        assertThatThrownBy(() -> new PosicionesServiceImpl(reporteGpsRepository, rutaRepository, 0, RELOJ))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("ventana");
        assertThatThrownBy(() -> new PosicionesServiceImpl(reporteGpsRepository, rutaRepository, 61, RELOJ))
                .isInstanceOf(IllegalArgumentException.class);
    }
}
