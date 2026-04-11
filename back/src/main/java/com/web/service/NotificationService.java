package com.web.service;

import com.web.pojo.Notification;
import java.util.List;

public interface NotificationService {
    Notification create(Long userId, String type, String title, String content, String relatedId);
    List<Notification> list(Long userId, int page, int size);
    boolean markRead(Long id, Long userId);
    int markAllRead(Long userId);
    int clearAll(Long userId);
}
