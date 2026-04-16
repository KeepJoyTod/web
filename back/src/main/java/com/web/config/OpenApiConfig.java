package com.web.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
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
        String base = contextPath == null ? "" : contextPath.trim();
        if (!base.isEmpty() && !base.startsWith("/")) {
            base = "/" + base;
        }
        if ("/".equals(base)) {
            base = "";
        }
        return new OpenAPI()
                .info(new Info()
                        .title("ProjectKu Web API")
                        .version("v1")
                        .description("REST API 文档"))
                .servers(List.of(new Server().url(base)));
    }
}
