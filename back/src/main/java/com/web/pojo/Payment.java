package com.web.pojo;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 支付记录实体类
 * 对应表: payments
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Payment {
    private Long id;
    private Long orderId;
    private String tradeId;   // 支付流水号
    private String channel;   // 支付渠道: alipay, wechat
    private BigDecimal amount; // 支付金额
    private String status;    // 状态: PENDING, SUCCESS, FAILED
    private LocalDateTime paidAt; // 实际支付时间
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
