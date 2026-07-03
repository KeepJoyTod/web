package com.web.mapper;

import com.web.pojo.Category;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;
import java.util.List;

@Mapper
public interface CategoryMapper {
    @Select("SELECT * FROM categories")
    List<Category> getAll();

    @Select("SELECT * FROM categories WHERE parent_id = #{parentId}")
    List<Category> getByParentId(Long parentId);

    List<Category> getTree();
}
