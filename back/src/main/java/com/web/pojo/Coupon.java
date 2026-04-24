package com.web.pojo;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 优惠券实体类
 * 对应表: coupons
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Coupon {
    private Long id;
    private Long userId;
    private String code;
    private String name;
    private String type; // full_reduction, discount
    private BigDecimal minAmount; // 最低消费门槛
    private BigDecimal discountAmount; // 优惠金额
    private String status; // VALID, USED, EXPIRED
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
