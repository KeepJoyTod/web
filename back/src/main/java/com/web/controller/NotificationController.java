package com.web.controller;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.map.MapUtil;
import com.web.interceptor.AuthInterceptor;
import com.web.pojo.Notification;
import com.web.service.NotificationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/v1/notifications")
public class NotificationController {

    @Autowired
    private NotificationService notificationService;

    @GetMapping
    public ResponseEntity<Map<String, Object>> list(@RequestParam(defaultValue = "1") int page,
                                                    @RequestParam(defaultValue = "20") int size) {
        Long userId = AuthInterceptor.getCurrentUserId();
        List<Notification> list = notificationService.list(userId, page, size);
        var data = list.stream().map(x -> BeanUtil.beanToMap(x, false, true)).collect(Collectors.toList());
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", 200)
                .put("message", "success")
                .put("data", data)
                .build());
    }

    @PostMapping
    public ResponseEntity<Map<String, Object>> create(@RequestBody Map<String, Object> params) {
        Long userId = AuthInterceptor.getCurrentUserId();
        String type = params.getOrDefault("type", "system").toString();
        String title = params.getOrDefault("title", "").toString();
        String content = params.getOrDefault("content", "").toString();
        String relatedId = params.getOrDefault("relatedId", "").toString();
        
        Notification n = notificationService.create(userId, type, title, content, relatedId);
        var meta = MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("requestId", UUID.randomUUID().toString())
                .build();
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", 200)
                .put("message", "success")
                .put("data", BeanUtil.beanToMap(n, false, true))
                .put("meta", meta)
                .build());
    }

    @PostMapping("/{id}/read")
    public ResponseEntity<Map<String, Object>> markRead(@PathVariable Long id) {
        Long userId = AuthInterceptor.getCurrentUserId();
        boolean ok = notificationService.markRead(id, userId);
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", ok ? 200 : 500)
                .put("message", ok ? "success" : "failed")
                .build());
    }

    @PostMapping("/markAllRead")
    public ResponseEntity<Map<String, Object>> markAllRead() {
        Long userId = AuthInterceptor.getCurrentUserId();
        int n = notificationService.markAllRead(userId);
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", 200)
                .put("message", "success")
                .put("data", MapUtil.of("count", n))
                .build());
    }

    @DeleteMapping
    public ResponseEntity<Map<String, Object>> clearAll() {
        Long userId = AuthInterceptor.getCurrentUserId();
        int n = notificationService.clearAll(userId);
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", 200)
                .put("message", "success")
                .put("data", MapUtil.of("count", n))
                .build());
    }
}
