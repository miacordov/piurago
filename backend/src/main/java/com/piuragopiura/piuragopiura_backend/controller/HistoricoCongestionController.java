package com.piuragopiura.piuragopiura_backend.controller;

import com.piuragopiura.piuragopiura_backend.dto.HistoricoCongestionResponseDTO;
import com.piuragopiura.piuragopiura_backend.service.HistoricoCongestionService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/historico-congestion")
public class HistoricoCongestionController {

    private final HistoricoCongestionService historicoCongestionService;

    public HistoricoCongestionController(HistoricoCongestionService historicoCongestionService) {
        this.historicoCongestionService = historicoCongestionService;
    }

    @GetMapping("/ruta/{idRuta}")
    public List<HistoricoCongestionResponseDTO> obtenerPorRuta(@PathVariable Long idRuta) {
        return historicoCongestionService.obtenerPorRuta(idRuta).stream()
                .map(HistoricoCongestionResponseDTO::desde)
                .toList();
    }

    @PostMapping("/recalcular")
    public HistoricoCongestionResponseDTO recalcular(
            @RequestParam Long idRuta,
            @RequestParam String franjaHoraria,
            @RequestParam String diaSemana) {
        return HistoricoCongestionResponseDTO.desde(
                historicoCongestionService.recalcularParaRuta(idRuta, franjaHoraria, diaSemana));
    }
}