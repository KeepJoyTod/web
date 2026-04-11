package com.web.service;

import com.web.pojo.Product;
import java.util.List;

public interface ProductService {
    Product getProductById(Long id);
    List<Product> getProductList(String keyword, Long categoryId, int page, int size);
    boolean createProduct(Product product);
    boolean updateProduct(Product product);
    boolean deleteProduct(Long id);
}
