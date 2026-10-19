package com.piuragopiura.piuragopiura_backend.service.impl;

import com.piuragopiura.piuragopiura_backend.model.Paradero;
import com.piuragopiura.piuragopiura_backend.model.Ruta;
import com.piuragopiura.piuragopiura_backend.repository.ParaderoRepository;
import com.piuragopiura.piuragopiura_backend.repository.RutaRepository;
import com.piuragopiura.piuragopiura_backend.service.RutaService;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class RutaServiceImpl implements RutaService {

    private final RutaRepository rutaRepository;
    private final ParaderoRepository paraderoRepository;

    public RutaServiceImpl(RutaRepository rutaRepository, ParaderoRepository paraderoRepository) {
        this.rutaRepository = rutaRepository;
        this.paraderoRepository = paraderoRepository;
    }

    @Override
    public List<Ruta> listarActivas() {
        return rutaRepository.findByActivaTrue();
    }

    @Override
    public Ruta obtenerPorId(Long idRuta) {
        return rutaRepository.findById(idRuta)
            .orElseThrow(() -> new IllegalArgumentException("Ruta no encontrada: " + idRuta));
    }

    @Override
    public List<Paradero> obtenerParaderos(Long idRuta) {
        return paraderoRepository.findByRuta_IdRutaOrderByOrdenSecuencialAsc(idRuta);
    }
}