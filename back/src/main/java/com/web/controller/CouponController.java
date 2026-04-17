package com.web.controller;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.map.MapUtil;
import com.web.interceptor.AuthInterceptor;
import com.web.dto.CouponRequests;
import com.web.pojo.Coupon;
import com.web.service.CouponService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
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
@Tag(name = "营销管理", description = "优惠券查询与校验")
@RestController
@RequestMapping("/v1/coupons")
public class CouponController {

    @Autowired
    private CouponService couponService;

    @Operation(summary = "获取可用优惠券", description = "获取当前用户可使用的优惠券列表")
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

    @Operation(summary = "校验优惠券", description = "根据优惠券码和订单金额校验是否可用")
    @PostMapping("/{code}/check")
    public ResponseEntity<Map<String, Object>> checkCoupon(
            @PathVariable String code,
            @RequestBody CouponRequests.CheckRequest req) {
            
        Long userId = AuthInterceptor.getCurrentUserId();
        BigDecimal amount = req.getAmount() == null ? BigDecimal.ZERO : req.getAmount();
        
        Map<String, Object> result = couponService.checkCoupon(userId, code, amount);
        
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", 200)
                .put("message", "success")
                .put("data", result)
                .build());
    }
}
