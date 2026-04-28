package com.web.controller;

import com.web.pojo.Category;
import com.web.service.CategoryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Tag(name = "类目管理", description = "商品类目查询接口")
@RestController
@RequestMapping("/v1/categories")
public class CategoryController {

    @Autowired
    private CategoryService categoryService;

    @Operation(summary = "获取所有类目", description = "获取系统中的所有商品类目")
    @GetMapping
    public ResponseEntity<Map<String, Object>> getCategories() {
        List<Category> list = categoryService.getAllCategories();
        
        Map<String, Object> result = new HashMap<>();
        result.put("code", 200);
        result.put("message", "success");
        result.put("data", list);
        
        return ResponseEntity.ok(result);
    }
}
