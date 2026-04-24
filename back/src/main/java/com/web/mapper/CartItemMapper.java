package com.web.mapper;

import com.web.pojo.CartItem;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface CartItemMapper {
    List<CartItem> getListByUserId(Long userId);
    
    CartItem getByUserIdAndProductId(@Param("userId") Long userId, @Param("productId") Long productId, @Param("skuId") Long skuId);
    
    int insert(CartItem cartItem);
    
    int update(CartItem cartItem);
    
    int delete(@Param("userId") Long userId, @Param("id") Long id);
    
    int clearCheckedByUserId(Long userId);
}
