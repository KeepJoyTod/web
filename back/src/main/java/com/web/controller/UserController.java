package com.web.controller;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.map.MapUtil;
<<<<<<< HEAD
=======
import com.web.dto.UserAddressRequests;
>>>>>>> origin/main
import com.web.interceptor.AuthInterceptor;
import com.web.pojo.User;
import com.web.pojo.UserAddress;
import com.web.service.UserAddressService;
import com.web.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 用户中心与地址接口
 */
@RestController
@RequestMapping("/v1/me")
public class UserController {

    @Autowired
    private UserService userService;
    
    @Autowired
    private UserAddressService userAddressService;

    /**
     * 获取当前登录用户信息
     * GET /v1/me
     */
    @GetMapping
    public ResponseEntity<Map<String, Object>> getCurrentUser() {
        Long userId = AuthInterceptor.getCurrentUserId();
        User user = userService.getUserById(userId);
        
        Map<String, Object> userMap = BeanUtil.beanToMap(user, false, true);
        userMap.remove("password");
        
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", 200)
                .put("message", "success")
                .put("data", userMap)
                .build());
    }

    /**
     * 获取当前用户的地址列表
     * GET /v1/me/addresses
     */
    @GetMapping("/addresses")
    public ResponseEntity<Map<String, Object>> getAddresses() {
        Long userId = AuthInterceptor.getCurrentUserId();
        List<UserAddress> list = userAddressService.getListByUserId(userId);
        
        List<Map<String, Object>> mapList = list.stream()
                .map(addr -> BeanUtil.beanToMap(addr, false, true))
                .collect(Collectors.toList());
                
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", 200)
                .put("message", "success")
                .put("data", mapList)
                .build());
    }

    /**
     * 新增地址
     * POST /v1/me/addresses
     */
    @PostMapping("/addresses")
<<<<<<< HEAD
    public ResponseEntity<Map<String, Object>> addAddress(@RequestBody UserAddress address) {
        Long userId = AuthInterceptor.getCurrentUserId();
        address.setUserId(userId);
=======
    public ResponseEntity<Map<String, Object>> addAddress(@RequestBody UserAddressRequests.CreateRequest req) {
        Long userId = AuthInterceptor.getCurrentUserId();

        UserAddress address = new UserAddress();
        address.setUserId(userId);
        address.setReceiver(req.getReceiver());
        address.setPhone(req.getPhone());
        address.setRegion(req.getRegion());
        address.setDetail(req.getDetail());
        address.setIsDefault(req.getIsDefault());
>>>>>>> origin/main
        
        UserAddress saved = userAddressService.addAddress(address);
        
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", 200)
                .put("message", "success")
                .put("data", BeanUtil.beanToMap(saved, false, true))
                .build());
    }

    /**
     * 修改地址
     * PUT /v1/me/addresses/{id}
     */
    @PutMapping("/addresses/{id}")
<<<<<<< HEAD
    public ResponseEntity<Map<String, Object>> updateAddress(@PathVariable Long id, @RequestBody UserAddress address) {
        Long userId = AuthInterceptor.getCurrentUserId();
        address.setId(id);
        address.setUserId(userId);
=======
    public ResponseEntity<Map<String, Object>> updateAddress(@PathVariable Long id, @RequestBody UserAddressRequests.UpdateRequest req) {
        Long userId = AuthInterceptor.getCurrentUserId();

        UserAddress address = new UserAddress();
        address.setId(id);
        address.setUserId(userId);
        address.setReceiver(req.getReceiver());
        address.setPhone(req.getPhone());
        address.setRegion(req.getRegion());
        address.setDetail(req.getDetail());
        address.setIsDefault(req.getIsDefault());
>>>>>>> origin/main
        
        boolean success = userAddressService.updateAddress(address);
        
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", success ? 200 : 500)
                .put("message", success ? "success" : "failed")
                .build());
    }

    /**
     * 删除地址
     * DELETE /v1/me/addresses/{id}
     */
    @DeleteMapping("/addresses/{id}")
    public ResponseEntity<Map<String, Object>> deleteAddress(@PathVariable Long id) {
        Long userId = AuthInterceptor.getCurrentUserId();
        boolean success = userAddressService.deleteAddress(id, userId);
        
        return ResponseEntity.ok(MapUtil.builder(new java.util.HashMap<String, Object>())
                .put("code", success ? 200 : 500)
                .put("message", success ? "success" : "failed")
                .build());
    }
}
