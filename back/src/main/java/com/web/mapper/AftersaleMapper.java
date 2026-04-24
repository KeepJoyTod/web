package com.web.mapper;

import com.web.pojo.Aftersale;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface AftersaleMapper {
    List<Aftersale> getListByUserId(@Param("userId") Long userId, @Param("offset") int offset, @Param("limit") int limit);
    
    Aftersale getByIdAndUserId(@Param("id") Long id, @Param("userId") Long userId);
    
    int insert(Aftersale aftersale);
    
    int updateStatus(@Param("id") Long id, @Param("status") String status);
}
