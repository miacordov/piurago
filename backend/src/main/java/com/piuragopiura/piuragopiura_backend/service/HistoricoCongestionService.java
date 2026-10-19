package com.piuragopiura.piuragopiura_backend.service;

import com.piuragopiura.piuragopiura_backend.model.HistoricoCongestion;

import java.util.List;

public interface HistoricoCongestionService {
    List<HistoricoCongestion> obtenerPorRuta(Long idRuta);
    HistoricoCongestion recalcularParaRuta(Long idRuta, String franjaHoraria, String diaSemana);
}