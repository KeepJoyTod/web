package com.web.controller;

import cn.hutool.core.map.MapUtil;
import io.swagger.v3.oas.annotations.Hidden;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 首页控制器，用于验证后端服务状态
 */
@RestController
public class IndexController {

    @Hidden
    @GetMapping("/")
    public Map<String, Object> index() {
        return MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("status", "UP")
                .put("message", "ProjectKu Backend is running")
                .put("swagger_ui", "/api/swagger-ui.html")
                .put("api_docs", "/api/v3/api-docs")
                .build();
    }
}
