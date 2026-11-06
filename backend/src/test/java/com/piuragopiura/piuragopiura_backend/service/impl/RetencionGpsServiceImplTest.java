package com.piuragopiura.piuragopiura_backend.service.impl;

import com.piuragopiura.piuragopiura_backend.repository.ReporteGpsRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Clock;
import java.time.LocalDateTime;
import java.time.ZoneId;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class RetencionGpsServiceImplTest {

    private static final ZoneId ZONA_LIMA = ZoneId.of("America/Lima");
    private static final LocalDateTime AHORA = LocalDateTime.of(2026, 11, 4, 3, 30);
    private static final Clock RELOJ = Clock.fixed(AHORA.atZone(ZONA_LIMA).toInstant(), ZONA_LIMA);

    @Mock private ReporteGpsRepository reporteGpsRepository;

    @Test
    void borraLosReportesDeMasDeTreintaDiasPorDefecto() {
        RetencionGpsServiceImpl service = new RetencionGpsServiceImpl(reporteGpsRepository, 30, RELOJ);
        when(reporteGpsRepository.borrarAnterioresA(AHORA.minusDays(30))).thenReturn(12);

        int borrados = service.borrarReportesAntiguos();

        assertThat(borrados).isEqualTo(12);
        verify(reporteGpsRepository).borrarAnterioresA(AHORA.minusDays(30));
    }

    @Test
    void elPlazoSeConfigura() {
        RetencionGpsServiceImpl service = new RetencionGpsServiceImpl(reporteGpsRepository, 45, RELOJ);
        when(reporteGpsRepository.borrarAnterioresA(AHORA.minusDays(45))).thenReturn(0);

        assertThat(service.borrarReportesAntiguos()).isZero();
        assertThat(service.getDiasRetencion()).isEqualTo(45);
    }

    @Test
    void noAceptaUnPlazoMenorQueLaVentanaDeCongestion() {
        // La congestión analiza 28 días: retener menos dejaría el histórico sin datos.
        assertThatThrownBy(() -> new RetencionGpsServiceImpl(reporteGpsRepository, 27, RELOJ))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("28");
    }

    @Test
    void aceptaExactamenteLaVentanaDeCongestion() {
        RetencionGpsServiceImpl service = new RetencionGpsServiceImpl(reporteGpsRepository, 28, RELOJ);
        when(reporteGpsRepository.borrarAnterioresA(AHORA.minusDays(28))).thenReturn(3);

        assertThat(service.borrarReportesAntiguos()).isEqualTo(3);
    }
}
