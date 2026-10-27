package com.piuragopiura.piuragopiura_backend.tarea;

import com.piuragopiura.piuragopiura_backend.service.HistoricoCongestionService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Recalcula la congestión de todas las rutas cada cierto tiempo (por defecto, cada hora),
 * para que el histórico se arme solo con los reportes GPS de los pasajeros.
 * Se apaga con piurago.congestion.recalculo-automatico=false.
 */
@Component
@EnableScheduling
@ConditionalOnProperty(name = "piurago.congestion.recalculo-automatico", havingValue = "true", matchIfMissing = true)
public class RecalculoCongestionProgramado {

    private static final Logger log = LoggerFactory.getLogger(RecalculoCongestionProgramado.class);

    private final HistoricoCongestionService historicoCongestionService;

    public RecalculoCongestionProgramado(HistoricoCongestionService historicoCongestionService) {
        this.historicoCongestionService = historicoCongestionService;
    }

    @Scheduled(initialDelayString = "${piurago.congestion.recalculo-inicial-ms:120000}",
               fixedDelayString = "${piurago.congestion.recalculo-ms:3600000}")
    public void recalcular() {
        try {
            int guardados = historicoCongestionService.recalcularTodas();
            log.info("Congestión recalculada: {} registros guardados", guardados);
        } catch (RuntimeException e) {
            // Un fallo (por ejemplo, la base caída) no debe detener las siguientes ejecuciones.
            log.warn("No se pudo recalcular la congestión: {}", e.getMessage());
        }
    }
}
