package com.web.interceptor;

import cn.hutool.core.util.StrUtil;
import cn.hutool.jwt.JWT;
import cn.hutool.jwt.JWTUtil;
import com.web.exception.BusinessException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * 认证拦截器，用于解析 JWT
 */
@Component
public class AuthInterceptor implements HandlerInterceptor {

    private static final byte[] JWT_KEY = "projectku_secret_key".getBytes();
    
    // 使用 ThreadLocal 存储当前请求的用户ID
    private static final ThreadLocal<Long> CURRENT_USER = new ThreadLocal<>();

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        String token = request.getHeader("Authorization");
        
        if (StrUtil.isBlank(token) || !token.startsWith("Bearer ")) {
            throw new BusinessException("UNAUTHORIZED", "未登录或令牌失效");
        }
        
        token = token.substring(7); // 移除 "Bearer "
        
        try {
            boolean verify = JWTUtil.verify(token, JWT_KEY);
            if (!verify) {
                throw new BusinessException("UNAUTHORIZED", "令牌签名无效");
            }
            
            JWT jwt = JWTUtil.parseToken(token);
            // 校验过期时间
            Long exp = Long.valueOf(jwt.getPayload("exp").toString());
            if (System.currentTimeMillis() > exp) {
                throw new BusinessException("UNAUTHORIZED", "令牌已过期");
            }
            
            Long userId = Long.valueOf(jwt.getPayload("id").toString());
            CURRENT_USER.set(userId);
            
            return true;
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            throw new BusinessException("UNAUTHORIZED", "解析令牌失败");
        }
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) throws Exception {
        CURRENT_USER.remove(); // 防止内存泄漏
    }
    
    /**
     * 获取当前登录用户ID
     */
    public static Long getCurrentUserId() {
        Long userId = CURRENT_USER.get();
        if (userId == null) {
            throw new BusinessException("UNAUTHORIZED", "未获取到用户身份信息");
        }
        return userId;
    }
}
