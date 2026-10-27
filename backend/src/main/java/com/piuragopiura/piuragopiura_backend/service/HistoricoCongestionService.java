package com.piuragopiura.piuragopiura_backend.service;

import com.piuragopiura.piuragopiura_backend.dto.ResumenCongestionDTO;
import com.piuragopiura.piuragopiura_backend.model.HistoricoCongestion;

import java.util.List;

public interface HistoricoCongestionService {
    List<HistoricoCongestion> obtenerPorRuta(Long idRuta);
    HistoricoCongestion recalcularParaRuta(Long idRuta, String franjaHoraria, String diaSemana);

    /** Recalcula todas las rutas activas, en todas las franjas y días, por ruta y por tramo. Devuelve cuántos registros guardó. */
    int recalcularTodas();

    /** Resumen de la ciudad; si franja o día vienen vacíos, usa los de ahora. */
    ResumenCongestionDTO resumenCiudad(String franjaHoraria, String diaSemana);
}
