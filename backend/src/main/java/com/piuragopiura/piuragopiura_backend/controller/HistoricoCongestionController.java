package com.piuragopiura.piuragopiura_backend.controller;

import com.piuragopiura.piuragopiura_backend.dto.HistoricoCongestionResponseDTO;
import com.piuragopiura.piuragopiura_backend.dto.ResumenCongestionDTO;
import com.piuragopiura.piuragopiura_backend.service.ExportacionCongestionService;
import com.piuragopiura.piuragopiura_backend.service.HistoricoCongestionService;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/historico-congestion")
public class HistoricoCongestionController {

    private static final MediaType EXCEL =
            MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");

    private final HistoricoCongestionService historicoCongestionService;
    private final ExportacionCongestionService exportacionCongestionService;

    public HistoricoCongestionController(HistoricoCongestionService historicoCongestionService,
                                         ExportacionCongestionService exportacionCongestionService) {
        this.historicoCongestionService = historicoCongestionService;
        this.exportacionCongestionService = exportacionCongestionService;
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

    /** Congestión de toda la ciudad; sin parámetros usa la franja y el día de ahora. */
    @GetMapping("/resumen")
    public ResumenCongestionDTO resumen(
            @RequestParam(required = false) String franjaHoraria,
            @RequestParam(required = false) String diaSemana) {
        return historicoCongestionService.resumenCiudad(franjaHoraria, diaSemana);
    }

    @PostMapping("/recalcular-todas")
    public Map<String, Integer> recalcularTodas() {
        return Map.of("registrosGuardados", historicoCongestionService.recalcularTodas());
    }

    /** Descarga el histórico de congestión en Excel (Apache POI). */
    @GetMapping("/exportar")
    public ResponseEntity<byte[]> exportar() {
        String archivo = "congestion-piura-" + LocalDate.now() + ".xlsx";
        return ResponseEntity.ok()
                .contentType(EXCEL)
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.attachment().filename(archivo).build().toString())
                .body(exportacionCongestionService.exportarExcel());
    }
}
