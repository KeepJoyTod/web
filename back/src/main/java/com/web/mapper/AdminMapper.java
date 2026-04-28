package com.web.mapper;

import com.web.pojo.Category;
import com.web.pojo.Product;
import com.web.pojo.ProductMedia;
import com.web.pojo.ProductSku;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@Mapper
public interface AdminMapper {
    long countUsers();

    long countProducts();

    long countOrders();

    BigDecimal sumTodaySales();

    long countPendingShipmentOrders();

    long countPendingAftersales();

    long countLowStockProducts(@Param("threshold") int threshold);

    List<Map<String, Object>> recentOrders(@Param("limit") int limit);

    List<Product> listProducts(
            @Param("keyword") String keyword,
            @Param("categoryId") Long categoryId,
            @Param("status") Integer status,
            @Param("offset") int offset,
            @Param("limit") int limit
    );

    long countProductList(
            @Param("keyword") String keyword,
            @Param("categoryId") Long categoryId,
            @Param("status") Integer status
    );

    Product getProductById(@Param("id") Long id);

    List<ProductMedia> listProductMedia(@Param("productId") Long productId);

    List<ProductSku> listProductSkus(@Param("productId") Long productId);

    int insertProductMedia(ProductMedia media);

    int deleteProductMediaByProductId(@Param("productId") Long productId);

    int insertProductSku(ProductSku sku);

    int deleteProductSkuByProductId(@Param("productId") Long productId);

    List<Category> listCategories();

    int insertCategory(Category category);

    int updateCategory(Category category);

    int deleteCategory(@Param("id") Long id);

    List<Map<String, Object>> listOrders(
            @Param("keyword") String keyword,
            @Param("status") Integer status,
            @Param("dateFrom") String dateFrom,
            @Param("dateTo") String dateTo,
            @Param("offset") int offset,
            @Param("limit") int limit
    );

    long countOrderList(
            @Param("keyword") String keyword,
            @Param("status") Integer status,
            @Param("dateFrom") String dateFrom,
            @Param("dateTo") String dateTo
    );

    Map<String, Object> getOrderDetail(@Param("id") Long id);

    List<Map<String, Object>> listOrderItems(@Param("orderId") Long orderId);

    Map<String, Object> getOrderAddress(@Param("addressId") Long addressId);

    Map<String, Object> getOrderPayment(@Param("orderId") Long orderId);

    int updateOrderStatus(@Param("id") Long id, @Param("status") Integer status);

    int shipOrder(
            @Param("id") Long id,
            @Param("logisticsCompany") String logisticsCompany,
            @Param("logisticsNo") String logisticsNo
    );

    List<Map<String, Object>> listAftersales(
            @Param("keyword") String keyword,
            @Param("status") String status,
            @Param("offset") int offset,
            @Param("limit") int limit
    );

    long countAftersales(
            @Param("keyword") String keyword,
            @Param("status") String status
    );

    Map<String, Object> getAftersaleDetail(@Param("id") Long id);

    int reviewAftersale(
            @Param("id") Long id,
            @Param("status") String status,
            @Param("adminRemark") String adminRemark
    );

    List<Map<String, Object>> listUsers(
            @Param("keyword") String keyword,
            @Param("role") String role,
            @Param("status") Integer status,
            @Param("offset") int offset,
            @Param("limit") int limit
    );

    long countUserList(
            @Param("keyword") String keyword,
            @Param("role") String role,
            @Param("status") Integer status
    );

    Map<String, Object> getUserDetail(@Param("id") Long id);

    int updateUserStatus(@Param("id") Long id, @Param("status") Integer status);
}
