package com.web.service.impl;

import com.web.mapper.CartItemMapper;
import com.web.pojo.CartItem;
import com.web.service.CartService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class CartServiceImpl implements CartService {

    @Autowired
    private CartItemMapper cartItemMapper;

    @Override
    public List<CartItem> getCartList(Long userId) {
        return cartItemMapper.getListByUserId(userId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean addCartItem(Long userId, Long productId, Integer quantity) {
        CartItem existing = cartItemMapper.getByUserIdAndProductId(userId, productId);
        if (existing != null) {
            existing.setQuantity(existing.getQuantity() + quantity);
            return cartItemMapper.update(existing) > 0;
        } else {
            CartItem item = new CartItem();
            item.setUserId(userId);
            item.setProductId(productId);
            item.setQuantity(quantity);
            item.setChecked(1);
            return cartItemMapper.insert(item) > 0;
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean updateCartItemQuantity(Long userId, Long cartItemId, Integer quantity) {
        CartItem item = new CartItem();
        item.setId(cartItemId);
        item.setUserId(userId);
        item.setQuantity(quantity);
        return cartItemMapper.update(item) > 0;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean removeCartItem(Long userId, Long cartItemId) {
        return cartItemMapper.delete(userId, cartItemId) > 0;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean clearCheckedCart(Long userId) {
        return cartItemMapper.clearCheckedByUserId(userId) > 0;
    }
}
