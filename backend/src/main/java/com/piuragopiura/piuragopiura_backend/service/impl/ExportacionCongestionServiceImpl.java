package com.piuragopiura.piuragopiura_backend.service.impl;

import com.piuragopiura.piuragopiura_backend.model.HistoricoCongestion;
import com.piuragopiura.piuragopiura_backend.repository.HistoricoCongestionRepository;
import com.piuragopiura.piuragopiura_backend.service.ExportacionCongestionService;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.IndexedColors;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.math.BigDecimal;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.function.Function;

/** Genera con Apache POI el Excel del histórico de congestión. */
@Service
public class ExportacionCongestionServiceImpl implements ExportacionCongestionService {

    private static final Map<String, String> NOMBRE_FRANJA = Map.of(
            "MANANA_PICO", "Mañana",
            "MEDIO_DIA", "Mediodía",
            "TARDE_PICO", "Tarde",
            "NOCHE", "Noche");

    private static final Map<String, String> NOMBRE_DIA = Map.of(
            "LUN", "Lunes", "MAR", "Martes", "MIE", "Miércoles", "JUE", "Jueves",
            "VIE", "Viernes", "SAB", "Sábado", "DOM", "Domingo");

    private static final List<String> COLUMNAS_FINALES = List.of(
            "Franja", "Día", "Nivel", "Velocidad (km/h)", "Demora (min/km)", "Puntos críticos", "Calculado");

    /** Por línea, luego por día de la semana (LUN…DOM) y por franja en el orden del día. */
    private static final Comparator<HistoricoCongestion> ORDEN = Comparator
            .comparing((HistoricoCongestion h) -> textoONada(h.getRuta().getCodigo()))
            .thenComparing(h -> posicion(FranjaHoraria.DIAS, h.getDiaSemana()))
            .thenComparing(h -> posicion(FranjaHoraria.FRANJAS, h.getFranjaHoraria()));

    private final HistoricoCongestionRepository historicoRepository;

    public ExportacionCongestionServiceImpl(HistoricoCongestionRepository historicoRepository) {
        this.historicoRepository = historicoRepository;
    }

    @Override
    public byte[] exportarExcel() {
        List<HistoricoCongestion> todos = historicoRepository.findAll().stream().sorted(ORDEN).toList();

        try (Workbook libro = new XSSFWorkbook(); ByteArrayOutputStream salida = new ByteArrayOutputStream()) {
            CellStyle encabezado = estiloEncabezado(libro);

            escribirHoja(libro, encabezado, "Por ruta", List.of("Línea", "Ruta"),
                    todos.stream().filter(h -> h.getParadero() == null).toList(),
                    h -> h.getRuta().getNombre());
            escribirHoja(libro, encabezado, "Por tramo", List.of("Línea", "Desde el paradero"),
                    todos.stream().filter(h -> h.getParadero() != null).toList(),
                    h -> h.getParadero().getNombre());

            libro.write(salida);
            return salida.toByteArray();
        } catch (IOException e) {
            throw new UncheckedIOException("No se pudo generar el Excel de congestión", e);
        }
    }

    private void escribirHoja(Workbook libro, CellStyle estiloEncabezado, String nombre,
                              List<String> primerasColumnas, List<HistoricoCongestion> registros,
                              Function<HistoricoCongestion, String> segundaColumna) {
        Sheet hoja = libro.createSheet(nombre);

        Row cabecera = hoja.createRow(0);
        int c = 0;
        for (String titulo : primerasColumnas) {
            celdaTexto(cabecera, c++, titulo).setCellStyle(estiloEncabezado);
        }
        for (String titulo : COLUMNAS_FINALES) {
            celdaTexto(cabecera, c++, titulo).setCellStyle(estiloEncabezado);
        }

        int numeroFila = 1;
        for (HistoricoCongestion h : registros) {
            Row fila = hoja.createRow(numeroFila++);
            celdaTexto(fila, 0, textoONada(h.getRuta().getCodigo()));
            celdaTexto(fila, 1, textoONada(segundaColumna.apply(h)));
            celdaTexto(fila, 2, NOMBRE_FRANJA.getOrDefault(h.getFranjaHoraria(), textoONada(h.getFranjaHoraria())));
            celdaTexto(fila, 3, NOMBRE_DIA.getOrDefault(h.getDiaSemana(), textoONada(h.getDiaSemana())));
            celdaTexto(fila, 4, textoONada(h.getNivelCongestion()));
            celdaNumero(fila, 5, h.getVelocidadPromedio());
            celdaNumero(fila, 6, h.getDemoraPromedio());
            celdaNumero(fila, 7, h.getCantidadPuntosCriticos() == null ? null
                    : BigDecimal.valueOf(h.getCantidadPuntosCriticos()));
            celdaTexto(fila, 8, h.getFechaCalculo() == null ? "" : h.getFechaCalculo().toString());
        }

        hoja.createFreezePane(0, 1);
        // Al imprimir: horizontal y todas las columnas en el ancho de la página.
        hoja.setFitToPage(true);
        hoja.getPrintSetup().setLandscape(true);
        hoja.getPrintSetup().setFitWidth((short) 1);
        hoja.getPrintSetup().setFitHeight((short) 0);
        ajustarAnchos(hoja, primerasColumnas.size() + COLUMNAS_FINALES.size());
    }

    /**
     * Ancho de cada columna según su texto más largo. No se usa autoSizeColumn porque necesita
     * las fuentes del sistema, que las imágenes de Docker livianas pueden no traer.
     */
    private void ajustarAnchos(Sheet hoja, int columnas) {
        for (int c = 0; c < columnas; c++) {
            int maximo = 8;
            for (Row fila : hoja) {
                Cell celda = fila.getCell(c);
                if (celda != null) {
                    maximo = Math.max(maximo, celda.toString().length());
                }
            }
            hoja.setColumnWidth(c, Math.min(maximo + 2, 60) * 256);
        }
    }

    private CellStyle estiloEncabezado(Workbook libro) {
        Font negrita = libro.createFont();
        negrita.setBold(true);
        CellStyle estilo = libro.createCellStyle();
        estilo.setFont(negrita);
        estilo.setFillForegroundColor(IndexedColors.GREY_25_PERCENT.getIndex());
        estilo.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        return estilo;
    }

    private Cell celdaTexto(Row fila, int columna, String valor) {
        Cell celda = fila.createCell(columna);
        celda.setCellValue(valor);
        return celda;
    }

    private void celdaNumero(Row fila, int columna, BigDecimal valor) {
        Cell celda = fila.createCell(columna);
        if (valor == null) {
            celda.setCellValue("");
        } else {
            celda.setCellValue(valor.doubleValue());
        }
    }

    private static String textoONada(String valor) {
        return valor == null ? "" : valor;
    }

    private static int posicion(List<String> orden, String valor) {
        int i = orden.indexOf(valor);
        return i < 0 ? orden.size() : i;
    }
}
