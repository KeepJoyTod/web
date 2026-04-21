package com.web.controller;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.map.MapUtil;
import com.web.pojo.Product;
import com.web.service.ProductService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 商品相关接口 (RESTful API)
 */
@Tag(name = "商品管理", description = "商品查询与管理接口")
@RestController
@RequestMapping("/v1/products")
public class ProductController {

    @Autowired
    private ProductService productService;

    /**
     * 获取商品列表
     * GET /v1/products?keyword=&category=&page=&size=
     */
    @Operation(summary = "获取商品列表", description = "根据关键词、类目分页获取商品列表")
    @GetMapping
    public ResponseEntity<Map<String, Object>> getProducts(
            @Parameter(description = "搜索关键词") @RequestParam(required = false) String keyword,
            @Parameter(description = "类目ID") @RequestParam(required = false) Long category,
            @Parameter(description = "页码") @RequestParam(defaultValue = "1") int page,
            @Parameter(description = "每页数量") @RequestParam(defaultValue = "10") int size) {
        
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
    @Operation(summary = "获取商品详情", description = "根据商品ID获取详细信息")
    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> getProductById(@Parameter(description = "商品ID") @PathVariable Long id) {
        Map<String, Object> data = productService.getProductDetail(id);
        if (data == null) {
            return ResponseEntity.status(404).body(
                MapUtil.builder(new java.util.HashMap<String, Object>())
                    .put("code", 404)
                    .put("message", "Product not found")
                    .build()
            );
        }
        
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
    @Operation(summary = "创建商品", description = "创建新商品（仅限管理员/示例）")
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
