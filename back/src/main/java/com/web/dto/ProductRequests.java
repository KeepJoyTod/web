package com.web.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;

public class ProductRequests {
    @Schema(name = "ProductCreateRequest")
    @Data
    public static class CreateRequest {
        @Schema(example = "1")
        private Long categoryId;

        @Schema(example = "iPhone 15 Pro")
        private String name;

        @Schema(example = "A17 Pro 芯片，钛金属机身")
        private String description;

        @Schema(example = "旗舰,手机")
        private String tags;

        @Schema(example = "7999.00")
        private BigDecimal price;

        @Schema(example = "100")
        private Integer stock;

        @Schema(example = "1", description = "状态：0-下架，1-上架")
        private Integer status;
    }
}
