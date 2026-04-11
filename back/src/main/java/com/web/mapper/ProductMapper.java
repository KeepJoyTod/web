package com.web.mapper;

import com.web.pojo.Product;
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
}
