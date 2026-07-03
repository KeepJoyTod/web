package com.web.util;

import cn.hutool.core.map.MapUtil;
import org.springframework.http.ResponseEntity;

import java.util.Map;
import java.util.UUID;

public final class ApiResponses {
    private ApiResponses() {
    }

    public static ResponseEntity<Map<String, Object>> ok(Object data) {
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", 200)
                .put("message", "success")
                .put("data", data)
                .put("meta", Map.of("requestId", UUID.randomUUID().toString()))
                .build());
    }

    public static ResponseEntity<Map<String, Object>> ok() {
        return ok(Map.of());
    }
}
