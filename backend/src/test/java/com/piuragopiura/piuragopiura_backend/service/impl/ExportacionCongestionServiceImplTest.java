package com.piuragopiura.piuragopiura_backend.service.impl;

import com.piuragopiura.piuragopiura_backend.model.HistoricoCongestion;
import com.piuragopiura.piuragopiura_backend.model.Paradero;
import com.piuragopiura.piuragopiura_backend.model.Ruta;
import com.piuragopiura.piuragopiura_backend.repository.HistoricoCongestionRepository;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ExportacionCongestionServiceImplTest {

    @Mock private HistoricoCongestionRepository historicoRepository;

    private ExportacionCongestionServiceImpl service;

    @BeforeEach
    void setUp() {
        service = new ExportacionCongestionServiceImpl(historicoRepository);
    }

    // ---------- ayudas ----------

    private Ruta ruta(long id, String codigo, String nombre) {
        Ruta ruta = new Ruta();
        ruta.setIdRuta(id);
        ruta.setCodigo(codigo);
        ruta.setNombre(nombre);
        return ruta;
    }

    private Paradero paradero(long id, String nombre) {
        Paradero p = new Paradero();
        p.setIdParadero(id);
        p.setNombre(nombre);
        return p;
    }

    private HistoricoCongestion historico(Ruta ruta, Paradero paradero, String franja, String dia,
                                          String nivel, double velocidad, double demora, int puntos) {
        HistoricoCongestion h = new HistoricoCongestion();
        h.setRuta(ruta);
        h.setParadero(paradero);
        h.setFranjaHoraria(franja);
        h.setDiaSemana(dia);
        h.setNivelCongestion(nivel);
        h.setVelocidadPromedio(BigDecimal.valueOf(velocidad));
        h.setDemoraPromedio(BigDecimal.valueOf(demora));
        h.setCantidadPuntosCriticos((short) puntos);
        h.setFechaCalculo(LocalDate.of(2026, 10, 27));
        return h;
    }

    private Workbook leer(byte[] archivo) throws IOException {
        return new XSSFWorkbook(new ByteArrayInputStream(archivo));
    }

    /** Valores de una fila como texto (los números, tal cual los guarda Excel). */
    private List<String> fila(Sheet hoja, int indice) {
        Row row = hoja.getRow(indice);
        List<String> valores = new ArrayList<>();
        for (int c = 0; c < row.getLastCellNum(); c++) {
            var celda = row.getCell(c);
            valores.add(switch (celda.getCellType()) {
                case NUMERIC -> String.valueOf(celda.getNumericCellValue());
                default -> celda.getStringCellValue();
            });
        }
        return valores;
    }

    // ---------- pruebas ----------

    @Test
    void generaUnExcelConUnaHojaPorRutaYOtraPorTramo() throws IOException {
        Ruta rd10 = ruta(9L, "RD-10", "UPIS San Gabriel - Av. Raúl Mata La Cruz");
        when(historicoRepository.findAll()).thenReturn(List.of(
                historico(rd10, null, "MEDIO_DIA", "MAR", "BAJA", 20.75, 0.49, 9),
                historico(rd10, paradero(3L, "Open Plaza"), "MEDIO_DIA", "MAR", "ALTA", 6.0, 7.6, 2)));

        try (Workbook libro = leer(service.exportarExcel())) {
            assertThat(libro.getNumberOfSheets()).isEqualTo(2);

            Sheet porRuta = libro.getSheet("Por ruta");
            assertThat(fila(porRuta, 0)).containsExactly("Línea", "Ruta", "Franja", "Día", "Nivel",
                    "Velocidad (km/h)", "Demora (min/km)", "Puntos críticos", "Calculado");
            assertThat(fila(porRuta, 1)).containsExactly("RD-10", "UPIS San Gabriel - Av. Raúl Mata La Cruz",
                    "Mediodía", "Martes", "BAJA", "20.75", "0.49", "9.0", "2026-10-27");
            assertThat(porRuta.getLastRowNum()).isEqualTo(1);

            Sheet porTramo = libro.getSheet("Por tramo");
            assertThat(fila(porTramo, 0)).containsExactly("Línea", "Desde el paradero", "Franja", "Día", "Nivel",
                    "Velocidad (km/h)", "Demora (min/km)", "Puntos críticos", "Calculado");
            assertThat(fila(porTramo, 1)).containsExactly("RD-10", "Open Plaza", "Mediodía", "Martes", "ALTA",
                    "6.0", "7.6", "2.0", "2026-10-27");
        }
    }

    @Test
    void ordenaPorLineaDiaYFranjaComoEnLaSemana() throws IOException {
        Ruta a = ruta(1L, "RD-10", "A");
        Ruta b = ruta(2L, "I-18", "B");
        when(historicoRepository.findAll()).thenReturn(List.of(
                historico(a, null, "NOCHE", "LUN", "BAJA", 30, 0, 0),
                historico(a, null, "MANANA_PICO", "MAR", "ALTA", 8, 5.1, 3),
                historico(a, null, "MANANA_PICO", "LUN", "MEDIA", 12, 2.6, 1),
                historico(b, null, "TARDE_PICO", "DOM", "MEDIA", 15, 1.6, 0)));

        try (Workbook libro = leer(service.exportarExcel())) {
            Sheet hoja = libro.getSheet("Por ruta");
            List<String> orden = new ArrayList<>();
            for (int i = 1; i <= hoja.getLastRowNum(); i++) {
                List<String> f = fila(hoja, i);
                orden.add(f.get(0) + " " + f.get(3) + " " + f.get(2));
            }
            assertThat(orden).containsExactly(
                    "I-18 Domingo Tarde",
                    "RD-10 Lunes Mañana",
                    "RD-10 Lunes Noche",
                    "RD-10 Martes Mañana");
        }
    }

    @Test
    void sinDatosGeneraLasHojasSoloConEncabezados() throws IOException {
        when(historicoRepository.findAll()).thenReturn(List.of());

        try (Workbook libro = leer(service.exportarExcel())) {
            assertThat(libro.getSheet("Por ruta").getLastRowNum()).isZero();
            assertThat(libro.getSheet("Por tramo").getLastRowNum()).isZero();
            assertThat(fila(libro.getSheet("Por ruta"), 0)).first().isEqualTo("Línea");
        }
    }
}
