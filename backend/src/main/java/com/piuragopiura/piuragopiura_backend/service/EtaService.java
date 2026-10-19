package com.piuragopiura.piuragopiura_backend.service;

import com.piuragopiura.piuragopiura_backend.dto.EtaResponseDTO;

public interface EtaService {
    EtaResponseDTO calcularEtaProximoParadero(Long idRuta);
}