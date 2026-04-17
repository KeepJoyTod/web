package com.web.exception;

import cn.hutool.core.map.MapUtil;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.util.Map;
import java.util.UUID;

/**
 * 全局异常处理器
 */
@ControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<Map<String, Object>> handleBusinessException(BusinessException e) {
        // 根据 PRD 12.错误码示例 封装
        Map<String, Object> error = MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", e.getCode())
                .put("message", e.getMessage())
                .build();
                
        Map<String, Object> meta = MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("requestId", UUID.randomUUID().toString())
                .build();
                
        Map<String, Object> result = MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("error", error)
                .put("meta", meta)
                .build();

        return ResponseEntity.status(400).body(result);
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<Map<String, Object>> handleNoResourceFoundException(NoResourceFoundException e) {
        Map<String, Object> error = MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", "NOT_FOUND")
                .put("message", "接口不存在: " + e.getResourcePath())
                .build();
                
        Map<String, Object> meta = MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("requestId", UUID.randomUUID().toString())
                .build();
                
        Map<String, Object> result = MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("error", error)
                .put("meta", meta)
                .build();

        return ResponseEntity.status(404).body(result);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleException(Exception e) {
        Map<String, Object> error = MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", "INTERNAL_ERROR")
                .put("message", "服务器内部错误: " + e.getMessage())
                .build();
                
        Map<String, Object> meta = MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("requestId", UUID.randomUUID().toString())
                .build();
                
        Map<String, Object> result = MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("error", error)
                .put("meta", meta)
                .build();

        return ResponseEntity.status(500).body(result);
    }
}
