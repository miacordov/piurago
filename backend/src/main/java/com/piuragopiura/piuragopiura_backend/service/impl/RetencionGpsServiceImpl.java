package com.piuragopiura.piuragopiura_backend.service.impl;

import com.piuragopiura.piuragopiura_backend.repository.ReporteGpsRepository;
import com.piuragopiura.piuragopiura_backend.service.RetencionGpsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;

/**
 * La ubicación exacta de un pasajero se guarda solo el tiempo que hace falta (RNF-08).
 * El plazo no puede ser menor que la ventana de la congestión (28 días): si lo fuera,
 * el histórico de "horas calientes" se calcularía con datos incompletos. Ver
 * docs/retencion-reportes-gps.md.
 */
@Service
public class RetencionGpsServiceImpl implements RetencionGpsService {

    private final ReporteGpsRepository reporteGpsRepository;
    private final int diasRetencion;
    private final Clock reloj;

    @Autowired
    public RetencionGpsServiceImpl(ReporteGpsRepository reporteGpsRepository,
                                   @Value("${piurago.gps.retencion-dias:30}") int diasRetencion) {
        // Los reportes se guardan con la hora local del servidor (LocalDateTime.now()).
        this(reporteGpsRepository, diasRetencion, Clock.systemDefaultZone());
    }

    RetencionGpsServiceImpl(ReporteGpsRepository reporteGpsRepository, int diasRetencion, Clock reloj) {
        if (diasRetencion < HistoricoCongestionServiceImpl.VENTANA_DIAS) {
            throw new IllegalArgumentException("piurago.gps.retencion-dias debe ser de al menos "
                    + HistoricoCongestionServiceImpl.VENTANA_DIAS
                    + " días (la ventana de la congestión): " + diasRetencion);
        }
        this.reporteGpsRepository = reporteGpsRepository;
        this.diasRetencion = diasRetencion;
        this.reloj = reloj;
    }

    public int getDiasRetencion() {
        return diasRetencion;
    }

    @Override
    @Transactional
    public int borrarReportesAntiguos() {
        LocalDateTime limite = LocalDateTime.now(reloj).minusDays(diasRetencion);
        return reporteGpsRepository.borrarAnterioresA(limite);
    }
}
