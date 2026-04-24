package com.web.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

public class NotificationRequests {
    @Schema(name = "NotificationCreateRequest")
    @Data
    public static class CreateRequest {
        @Schema(example = "system")
        private String type;

        @Schema(example = "系统通知")
        private String title;

        @Schema(example = "欢迎使用 ProjectKu")
        private String content;

        @Schema(example = "order:1001")
        private String relatedId;
    }
}
