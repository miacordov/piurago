package com.piuragopiura.piuragopiura_backend.service;

import com.piuragopiura.piuragopiura_backend.dto.PosicionesRutaResponseDTO;

public interface PosicionesService {

    /**
     * Última posición de cada colaborador de la ruta en la ventana reciente.
     * Lanza RecursoNoEncontradoException si la ruta no existe.
     */
    PosicionesRutaResponseDTO obtenerPosiciones(Long idRuta);
}
