package com.web.mapper;

import com.web.pojo.UserAddress;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface UserAddressMapper {
    List<UserAddress> getListByUserId(Long userId);
    
    UserAddress getByIdAndUserId(@Param("id") Long id, @Param("userId") Long userId);
    
    int insert(UserAddress address);
    
    int update(UserAddress address);
    
    int delete(@Param("id") Long id, @Param("userId") Long userId);
    
    int clearDefaultStatus(Long userId);
}
