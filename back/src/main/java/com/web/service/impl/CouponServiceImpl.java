package com.web.service.impl;

import com.web.exception.BusinessException;
import com.web.mapper.CouponMapper;
import com.web.pojo.Coupon;
import com.web.service.CouponService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class CouponServiceImpl implements CouponService {

    @Autowired
    private CouponMapper couponMapper;

    @Override
    public List<Coupon> getValidCoupons(Long userId) {
        return couponMapper.getValidCouponsByUserId(userId);
    }

    @Override
    public Map<String, Object> checkCoupon(Long userId, String code, BigDecimal orderAmount) {
        Coupon coupon = couponMapper.getByCode(code);
        Map<String, Object> result = new HashMap<>();
        
        if (coupon == null || !coupon.getUserId().equals(userId)) {
            result.put("valid", false);
            result.put("reason", "优惠券不存在或不属于该用户");
            return result;
        }
        
        if (!"VALID".equals(coupon.getStatus())) {
            result.put("valid", false);
            result.put("reason", "优惠券已被使用或已过期");
            return result;
        }
        
        java.util.Date now = new java.util.Date();
        if (now.before(coupon.getStartTime()) || now.after(coupon.getEndTime())) {
            result.put("valid", false);
            result.put("reason", "不在优惠券使用有效期内");
            return result;
        }
        
        if (orderAmount.compareTo(coupon.getMinAmount()) < 0) {
            result.put("valid", false);
            result.put("reason", "未达到优惠券使用门槛金额");
            return result;
        }
        
        result.put("valid", true);
        result.put("discount", coupon.getDiscountAmount());
        result.put("reason", null);
        return result;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean useCoupon(Long userId, String code, BigDecimal orderAmount) {
        Map<String, Object> checkResult = checkCoupon(userId, code, orderAmount);
        if (!(Boolean) checkResult.get("valid")) {
            throw new BusinessException("COUPON_INVALID", (String) checkResult.get("reason"));
        }
        
        Coupon coupon = couponMapper.getByCode(code);
        return couponMapper.updateStatus(coupon.getId(), "USED") > 0;
    }
}
