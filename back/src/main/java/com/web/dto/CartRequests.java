package com.web.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

public class CartRequests {
    @Schema(name = "CartAddItemRequest")
    @Data
    public static class AddItemRequest {
        private Long productId;

        @Schema(example = "1")
        private Integer quantity;
    }

    @Schema(name = "CartUpdateItemRequest")
    @Data
    public static class UpdateItemRequest {
        private Integer quantity;
    }
}
