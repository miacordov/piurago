package com.piuragopiura.piuragopiura_backend.dto;

import com.piuragopiura.piuragopiura_backend.model.Ruta;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThat;

class RutaResponseDTOTest {

    @Test
    void desdeCopiaLosDatosDelServicio() {
        Ruta r = new Ruta();
        r.setIdRuta(2L);
        r.setCodigo("I-19");
        r.setNombre("Piura - Catacaos");
        r.setEmpresa("6M Buss SAA");
        r.setTipoServicio("Interurbana");
        r.setHorario("05:30–22:00");
        r.setPasaje(new BigDecimal("3.00"));
        r.setPasajeEstudiante(new BigDecimal("1.50"));
        r.setFrecuenciaMinutos(15);

        RutaResponseDTO dto = RutaResponseDTO.desde(r);

        assertThat(dto.codigo()).isEqualTo("I-19");
        assertThat(dto.tipoServicio()).isEqualTo("Interurbana");
        assertThat(dto.horario()).isEqualTo("05:30–22:00");
        assertThat(dto.pasaje()).isEqualByComparingTo("3.00");
        assertThat(dto.pasajeEstudiante()).isEqualByComparingTo("1.50");
        assertThat(dto.frecuenciaMinutos()).isEqualTo(15);
    }

    @Test
    void losDatosDelServicioSonOpcionales() {
        Ruta r = new Ruta();
        r.setIdRuta(1L);
        r.setNombre("Ruta sin datos de servicio");

        RutaResponseDTO dto = RutaResponseDTO.desde(r);

        assertThat(dto.tipoServicio()).isNull();
        assertThat(dto.horario()).isNull();
        assertThat(dto.pasaje()).isNull();
        assertThat(dto.pasajeEstudiante()).isNull();
    }
}
