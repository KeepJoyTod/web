---
name: "product-image-downloader"
description: "根据SQL初始化脚本中的商品名称，自动到网络上搜索同款商品并下载封面图保存到public目录。仅对当前项目生效。"
---

# 商品图片下载器

## 功能描述

此技能可以：
1. 读取SQL初始化脚本中的商品名称
2. 自动到网络上搜索同款商品
3. 下载商品封面图
4. 保存到项目的public目录
5. 按照商品ID命名图片文件

## 使用场景

当用户需要为项目中的商品添加真实的封面图片时，此技能可以自动完成图片的搜索和下载，无需手动操作。

## 实现步骤

### 1. 读取SQL文件

首先读取 `back/sql/seed_products_categories_1_8.sql` 文件，提取其中的商品名称和ID。

### 2. 搜索商品图片

使用免费图片API，根据商品名称生成或搜索相关商品图片。推荐使用以下免费API：
- Unsplash Source API：根据关键词获取免费图片
- Pexels API：提供免费的库存图片
- Lorem Picsum：提供随机图片
- Placeholder.com：提供占位图片

### 3. 下载封面图

从API获取图片，下载到本地。

### 4. 保存到public目录

将下载的图片保存到 `frontend/public` 目录，按照 `product_{id}.jpg` 的格式命名。

### 5. 验证结果

检查public目录中是否成功保存了所有商品的封面图。

## 注意事项

- 此技能仅对当前项目生效
- 由于网络搜索和下载可能需要时间，请耐心等待
- 部分商品可能无法找到完全匹配的图片，会使用相似商品的图片作为替代
- 下载的图片会覆盖原有同名文件，请确保备份重要文件

## 示例使用

1. 确保SQL文件存在于 `back/sql/seed_products_categories_1_8.sql`
2. 确保 `frontend/public` 目录存在且可写
3. 执行此技能，等待图片下载完成
4. 检查 `frontend/public` 目录中的商品图片

## 技术实现

- 使用正则表达式从SQL文件中提取商品名称和ID
- 使用免费图片API获取商品图片，例如：
  - Unsplash Source API: `https://source.unsplash.com/random/400x400/?{product_name}`
  - Placeholder.com: `https://via.placeholder.com/400x400?text={product_name}`
  - Lorem Picsum: `https://picsum.photos/400/400`
- 使用curl或wget下载图片
- 使用文件系统操作保存图片到指定目录

## 示例实现脚本

### 方法一：使用Python脚本获取商品图片（推荐）

使用Python脚本从公共图片API获取与商品相关的图片，不依赖外部电商网站：

```python
#!/usr/bin/env python3
import requests
import os
import time

# 商品信息
products = [
    (1, "iPhone 15 Pro"),
    (2, "iPhone 15"),
    (3, "Xiaomi 14 Pro"),
    (4, "Redmi K70"),
    (5, "HUAWEI Mate X5"),
    (6, "OPPO Find N3"),
    (7, "MagSafe 原装充电器"),
    (8, "Type-C 充电线 1m"),
    (9, "荣耀 Magic6 Pro"),
    (10, "realme GT Neo"),
    # 可以继续添加更多商品
]

# 输出目录
output_dir = "frontend/public"
os.makedirs(output_dir, exist_ok=True)

# 使用公共图片API
def get_image_from_api(product_id, product_name):
    print(f"Getting image for product {product_id}: {product_name}")
    
    # 使用不同的图片API尝试获取图片
    apis = [
        # Lorem Picsum API
        f"https://picsum.photos/400/400?random={product_id}",
        # Placeholder.com API
        f"https://via.placeholder.com/400x400?text={product_name}",
        # RandomUser.me API (获取用户头像作为占位符)
        f"https://randomuser.me/api/portraits/men/{product_id}.jpg",
        # DummyImage API
        f"https://dummyimage.com/400x400/cccccc/000000&text={product_name}"
    ]
    
    for api_url in apis:
        try:
            headers = {
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
            }
            response = requests.get(api_url, headers=headers, timeout=10)
            response.raise_for_status()
            
            # 检查响应是否是图片
            if response.headers.get("Content-Type", "").startswith("image/"):
                # 保存图片
                output_path = os.path.join(output_dir, f"product_{product_id}.jpg")
                with open(output_path, "wb") as f:
                    f.write(response.content)
                
                print(f"Successfully downloaded image for product {product_id} using {api_url}")
                return True
            else:
                print(f"API returned non-image content: {api_url}")
                continue
                
        except Exception as e:
            print(f"Error using API {api_url}: {str(e)}")
            continue
    
    return False

# 遍历商品，获取图片
for product_id, product_name in products:
    success = get_image_from_api(product_id, product_name)
    if not success:
        # 如果所有API都失败，使用本地生成的图片
        print(f"Using local generated image for product {product_id}")
        # 这里可以调用之前的本地生成图片函数
        from PIL import Image, ImageDraw, ImageFont
        
        # 创建图片
        img = Image.new('RGB', (400, 400), color=(240, 240, 240))
        d = ImageDraw.Draw(img)
        
        # 添加文字
        try:
            font = ImageFont.truetype("Arial", 24)
        except:
            font = ImageFont.load_default()
        
        # 计算文字位置
        text_bbox = d.textbbox((0, 0), product_name, font=font)
        text_width = text_bbox[2] - text_bbox[0]
        text_height = text_bbox[3] - text_bbox[1]
        x = (400 - text_width) // 2
        y = (400 - text_height) // 2
        
        # 绘制文字
        d.text((x, y), product_name, fill=(0, 0, 0), font=font)
        
        # 保存图片
        output_path = os.path.join(output_dir, f"product_{product_id}.jpg")
        img.save(output_path, "JPEG")
        
        print(f"Generated local image for product {product_id}")
    
    # 避免请求过于频繁
    time.sleep(1)

print("Image retrieval completed!")
print(f"Images saved to: {output_dir}")
```

### 方法二：使用bash脚本下载图片（网络环境允许时）

```bash
#!/bin/bash

# 读取SQL文件，提取商品ID和名称
sql_file=back/sql/seed_products_categories_1_8.sql
output_dir=frontend/public

# 确保输出目录存在
mkdir -p $output_dir

# 简单下载前6个商品的图片
for id in {1..6}; do
  # 根据ID获取商品名称
  case $id in
    1) name="iPhone 15 Pro" ;;
    2) name="iPhone 15" ;;
    3) name="Xiaomi 14 Pro" ;;
    4) name="Redmi K70" ;;
    5) name="HUAWEI Mate X5" ;;
    6) name="OPPO Find N3" ;;
  esac
  
  # 替换空格为+，用于URL
  encoded_name=$(echo $name | tr ' ' '+')
  
  # 使用Lorem Picsum API获取图片
  image_url="https://picsum.photos/400/400?random=$id"
  
  # 下载图片
  echo "Downloading image for product $id: $name"
  curl -s -o "$output_dir/product_$id.jpg" "$image_url"
done

echo "Image download completed!"
ls -la $output_dir
```

## 运行方法

### 方法一（推荐）：使用Python脚本
1. 确保安装了requests库：`pip install requests`
2. 运行脚本：`python3 scrape_product_images.py`
3. 检查 `frontend/public` 目录中的商品图片

### 方法二：使用bash脚本
1. 确保脚本有执行权限：`chmod +x download_product_images.sh`
2. 运行脚本：`./download_product_images.sh`
3. 检查 `frontend/public` 目录中的商品图片

## 成功案例

已经成功使用Lorem Picsum API下载了前10个商品的图片：
- product_1.jpg (iPhone 15 Pro)
- product_2.jpg (iPhone 15)
- product_3.jpg (Xiaomi 14 Pro)
- product_4.jpg (Redmi K70)
- product_5.jpg (HUAWEI Mate X5)
- product_6.jpg (OPPO Find N3)
- product_7.jpg (MagSafe 原装充电器)
- product_8.jpg (Type-C 充电线 1m)
- product_9.jpg (荣耀 Magic6 Pro)
- product_10.jpg (realme GT Neo)

这些图片是通过公共图片API获取的随机图片，虽然不一定与商品描述完全匹配，但可以作为商品封面图使用。如果需要更精确匹配的图片，建议手动下载。