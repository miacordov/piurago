package com.piuragopiura.piuragopiura_backend;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Properties;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * El repositorio es público: ningún .properties versionado puede traer el valor de una
 * clave o credencial. Solo se aceptan referencias a variables de entorno, como
 * jwt.secret=${JWT_SECRET}. Los valores reales van en variables de entorno o en
 * backend/config/application-local.properties (ignorado por Git).
 */
class PropiedadesSinSecretosTest {

    private static final List<String> SENSIBLES = List.of("secret", "password", "jwt_secret", "datasource.url",
            "datasource.username");

    private static boolean esSensible(String clave) {
        String c = clave.toLowerCase(Locale.ROOT);
        return SENSIBLES.stream().anyMatch(c::contains);
    }

    private static boolean esReferenciaAVariable(String valor) {
        return valor.strip().matches("\\$\\{[A-Za-z0-9_.\\-]+(:[^}]*)?}");
    }

    @Test
    void ningunArchivoDePropiedadesTraeSecretosEscritos() throws IOException {
        List<String> problemas = new ArrayList<>();
        try (Stream<Path> archivos = Files.list(Path.of("src/main/resources"))) {
            for (Path archivo : archivos.filter(p -> p.toString().endsWith(".properties")).toList()) {
                Properties props = new Properties();
                try (Reader r = Files.newBufferedReader(archivo, StandardCharsets.UTF_8)) {
                    props.load(r);
                }
                for (String clave : props.stringPropertyNames()) {
                    if (esSensible(clave) && !esReferenciaAVariable(props.getProperty(clave))) {
                        // Solo el nombre de la clave: el valor no se muestra en el reporte.
                        problemas.add(archivo.getFileName() + ": " + clave);
                    }
                }
            }
        }
        assertThat(problemas).as("propiedades sensibles con un valor escrito").isEmpty();
    }

    @Test
    void reconoceLasReferenciasAVariables() {
        assertThat(esReferenciaAVariable("${JWT_SECRET}")).isTrue();
        assertThat(esReferenciaAVariable("${APP_CORS:http://localhost:*}")).isTrue();
        assertThat(esReferenciaAVariable("una-clave-escrita")).isFalse();
    }
}
