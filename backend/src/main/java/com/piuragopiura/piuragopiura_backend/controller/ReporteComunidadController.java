package com.piuragopiura.piuragopiura_backend.controller;

import com.piuragopiura.piuragopiura_backend.dto.ReporteComunidadRequestDTO;
import com.piuragopiura.piuragopiura_backend.dto.ReporteComunidadResponseDTO;
import com.piuragopiura.piuragopiura_backend.security.UsuarioAutenticado;
import com.piuragopiura.piuragopiura_backend.service.ReporteComunidadService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

/** Reportes de los pasajeros sobre rutas y paraderos desactualizados. */
@RestController
@RequestMapping("/api/reportes-comunidad")
public class ReporteComunidadController {

    private final ReporteComunidadService reporteComunidadService;

    public ReporteComunidadController(ReporteComunidadService reporteComunidadService) {
        this.reporteComunidadService = reporteComunidadService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ReporteComunidadResponseDTO registrar(@AuthenticationPrincipal UsuarioAutenticado usuario,
                                                 @Valid @RequestBody ReporteComunidadRequestDTO request) {
        return ReporteComunidadResponseDTO.desde(reporteComunidadService.registrar(
                usuario.getIdUsuario(), request.tipo(), request.idRuta(),
                request.descripcion(), request.latitud(), request.longitud()));
    }
}
