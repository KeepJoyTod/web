package com.web.service;

import com.web.pojo.UserAddress;
import java.util.List;

public interface UserAddressService {
    List<UserAddress> getListByUserId(Long userId);
    
    UserAddress getAddressById(Long id, Long userId);
    
    UserAddress addAddress(UserAddress address);
    
    boolean updateAddress(UserAddress address);
    
    boolean deleteAddress(Long id, Long userId);
}
