package com.web.pojo;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.LocalDateTime;

/**
 * 售后记录实体类
 * 对应表: aftersales
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Aftersale {
    private Long id;
    private Long userId;
    private Long orderId;
    private String orderItemId;
    private Integer qty;
    private String evidence;
    private String type; // refund_only, return_refund
    private String reason;
    private String status; // SUBMITTED, PROCESSING, COMPLETED, CANCELLED
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
