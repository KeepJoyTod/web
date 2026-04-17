package com.web.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

public class UserAddressRequests {
    @Schema(name = "UserAddressCreateRequest")
    @Data
    public static class CreateRequest {
        @Schema(example = "张三")
        private String receiver;

        @Schema(example = "13800138000")
        private String phone;

        @Schema(example = "上海市 浦东新区")
        private String region;

        @Schema(example = "世纪大道100号 1号楼 1001室")
        private String detail;

        @Schema(example = "1", description = "是否默认：0-否，1-是")
        private Integer isDefault;
    }

    @Schema(name = "UserAddressUpdateRequest")
    @Data
    public static class UpdateRequest {
        @Schema(example = "张三")
        private String receiver;

        @Schema(example = "13800138000")
        private String phone;

        @Schema(example = "上海市 浦东新区")
        private String region;

        @Schema(example = "世纪大道100号 1号楼 1001室")
        private String detail;

        @Schema(example = "1", description = "是否默认：0-否，1-是")
        private Integer isDefault;
    }
}
