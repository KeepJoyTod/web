package com.web.service;

import com.web.pojo.Product;
import java.util.List;
import java.util.Map;

public interface ProductService {
    Product getProductById(Long id);
    // 获取包含聚合数据的详情
    Map<String, Object> getProductDetail(Long id);
    List<Product> getProductList(String keyword, Long categoryId, int page, int size);
    boolean createProduct(Product product);
    boolean updateProduct(Product product);
    boolean deleteProduct(Long id);
}
