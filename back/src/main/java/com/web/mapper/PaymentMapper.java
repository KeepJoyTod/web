package com.web.mapper;

import com.web.pojo.Payment;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface PaymentMapper {
    Payment getByOrderId(Long orderId);
    
    Payment getByTradeId(String tradeId);
    
    int insert(Payment payment);
    
    int updateStatus(@Param("tradeId") String tradeId, @Param("status") String status, @Param("paidAt") java.time.LocalDateTime paidAt);
}
