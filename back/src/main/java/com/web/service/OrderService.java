package com.web.service;

import com.web.pojo.Order;
import com.web.pojo.OrderItem;
import java.util.List;
import java.util.Map;

public interface OrderService {
    Order getOrderById(Long id);
    
    Order getOrderByOrderNo(String orderNo);
    
    List<Order> getOrderList(Long userId, int page, int size);
    
    List<OrderItem> getOrderItems(Long orderId);
    
    // 简化的下单逻辑，支持传入优惠券码，返回包含 order 和 orderItems 的 map
    Map<String, Object> checkout(Long userId, Long addressId, String couponCode);
    
    boolean cancelOrder(Long id, Long userId);
    
    // 更新订单状态 (供支付回调使用)
    boolean updateOrderStatus(Long id, Integer status);
}
