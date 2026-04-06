package com.web.pojo;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.LocalDateTime;

/**
 * 用户实体类
 * 对应表: users
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class User {
    private Long id;
    private String account;
    private String password;
    private String nickname;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
