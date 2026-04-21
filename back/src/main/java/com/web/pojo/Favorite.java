package com.web.pojo;

import lombok.Data;
import java.util.Date;

@Data
public class Favorite {
    private Long id;
    private Long userId;
    private Long productId;
    private Date createTime;
}
