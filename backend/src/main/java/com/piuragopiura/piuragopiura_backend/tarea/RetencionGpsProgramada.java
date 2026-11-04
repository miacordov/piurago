package com.piuragopiura.piuragopiura_backend.tarea;

import com.piuragopiura.piuragopiura_backend.service.RetencionGpsService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Borra todos los días, a las 03:30 de Lima (poca actividad), los reportes GPS que
 * superan el plazo de retención (piurago.gps.retencion-dias, 30 por defecto).
 * La hora se cambia con piurago.gps.retencion-cron y la tarea se apaga con
 * piurago.gps.retencion-automatica=false.
 */
@Component
@EnableScheduling
@ConditionalOnProperty(name = "piurago.gps.retencion-automatica", havingValue = "true", matchIfMissing = true)
public class RetencionGpsProgramada {

    private static final Logger log = LoggerFactory.getLogger(RetencionGpsProgramada.class);

    private final RetencionGpsService retencionGpsService;

    public RetencionGpsProgramada(RetencionGpsService retencionGpsService) {
        this.retencionGpsService = retencionGpsService;
    }

    @Scheduled(cron = "${piurago.gps.retencion-cron:0 30 3 * * *}", zone = "America/Lima")
    public void borrarReportesAntiguos() {
        try {
            int borrados = retencionGpsService.borrarReportesAntiguos();
            log.info("Retención GPS: {} reportes antiguos borrados", borrados);
        } catch (RuntimeException e) {
            // Un fallo (por ejemplo, la base caída) no debe detener las siguientes ejecuciones.
            log.warn("No se pudieron borrar los reportes GPS antiguos: {}", e.getMessage());
        }
    }
}
