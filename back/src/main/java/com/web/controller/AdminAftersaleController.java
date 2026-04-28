package com.web.controller;

import com.web.exception.BusinessException;
import com.web.mapper.AdminMapper;
import com.web.util.ApiResponses;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

@RestController
@RequestMapping("/v1/admin/aftersales")
public class AdminAftersaleController {

    private static final Set<String> ALLOWED_STATUS = Set.of(
            "SUBMITTED", "PROCESSING", "APPROVED", "REJECTED", "COMPLETED", "CANCELLED"
    );

    @Autowired
    private AdminMapper adminMapper;

    @GetMapping
    public ResponseEntity<Map<String, Object>> list(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        int safePage = Math.max(page, 1);
        int safeSize = Math.min(Math.max(size, 1), 100);
        int offset = (safePage - 1) * safeSize;

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("items", adminMapper.listAftersales(keyword, status, offset, safeSize));
        data.put("total", adminMapper.countAftersales(keyword, status));
        data.put("page", safePage);
        data.put("size", safeSize);
        return ApiResponses.ok(data);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> detail(@PathVariable Long id) {
        Map<String, Object> aftersale = adminMapper.getAftersaleDetail(id);
        if (aftersale == null) {
            throw new BusinessException("NOT_FOUND", "售后申请不存在");
        }
        aftersale.put("items", adminMapper.listOrderItems(Long.valueOf(aftersale.get("orderId").toString())));
        return ApiResponses.ok(aftersale);
    }

    @PutMapping("/{id}/review")
    public ResponseEntity<Map<String, Object>> review(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        String status = body.get("status") == null ? "" : body.get("status").toString().trim().toUpperCase();
        String adminRemark = body.get("adminRemark") == null ? "" : body.get("adminRemark").toString().trim();
        if (!ALLOWED_STATUS.contains(status)) {
            throw new BusinessException("VALIDATION_FAILED", "售后状态不合法");
        }
        adminMapper.reviewAftersale(id, status, adminRemark);
        return ApiResponses.ok();
    }
}
