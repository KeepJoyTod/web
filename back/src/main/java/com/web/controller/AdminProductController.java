package com.web.controller;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.json.JSONUtil;
import com.web.exception.BusinessException;
import com.web.mapper.AdminMapper;
import com.web.mapper.ProductMapper;
import com.web.pojo.Product;
import com.web.pojo.ProductMedia;
import com.web.pojo.ProductSku;
import com.web.util.ApiResponses;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/v1/admin/products")
public class AdminProductController {

    @Autowired
    private AdminMapper adminMapper;

    @Autowired
    private ProductMapper productMapper;

    @GetMapping
    public ResponseEntity<Map<String, Object>> list(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        int safePage = Math.max(page, 1);
        int safeSize = Math.min(Math.max(size, 1), 100);
        int offset = (safePage - 1) * safeSize;

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("items", adminMapper.listProducts(keyword, categoryId, status, offset, safeSize));
        data.put("total", adminMapper.countProductList(keyword, categoryId, status));
        data.put("page", safePage);
        data.put("size", safeSize);
        return ApiResponses.ok(data);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> detail(@PathVariable Long id) {
        Product product = adminMapper.getProductById(id);
        if (product == null) {
            throw new BusinessException("NOT_FOUND", "商品不存在");
        }
        return ApiResponses.ok(toDetailMap(product));
    }

    @PostMapping
    @CacheEvict(value = {"product_detail", "product_list"}, allEntries = true)
    @Transactional(rollbackFor = Exception.class)
    public ResponseEntity<Map<String, Object>> create(@RequestBody Map<String, Object> body) {
        Product product = toProduct(body);
        if (product.getStatus() == null) {
            product.setStatus(1);
        }
        if (product.getStock() == null) {
            product.setStock(0);
        }
        if (product.getSold() == null) {
            product.setSold(0);
        }
        if (product.getRating() == null) {
            product.setRating(new BigDecimal("4.5"));
        }

        productMapper.insert(product);
        replaceMediaAndSkus(product.getId(), body, true);

        Product created = adminMapper.getProductById(product.getId());
        return ApiResponses.ok(toDetailMap(created));
    }

    @PutMapping("/{id}")
    @CacheEvict(value = {"product_detail", "product_list"}, allEntries = true)
    @Transactional(rollbackFor = Exception.class)
    public ResponseEntity<Map<String, Object>> update(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Product existing = adminMapper.getProductById(id);
        if (existing == null) {
            throw new BusinessException("NOT_FOUND", "商品不存在");
        }

        Product product = toProduct(body);
        product.setId(id);
        productMapper.update(product);
        replaceMediaAndSkus(id, body, false);

        Product updated = adminMapper.getProductById(id);
        return ApiResponses.ok(toDetailMap(updated));
    }

    @PutMapping("/{id}/status")
    @CacheEvict(value = {"product_detail", "product_list"}, allEntries = true)
    public ResponseEntity<Map<String, Object>> updateStatus(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Integer status = toInteger(body.get("status"));
        if (status == null || (status != 0 && status != 1)) {
            throw new BusinessException("VALIDATION_FAILED", "商品状态只能是 0 或 1");
        }
        Product product = new Product();
        product.setId(id);
        product.setStatus(status);
        productMapper.update(product);
        return ApiResponses.ok();
    }

    @DeleteMapping("/{id}")
    @CacheEvict(value = {"product_detail", "product_list"}, allEntries = true)
    public ResponseEntity<Map<String, Object>> delete(@PathVariable Long id) {
        productMapper.delete(id);
        return ApiResponses.ok();
    }

    private Map<String, Object> toDetailMap(Product product) {
        Map<String, Object> detail = BeanUtil.beanToMap(product, false, true);
        List<ProductMedia> media = adminMapper.listProductMedia(product.getId());
        List<ProductSku> skus = adminMapper.listProductSkus(product.getId());
        detail.put("mediaList", media);
        detail.put("media", media.stream().map(ProductMedia::getUrl).collect(Collectors.toList()));
        detail.put("skus", skus.stream().map(this::skuToMap).collect(Collectors.toList()));
        return detail;
    }

    private Map<String, Object> skuToMap(ProductSku sku) {
        Map<String, Object> map = BeanUtil.beanToMap(sku, false, true);
        if (sku.getAttrs() != null && !sku.getAttrs().isBlank()) {
            try {
                map.put("attrs", JSONUtil.parseObj(sku.getAttrs()));
            } catch (Exception e) {
                map.put("attrs", sku.getAttrs());
            }
        }
        return map;
    }

    private void replaceMediaAndSkus(Long productId, Map<String, Object> body, boolean creating) {
        if (creating || body.containsKey("media")) {
            adminMapper.deleteProductMediaByProductId(productId);
            for (ProductMedia media : parseMedia(productId, body.get("media"))) {
                adminMapper.insertProductMedia(media);
            }
        }

        if (creating || body.containsKey("skus")) {
            adminMapper.deleteProductSkuByProductId(productId);
            for (ProductSku sku : parseSkus(productId, body.get("skus"))) {
                adminMapper.insertProductSku(sku);
            }
        }
    }

    private List<ProductMedia> parseMedia(Long productId, Object raw) {
        List<ProductMedia> media = new ArrayList<>();
        if (!(raw instanceof List<?> list)) {
            return media;
        }
        int index = 0;
        for (Object item : list) {
            String url = null;
            if (item instanceof Map<?, ?> itemMap) {
                Object value = itemMap.get("url");
                url = value == null ? null : value.toString();
            } else if (item != null) {
                url = item.toString();
            }
            if (url != null && !url.isBlank()) {
                ProductMedia productMedia = new ProductMedia();
                productMedia.setProductId(productId);
                productMedia.setUrl(url.trim());
                productMedia.setSortOrder(index++);
                media.add(productMedia);
            }
        }
        return media;
    }

    private List<ProductSku> parseSkus(Long productId, Object raw) {
        List<ProductSku> skus = new ArrayList<>();
        if (!(raw instanceof List<?> list)) {
            return skus;
        }
        for (Object item : list) {
            if (!(item instanceof Map<?, ?> itemMap)) {
                continue;
            }
            BigDecimal price = toBigDecimal(itemMap.get("price"));
            Integer stock = toInteger(itemMap.get("stock"));
            if (price == null || stock == null) {
                continue;
            }

            ProductSku sku = new ProductSku();
            sku.setProductId(productId);
            Object attrs = itemMap.get("attrs");
            sku.setAttrs(attrs instanceof String ? attrs.toString() : JSONUtil.toJsonStr(attrs == null ? Map.of() : attrs));
            sku.setPrice(price);
            sku.setStock(stock);
            skus.add(sku);
        }
        return skus;
    }

    private Product toProduct(Map<String, Object> body) {
        Product product = new Product();
        product.setCategoryId(toLong(body.get("categoryId")));
        product.setName(toStringValue(body.get("name")));
        product.setDescription(toStringValue(body.get("description")));
        product.setTags(toStringValue(body.get("tags")));
        product.setRating(toBigDecimal(body.get("rating")));
        product.setSold(toInteger(body.get("sold")));
        product.setActivityLabel(toStringValue(body.get("activityLabel")));
        product.setOriginalPrice(toBigDecimal(body.get("originalPrice")));
        product.setPrice(toBigDecimal(body.get("price")));
        product.setStock(toInteger(body.get("stock")));
        product.setStatus(toInteger(body.get("status")));
        return product;
    }

    private String toStringValue(Object value) {
        return value == null ? null : value.toString();
    }

    private Long toLong(Object value) {
        if (value == null || value.toString().isBlank()) {
            return null;
        }
        return Long.valueOf(value.toString());
    }

    private Integer toInteger(Object value) {
        if (value == null || value.toString().isBlank()) {
            return null;
        }
        return Integer.valueOf(value.toString());
    }

    private BigDecimal toBigDecimal(Object value) {
        if (value == null || value.toString().isBlank()) {
            return null;
        }
        return new BigDecimal(value.toString());
    }
}
