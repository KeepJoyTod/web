package com.web.service.impl;

import cn.hutool.core.util.IdUtil;
import com.web.exception.BusinessException;
import com.web.mapper.CartItemMapper;
import com.web.mapper.OrderItemMapper;
import com.web.mapper.OrderMapper;
import com.web.mapper.ProductMapper;
import com.web.pojo.CartItem;
import com.web.pojo.Order;
import com.web.pojo.OrderItem;
import com.web.pojo.Product;
import com.web.pojo.ProductSku;
import com.web.service.OrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class OrderServiceImpl implements OrderService {

    @Autowired
    private OrderMapper orderMapper;
    
    @Autowired
    private OrderItemMapper orderItemMapper;
    
    @Autowired
    private CartItemMapper cartItemMapper;
    
    @Autowired
    private ProductMapper productMapper;

    @Override
    public Order getOrderById(Long id) {
        return orderMapper.getById(id);
    }

    @Override
    public Order getOrderByOrderNo(String orderNo) {
        return orderMapper.getByOrderNo(orderNo);
    }

    @Override
    public List<Order> getOrderList(Long userId, int page, int size) {
        int offset = (page - 1) * size;
        return orderMapper.getListByUserId(userId, offset, size);
    }

    @Override
    public List<OrderItem> getOrderItems(Long orderId) {
        return orderItemMapper.getListByOrderId(orderId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Map<String, Object> checkout(Long userId, Long addressId, String couponCode) {
        // 1. 获取购物车选中的商品
        List<CartItem> cartItems = cartItemMapper.getListByUserId(userId);
        if (cartItems == null || cartItems.isEmpty()) {
            throw new BusinessException("CART_EMPTY", "购物车为空");
        }
        
        List<CartItem> checkedItems = cartItems.stream()
                .filter(item -> item.getChecked() == 1)
                .toList();
        if (checkedItems.isEmpty()) {
            checkedItems = cartItems;
        }
        
        BigDecimal totalAmount = BigDecimal.ZERO;
        List<OrderItem> orderItems = new ArrayList<>();
        
        // 2. 预占库存与计算价格
        for (CartItem cartItem : checkedItems) {
            if (cartItem.getQuantity() == null || cartItem.getQuantity() <= 0) {
                throw new BusinessException("INVALID_QUANTITY", "商品数量不正确");
            }

            Product product = productMapper.getById(cartItem.getProductId());
            if (product == null) {
                throw new BusinessException("PRODUCT_NOT_FOUND", "商品不存在: " + cartItem.getProductId());
            }

            BigDecimal unitPrice = product.getPrice();

            if (cartItem.getSkuId() != null) {
                ProductSku sku = productMapper.getSkuByIdAndProductId(cartItem.getSkuId(), cartItem.getProductId());
                if (sku == null) {
                    throw new BusinessException("SKU_NOT_FOUND", "商品规格不存在或不属于该商品: " + cartItem.getSkuId());
                }
                if (productMapper.decreaseSkuStock(cartItem.getSkuId(), cartItem.getProductId(), cartItem.getQuantity()) <= 0) {
                    throw new BusinessException("INSUFFICIENT_STOCK", "商品规格库存不足: " + cartItem.getSkuId());
                }
                productMapper.syncProductStockFromSkus(cartItem.getProductId());
                unitPrice = sku.getPrice();
            } else {
                List<ProductSku> skus = productMapper.getSkusByProductId(cartItem.getProductId());
                if (skus != null && !skus.isEmpty()) {
                    throw new BusinessException("SKU_REQUIRED", "请选择商品规格: " + cartItem.getProductId());
                }
                if (productMapper.decreaseProductStock(cartItem.getProductId(), cartItem.getQuantity()) <= 0) {
                    throw new BusinessException("INSUFFICIENT_STOCK", "商品库存不足: " + cartItem.getProductId());
                }
            }

            BigDecimal itemTotal = unitPrice.multiply(new BigDecimal(cartItem.getQuantity()));
            totalAmount = totalAmount.add(itemTotal);
            
            OrderItem orderItem = new OrderItem();
            orderItem.setProductId(product.getId());
            orderItem.setSkuId(cartItem.getSkuId());
            orderItem.setProductName(product.getName());
            orderItem.setPrice(unitPrice);
            orderItem.setQuantity(cartItem.getQuantity());
            orderItem.setTotalAmount(itemTotal);
            orderItem.setProductImage("/product_" + product.getId() + ".jpg"); // 设置商品图片
            orderItems.add(orderItem);
        }
        
        BigDecimal payAmount = totalAmount;
        
        // 4. 生成订单
        Order order = new Order();
        order.setUserId(userId);
        order.setOrderNo(IdUtil.getSnowflakeNextIdStr());
        order.setTotalAmount(totalAmount);
        order.setPayAmount(payAmount); 
        order.setStatus(0); // 待支付
        order.setAddressId(addressId);
        
        orderMapper.insert(order);
        
        // 5. 保存订单明细
        for (OrderItem item : orderItems) {
            item.setOrderId(order.getId());
        }
        orderItemMapper.insertBatch(orderItems);
        
        // 6. 清空购物车
        cartItemMapper.clearCheckedByUserId(userId);
        
        Map<String, Object> result = new HashMap<>();
        result.put("order", order);
        result.put("orderItems", orderItems);
        return result;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean cancelOrder(Long id, Long userId) {
        Order order = orderMapper.getById(id);
        if (order != null && order.getUserId().equals(userId) && order.getStatus() == 0) {
            return orderMapper.updateStatus(id, 4) > 0; // 4: 已取消
        }
        return false;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean updateOrderStatus(Long id, Integer status) {
        Order order = orderMapper.getById(id);
        if (order == null) return false;
        
        // 如果已经是目标状态，则不需要重复操作
        if (order.getStatus().equals(status)) return true;

        boolean success = orderMapper.updateStatus(id, status) > 0;
        
        // 如果状态更新为已支付 (1)，则增加商品销量
        if (success && status == 1) {
            List<OrderItem> items = orderItemMapper.getListByOrderId(id);
            for (OrderItem item : items) {
                Product product = productMapper.getById(item.getProductId());
                if (product != null) {
                    product.setSold((product.getSold() != null ? product.getSold() : 0) + item.getQuantity());
                    productMapper.update(product);
                }
            }
        }
        
        return success;
    }
}
