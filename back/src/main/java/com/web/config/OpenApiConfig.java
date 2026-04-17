package com.web.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class OpenApiConfig {
    @Value("${server.servlet.context-path:}")
    private String contextPath;

    @Bean
    public OpenAPI openAPI() {
        String base = contextPath == null || contextPath.isEmpty() ? "/" : contextPath;
        
        return new OpenAPI()
                .info(new Info()
                        .title("ProjectKu 电子商城 API")
                        .version("v1.0.0")
                        .description("ProjectKu 后端 REST API 文档，包含商品、订单、支付等模块。"))
                .servers(List.of(new Server().url(base).description("当前环境")))
                .addSecurityItem(new SecurityRequirement().addList("Bearer Authentication"))
                .components(new Components()
                        .addSecuritySchemes("Bearer Authentication", createAPIKeyScheme()));
    }

    private SecurityScheme createAPIKeyScheme() {
        return new SecurityScheme()
                .type(SecurityScheme.Type.HTTP)
                .bearerFormat("JWT")
                .scheme("bearer");
    }
}
