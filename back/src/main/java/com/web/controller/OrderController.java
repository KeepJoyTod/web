package com.web.controller;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.map.MapUtil;
import com.web.interceptor.AuthInterceptor;
import com.web.dto.OrderRequests;
import com.web.pojo.Order;
import com.web.pojo.OrderItem;
import com.web.service.OrderService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Tag(name = "订单管理", description = "订单查询、下单及状态流转")
@RestController
@RequestMapping("/v1/orders")
public class OrderController {

    @Autowired
    private OrderService orderService;

    @Operation(summary = "提交订单", description = "根据购物车项创建新订单")
    @PostMapping("/checkout")
    public ResponseEntity<Map<String, Object>> checkout(@RequestBody OrderRequests.CheckoutRequest req) {
        Long userId = AuthInterceptor.getCurrentUserId();
        Long addressId = req.getAddressId() == null ? 0L : req.getAddressId();
        String couponCode = req.getCouponCode() == null ? "" : req.getCouponCode();
        
        try {
            Map<String, Object> checkoutResult = orderService.checkout(userId, addressId, couponCode);
            
            Order order = (Order) checkoutResult.get("order");
            @SuppressWarnings("unchecked")
            List<OrderItem> items = (List<OrderItem>) checkoutResult.get("orderItems");
            
            // 实体转 Map
            Map<String, Object> orderMap = BeanUtil.beanToMap(order, false, true);
            List<Map<String, Object>> itemsMap = items.stream()
                    .map(item -> BeanUtil.beanToMap(item, false, true))
                    .collect(Collectors.toList());
            orderMap.put("items", itemsMap);
            
            return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                    .put("code", 200)
                    .put("message", "success")
                    .put("data", orderMap)
                    .build());
                    
        } catch (Exception e) {
            return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                    .put("code", 500)
                    .put("message", e.getMessage())
                    .build());
        }
    }

    @Operation(summary = "获取用户订单列表", description = "获取当前登录用户的所有订单")
    @GetMapping
    public ResponseEntity<Map<String, Object>> getMyOrders(@RequestAttribute("userId") Long userId) {
        List<Order> orders = orderService.getOrderList(userId, 1, 100);
        
        List<Map<String, Object>> data = orders.stream()
                .map(o -> BeanUtil.beanToMap(o, false, true))
                .collect(Collectors.toList());
                
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("data", data)
                .build());
    }

    @Operation(summary = "获取订单详情", description = "根据订单ID获取订单及其商品详情")
    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> getOrderDetail(@PathVariable Long id) {
        Long userId = AuthInterceptor.getCurrentUserId();
        Order order = orderService.getOrderById(id);
        if (order == null || !order.getUserId().equals(userId)) {
            return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                    .put("code", 404)
                    .put("message", "Order not found")
                    .build());
        }
        
        List<OrderItem> items = orderService.getOrderItems(id);
        
        Map<String, Object> orderMap = BeanUtil.beanToMap(order, false, true);
        List<Map<String, Object>> itemsMap = items.stream()
                .map(item -> BeanUtil.beanToMap(item, false, true))
                .collect(Collectors.toList());
        orderMap.put("items", itemsMap);
        
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", 200)
                .put("message", "success")
                .put("data", orderMap)
                .build());
    }

    /**
     * 取消订单
     * POST /v1/orders/{id}/cancel
     */
    @PostMapping("/{id}/cancel")
    public ResponseEntity<Map<String, Object>> cancelOrder(@PathVariable Long id) {
        Long userId = AuthInterceptor.getCurrentUserId();
        boolean success = orderService.cancelOrder(id, userId);
        
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", success ? 200 : 500)
                .put("message", success ? "success" : "failed")
                .build());
    }
}
