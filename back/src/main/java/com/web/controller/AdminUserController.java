package com.web.controller;

import com.web.exception.BusinessException;
import com.web.interceptor.AuthInterceptor;
import com.web.mapper.AdminMapper;
import com.web.util.ApiResponses;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/v1/admin/users")
public class AdminUserController {

    @Autowired
    private AdminMapper adminMapper;

    @GetMapping
    public ResponseEntity<Map<String, Object>> list(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String role,
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        int safePage = Math.max(page, 1);
        int safeSize = Math.min(Math.max(size, 1), 100);
        int offset = (safePage - 1) * safeSize;

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("items", adminMapper.listUsers(keyword, role, status, offset, safeSize));
        data.put("total", adminMapper.countUserList(keyword, role, status));
        data.put("page", safePage);
        data.put("size", safeSize);
        return ApiResponses.ok(data);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> detail(@PathVariable Long id) {
        Map<String, Object> user = adminMapper.getUserDetail(id);
        if (user == null) {
            throw new BusinessException("NOT_FOUND", "用户不存在");
        }
        return ApiResponses.ok(user);
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<Map<String, Object>> updateStatus(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Integer status = toInteger(body.get("status"));
        if (status == null || (status != 0 && status != 1)) {
            throw new BusinessException("VALIDATION_FAILED", "用户状态只能是 0 或 1");
        }
        if (id.equals(AuthInterceptor.getCurrentUserId()) && status == 0) {
            throw new BusinessException("VALIDATION_FAILED", "不能禁用当前登录管理员");
        }
        adminMapper.updateUserStatus(id, status);
        return ApiResponses.ok();
    }

    private Integer toInteger(Object value) {
        if (value == null || value.toString().isBlank()) {
            return null;
        }
        return Integer.valueOf(value.toString());
    }
}
