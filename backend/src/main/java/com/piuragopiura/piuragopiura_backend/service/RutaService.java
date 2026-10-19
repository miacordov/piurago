package com.piuragopiura.piuragopiura_backend.service;

import com.piuragopiura.piuragopiura_backend.model.Paradero;
import com.piuragopiura.piuragopiura_backend.model.Ruta;

import java.util.List;

public interface RutaService {
    List<Ruta> listarActivas();
    Ruta obtenerPorId(Long idRuta);
    List<Paradero> obtenerParaderos(Long idRuta);
}