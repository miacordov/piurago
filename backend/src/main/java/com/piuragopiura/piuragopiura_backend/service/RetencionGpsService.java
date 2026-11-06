package com.piuragopiura.piuragopiura_backend.service;

/** Borra los reportes GPS que superan el plazo de retención (RNF-08). */
public interface RetencionGpsService {

    /** Borra los reportes más viejos que el plazo y devuelve cuántos borró. */
    int borrarReportesAntiguos();
}
