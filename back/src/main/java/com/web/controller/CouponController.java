package com.web.controller;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.map.MapUtil;
import com.web.interceptor.AuthInterceptor;
import com.web.pojo.Coupon;
import com.web.service.CouponService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 营销与优惠券接口
 */
@RestController
@RequestMapping("/v1/coupons")
public class CouponController {

    @Autowired
    private CouponService couponService;

    /**
     * 获取可用优惠券列表
     * GET /v1/coupons/available
     */
    @GetMapping("/available")
    public ResponseEntity<Map<String, Object>> getAvailableCoupons() {
        Long userId = AuthInterceptor.getCurrentUserId();
        List<Coupon> list = couponService.getValidCoupons(userId);
        
        List<Map<String, Object>> mapList = list.stream()
                .map(c -> BeanUtil.beanToMap(c, false, true))
                .collect(Collectors.toList());
                
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", 200)
                .put("message", "success")
                .put("data", mapList)
                .build());
    }

    /**
     * 校验优惠券是否可用
     * POST /v1/coupons/{code}/check
     */
    @PostMapping("/{code}/check")
    public ResponseEntity<Map<String, Object>> checkCoupon(
            @PathVariable String code,
            @RequestBody Map<String, Object> params) {
            
        Long userId = AuthInterceptor.getCurrentUserId();
        BigDecimal amount = new BigDecimal(params.getOrDefault("amount", "0").toString());
        
        Map<String, Object> result = couponService.checkCoupon(userId, code, amount);
        
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", 200)
                .put("message", "success")
                .put("data", result)
                .build());
    }
}
