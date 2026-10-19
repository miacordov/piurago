package com.piuragopiura.piuragopiura_backend.config;

import com.google.common.cache.Cache;
import com.google.common.cache.CacheBuilder;
import com.piuragopiura.piuragopiura_backend.dto.EtaResponseDTO;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.concurrent.TimeUnit;

@Configuration
public class CacheConfig {

    @Bean
    public Cache<Long, EtaResponseDTO> etaCache() {
        return CacheBuilder.newBuilder()
            .expireAfterWrite(10, TimeUnit.SECONDS) // el ETA se recalcula cada 10s como máximo
            .maximumSize(200) // tope defensivo: no vas a tener más de 200 rutas activas a la vez
            .build();
    }
}