package com.web.controller;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.map.MapUtil;
import com.web.pojo.Product;
import com.web.service.ProductService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 商品相关接口 (RESTful API)
 */
@RestController
@RequestMapping("/v1/products")
public class ProductController {

    @Autowired
    private ProductService productService;

    /**
     * 获取商品列表
     * GET /v1/products?keyword=&category=&page=&size=
     */
    @GetMapping
    public ResponseEntity<Map<String, Object>> getProducts(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Long category,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        
        List<Product> list = productService.getProductList(keyword, category, page, size);
        
        // 实体转 Map 返回，不使用 DTO
        List<Map<String, Object>> mapList = list.stream()
                .map(product -> BeanUtil.beanToMap(product, false, true))
                .collect(Collectors.toList());
                
        Map<String, Object> result = MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", 200)
                .put("message", "success")
                .put("data", mapList)
                .build();
                
        return ResponseEntity.ok(result);
    }

    /**
     * 获取商品详情
     * GET /v1/products/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> getProductById(@PathVariable Long id) {
        Product product = productService.getProductById(id);
        if (product == null) {
            return ResponseEntity.status(404).body(
                MapUtil.builder(new java.util.HashMap<String, Object>())
                    .put("code", 404)
                    .put("message", "Product not found")
                    .build()
            );
        }
        
        // 实体转 Map
        Map<String, Object> data = BeanUtil.beanToMap(product, false, true);
        
        Map<String, Object> result = MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", 200)
                .put("message", "success")
                .put("data", data)
                .build();
                
        return ResponseEntity.ok(result);
    }

    /**
     * 创建商品 (仅示例，通常在 /v1/merchant/products)
     */
    @PostMapping
    public ResponseEntity<Map<String, Object>> createProduct(@RequestBody Product product) {
        boolean success = productService.createProduct(product);
        
        Map<String, Object> result = MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", success ? 200 : 500)
                .put("message", success ? "success" : "failed")
                .put("data", BeanUtil.beanToMap(product, false, true))
                .build();
                
        return ResponseEntity.ok(result);
    }
}
