package com.web.mapper;

import com.web.pojo.Coupon;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface CouponMapper {
    List<Coupon> getValidCouponsByUserId(Long userId);
    
    Coupon getByCode(@Param("code") String code);
    
    int updateStatus(@Param("id") Long id, @Param("status") String status);
}
