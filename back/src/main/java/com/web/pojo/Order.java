package com.web.pojo;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 订单实体类
 * 对应表: orders
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Order {
    private Long id;
    private Long userId;
    private String orderNo;         // 业务订单号
    private BigDecimal totalAmount; // 订单总金额
    private BigDecimal payAmount;   // 实际支付金额
    private Integer status;         // 订单状态 (0-待支付, 1-已支付, 2-已发货, 3-已完成, 4-已取消)
    private Long addressId;         // 收货地址ID
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
