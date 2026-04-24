package com.web.pojo;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class Review {
    private Long id;
    private Long userId;
    private Long orderId;
    private Long productId;
    private Integer rating;
    private String content;
    private String images;
    private String nickname; // 用户昵称
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
