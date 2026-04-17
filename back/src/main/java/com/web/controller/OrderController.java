package com.web.controller;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.map.MapUtil;
import com.web.interceptor.AuthInterceptor;
import com.web.dto.OrderRequests;
import com.web.pojo.Order;
import com.web.pojo.OrderItem;
import com.web.service.OrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 订单接口 (RESTful API)
 */
@RestController
@RequestMapping("/v1/orders")
public class OrderController {

    @Autowired
    private OrderService orderService;

    /**
     * 下单 (结算购物车选中的商品)
     * POST /v1/orders/checkout
     */
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

    /**
     * 获取订单列表
     * GET /v1/orders
     */
    @GetMapping
    public ResponseEntity<Map<String, Object>> getOrders(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
            
        Long userId = AuthInterceptor.getCurrentUserId();
        List<Order> list = orderService.getOrderList(userId, page, size);
        
        List<Map<String, Object>> mapList = list.stream()
                .map(order -> BeanUtil.beanToMap(order, false, true))
                .collect(Collectors.toList());
                
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", 200)
                .put("message", "success")
                .put("data", mapList)
                .build());
    }

    /**
     * 获取订单详情
     * GET /v1/orders/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> getOrderById(@PathVariable Long id) {
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
