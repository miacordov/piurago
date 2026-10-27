package com.piuragopiura.piuragopiura_backend.service.impl;

import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

class FranjaHorariaTest {

    @Test
    void clasificaLaHoraEnLasCuatroFranjas() {
        assertThat(FranjaHoraria.franjaDe(LocalDateTime.of(2026, 10, 26, 7, 30))).isEqualTo("MANANA_PICO");
        assertThat(FranjaHoraria.franjaDe(LocalDateTime.of(2026, 10, 26, 13, 0))).isEqualTo("MEDIO_DIA");
        assertThat(FranjaHoraria.franjaDe(LocalDateTime.of(2026, 10, 26, 18, 45))).isEqualTo("TARDE_PICO");
        assertThat(FranjaHoraria.franjaDe(LocalDateTime.of(2026, 10, 26, 23, 0))).isEqualTo("NOCHE");
        assertThat(FranjaHoraria.franjaDe(LocalDateTime.of(2026, 10, 26, 5, 0))).isEqualTo("NOCHE");
    }

    @Test
    void elDiaUsaLasAbreviaturasDelHistorico() {
        // 26/10/2026 es lunes; 1/11/2026, domingo.
        assertThat(FranjaHoraria.diaDe(LocalDateTime.of(2026, 10, 26, 8, 0))).isEqualTo("LUN");
        assertThat(FranjaHoraria.diaDe(LocalDateTime.of(2026, 11, 1, 8, 0))).isEqualTo("DOM");
    }
}
