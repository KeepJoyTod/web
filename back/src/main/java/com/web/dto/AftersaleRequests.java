package com.web.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

public class AftersaleRequests {
    @Schema(name = "AftersaleApplyRequest")
    @Data
    public static class ApplyRequest {
        private Long orderId;
        private String orderItemId;
        private Integer qty;

        @Schema(example = "refund_only")
        private String type;

        private String reason;
        private String evidence;
    }
}
