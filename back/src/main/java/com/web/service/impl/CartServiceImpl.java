package com.web.service.impl;

import com.web.exception.BusinessException;
import com.web.mapper.CartItemMapper;
import com.web.mapper.ProductMapper;
import com.web.pojo.CartItem;
import com.web.pojo.Product;
import com.web.pojo.ProductSku;
import com.web.service.CartService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class CartServiceImpl implements CartService {

    @Autowired
    private CartItemMapper cartItemMapper;

    @Autowired
    private ProductMapper productMapper;

    @Override
    public List<CartItem> getCartList(Long userId) {
        return cartItemMapper.getListByUserId(userId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean addCartItem(Long userId, Long productId, Long skuId, Integer quantity) {
        if (quantity == null || quantity <= 0) {
            throw new BusinessException("INVALID_QUANTITY", "商品数量不正确");
        }

        Product product = productMapper.getById(productId);
        if (product == null) {
            throw new BusinessException("PRODUCT_NOT_FOUND", "商品不存在");
        }

        CartItem existing = cartItemMapper.getByUserIdAndProductId(userId, productId, skuId);
        int targetQuantity = existing == null ? quantity : existing.getQuantity() + quantity;

        if (skuId != null) {
            ProductSku sku = productMapper.getSkuByIdAndProductId(skuId, productId);
            if (sku == null) {
                throw new BusinessException("SKU_NOT_FOUND", "商品规格不存在或不属于该商品");
            }
            if (sku.getStock() == null || sku.getStock() < targetQuantity) {
                throw new BusinessException("INSUFFICIENT_STOCK", "商品规格库存不足");
            }
        } else {
            List<ProductSku> skus = productMapper.getSkusByProductId(productId);
            if (skus != null && !skus.isEmpty()) {
                throw new BusinessException("SKU_REQUIRED", "请选择商品规格");
            }
            if (product.getStock() == null || product.getStock() < targetQuantity) {
                throw new BusinessException("INSUFFICIENT_STOCK", "商品库存不足");
            }
        }

        if (existing != null) {
            existing.setQuantity(targetQuantity);
            return cartItemMapper.update(existing) > 0;
        } else {
            CartItem item = new CartItem();
            item.setUserId(userId);
            item.setProductId(productId);
            item.setSkuId(skuId);
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
