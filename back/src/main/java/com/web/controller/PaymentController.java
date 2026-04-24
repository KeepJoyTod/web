package com.web.controller;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.map.MapUtil;
import com.web.interceptor.AuthInterceptor;
import com.web.pojo.Payment;
import com.web.service.PaymentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

/**
 * 支付接口
 */
@RestController
@RequestMapping("/v1/payments")
public class PaymentController {

    @Autowired
    private PaymentService paymentService;

    /**
     * 发起支付
     * POST /v1/payments/{orderId}/pay
     */
    @PostMapping("/{orderId}/pay")
    public ResponseEntity<Map<String, Object>> initiatePayment(
            @PathVariable Long orderId,
            @RequestBody Map<String, Object> params) {
            
        Long userId = AuthInterceptor.getCurrentUserId();
        String channel = params.getOrDefault("channel", "alipay").toString();
        
        Map<String, Object> payParams = paymentService.initiatePayment(userId, orderId, channel);
        
        Map<String, Object> meta = MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("requestId", UUID.randomUUID().toString())
                .build();
                
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", 200)
                .put("message", "success")
                .put("data", payParams)
                .put("meta", meta)
                .build());
    }

    /**
     * 查询支付状态
     * GET /v1/payments/{orderId}/status
     */
    @GetMapping("/{orderId}/status")
    public ResponseEntity<Map<String, Object>> getPaymentStatus(@PathVariable Long orderId) {
        Long userId = AuthInterceptor.getCurrentUserId();
        Payment payment = paymentService.getPaymentStatus(orderId, userId);
        
        if (payment == null) {
            return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                    .put("code", 404)
                    .put("message", "支付记录不存在")
                    .build());
        }
        
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", 200)
                .put("message", "success")
                .put("data", BeanUtil.beanToMap(payment, false, true))
                .build());
    }

    /**
     * 模拟支付回调 (通常由第三方支付网关调用，不需要 Token)
     * POST /v1/payments/webhook
     */
    @PostMapping("/webhook")
    public ResponseEntity<Map<String, Object>> webhook(@RequestBody Map<String, Object> params) {
        String tradeId = params.containsKey("tradeId") ? (String) params.get("tradeId") : null;
        String status = params.containsKey("status") ? (String) params.get("status") : null;
        
        // 实际开发中需要验签(sign)，此处略过
        boolean success = paymentService.handleWebhook(tradeId, status);
        
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", success ? 200 : 500)
                .put("message", success ? "success" : "failed")
                .build());
    }
}
