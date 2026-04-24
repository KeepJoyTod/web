package com.web.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Schema(name = "AuthLoginRequest")
@Data
public class AuthRequests {
    @Schema(name = "LoginRequest")
    @Data
    public static class LoginRequest {
        @Schema(example = "17863026867@163.com")
        private String account;

        @Schema(example = "bill0821")
        private String password;
    }

    @Schema(name = "RegisterRequest")
    @Data
    public static class RegisterRequest {
        @Schema(example = "17863026867@163.com")
        private String account;

        @Schema(example = "bill0821")
        private String password;

        @Schema(example = "Bill")
        private String nickname;
    }
}
