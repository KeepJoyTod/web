package com.web.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

public class OrderRequests {
    @Schema(name = "OrderCheckoutRequest")
    @Data
    public static class CheckoutRequest {
        @Schema(example = "1")
        private Long addressId;

        @Schema(example = "NEW_USER_10")
        private String couponCode;
    }
}
