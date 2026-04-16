package com.web.controller;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.map.MapUtil;
import com.web.interceptor.AuthInterceptor;
import com.web.pojo.CartItem;
import com.web.dto.CartRequests;
import com.web.service.CartService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 购物车接口 (RESTful API)
 */
@RestController
@RequestMapping("/v1/cart")
public class CartController {

    @Autowired
    private CartService cartService;

    /**
     * 获取购物车列表
     * GET /v1/cart
     */
    @GetMapping
    public ResponseEntity<Map<String, Object>> getCartList() {
        Long userId = AuthInterceptor.getCurrentUserId();
        List<CartItem> list = cartService.getCartList(userId);
        
        List<Map<String, Object>> mapList = list.stream()
                .map(item -> BeanUtil.beanToMap(item, false, true))
                .collect(Collectors.toList());
                
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", 200)
                .put("message", "success")
                .put("data", mapList)
                .build());
    }

    /**
     * 添加商品到购物车
     * POST /v1/cart/items
     */
    @PostMapping("/items")
    public ResponseEntity<Map<String, Object>> addCartItem(@RequestBody CartRequests.AddItemRequest req) {
        Long userId = AuthInterceptor.getCurrentUserId();
        Long productId = req.getProductId();
        Integer quantity = req.getQuantity() == null ? 1 : req.getQuantity();
        
        boolean success = cartService.addCartItem(userId, productId, quantity);
        
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", success ? 200 : 500)
                .put("message", success ? "success" : "failed")
                .build());
    }

    /**
     * 修改购物车商品数量
     * PUT /v1/cart/items/{id}
     */
    @PutMapping("/items/{id}")
    public ResponseEntity<Map<String, Object>> updateCartItem(
            @PathVariable Long id, 
            @RequestBody CartRequests.UpdateItemRequest req) {
            
        Long userId = AuthInterceptor.getCurrentUserId();
        Integer quantity = req.getQuantity();
        boolean success = cartService.updateCartItemQuantity(userId, id, quantity);
        
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", success ? 200 : 500)
                .put("message", success ? "success" : "failed")
                .build());
    }

    /**
     * 移除购物车商品
     * DELETE /v1/cart/items/{id}
     */
    @DeleteMapping("/items/{id}")
    public ResponseEntity<Map<String, Object>> removeCartItem(@PathVariable Long id) {
        Long userId = AuthInterceptor.getCurrentUserId();
        boolean success = cartService.removeCartItem(userId, id);
        
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", success ? 200 : 500)
                .put("message", success ? "success" : "failed")
                .build());
    }
}
