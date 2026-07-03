package com.web.service.impl;

import com.web.mapper.FavoriteMapper;
import com.web.pojo.Favorite;
import com.web.service.FavoriteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
public class FavoriteServiceImpl implements FavoriteService {

    @Autowired
    private FavoriteMapper favoriteMapper;

    @Override
    @Transactional
    public boolean add(Long userId, Long productId) {
        Favorite existed = favoriteMapper.findOne(userId, productId);
        if (existed != null) {
            return true;
        }
        Favorite fav = new Favorite();
        fav.setUserId(userId);
        fav.setProductId(productId);
        return favoriteMapper.insert(fav) > 0;
    }

    @Override
    @Transactional
    public boolean remove(Long userId, Long favId) {
        return favoriteMapper.deleteById(userId, favId) > 0;
    }

    @Override
    @Transactional
    public boolean removeByProduct(Long userId, Long productId) {
        return favoriteMapper.deleteByProductId(userId, productId) > 0;
    }

    @Override
    @Transactional
    public boolean removeMany(Long userId, List<Long> favIds) {
        if (favIds == null || favIds.isEmpty()) return true;
        return favoriteMapper.deleteByIds(userId, favIds) > 0;
    }

    @Override
    public List<Map<String, Object>> getList(Long userId) {
        return favoriteMapper.listByUserId(userId);
    }
}
