package com.piuragopiura.piuragopiura_backend.config;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Comprueba que springdoc es compatible con la versión de Spring Boot del proyecto:
 * levanta solo la capa web (sin base de datos) y pide /v3/api-docs y /swagger-ui.
 * Una versión de springdoc incompatible falla aquí y no recién al desplegar.
 */
@SpringBootTest(
        classes = SwaggerDocsTest.ContextoWeb.class,
        properties = "spring.autoconfigure.exclude="
                + "org.springframework.boot.jdbc.autoconfigure.DataSourceAutoConfiguration,"
                + "org.springframework.boot.hibernate.autoconfigure.HibernateJpaAutoConfiguration,"
                + "org.springframework.boot.data.jpa.autoconfigure.DataJpaRepositoriesAutoConfiguration")
@AutoConfigureMockMvc
class SwaggerDocsTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void generaElDocumentoOpenApiConLosEndpoints() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.openapi").exists())
                .andExpect(jsonPath("$.paths['/prueba-swagger']").exists());
    }

    @Test
    void sirveLaInterfazDeSwagger() throws Exception {
        mockMvc.perform(get("/swagger-ui/index.html"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("swagger")));
    }

    @Configuration
    @EnableAutoConfiguration
    static class ContextoWeb {

        @Bean
        SecurityFilterChain todoPermitido(HttpSecurity http) throws Exception {
            return http.authorizeHttpRequests(a -> a.anyRequest().permitAll()).build();
        }

        @Bean
        ControladorDePrueba controladorDePrueba() {
            return new ControladorDePrueba();
        }
    }

    @RestController
    static class ControladorDePrueba {
        @GetMapping("/prueba-swagger")
        String hola() {
            return "hola";
        }
    }
}
