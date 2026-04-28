package com.web.interceptor;

import cn.hutool.core.util.StrUtil;
import cn.hutool.jwt.JWT;
import cn.hutool.jwt.JWTUtil;
import com.web.exception.BusinessException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
public class AuthInterceptor implements HandlerInterceptor {

    public static final byte[] JWT_KEY = "projectku_secret_key".getBytes();

    private static final ThreadLocal<Long> CURRENT_USER = new ThreadLocal<>();
    private static final ThreadLocal<String> CURRENT_ROLE = new ThreadLocal<>();

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            return true;
        }

        String token = request.getHeader("Authorization");
        if (StrUtil.isBlank(token) || !token.startsWith("Bearer ")) {
            throw new BusinessException("UNAUTHORIZED", "未登录或令牌失效");
        }

        token = token.substring(7);
        try {
            boolean verify = JWTUtil.verify(token, JWT_KEY);
            if (!verify) {
                throw new BusinessException("UNAUTHORIZED", "令牌签名无效");
            }

            JWT jwt = JWTUtil.parseToken(token);
            Object expPayload = jwt.getPayload("exp");
            if (expPayload == null || System.currentTimeMillis() > Long.parseLong(expPayload.toString())) {
                throw new BusinessException("UNAUTHORIZED", "令牌已过期");
            }

            Object userIdPayload = jwt.getPayload("id");
            if (userIdPayload == null) {
                throw new BusinessException("UNAUTHORIZED", "令牌缺少用户信息");
            }

            Long userId = Long.valueOf(userIdPayload.toString());
            String role = jwt.getPayload("role") == null ? "USER" : jwt.getPayload("role").toString();
            CURRENT_USER.set(userId);
            CURRENT_ROLE.set(role);

            if (isAdminPath(request) && !"ADMIN".equalsIgnoreCase(role)) {
                throw new BusinessException("FORBIDDEN", "无管理员权限");
            }

            return true;
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            throw new BusinessException("UNAUTHORIZED", "解析令牌失败");
        }
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) {
        CURRENT_USER.remove();
        CURRENT_ROLE.remove();
    }

    public static Long getCurrentUserId() {
        Long userId = CURRENT_USER.get();
        if (userId == null) {
            throw new BusinessException("UNAUTHORIZED", "未获取到用户身份信息");
        }
        return userId;
    }

    public static String getCurrentRole() {
        String role = CURRENT_ROLE.get();
        return role == null ? "USER" : role;
    }

    public static boolean isCurrentAdmin() {
        return "ADMIN".equalsIgnoreCase(getCurrentRole());
    }

    private boolean isAdminPath(HttpServletRequest request) {
        String contextPath = request.getContextPath();
        String uri = request.getRequestURI();
        String path = uri.startsWith(contextPath) ? uri.substring(contextPath.length()) : uri;
        return path.startsWith("/v1/admin/");
    }
}
