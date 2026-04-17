package com.web.controller;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.map.MapUtil;
import com.web.interceptor.AuthInterceptor;
import com.web.pojo.CartItem;
import com.web.dto.CartRequests;
import com.web.service.CartService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Tag(name = "购物车管理", description = "添加、删除、更新购物车项")
@RestController
@RequestMapping("/v1/cart")
public class CartController {

    @Autowired
    private CartService cartService;

    @Operation(summary = "获取购物车", description = "获取当前登录用户的购物车清单")
    @GetMapping
    public ResponseEntity<Map<String, Object>> getCart(@RequestAttribute("userId") Long userId) {
        List<CartItem> items = cartService.getCartList(userId);
        
        List<Map<String, Object>> data = items.stream()
                .map(item -> BeanUtil.beanToMap(item, false, true))
                .collect(Collectors.toList());
                
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("data", data)
                .build());
    }

    @Operation(summary = "添加商品到购物车", description = "将指定商品及数量加入购物车")
    @PostMapping
    public ResponseEntity<Map<String, Object>> addToCart(
            @RequestAttribute("userId") Long userId,
            @RequestBody CartRequests.AddItemRequest req) {
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
