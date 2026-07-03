package com.web.controller;

import com.web.exception.BusinessException;
import com.web.mapper.AdminMapper;
import com.web.util.ApiResponses;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/v1/admin/orders")
public class AdminOrderController {

    @Autowired
    private AdminMapper adminMapper;

    @GetMapping
    public ResponseEntity<Map<String, Object>> list(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) String dateFrom,
            @RequestParam(required = false) String dateTo,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        int safePage = Math.max(page, 1);
        int safeSize = Math.min(Math.max(size, 1), 100);
        int offset = (safePage - 1) * safeSize;

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("items", adminMapper.listOrders(keyword, status, dateFrom, dateTo, offset, safeSize));
        data.put("total", adminMapper.countOrderList(keyword, status, dateFrom, dateTo));
        data.put("page", safePage);
        data.put("size", safeSize);
        return ApiResponses.ok(data);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> detail(@PathVariable Long id) {
        Map<String, Object> order = adminMapper.getOrderDetail(id);
        if (order == null) {
            throw new BusinessException("NOT_FOUND", "订单不存在");
        }

        Object addressId = order.get("addressId");
        order.put("items", adminMapper.listOrderItems(id));
        order.put("payment", adminMapper.getOrderPayment(id));
        if (addressId != null) {
            order.put("address", adminMapper.getOrderAddress(Long.valueOf(addressId.toString())));
        }
        return ApiResponses.ok(order);
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<Map<String, Object>> updateStatus(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Integer status = toInteger(body.get("status"));
        if (status == null || status < 0 || status > 4) {
            throw new BusinessException("VALIDATION_FAILED", "订单状态不合法");
        }
        adminMapper.updateOrderStatus(id, status);
        return ApiResponses.ok();
    }

    @PostMapping("/{id}/ship")
    public ResponseEntity<Map<String, Object>> ship(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        String company = body.get("logisticsCompany") == null ? "" : body.get("logisticsCompany").toString().trim();
        String no = body.get("logisticsNo") == null ? "" : body.get("logisticsNo").toString().trim();
        if (company.isEmpty() || no.isEmpty()) {
            throw new BusinessException("VALIDATION_FAILED", "物流公司和物流单号不能为空");
        }
        adminMapper.shipOrder(id, company, no);
        return ApiResponses.ok();
    }

    private Integer toInteger(Object value) {
        if (value == null || value.toString().isBlank()) {
            return null;
        }
        return Integer.valueOf(value.toString());
    }
}
