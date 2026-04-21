package com.web.mapper;

import com.web.pojo.Favorite;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;
import java.util.Map;

@Mapper
public interface FavoriteMapper {
    int insert(Favorite favorite);
    int deleteById(@Param("userId") Long userId, @Param("favId") Long favId);
    int deleteByProductId(@Param("userId") Long userId, @Param("productId") Long productId);
    int deleteByIds(@Param("userId") Long userId, @Param("ids") List<Long> ids);
    Favorite findOne(@Param("userId") Long userId, @Param("productId") Long productId);
    List<Map<String, Object>> listByUserId(@Param("userId") Long userId);
}
