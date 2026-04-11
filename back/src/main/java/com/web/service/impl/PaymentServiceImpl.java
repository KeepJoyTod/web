package com.web.service.impl;

import cn.hutool.core.util.IdUtil;
import com.web.exception.BusinessException;
import com.web.mapper.PaymentMapper;
import com.web.pojo.Order;
import com.web.pojo.Payment;
import com.web.service.OrderService;
import com.web.service.PaymentService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@Service
public class PaymentServiceImpl implements PaymentService {

    @Autowired
    private PaymentMapper paymentMapper;
    
    @Autowired
    private OrderService orderService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Map<String, Object> initiatePayment(Long userId, Long orderId, String channel) {
        Order order = orderService.getOrderById(orderId);
        if (order == null || !order.getUserId().equals(userId)) {
            throw new BusinessException("ORDER_NOT_FOUND", "订单不存在");
        }
        if (order.getStatus() != 0) { // 0: 待支付
            throw new BusinessException("ORDER_STATE_INVALID", "订单状态不允许支付");
        }
        
        // 检查是否已有待支付记录，防止重复创建 (简单的幂等处理)
        Payment existing = paymentMapper.getByOrderId(orderId);
        if (existing != null && "SUCCESS".equals(existing.getStatus())) {
            throw new BusinessException("PAYMENT_FAILED", "订单已支付，请勿重复操作");
        }
        
        String tradeId = "TRD" + IdUtil.getSnowflakeNextIdStr();
        
        Payment payment = new Payment();
        payment.setOrderId(orderId);
        payment.setTradeId(tradeId);
        payment.setChannel(channel);
        payment.setAmount(order.getPayAmount());
        payment.setStatus("PENDING");
        
        paymentMapper.insert(payment);
        
        // 模拟返回给前端的支付网关参数
        Map<String, Object> result = new HashMap<>();
        result.put("tradeId", tradeId);
        result.put("channel", channel);
        result.put("qr", "https://mock-payment-gateway.com/qr/" + tradeId);
        result.put("expiresAt", LocalDateTime.now().plusMinutes(30));
        
        return result;
    }

    @Override
    public Payment getPaymentStatus(Long orderId, Long userId) {
        Order order = orderService.getOrderById(orderId);
        if (order == null || !order.getUserId().equals(userId)) {
            throw new BusinessException("ORDER_NOT_FOUND", "订单不存在");
        }
        return paymentMapper.getByOrderId(orderId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean handleWebhook(String tradeId, String status) {
        Payment payment = paymentMapper.getByTradeId(tradeId);
        if (payment == null) {
            return false;
        }
        // 幂等校验，如果已经处理过，直接返回成功
        if (!"PENDING".equals(payment.getStatus())) {
            return true;
        }
        
        LocalDateTime paidAt = "SUCCESS".equals(status) ? LocalDateTime.now() : null;
        int rows = paymentMapper.updateStatus(tradeId, status, paidAt);
        
        // 支付成功，联动更新订单状态为已支付 (1: 已支付)
        if (rows > 0 && "SUCCESS".equals(status)) {
            orderService.updateOrderStatus(payment.getOrderId(), 1);
        }
        
        return rows > 0;
    }
}
