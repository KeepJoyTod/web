package com.web.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.json.JSONUtil;
import com.web.mapper.ProductMapper;
import com.web.pojo.Product;
import com.web.pojo.ProductMedia;
import com.web.pojo.ProductSku;
import com.web.service.ProductService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class ProductServiceImpl implements ProductService {

    @Autowired
    private ProductMapper productMapper;

    @Override
    public Product getProductById(Long id) {
        return productMapper.getById(id);
    }

    @Override
    public Map<String, Object> getProductDetail(Long id) {
        Product product = productMapper.getById(id);
        if (product == null) return null;

        // 1. 基础属性转 Map
        Map<String, Object> detail = BeanUtil.beanToMap(product, false, true);

        // 2. 获取多媒体图片列表
        List<ProductMedia> mediaList = productMapper.getMediaByProductId(id);
        List<String> mediaUrls = mediaList.stream()
                .map(ProductMedia::getUrl)
                .collect(Collectors.toList());
        detail.put("media", mediaUrls);

        // 3. 获取 SKU 列表并解析属性 JSON
        List<ProductSku> skus = productMapper.getSkusByProductId(id);
        List<Map<String, Object>> skuMaps = skus.stream().map(sku -> {
            Map<String, Object> m = BeanUtil.beanToMap(sku, false, true);
            // 将数据库存储的 JSON 字符串转为 Map 对象
            if (sku.getAttrs() != null && !sku.getAttrs().isEmpty()) {
                m.put("attrs", JSONUtil.parseObj(sku.getAttrs()));
            } else {
                m.put("attrs", Map.of());
            }
            return m;
        }).collect(Collectors.toList());
        detail.put("skus", skuMaps);

        return detail;
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
