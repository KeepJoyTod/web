package com.web.security;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Component;

@Component
public class AdminPermissionResolver {

    public String resolvePermission(HttpServletRequest request) {
        String path = normalizedPath(request);
        if (path.startsWith("/v1/admin/dashboard")) return "DASHBOARD_VIEW";
        if (path.startsWith("/v1/admin/products")) return "PRODUCT_MANAGE";
        if (path.startsWith("/v1/admin/categories")) return "CATEGORY_MANAGE";
        if (path.startsWith("/v1/admin/orders")) return "ORDER_MANAGE";
        if (path.startsWith("/v1/admin/aftersales")) return "AFTERSALE_MANAGE";
        if (path.startsWith("/v1/admin/users")) return "USER_MANAGE";
        if (path.startsWith("/v1/admin/operation-logs")) return "OPERATION_LOG_VIEW";
        return null;
    }

    public String resolveAction(HttpServletRequest request) {
        String permission = resolvePermission(request);
        if (permission == null) {
            return "后台操作";
        }
        return switch (permission) {
            case "DASHBOARD_VIEW" -> "查看工作台";
            case "PRODUCT_MANAGE" -> "管理商品";
            case "CATEGORY_MANAGE" -> "管理分类";
            case "ORDER_MANAGE" -> "管理订单";
            case "AFTERSALE_MANAGE" -> "管理售后";
            case "USER_MANAGE" -> "管理用户";
            case "OPERATION_LOG_VIEW" -> "查看操作日志";
            default -> permission;
        };
    }

    public String normalizedPath(HttpServletRequest request) {
        String contextPath = request.getContextPath();
        String uri = request.getRequestURI();
        return uri.startsWith(contextPath) ? uri.substring(contextPath.length()) : uri;
    }
}
