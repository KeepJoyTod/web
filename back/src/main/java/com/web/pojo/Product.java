package com.web.pojo;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 商品实体类 (SPU)
 * 对应表: products
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Product {
    private Long id;
    private Long categoryId;
    private String name;
    private String description;
    private String tags;
    private BigDecimal rating; // 评分
    private Integer sold;      // 已售数量
    private String activityLabel; // 活动标签
    private BigDecimal originalPrice; // 原价
    private BigDecimal price; // 基础展示价格
    private Integer stock;    // 基础库存
    private Integer status;   // 状态 (0-下架, 1-上架)
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
