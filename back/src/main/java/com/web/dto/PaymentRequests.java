package com.web.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

public class PaymentRequests {
    @Schema(name = "PaymentInitiateRequest")
    @Data
    public static class InitiateRequest {
        @Schema(example = "alipay")
        private String channel;
    }

    @Schema(name = "PaymentWebhookRequest")
    @Data
    public static class WebhookRequest {
        private String tradeId;
        private String status;
    }
}
