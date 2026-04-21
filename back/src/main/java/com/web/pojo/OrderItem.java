package com.web.pojo;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 订单明细实体类
 * 对应表: order_items
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class OrderItem {
    private Long id;
    private Long orderId;
    private Long productId;
    private Long skuId;
    private String productName;
    private BigDecimal price; // 购买时单价
    private Integer quantity; // 购买数量
    private BigDecimal totalAmount; // 总金额
    private String productImage; // 商品图片
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
