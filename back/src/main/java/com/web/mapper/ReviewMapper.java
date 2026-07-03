package com.web.mapper;

import com.web.pojo.Review;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface ReviewMapper {
    int insert(Review review);
    List<Review> listByUser(@Param("userId") Long userId, @Param("offset") int offset, @Param("limit") int limit,
                            @Param("productId") Long productId, @Param("orderId") Long orderId);

    List<Review> listByProduct(@Param("productId") Long productId, @Param("offset") int offset, @Param("limit") int limit);
}
