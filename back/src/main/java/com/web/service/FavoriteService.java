package com.web.service;

import java.util.List;
import java.util.Map;

public interface FavoriteService {
    boolean add(Long userId, Long productId);
    boolean remove(Long userId, Long favId);
    boolean removeByProduct(Long userId, Long productId);
    boolean removeMany(Long userId, List<Long> favIds);
    List<Map<String, Object>> getList(Long userId);
}
