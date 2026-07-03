package com.web.controller;

import com.web.mapper.AdminMapper;
import com.web.util.ApiResponses;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/v1/admin/dashboard")
public class AdminDashboardController {

    @Autowired
    private AdminMapper adminMapper;

    @GetMapping("/stats")
    public ResponseEntity<Map<String, Object>> stats() {
        Map<String, Object> data = new LinkedHashMap<>();
        BigDecimal todaySales = adminMapper.sumTodaySales();

        data.put("users", adminMapper.countUsers());
        data.put("products", adminMapper.countProducts());
        data.put("orders", adminMapper.countOrders());
        data.put("todaySales", todaySales == null ? BigDecimal.ZERO : todaySales);
        data.put("pendingShipment", adminMapper.countPendingShipmentOrders());
        data.put("pendingAftersales", adminMapper.countPendingAftersales());
        data.put("lowStockProducts", adminMapper.countLowStockProducts(10));
        data.put("recentOrders", adminMapper.recentOrders(8));

        return ApiResponses.ok(data);
    }
}
