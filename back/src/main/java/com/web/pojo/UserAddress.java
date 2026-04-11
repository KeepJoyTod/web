package com.web.pojo;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.LocalDateTime;

/**
 * 用户收货地址实体类
 * 对应表: user_addresses
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserAddress {
    private Long id;
    private Long userId;
    private String receiver;
    private String phone;
    private String region;
    private String detail;
    private Integer isDefault; // 是否默认: 0-否, 1-是
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
