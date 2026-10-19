package com.piuragopiura.piuragopiura_backend.controller;

import com.piuragopiura.piuragopiura_backend.dto.ParaderoResponseDTO;
import com.piuragopiura.piuragopiura_backend.dto.RutaResponseDTO;
import com.piuragopiura.piuragopiura_backend.service.RutaService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/rutas")
public class RutaController {

    private final RutaService rutaService;

    public RutaController(RutaService rutaService) {
        this.rutaService = rutaService;
    }

    @GetMapping
    public List<RutaResponseDTO> listarActivas() {
        return rutaService.listarActivas().stream()
                .map(RutaResponseDTO::desde)
                .toList();
    }

    @GetMapping("/{id}")
    public RutaResponseDTO obtenerPorId(@PathVariable Long id) {
        return RutaResponseDTO.desde(rutaService.obtenerPorId(id));
    }

    @GetMapping("/{id}/paraderos")
    public List<ParaderoResponseDTO> obtenerParaderos(@PathVariable Long id) {
        return rutaService.obtenerParaderos(id).stream()
                .map(ParaderoResponseDTO::desde)
                .toList();
    }
}