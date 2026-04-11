package com.web.mapper;

import com.web.pojo.OrderItem;
import org.apache.ibatis.annotations.Mapper;
import java.util.List;

@Mapper
public interface OrderItemMapper {
    List<OrderItem> getListByOrderId(Long orderId);
    
    int insertBatch(List<OrderItem> items);
}
