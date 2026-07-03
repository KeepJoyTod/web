package com.web.service;

import com.web.mapper.AdminPermissionMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashSet;
import java.util.Set;

@Service
public class AdminPermissionService {

    @Autowired
    private AdminPermissionMapper adminPermissionMapper;

    public boolean hasPermission(String role, String permissionCode) {
        if (role == null || permissionCode == null) {
            return false;
        }
        Set<String> permissions = new HashSet<>(adminPermissionMapper.listPermissionCodesByRole(role));
        return permissions.contains(permissionCode);
    }

    public boolean hasAnyPermission(String role) {
        return role != null && !adminPermissionMapper.listPermissionCodesByRole(role).isEmpty();
    }
}
