package com.web.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class SpringdocCompatController {

    @GetMapping("/api-docs")
    public String forwardApiDocs() {
        return "forward:/v3/api-docs";
    }

    @GetMapping("/api-docs/swagger-config")
    public String forwardApiDocsSwaggerConfig() {
        return "forward:/v3/api-docs/swagger-config";
    }

    @GetMapping("/swagger-ui-custom.html")
    public String redirectSwaggerUiCustom() {
        return "redirect:/swagger-ui.html";
    }
}

