package com.web.mapper;

import com.web.pojo.Product;
import com.web.pojo.ProductMedia;
import com.web.pojo.ProductSku;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface ProductMapper {
    Product getById(Long id);
    
    List<Product> getList(
        @Param("keyword") String keyword, 
        @Param("categoryId") Long categoryId, 
        @Param("offset") int offset, 
        @Param("limit") int limit
    );
    
    int insert(Product product);
    int update(Product product);
    int delete(Long id);

    // 获取商品的媒体图片
    List<ProductMedia> getMediaByProductId(Long productId);

    // 获取商品的 SKU 列表
    List<ProductSku> getSkusByProductId(Long productId);

    // 获取特定 SKU
    ProductSku getSkuById(Long skuId);

    // 更新 SKU (用于扣减库存)
    int updateSku(ProductSku sku);
}
