package com.web.service.impl;

import cn.hutool.crypto.digest.DigestUtil;
import cn.hutool.crypto.digest.BCrypt;
import com.web.exception.BusinessException;
import com.web.mapper.UserMapper;
import com.web.pojo.User;
import com.web.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class UserServiceImpl implements UserService {

    @Autowired
    private UserMapper userMapper;

    @Override
    public User login(String account, String password) {
        String normalizedAccount = normalize(account);
        if (normalizedAccount == null || normalizedAccount.isEmpty() || password == null || password.isEmpty()) {
            throw new BusinessException("UNAUTHORIZED", "用户不存在或密码错误");
        }

        User user = userMapper.getByAccount(normalizedAccount);
        if (user == null) {
            throw new BusinessException("UNAUTHORIZED", "用户不存在或密码错误");
        }
        
        // 使用 Hutool 简单 MD5 校验
        if (user.getStatus() != null && user.getStatus() == 0) {
            throw new BusinessException("FORBIDDEN", "账号已禁用");
        }

        if (!passwordMatches(password, user.getPassword())) {
            throw new BusinessException("UNAUTHORIZED", "用户不存在或密码错误");
        }
        return user;
    }

    @Override
    public User register(String account, String password, String nickname) {
        String normalizedAccount = normalize(account);
        if (normalizedAccount == null || normalizedAccount.isEmpty()) {
            throw new BusinessException("VALIDATION_FAILED", "账号不能为空");
        }
        if (normalizedAccount.length() > 64) {
            throw new BusinessException("VALIDATION_FAILED", "账号长度不能超过64位");
        }
        if (password == null || password.isEmpty()) {
            throw new BusinessException("VALIDATION_FAILED", "密码不能为空");
        }
        if (password.length() < 6) {
            throw new BusinessException("VALIDATION_FAILED", "密码长度不能少于6位");
        }

        String normalizedNickname = normalize(nickname);
        if (normalizedNickname == null || normalizedNickname.isEmpty()) {
            normalizedNickname = "User_" + System.currentTimeMillis();
        }
        if (normalizedNickname.length() > 64) {
            throw new BusinessException("VALIDATION_FAILED", "昵称长度不能超过64位");
        }

        User existing = userMapper.getByAccount(normalizedAccount);
        if (existing != null) {
            throw new BusinessException("VALIDATION_FAILED", "账号已存在");
        }
        
        User user = new User();
        user.setAccount(normalizedAccount);
        user.setPassword(DigestUtil.md5Hex(password));
        user.setNickname(normalizedNickname);
        user.setRole("USER");
        user.setStatus(1);
        
        userMapper.insert(user);
        return user;
    }

    @Override
    public User getUserById(Long id) {
        return userMapper.getById(id);
    }

    private String normalize(String value) {
        return value == null ? null : value.trim();
    }

    private boolean passwordMatches(String rawPassword, String storedPassword) {
        if (storedPassword == null || storedPassword.isEmpty()) {
            return false;
        }

        String normalizedStored = storedPassword.trim();
        if (isBcryptHash(normalizedStored)) {
            return BCrypt.checkpw(rawPassword, normalizedStored);
        }

        return normalizedStored.equals(DigestUtil.md5Hex(rawPassword));
    }

    private boolean isBcryptHash(String value) {
        return value.startsWith("$2a$") || value.startsWith("$2b$") || value.startsWith("$2y$");
    }
}
