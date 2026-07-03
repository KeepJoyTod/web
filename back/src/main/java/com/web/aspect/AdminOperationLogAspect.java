package com.web.aspect;

import com.web.interceptor.AuthInterceptor;
import com.web.mapper.AdminPermissionMapper;
import com.web.pojo.AdminOperationLog;
import com.web.security.AdminPermissionResolver;
import jakarta.servlet.http.HttpServletRequest;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

@Aspect
@Component
public class AdminOperationLogAspect {

    @Autowired
    private AdminPermissionMapper adminPermissionMapper;

    @Autowired
    private AdminPermissionResolver adminPermissionResolver;

    @Around("within(com.web.controller.Admin*Controller) && !within(com.web.controller.AdminAuthController)")
    public Object logAdminOperation(ProceedingJoinPoint joinPoint) throws Throwable {
        HttpServletRequest request = currentRequest();
        long start = System.currentTimeMillis();
        try {
            Object result = joinPoint.proceed();
            writeLog(request, start, "SUCCESS", null);
            return result;
        } catch (Throwable ex) {
            writeLog(request, start, "FAILED", ex.getMessage());
            throw ex;
        }
    }

    private HttpServletRequest currentRequest() {
        ServletRequestAttributes attrs = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        return attrs == null ? null : attrs.getRequest();
    }

    private void writeLog(HttpServletRequest request, long start, String status, String errorMessage) {
        if (request == null) {
            return;
        }
        AdminOperationLog log = new AdminOperationLog();
        log.setAdminId(AuthInterceptor.getCurrentUserId());
        log.setAdminAccount(AuthInterceptor.getCurrentAccount());
        log.setRole(AuthInterceptor.getCurrentRole());
        log.setPermissionCode(adminPermissionResolver.resolvePermission(request));
        log.setMethod(request.getMethod());
        log.setPath(adminPermissionResolver.normalizedPath(request));
        log.setAction(adminPermissionResolver.resolveAction(request));
        log.setStatus(status);
        log.setDurationMs(System.currentTimeMillis() - start);
        log.setErrorMessage(limit(errorMessage, 512));
        log.setIp(resolveIp(request));
        adminPermissionMapper.insertOperationLog(log);
    }

    private String resolveIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }

    private String limit(String value, int maxLength) {
        if (value == null || value.length() <= maxLength) {
            return value;
        }
        return value.substring(0, maxLength);
    }
}
