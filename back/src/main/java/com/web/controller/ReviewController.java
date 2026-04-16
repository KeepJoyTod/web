package com.web.controller;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.map.MapUtil;
import com.web.interceptor.AuthInterceptor;
import com.web.dto.ReviewRequests;
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
    public ResponseEntity<Map<String, Object>> create(@RequestBody ReviewRequests.CreateRequest req) {
        Long userId = AuthInterceptor.getCurrentUserId();
        Long orderId = req.getOrderId();
        Long productId = req.getProductId();
        Integer rating = req.getRating();
        String content = req.getContent() == null ? "" : req.getContent();
        String images = req.getImages() == null ? "[]" : req.getImages();
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
