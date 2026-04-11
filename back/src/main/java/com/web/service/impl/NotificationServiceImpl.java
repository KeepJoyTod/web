package com.web.service.impl;

import com.web.mapper.NotificationMapper;
import com.web.pojo.Notification;
import com.web.service.NotificationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class NotificationServiceImpl implements NotificationService {

    @Autowired
    private NotificationMapper notificationMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Notification create(Long userId, String type, String title, String content, String relatedId) {
        Notification n = new Notification();
        n.setUserId(userId);
        n.setType(type);
        n.setTitle(title);
        n.setContent(content);
        n.setRelatedId(relatedId);
        n.setIsRead(false);
        n.setReadTime(null);
        notificationMapper.insert(n);
        return n;
    }

    @Override
    public List<Notification> list(Long userId, int page, int size) {
        int offset = (page - 1) * size;
        return notificationMapper.listByUser(userId, offset, size);
    }

    @Override
    public boolean markRead(Long id, Long userId) {
        return notificationMapper.markRead(id, userId) > 0;
    }

    @Override
    public int markAllRead(Long userId) {
        return notificationMapper.markAllRead(userId);
    }

    @Override
    public int clearAll(Long userId) {
        return notificationMapper.clearAll(userId);
    }
}
