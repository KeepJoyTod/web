package com.web.service;

import com.web.pojo.Review;
import java.util.List;

public interface ReviewService {
    Review create(Long userId, Long orderId, Long productId, Integer rating, String content, String images);
    List<Review> list(Long userId, int page, int size, Long productId, Long orderId);
    List<Review> listByProduct(int page, int size, Long productId);
}
