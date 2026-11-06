package com.piuragopiura.piuragopiura_backend.tarea;

import com.piuragopiura.piuragopiura_backend.service.RetencionGpsService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.scheduling.annotation.Scheduled;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class RetencionGpsProgramadaTest {

    @Mock private RetencionGpsService retencionGpsService;

    @Test
    void llamaAlServicioDeRetencion() {
        when(retencionGpsService.borrarReportesAntiguos()).thenReturn(5);

        new RetencionGpsProgramada(retencionGpsService).borrarReportesAntiguos();

        verify(retencionGpsService).borrarReportesAntiguos();
    }

    @Test
    void unFalloNoDetieneLasSiguientesEjecuciones() {
        when(retencionGpsService.borrarReportesAntiguos()).thenThrow(new IllegalStateException("base caída"));

        assertThatCode(() -> new RetencionGpsProgramada(retencionGpsService).borrarReportesAntiguos())
                .doesNotThrowAnyException();
    }

    @Test
    void correTodosLosDiasEnLaMadrugadaDeLima() throws NoSuchMethodException {
        Scheduled programacion = RetencionGpsProgramada.class
                .getMethod("borrarReportesAntiguos")
                .getAnnotation(Scheduled.class);

        assertThat(programacion.cron()).isEqualTo("${piurago.gps.retencion-cron:0 30 3 * * *}");
        assertThat(programacion.zone()).isEqualTo("America/Lima");
    }
}
