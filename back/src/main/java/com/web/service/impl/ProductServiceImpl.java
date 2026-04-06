package com.web.service.impl;

import com.web.mapper.ProductMapper;
import com.web.pojo.Product;
import com.web.service.ProductService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class ProductServiceImpl implements ProductService {

    @Autowired
    private ProductMapper productMapper;

    @Override
    public Product getProductById(Long id) {
        return productMapper.getById(id);
    }

    @Override
    public List<Product> getProductList(String keyword, Long categoryId, int page, int size) {
        int offset = (page - 1) * size;
        return productMapper.getList(keyword, categoryId, offset, size);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean createProduct(Product product) {
        product.setStatus(1); // 默认上架
        return productMapper.insert(product) > 0;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean updateProduct(Product product) {
        return productMapper.update(product) > 0;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean deleteProduct(Long id) {
        return productMapper.delete(id) > 0;
    }
}
