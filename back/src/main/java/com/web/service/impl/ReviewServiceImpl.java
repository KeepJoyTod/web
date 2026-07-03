package com.web.service.impl;

import com.web.exception.BusinessException;
import com.web.mapper.ReviewMapper;
import com.web.pojo.Review;
import com.web.service.OrderService;
import com.web.service.ReviewService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class ReviewServiceImpl implements ReviewService {

    @Autowired
    private ReviewMapper reviewMapper;

    @Autowired
    private OrderService orderService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Review create(Long userId, Long orderId, Long productId, Integer rating, String content, String images) {
        var order = orderService.getOrderById(orderId);
        if (order == null || !order.getUserId().equals(userId)) {
            throw new BusinessException("ORDER_NOT_FOUND", "订单不存在");
        }
        Review r = new Review();
        r.setUserId(userId);
        r.setOrderId(orderId);
        r.setProductId(productId);
        r.setRating(rating);
        r.setContent(content);
        r.setImages(images);
        reviewMapper.insert(r);
        return r;
    }

    @Override
    public List<Review> list(Long userId, int page, int size, Long productId, Long orderId) {
        int offset = (page - 1) * size;
        return reviewMapper.listByUser(userId, offset, size, productId, orderId);
    }

    @Override
    public List<Review> listByProduct(int page, int size, Long productId) {
        int offset = (page - 1) * size;
        return reviewMapper.listByProduct(productId, offset, size);
    }
}
