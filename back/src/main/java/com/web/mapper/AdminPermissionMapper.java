package com.web.mapper;

import com.web.pojo.AdminOperationLog;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface AdminPermissionMapper {
    List<String> listPermissionCodesByRole(@Param("role") String role);

    int insertOperationLog(AdminOperationLog log);

    List<AdminOperationLog> listOperationLogs(
            @Param("keyword") String keyword,
            @Param("permissionCode") String permissionCode,
            @Param("status") String status,
            @Param("offset") int offset,
            @Param("limit") int limit
    );

    long countOperationLogs(
            @Param("keyword") String keyword,
            @Param("permissionCode") String permissionCode,
            @Param("status") String status
    );
}
