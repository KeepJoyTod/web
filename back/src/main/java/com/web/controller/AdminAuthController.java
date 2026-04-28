package com.web.controller;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.map.MapUtil;
import cn.hutool.jwt.JWT;
import cn.hutool.jwt.signers.JWTSignerUtil;
import com.web.exception.BusinessException;
import com.web.interceptor.AuthInterceptor;
import com.web.pojo.User;
import com.web.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/v1/admin/auth")
public class AdminAuthController {

    @Autowired
    private UserService userService;

    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> login(@RequestBody Map<String, Object> params) {
        String account = params.get("account") == null ? "" : params.get("account").toString();
        String password = params.get("password") == null ? "" : params.get("password").toString();

        User user = userService.login(account, password);
        if (!"ADMIN".equalsIgnoreCase(user.getRole())) {
            throw new BusinessException("FORBIDDEN", "账号不是管理员");
        }

        String token = JWT.create()
                .setPayload("id", user.getId())
                .setPayload("account", user.getAccount())
                .setPayload("role", "ADMIN")
                .setPayload("exp", System.currentTimeMillis() + 7200 * 1000)
                .setSigner(JWTSignerUtil.hs256(AuthInterceptor.JWT_KEY))
                .sign();

        Map<String, Object> userMap = BeanUtil.beanToMap(user, false, true);
        userMap.remove("password");

        Map<String, Object> data = MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("token", token)
                .put("expiresIn", 7200)
                .put("user", userMap)
                .build();

        Map<String, Object> meta = MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("requestId", UUID.randomUUID().toString())
                .build();

        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", 200)
                .put("message", "success")
                .put("data", data)
                .put("meta", meta)
                .build());
    }
}
