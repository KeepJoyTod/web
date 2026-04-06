package com.web.service.impl;

import cn.hutool.core.util.IdUtil;
import com.web.mapper.CartItemMapper;
import com.web.mapper.OrderItemMapper;
import com.web.mapper.OrderMapper;
import com.web.mapper.ProductMapper;
import com.web.pojo.CartItem;
import com.web.pojo.Order;
import com.web.pojo.OrderItem;
import com.web.pojo.Product;
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
            throw new RuntimeException("Cart is empty");
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
            Product product = productMapper.getById(cartItem.getProductId());
            if (product == null || product.getStock() < cartItem.getQuantity()) {
                throw new RuntimeException("Insufficient stock for product: " + cartItem.getProductId());
            }
            
            // 简单扣减库存
            product.setStock(product.getStock() - cartItem.getQuantity());
            productMapper.update(product);
            
            BigDecimal itemTotal = product.getPrice().multiply(new BigDecimal(cartItem.getQuantity()));
            totalAmount = totalAmount.add(itemTotal);
            
            OrderItem orderItem = new OrderItem();
            orderItem.setProductId(product.getId());
            orderItem.setProductName(product.getName());
            orderItem.setPrice(product.getPrice());
            orderItem.setQuantity(cartItem.getQuantity());
            orderItem.setTotalAmount(itemTotal);
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
        return orderMapper.updateStatus(id, status) > 0;
    }
}
