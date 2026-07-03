package com.web.pojo;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.math.BigDecimal;

/**
 * 商品 SKU 实体类
 * 对应表: product_skus
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProductSku {
    private Long id;
    private Long productId;
    private String attrs; // JSON 字符串
    private BigDecimal price;
    private Integer stock;
}
