package com.web.controller;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.map.MapUtil;
import com.web.interceptor.AuthInterceptor;
import com.web.pojo.Aftersale;
import com.web.service.AftersaleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * 售后服务接口
 */
@RestController
@RequestMapping("/v1/aftersales")
public class AftersaleController {

    @Autowired
    private AftersaleService aftersaleService;

    /**
     * 申请售后
     * POST /v1/aftersales/apply
     */
    @PostMapping("/apply")
    public ResponseEntity<Map<String, Object>> applyAftersale(@RequestBody Map<String, Object> params) {
        Long userId = AuthInterceptor.getCurrentUserId();
        Long orderId = Long.valueOf(params.get("orderId").toString());
        String orderItemId = params.getOrDefault("orderItemId", "").toString();
        Integer qty = null;
        try {
            qty = params.get("qty") == null ? null : Integer.valueOf(params.get("qty").toString());
        } catch (Exception ignore) {}
        String type = params.getOrDefault("type", "refund_only").toString();
        String reason = params.getOrDefault("reason", "").toString();
        String evidence = params.getOrDefault("evidence", null) == null ? null : params.get("evidence").toString();
        
        Aftersale aftersale = aftersaleService.applyAftersale(userId, orderId, orderItemId, qty, type, reason, evidence);
        
        Map<String, Object> meta = MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("requestId", UUID.randomUUID().toString())
                .build();
                
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", 200)
                .put("message", "success")
                .put("data", BeanUtil.beanToMap(aftersale, false, true))
                .put("meta", meta)
                .build());
    }

    /**
     * 查询售后列表
     * GET /v1/aftersales
     */
    @GetMapping
    public ResponseEntity<Map<String, Object>> getAftersales(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
            
        Long userId = AuthInterceptor.getCurrentUserId();
        List<Aftersale> list = aftersaleService.getAftersales(userId, page, size);
        
        List<Map<String, Object>> mapList = list.stream()
                .map(a -> BeanUtil.beanToMap(a, false, true))
                .collect(Collectors.toList());
                
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", 200)
                .put("message", "success")
                .put("data", mapList)
                .build());
    }

    /**
     * 取消售后申请
     * POST /v1/aftersales/{id}/cancel
     */
    @PostMapping("/{id}/cancel")
    public ResponseEntity<Map<String, Object>> cancelAftersale(@PathVariable Long id) {
        Long userId = AuthInterceptor.getCurrentUserId();
        boolean success = aftersaleService.cancelAftersale(id, userId);
        
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", success ? 200 : 500)
                .put("message", success ? "success" : "failed")
                .build());
    }
}
