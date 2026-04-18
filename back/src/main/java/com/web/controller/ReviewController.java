package com.web.controller;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.map.MapUtil;
import com.web.interceptor.AuthInterceptor;
import com.web.pojo.Review;
import com.web.service.ReviewService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/v1/reviews")
public class ReviewController {

    @Autowired
    private ReviewService reviewService;

    @PostMapping
    public ResponseEntity<Map<String, Object>> create(@RequestBody Map<String, Object> params) {
        Long userId = AuthInterceptor.getCurrentUserId();
        Long orderId = params.containsKey("orderId") ? Long.valueOf(params.get("orderId").toString()) : null;
        Long productId = params.containsKey("productId") ? Long.valueOf(params.get("productId").toString()) : null;
        Integer rating = params.containsKey("rating") ? Integer.valueOf(params.get("rating").toString()) : 5;
        String content = params.getOrDefault("content", "").toString();
        String images = params.getOrDefault("images", "[]").toString();
        
        Review r = reviewService.create(userId, orderId, productId, rating, content, images);
        Map<String, Object> meta = MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("requestId", UUID.randomUUID().toString())
                .build();
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", 200)
                .put("message", "success")
                .put("data", BeanUtil.beanToMap(r, false, true))
                .put("meta", meta)
                .build());
    }

    @GetMapping
    public ResponseEntity<Map<String, Object>> list(@RequestParam(defaultValue = "1") int page,
                                                    @RequestParam(defaultValue = "10") int size,
                                                    @RequestParam(required = false) Long productId,
                                                    @RequestParam(required = false) Long orderId) {
        Long userId = AuthInterceptor.getCurrentUserId();
        List<Review> list = reviewService.list(userId, page, size, productId, orderId);
        List<Map<String, Object>> mapList = list.stream()
                .map(x -> BeanUtil.beanToMap(x, false, true))
                .collect(Collectors.toList());
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", 200)
                .put("message", "success")
                .put("data", mapList)
                .build());
    }
}
