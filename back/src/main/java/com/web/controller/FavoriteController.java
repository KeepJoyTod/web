package com.web.controller;

import cn.hutool.core.map.MapUtil;
import com.web.interceptor.AuthInterceptor;
import com.web.service.FavoriteService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 商品收藏相关接口
 */
@Tag(name = "收藏管理", description = "用户收藏夹管理接口")
@RestController
@RequestMapping("/v1/favorites")
public class FavoriteController {

    @Autowired
    private FavoriteService favoriteService;

    /**
     * 获取收藏列表
     */
    @Operation(summary = "获取收藏列表", description = "获取当前用户的商品收藏列表")
    @GetMapping
    public ResponseEntity<Map<String, Object>> getFavorites() {
        Long userId = AuthInterceptor.getCurrentUserId();
        List<Map<String, Object>> list = favoriteService.getList(userId);
        
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", 200)
                .put("message", "success")
                .put("data", list)
                .build());
    }

    /**
     * 添加收藏
     */
    @Operation(summary = "添加收藏", description = "将商品添加到当前用户的收藏夹")
    @PostMapping
    public ResponseEntity<Map<String, Object>> addFavorite(@RequestBody Map<String, Object> params) {
        Long userId = AuthInterceptor.getCurrentUserId();
        Long productId = Long.valueOf(params.get("productId").toString());
        
        boolean success = favoriteService.add(userId, productId);
        
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", success ? 200 : 500)
                .put("message", success ? "success" : "failed")
                .build());
    }

    /**
     * 移除收藏 (按记录ID)
     */
    @Operation(summary = "移除收藏", description = "按收藏记录ID将其从收藏夹移除")
    @DeleteMapping("/{favId}")
    public ResponseEntity<Map<String, Object>> removeFavorite(@PathVariable Long favId) {
        Long userId = AuthInterceptor.getCurrentUserId();
        boolean success = favoriteService.remove(userId, favId);
        
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", success ? 200 : 500)
                .put("message", success ? "success" : "failed")
                .build());
    }

    /**
     * 移除收藏 (按商品ID)
     */
    @Operation(summary = "按商品ID移除收藏", description = "按商品ID将其从当前用户的收藏夹移除")
    @DeleteMapping("/product/{productId}")
    public ResponseEntity<Map<String, Object>> removeByProduct(@PathVariable Long productId) {
        Long userId = AuthInterceptor.getCurrentUserId();
        boolean success = favoriteService.removeByProduct(userId, productId);
        
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", success ? 200 : 500)
                .put("message", success ? "success" : "failed")
                .build());
    }

    /**
     * 批量移除收藏
     */
    @Operation(summary = "批量移除收藏", description = "批量将收藏项从收藏夹中移除")
    @DeleteMapping("/bulk")
    public ResponseEntity<Map<String, Object>> bulkRemoveFavorites(@RequestBody Map<String, Object> params) {
        Long userId = AuthInterceptor.getCurrentUserId();
        @SuppressWarnings("unchecked")
        List<Object> ids = (List<Object>) params.get("favIds");
        List<Long> favIds = ids.stream()
                .map(id -> Long.valueOf(id.toString()))
                .collect(Collectors.toList());
        
        boolean success = favoriteService.removeMany(userId, favIds);
        
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", success ? 200 : 500)
                .put("message", success ? "success" : "failed")
                .build());
    }
}
