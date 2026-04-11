package com.web.mapper;

import com.web.pojo.Order;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface OrderMapper {
    Order getById(Long id);
    
    Order getByOrderNo(String orderNo);
    
    List<Order> getListByUserId(@Param("userId") Long userId, @Param("offset") int offset, @Param("limit") int limit);
    
    int insert(Order order);
    
    int updateStatus(@Param("id") Long id, @Param("status") Integer status);
}
