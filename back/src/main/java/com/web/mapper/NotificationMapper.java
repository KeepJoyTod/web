package com.web.mapper;

import com.web.pojo.Notification;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface NotificationMapper {
    int insert(Notification n);
    List<Notification> listByUser(@Param("userId") Long userId, @Param("offset") int offset, @Param("limit") int limit);
    int markRead(@Param("id") Long id, @Param("userId") Long userId);
    int markAllRead(@Param("userId") Long userId);
    int clearAll(@Param("userId") Long userId);
}
