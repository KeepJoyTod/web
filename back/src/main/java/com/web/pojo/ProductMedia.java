package com.web.pojo;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

/**
 * 商品媒体实体类
 * 对应表: product_media
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProductMedia {
    private Long id;
    private Long productId;
    private String url;
    private Integer sortOrder;
}
