package com.web.pojo;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.LocalDateTime;

/**
 * 购物车明细实体类
 * 对应表: cart_items
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CartItem {
    private Long id;
    private Long userId;
    private Long productId;
    private Long skuId;
    private Integer quantity;
    private Integer checked; // 是否选中: 0-否, 1-是
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
