package com.web.service.impl;

import com.web.mapper.UserAddressMapper;
import com.web.pojo.UserAddress;
import com.web.service.UserAddressService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class UserAddressServiceImpl implements UserAddressService {

    @Autowired
    private UserAddressMapper userAddressMapper;

    @Override
    public List<UserAddress> getListByUserId(Long userId) {
        return userAddressMapper.getListByUserId(userId);
    }

    @Override
    public UserAddress getAddressById(Long id, Long userId) {
        return userAddressMapper.getByIdAndUserId(id, userId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public UserAddress addAddress(UserAddress address) {
        // 如果新增的是默认地址，先清空其他默认地址
        if (address.getIsDefault() != null && address.getIsDefault() == 1) {
            userAddressMapper.clearDefaultStatus(address.getUserId());
        } else {
            address.setIsDefault(0);
        }
        userAddressMapper.insert(address);
        return address;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean updateAddress(UserAddress address) {
        if (address.getIsDefault() != null && address.getIsDefault() == 1) {
            userAddressMapper.clearDefaultStatus(address.getUserId());
        }
        return userAddressMapper.update(address) > 0;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean deleteAddress(Long id, Long userId) {
        return userAddressMapper.delete(id, userId) > 0;
    }
}
