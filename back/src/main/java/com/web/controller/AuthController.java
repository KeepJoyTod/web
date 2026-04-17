package com.web.controller;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.map.MapUtil;
import cn.hutool.jwt.JWT;
import cn.hutool.jwt.signers.JWTSignerUtil;
import com.web.pojo.User;
import com.web.dto.AuthRequests;
import com.web.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.UUID;

@Tag(name = "身份认证", description = "登录、注册及 Token 管理")
@RestController
@RequestMapping("/v1/auth")
public class AuthController {

    @Autowired
    private UserService userService;

    // JWT 签名密钥
    private static final byte[] JWT_KEY = "projectku_secret_key".getBytes();

    @Operation(summary = "用户登录", description = "使用账号密码登录，返回 JWT Token")
    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> login(@RequestBody AuthRequests.LoginRequest req) {
        String account = req.getAccount();
        String password = req.getPassword();
        
        User user = userService.login(account, password);
        
        // 使用 Hutool 生成 JWT
        String token = JWT.create()
                .setPayload("id", user.getId())
                .setPayload("account", user.getAccount())
                .setPayload("exp", System.currentTimeMillis() + 7200 * 1000) // 2小时过期
                .setSigner(JWTSignerUtil.hs256(JWT_KEY))
                .sign();

        Map<String, Object> userMap = BeanUtil.beanToMap(user, false, true);
        userMap.remove("password"); // 移除敏感信息
        
        Map<String, Object> data = MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("token", token)
                .put("expiresIn", 7200)
                .put("user", userMap)
                .build();
                
        Map<String, Object> meta = MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("requestId", UUID.randomUUID().toString())
                .build();
                
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("data", data)
                .put("meta", meta)
                .build());
    }
    
    @Operation(summary = "用户注册", description = "注册新账号")
    @PostMapping("/register")
    public ResponseEntity<Map<String, Object>> register(@RequestBody AuthRequests.RegisterRequest req) {
        String account = req.getAccount();
        String password = req.getPassword();
        String nickname = req.getNickname() == null || req.getNickname().isBlank()
                ? "User_" + System.currentTimeMillis()
                : req.getNickname();
        
        User user = userService.register(account, password, nickname);
        
        Map<String, Object> userMap = BeanUtil.beanToMap(user, false, true);
        userMap.remove("password");
        
        Map<String, Object> meta = MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("requestId", UUID.randomUUID().toString())
                .build();
                
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("data", userMap)
                .put("meta", meta)
                .build());
    }
}
