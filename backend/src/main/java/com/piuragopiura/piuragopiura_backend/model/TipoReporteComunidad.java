package com.piuragopiura.piuragopiura_backend.model;

/** Qué cambió según el pasajero que reporta. */
public enum TipoReporteComunidad {
    /** La ruta cambió su recorrido (desvío, cierre de avenida). */
    RUTA_CAMBIO,
    /** Hay un paradero que no está en la app. */
    PARADERO_NUEVO,
    /** Un paradero de la app ya no existe o está mal ubicado. */
    PARADERO_NO_EXISTE,
    OTRO
}
