package com.web.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;

public class CouponRequests {
    @Schema(name = "CouponCheckRequest")
    @Data
    public static class CheckRequest {
        @Schema(example = "199.00")
        private BigDecimal amount;
    }
}
