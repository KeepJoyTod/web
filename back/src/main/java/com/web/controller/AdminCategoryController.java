package com.web.controller;

import com.web.exception.BusinessException;
import com.web.mapper.AdminMapper;
import com.web.pojo.Category;
import com.web.util.ApiResponses;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/v1/admin/categories")
public class AdminCategoryController {

    @Autowired
    private AdminMapper adminMapper;

    @GetMapping
    public ResponseEntity<Map<String, Object>> list() {
        return ApiResponses.ok(adminMapper.listCategories());
    }

    @PostMapping
    public ResponseEntity<Map<String, Object>> create(@RequestBody Map<String, Object> body) {
        String name = body.get("name") == null ? "" : body.get("name").toString().trim();
        if (name.isEmpty()) {
            throw new BusinessException("VALIDATION_FAILED", "分类名称不能为空");
        }

        Category category = new Category();
        category.setName(name);
        category.setParentId(toLong(body.get("parentId"), 0L));
        adminMapper.insertCategory(category);
        return ApiResponses.ok(category);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Map<String, Object>> update(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        String name = body.get("name") == null ? "" : body.get("name").toString().trim();
        if (name.isEmpty()) {
            throw new BusinessException("VALIDATION_FAILED", "分类名称不能为空");
        }

        Category category = new Category();
        category.setId(id);
        category.setName(name);
        category.setParentId(toLong(body.get("parentId"), 0L));
        adminMapper.updateCategory(category);
        return ApiResponses.ok(category);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, Object>> delete(@PathVariable Long id) {
        adminMapper.deleteCategory(id);
        return ApiResponses.ok();
    }

    private Long toLong(Object value, Long defaultValue) {
        if (value == null || value.toString().isBlank()) {
            return defaultValue;
        }
        return Long.valueOf(value.toString());
    }
}
