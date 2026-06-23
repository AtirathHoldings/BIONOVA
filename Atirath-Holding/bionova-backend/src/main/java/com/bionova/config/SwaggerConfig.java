package com.bionova.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.info.Contact;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import org.springframework.context.annotation.Configuration;

@Configuration
@OpenAPIDefinition(
    info = @Info(
        title        = "CBG / Atirath Holding API",
        version      = "v1.0",
        description  = "REST API documentation for CBG Backend. All endpoints except /api/auth/login require a Bearer JWT token.",
        contact      = @Contact(name = "Atirath Holding", email = "siva@atirath.com")
    ),
    security = @SecurityRequirement(name = "BearerAuth")
)
@SecurityScheme(
    name   = "BearerAuth",
    type   = SecuritySchemeType.HTTP,
    scheme = "bearer",
    bearerFormat = "JWT"
)
public class SwaggerConfig {
    // No additional beans needed – springdoc auto-configures everything
}
