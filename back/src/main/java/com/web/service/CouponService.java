package com.web.service;

import com.web.pojo.Coupon;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

public interface CouponService {
    List<Coupon> getValidCoupons(Long userId);
    
    Map<String, Object> checkCoupon(Long userId, String code, BigDecimal orderAmount);
    
    boolean useCoupon(Long userId, String code, BigDecimal orderAmount);
}
