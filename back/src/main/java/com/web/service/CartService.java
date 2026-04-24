package com.web.service;

import com.web.pojo.CartItem;
import java.util.List;

public interface CartService {
    List<CartItem> getCartList(Long userId);
    
    boolean addCartItem(Long userId, Long productId, Long skuId, Integer quantity);
    
    boolean updateCartItemQuantity(Long userId, Long cartItemId, Integer quantity);
    
    boolean removeCartItem(Long userId, Long cartItemId);
    
    boolean clearCheckedCart(Long userId);
}
