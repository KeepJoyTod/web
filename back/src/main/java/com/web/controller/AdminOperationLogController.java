package com.web.controller;

import com.web.mapper.AdminPermissionMapper;
import com.web.util.ApiResponses;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/v1/admin/operation-logs")
public class AdminOperationLogController {

    @Autowired
    private AdminPermissionMapper adminPermissionMapper;

    @GetMapping
    public ResponseEntity<Map<String, Object>> list(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String permissionCode,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        int safePage = Math.max(page, 1);
        int safeSize = Math.min(Math.max(size, 1), 100);
        int offset = (safePage - 1) * safeSize;

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("items", adminPermissionMapper.listOperationLogs(keyword, permissionCode, status, offset, safeSize));
        data.put("total", adminPermissionMapper.countOperationLogs(keyword, permissionCode, status));
        data.put("page", safePage);
        data.put("size", safeSize);
        return ApiResponses.ok(data);
    }
}
