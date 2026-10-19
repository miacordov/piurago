package com.piuragopiura.piuragopiura_backend.controller;

import com.piuragopiura.piuragopiura_backend.dto.EtaResponseDTO;
import com.piuragopiura.piuragopiura_backend.dto.ReporteGpsRequestDTO;
import com.piuragopiura.piuragopiura_backend.dto.ReporteGpsResponseDTO;
import com.piuragopiura.piuragopiura_backend.security.UsuarioAutenticado;
import com.piuragopiura.piuragopiura_backend.service.EtaService;
import com.piuragopiura.piuragopiura_backend.service.ReporteGpsService;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/reportes-gps")
public class ReporteGpsController {

    private final ReporteGpsService reporteGpsService;
    private final EtaService etaService;

    public ReporteGpsController(ReporteGpsService reporteGpsService, EtaService etaService) {
        this.reporteGpsService = reporteGpsService;
        this.etaService = etaService;
    }

    @PostMapping
    public ReporteGpsResponseDTO registrar(@AuthenticationPrincipal UsuarioAutenticado usuario,
                                           @Valid @RequestBody ReporteGpsRequestDTO request) {
        return ReporteGpsResponseDTO.desde(reporteGpsService.registrarReporte(
                usuario.getIdUsuario(), request.idRuta(),
                request.latitud(), request.longitud()));
    }

    @GetMapping("/eta/{idRuta}")
    public EtaResponseDTO obtenerEta(@PathVariable Long idRuta) {
        return etaService.calcularEtaProximoParadero(idRuta);
    }
}