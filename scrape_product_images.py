#!/usr/bin/env python3
import requests
from bs4 import BeautifulSoup
import os
import time
import random
import urllib.parse

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
]

# 输出目录
output_dir = "frontend/public"
os.makedirs(output_dir, exist_ok=True)

# 反爬虫头信息
user_agents = [
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0"
]

# 从京东获取商品图片
def get_image_from_jd(product_id, product_name):
    print(f"Scraping image from JD for product {product_id}: {product_name}")
    
    # 京东搜索URL
    encoded_name = urllib.parse.quote(product_name)
    search_url = f"https://search.jd.com/Search?keyword={encoded_name}&enc=utf-8"
    
    try:
        # 随机选择User-Agent
        headers = {
            "User-Agent": random.choice(user_agents),
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
            "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8",
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "keep-alive",
            "Upgrade-Insecure-Requests": "1",
            "Cache-Control": "max-age=0",
            "Referer": "https://www.jd.com/"
        }
        
        # 发送请求
        response = requests.get(search_url, headers=headers, timeout=20)
        response.raise_for_status()
        
        # 解析HTML
        soup = BeautifulSoup(response.text, "html.parser")
        
        # 京东商品图片通常在class为"p-img"的div中的img标签
        # 或者data-lazy-img属性中
        img_tags = soup.find_all("img")
        
        if img_tags:
            # 遍历所有img标签，找到合适的商品图片
            for img_tag in img_tags:
                # 尝试获取图片URL
                img_url = img_tag.get("data-lazy-img") or img_tag.get("src") or img_tag.get("data-src")
                
                if img_url:
                    # 补全URL
                    if img_url.startswith("//"):
                        img_url = "https:" + img_url
                    elif not img_url.startswith("http"):
                        img_url = "https://" + img_url
                    
                    # 过滤掉广告图片和小图标
                    if (".jpg" in img_url or ".png" in img_url or ".webp" in img_url):
                        # 检查是否是商品图片（通常包含京东图片域名）
                        if "jd.com" in img_url or "360buyimg.com" in img_url:
                            # 替换为小图或中图
                            img_url = img_url.replace("n0/", "n1/").replace("n1/", "n7/")
                            
                            print(f"Found JD image URL: {img_url}")
                            
                            # 下载图片
                            img_headers = {
                                "User-Agent": random.choice(user_agents),
                                "Referer": "https://search.jd.com/"
                            }
                            img_response = requests.get(img_url, headers=img_headers, timeout=15)
                            img_response.raise_for_status()
                            
                            # 检查响应是否是图片
                            if img_response.headers.get("Content-Type", "").startswith("image/"):
                                # 保存图片
                                output_path = os.path.join(output_dir, f"product_{product_id}.jpg")
                                with open(output_path, "wb") as f:
                                    f.write(img_response.content)
                                
                                print(f"Successfully scraped image from JD for product {product_id}")
                                return True
            
            print(f"No suitable image found on JD for product {product_id}")
            return False
        else:
            print(f"No image tags found on JD for product {product_id}")
            return False
            
    except Exception as e:
        print(f"Error scraping JD for product {product_id}: {str(e)}")
        return False

# 从淘宝获取商品图片
def get_image_from_taobao(product_id, product_name):
    print(f"Scraping image from Taobao for product {product_id}: {product_name}")
    
    # 淘宝搜索URL
    encoded_name = urllib.parse.quote(product_name)
    search_url = f"https://s.taobao.com/search?q={encoded_name}"
    
    try:
        # 随机选择User-Agent
        headers = {
            "User-Agent": random.choice(user_agents),
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
            "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8",
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "keep-alive",
            "Upgrade-Insecure-Requests": "1",
            "Cache-Control": "max-age=0",
            "Referer": "https://www.taobao.com/"
        }
        
        # 发送请求
        response = requests.get(search_url, headers=headers, timeout=20)
        response.raise_for_status()
        
        # 解析HTML
        soup = BeautifulSoup(response.text, "html.parser")
        
        # 淘宝商品图片通常在class为"img"或"J_ItemPic"的标签中
        # 或者在data-src属性中
        img_tags = soup.find_all("img")
        
        if img_tags:
            # 遍历所有img标签，找到合适的商品图片
            for img_tag in img_tags:
                # 尝试获取图片URL
                img_url = img_tag.get("data-src") or img_tag.get("src") or img_tag.get("data-ks-lazyload")
                
                if img_url:
                    # 补全URL
                    if img_url.startswith("//"):
                        img_url = "https:" + img_url
                    elif not img_url.startswith("http"):
                        img_url = "https://" + img_url
                    
                    # 过滤掉广告图片和小图标
                    if (".jpg" in img_url or ".png" in img_url or ".webp" in img_url):
                        # 检查是否是商品图片（通常包含淘宝图片域名）
                        if "alicdn.com" in img_url or "taobao.com" in img_url:
                            # 过滤掉广告图片
                            if "O1CN01slhH0k1CsnKADDImL" in img_url or "tps-" in img_url:
                                continue
                            
                            print(f"Found Taobao image URL: {img_url}")
                            
                            # 下载图片
                            img_headers = {
                                "User-Agent": random.choice(user_agents),
                                "Referer": "https://s.taobao.com/"
                            }
                            img_response = requests.get(img_url, headers=img_headers, timeout=15)
                            img_response.raise_for_status()
                            
                            # 检查响应是否是图片
                            if img_response.headers.get("Content-Type", "").startswith("image/"):
                                # 保存图片
                                output_path = os.path.join(output_dir, f"product_{product_id}.jpg")
                                with open(output_path, "wb") as f:
                                    f.write(img_response.content)
                                
                                print(f"Successfully scraped image from Taobao for product {product_id}")
                                return True
            
            print(f"No suitable image found on Taobao for product {product_id}")
            return False
        else:
            print(f"No image tags found on Taobao for product {product_id}")
            return False
            
    except Exception as e:
        print(f"Error scraping Taobao for product {product_id}: {str(e)}")
        return False

# 遍历商品，获取图片
for product_id, product_name in products:
    # 尝试从京东获取图片
    success = get_image_from_jd(product_id, product_name)
    
    if not success:
        # 如果京东失败，尝试从淘宝获取
        print(f"JD failed, trying Taobao for product {product_id}")
        success = get_image_from_taobao(product_id, product_name)
    
    if not success:
        # 如果所有网站都失败，使用本地生成的图片
        print(f"Both JD and Taobao failed for product {product_id}, using placeholder image")
        try:
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
            
            print(f"Generated placeholder image for product {product_id}")
        except ImportError:
            print(f"PIL not installed, cannot generate placeholder for product {product_id}")
    
    # 随机延迟，避免被反爬虫
    time.sleep(random.uniform(2, 5))

print("Image scraping completed!")
print(f"Images saved to: {output_dir}")
