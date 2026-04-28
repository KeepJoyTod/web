package com.web.pojo;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class Category {
    private Long id;
    private String name;
    private Long parentId;
    private java.util.Date createTime;

    // 关联字段
    private java.util.List<Category> children;
}
