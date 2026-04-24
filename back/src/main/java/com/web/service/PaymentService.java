package com.web.service;

import com.web.pojo.Payment;
import java.util.Map;

public interface PaymentService {
    
    /**
     * 发起支付
     * @param userId 当前用户
     * @param orderId 订单ID
     * @param channel 支付渠道 (alipay, wechat)
     * @return 支付所需参数 (如交易号、模拟二维码等)
     */
    Map<String, Object> initiatePayment(Long userId, Long orderId, String channel);
    
    /**
     * 获取支付状态
     */
    Payment getPaymentStatus(Long orderId, Long userId);
    
    /**
     * 处理支付网关的异步回调
     * @param tradeId 流水号
     * @param status 支付结果 (SUCCESS / FAILED)
     */
    boolean handleWebhook(String tradeId, String status);
}
