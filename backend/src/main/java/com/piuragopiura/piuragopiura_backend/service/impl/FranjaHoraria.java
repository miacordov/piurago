package com.piuragopiura.piuragopiura_backend.service.impl;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Franja horaria y día de la semana con los que se guarda el histórico de
 * congestión. Lo usan el cálculo del histórico y el ETA (que busca la
 * velocidad típica de la línea en la franja y el día actuales).
 */
public final class FranjaHoraria {

    public static final List<String> FRANJAS = List.of("MANANA_PICO", "MEDIO_DIA", "TARDE_PICO", "NOCHE");
    public static final List<String> DIAS = List.of("LUN", "MAR", "MIE", "JUE", "VIE", "SAB", "DOM");

    private FranjaHoraria() {
    }

    public static String franjaDe(LocalDateTime t) {
        int hora = t.getHour();
        if (hora >= 6 && hora <= 9) return "MANANA_PICO";
        if (hora >= 10 && hora <= 16) return "MEDIO_DIA";
        if (hora >= 17 && hora <= 20) return "TARDE_PICO";
        return "NOCHE";
    }

    public static String diaDe(LocalDateTime t) {
        return DIAS.get(t.getDayOfWeek().getValue() - 1); // lunes = 1
    }
}
