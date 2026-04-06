package com.web.service;

import com.web.pojo.Aftersale;
import java.util.List;

public interface AftersaleService {
    Aftersale applyAftersale(Long userId, Long orderId, String orderItemId, Integer qty, String type, String reason, String evidence);
    
    List<Aftersale> getAftersales(Long userId, int page, int size);
    
    boolean cancelAftersale(Long id, Long userId);
}
