package com.web.pojo;

import lombok.Data;

import java.util.Date;

@Data
public class AdminOperationLog {
    private Long id;
    private Long adminId;
    private String adminAccount;
    private String role;
    private String permissionCode;
    private String method;
    private String path;
    private String action;
    private String status;
    private Long durationMs;
    private String errorMessage;
    private String ip;
    private Date createTime;
}
