package com.web.mapper;

import com.web.pojo.User;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface UserMapper {
    User getById(Long id);
    
    User getByAccount(String account);
    
    int insert(User user);
}
