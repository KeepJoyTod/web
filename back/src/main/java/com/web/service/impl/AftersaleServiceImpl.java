package com.web.service.impl;

import com.web.exception.BusinessException;
import com.web.mapper.AftersaleMapper;
import com.web.pojo.Aftersale;
import com.web.pojo.Order;
import com.web.service.AftersaleService;
import com.web.service.OrderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class AftersaleServiceImpl implements AftersaleService {

    @Autowired
    private AftersaleMapper aftersaleMapper;
    
    @Autowired
    private OrderService orderService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Aftersale applyAftersale(Long userId, Long orderId, String orderItemId, Integer qty, String type, String reason, String evidence) {
        Order order = orderService.getOrderById(orderId);
        if (order == null || !order.getUserId().equals(userId)) {
            throw new BusinessException("ORDER_NOT_FOUND", "订单不存在");
        }
        
        // 只有已支付或已发货的订单才能申请售后
        if (order.getStatus() < 1 || order.getStatus() > 3) {
            throw new BusinessException("ORDER_STATE_INVALID", "当前订单状态不允许申请售后");
        }
        
        Aftersale aftersale = new Aftersale();
        aftersale.setUserId(userId);
        aftersale.setOrderId(orderId);
        aftersale.setOrderItemId(orderItemId);
        aftersale.setQty(qty == null ? 1 : qty);
        aftersale.setEvidence(evidence);
        aftersale.setType(type);
        aftersale.setReason(reason);
        aftersale.setStatus("SUBMITTED");
        
        aftersaleMapper.insert(aftersale);
        return aftersale;
    }

    @Override
    public List<Aftersale> getAftersales(Long userId, int page, int size) {
        int offset = (page - 1) * size;
        return aftersaleMapper.getListByUserId(userId, offset, size);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean cancelAftersale(Long id, Long userId) {
        Aftersale aftersale = aftersaleMapper.getByIdAndUserId(id, userId);
        if (aftersale == null) {
            throw new BusinessException("NOT_FOUND", "售后记录不存在");
        }
        if (!"SUBMITTED".equals(aftersale.getStatus()) && !"PROCESSING".equals(aftersale.getStatus())) {
            throw new BusinessException("STATE_INVALID", "当前状态不可取消");
        }
        return aftersaleMapper.updateStatus(id, "CANCELLED") > 0;
    }
}
