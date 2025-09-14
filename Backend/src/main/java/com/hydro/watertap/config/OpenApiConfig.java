package com.hydro.watertap.config;

import io.swagger.v3.oas.models.ExternalDocumentation;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
                .info(new Info().title("Water Tap API")
                        .version("1.0")
                        .description("API para monitoreo de sensores de agua"))
                .externalDocs(new ExternalDocumentation()
                        .description("Documentación de referencia")
                        .url("https://github.com/tu-repo"));
    }
}
