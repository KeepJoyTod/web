package com.web.service.impl;

import cn.hutool.crypto.digest.DigestUtil;
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
        User user = userMapper.getByAccount(account);
        if (user == null) {
            throw new BusinessException("UNAUTHORIZED", "用户不存在或密码错误");
        }
        
        // 使用 Hutool 简单 MD5 校验
        if (user.getStatus() != null && user.getStatus() == 0) {
            throw new BusinessException("FORBIDDEN", "账号已禁用");
        }

        String encryptedPassword = DigestUtil.md5Hex(password);
        if (!user.getPassword().equals(encryptedPassword)) {
            throw new BusinessException("UNAUTHORIZED", "用户不存在或密码错误");
        }
        return user;
    }

    @Override
    public User register(String account, String password, String nickname) {
        User existing = userMapper.getByAccount(account);
        if (existing != null) {
            throw new BusinessException("VALIDATION_FAILED", "账号已存在");
        }
        
        User user = new User();
        user.setAccount(account);
        user.setPassword(DigestUtil.md5Hex(password));
        user.setNickname(nickname);
        user.setRole("USER");
        user.setStatus(1);
        
        userMapper.insert(user);
        return user;
    }

    @Override
    public User getUserById(Long id) {
        return userMapper.getById(id);
    }
}
