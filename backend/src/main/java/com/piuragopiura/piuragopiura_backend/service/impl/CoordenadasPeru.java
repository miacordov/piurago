package com.piuragopiura.piuragopiura_backend.service.impl;

import org.apache.commons.lang3.Range;

import java.math.BigDecimal;

/**
 * Rango aproximado del territorio peruano: descarta coordenadas claramente
 * corruptas o falsificadas en los reportes de los pasajeros.
 */
final class CoordenadasPeru {

    private static final Range<Double> LATITUD = Range.of(-18.5, 0.0);
    private static final Range<Double> LONGITUD = Range.of(-81.5, -68.5);

    private CoordenadasPeru() {
    }

    static void validar(BigDecimal latitud, BigDecimal longitud) {
        if (!LATITUD.contains(latitud.doubleValue())) {
            throw new IllegalArgumentException("Latitud fuera de rango esperado: " + latitud);
        }
        if (!LONGITUD.contains(longitud.doubleValue())) {
            throw new IllegalArgumentException("Longitud fuera de rango esperado: " + longitud);
        }
    }
}
