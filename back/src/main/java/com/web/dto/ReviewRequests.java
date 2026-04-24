package com.web.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

public class ReviewRequests {
    @Schema(name = "ReviewCreateRequest")
    @Data
    public static class CreateRequest {
        private Long orderId;
        private Long productId;
        private Integer rating;

        @Schema(example = "很好用，物流很快")
        private String content;

        @Schema(example = "[]")
        private String images;
    }
}
