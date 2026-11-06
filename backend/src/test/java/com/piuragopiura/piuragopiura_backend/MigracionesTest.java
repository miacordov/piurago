package com.piuragopiura.piuragopiura_backend;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Revisa los archivos SQL sin conectarse a ninguna base: las pruebas corren desde
 * backend/, igual que el perfil "carga" (que lee db/ con rutas relativas).
 */
class MigracionesTest {

    private static String leer(String ruta) throws IOException {
        return Files.readString(Path.of(ruta), StandardCharsets.UTF_8);
    }

    @Test
    void laMigracionCreaElIndicePorFechaDeReporteGpsSinFallarSiYaExiste() throws IOException {
        String sql = leer("db/migraciones/002_indice_reporte_gps_fecha.sql");

        assertThat(sql).containsIgnoringCase(
                "CREATE INDEX IF NOT EXISTS idx_reporte_gps_fecha ON reporte_gps (fecha_hora)");
    }

    @Test
    void elEsquemaInicialYaTraeElIndice() throws IOException {
        assertThat(leer("db/schema.sql")).contains("idx_reporte_gps_fecha");
    }

    @Test
    void elPerfilDeCargaAplicaLaMigracion() throws IOException {
        assertThat(leer("src/main/resources/application-carga.properties"))
                .contains("file:db/migraciones/002_indice_reporte_gps_fecha.sql");
    }
}
