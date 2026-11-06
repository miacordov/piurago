package com.piuragopiura.piuragopiura_backend;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

import static org.assertj.core.api.Assertions.assertThat;

/** Actuator expone solo health e info, y health no muestra detalles de la base. */
class ActuatorConfiguracionTest {

    private static Properties propiedades() throws IOException {
        Properties p = new Properties();
        try (InputStream in = ActuatorConfiguracionTest.class.getResourceAsStream("/application.properties")) {
            p.load(in);
        }
        return p;
    }

    @Test
    void actuatorEstaEnElClasspath() {
        assertThat(ActuatorConfiguracionTest.class.getClassLoader()
                .getResource("org/springframework/boot/actuate/endpoint/annotation/Endpoint.class"))
                .as("falta spring-boot-starter-actuator en el pom")
                .isNotNull();
    }

    @Test
    void soloSeExponenHealthEInfo() throws IOException {
        assertThat(propiedades().getProperty("management.endpoints.web.exposure.include"))
                .isEqualTo("health,info");
    }

    @Test
    void healthNoMuestraDetalles() throws IOException {
        Properties p = propiedades();
        assertThat(p.getProperty("management.endpoint.health.show-details")).isEqualTo("never");
        assertThat(p.getProperty("management.endpoint.health.show-components")).isEqualTo("never");
    }

    @Test
    void infoDiceQueAppEs() throws IOException {
        Properties p = propiedades();
        assertThat(p.getProperty("management.info.env.enabled")).isEqualTo("true");
        assertThat(p.getProperty("info.app.nombre")).isEqualTo("PiuraGo backend");
    }
}
