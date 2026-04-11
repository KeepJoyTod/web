export type ProductCategoryHint =
  | 'phone'
  | 'computer'
  | 'appliance'
  | 'digital'
  | 'daily'
  | 'beauty'
  | 'food'
  | 'sport'

type Rule = {
  keyword: string
  url: string
}

const phoneRules: Rule[] = [
  {
    keyword: 'iphone 15 pro',
    url: 'https://images.pexels.com/photos/29020349/pexels-photo-29020349.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'iphone 17 ',
    url: 'https://images.pexels.com/photos/34624326/pexels-photo-34624326.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'xiaomi 17 pro',
    url: 'https://images.pexels.com/photos/33376151/pexels-photo-33376151.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'k70',
    url: 'https://images.pexels.com/photos/1092644/pexels-photo-1092644.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'magic6 pro',
    url: 'https://images.pexels.com/photos/404280/pexels-photo-404280.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'x100',
    url: 'https://images.pexels.com/photos/47261/pexels-photo-47261.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: ' ace ',
    url: 'https://images.pexels.com/photos/699122/pexels-photo-699122.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'mix fold',
    url: 'https://images.pexels.com/photos/788946/pexels-photo-788946.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'z fold',
    url: 'https://images.pexels.com/photos/788946/pexels-photo-788946.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'iqoo 12',
    url: 'https://images.pexels.com/photos/404280/pexels-photo-404280.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'note 13',
    url: 'https://images.pexels.com/photos/1092644/pexels-photo-1092644.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: ' x50',
    url: 'https://images.pexels.com/photos/404280/pexels-photo-404280.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'reno',
    url: 'https://images.pexels.com/photos/699122/pexels-photo-699122.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'iphone 17',
    url: 'https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-17-pro-max-colors.png?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'xiaomi 17',
    url: 'https://images.pexels.com/photos/404280/pexels-photo-404280.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'redmi',
    url: 'https://images.pexels.com/photos/1092644/pexels-photo-1092644.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'mate x',
    url: 'https://images.pexels.com/photos/788946/pexels-photo-788946.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'oppo',
    url: 'https://images.pexels.com/photos/699122/pexels-photo-699122.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '荣耀',
    url: 'https://images.pexels.com/photos/404280/pexels-photo-404280.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'vivo',
    url: 'https://images.pexels.com/photos/47261/pexels-photo-47261.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '一加',
    url: 'https://images.pexels.com/photos/47261/pexels-photo-47261.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '三星',
    url: 'https://images.pexels.com/photos/47261/pexels-photo-47261.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
]

const computerRules: Rule[] = [
  {
    keyword: 'air 13 m3',
    url: 'https://images.pexels.com/photos/18105/pexels-photo.jpg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'x1 carbon',
    url: 'https://images.pexels.com/photos/374631/pexels-photo-374631.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'y7000',
    url: 'https://images.pexels.com/photos/159888/laptop-macbook-apple-computer-159888.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'u2723qe',
    url: 'https://images.pexels.com/photos/374631/pexels-photo-374631.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '34wp65c',
    url: 'https://images.pexels.com/photos/459653/pexels-photo-459653.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'mx master',
    url: 'https://images.pexels.com/photos/1999463/pexels-photo-1999463.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'keychron k2',
    url: 'https://images.pexels.com/photos/2115257/pexels-photo-2115257.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'pd2705u',
    url: 'https://images.pexels.com/photos/1779487/pexels-photo-1779487.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'ds220+',
    url: 'https://images.pexels.com/photos/325229/pexels-photo-325229.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'macbook Air',
    url: 'https://images.pexels.com/photos/12935279/pexels-photo-12935279.jpeg',
  },
  {
    keyword: 'thinkpad',
    url: 'https://images.pexels.com/photos/374631/pexels-photo-374631.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '拯救者',
    url: 'https://images.pexels.com/photos/19269785/pexels-photo-19269785.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'rog',
    url: 'https://images.pexels.com/photos/159888/laptop-macbook-apple-computer-159888.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '外星人',
    url: 'https://images.pexels.com/photos/459653/pexels-photo-459653.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
]

const applianceRules: Rule[] = [
  {
    keyword: '纤诺 洗衣机',
    url: 'https://images.pexels.com/photos/3967570/pexels-photo-3967570.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '风冷 冰箱',
    url: 'https://images.pexels.com/photos/3738096/pexels-photo-3738096.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'v12 吸尘器',
    url: 'https://images.pexels.com/photos/8566442/pexels-photo-8566442.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '扫拖机器人',
    url: 'https://images.pexels.com/photos/8566446/pexels-photo-8566446.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '空调',
    url: 'https://images.pexels.com/photos/3964739/pexels-photo-3964739.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '破壁机',
    url: 'https://images.pexels.com/photos/414555/pexels-photo-414555.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '电吹风',
    url: 'https://images.pexels.com/photos/853446/pexels-photo-853446.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '洗衣机',
    url: 'https://images.pexels.com/photos/3967570/pexels-photo-3967570.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '冰箱',
    url: 'https://images.pexels.com/photos/3738096/pexels-photo-3738096.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '扫拖机器人',
    url: 'https://images.pexels.com/photos/8566446/pexels-photo-8566446.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '吸尘器',
    url: 'https://images.pexels.com/photos/8566442/pexels-photo-8566442.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '空调',
    url: 'https://images.pexels.com/photos/3964739/pexels-photo-3964739.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
]

const digitalRules: Rule[] = [
  {
    keyword: 'wh-1000xm5',
    url: 'https://images.pexels.com/photos/3394664/pexels-photo-3394664.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'airpods pro 2',
    url: 'https://images.pexels.com/photos/788946/pexels-photo-788946.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'live pro',
    url: 'https://images.pexels.com/photos/3394668/pexels-photo-3394668.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '65w',
    url: 'https://images.pexels.com/photos/404280/pexels-photo-404280.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '20000mah',
    url: 'https://images.pexels.com/photos/404280/pexels-photo-404280.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'evo 256g',
    url: 'https://images.pexels.com/photos/343457/pexels-photo-343457.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'watch se',
    url: 'https://images.pexels.com/photos/190819/pexels-photo-190819.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'watch 4',
    url: 'https://images.pexels.com/photos/267394/pexels-photo-267394.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '手环 8 pro',
    url: 'https://images.pexels.com/photos/437037/pexels-photo-437037.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'wh-1000xm5',
    url: 'https://images.pexels.com/photos/3394664/pexels-photo-3394664.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'airpods pro',
    url: 'https://images.pexels.com/photos/788946/pexels-photo-788946.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '耳机',
    url: 'https://images.pexels.com/photos/3394668/pexels-photo-3394668.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '充电宝',
    url: 'https://images.pexels.com/photos/404280/pexels-photo-404280.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: 'ssd',
    url: 'https://images.pexels.com/photos/343457/pexels-photo-343457.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
]

const dailyRules: Rule[] = [
  {
    keyword: '中性笔',
    url: 'https://images.pexels.com/photos/211092/pexels-photo-211092.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '活页本',
    url: 'https://images.pexels.com/photos/261209/pexels-photo-261209.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '纸巾',
    url: 'https://images.pexels.com/photos/3944405/pexels-photo-3944405.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '一次性手套',
    url: 'https://images.pexels.com/photos/4167544/pexels-photo-4167544.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '收纳盒',
    url: 'https://images.pexels.com/photos/3738089/pexels-photo-3738089.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '整理箱',
    url: 'https://images.pexels.com/photos/3738086/pexels-photo-3738086.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '抱枕',
    url: 'https://images.pexels.com/photos/276583/pexels-photo-276583.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '台灯',
    url: 'https://images.pexels.com/photos/112811/pexels-photo-112811.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '垃圾袋',
    url: 'https://images.pexels.com/photos/3738083/pexels-photo-3738083.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
]

const beautyRules: Rule[] = [
  {
    keyword: '防晒',
    url: 'https://images.pexels.com/photos/6235691/pexels-photo-6235691.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '眉笔',
    url: 'https://images.pexels.com/photos/3373744/pexels-photo-3373744.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '睫毛膏',
    url: 'https://images.pexels.com/photos/3373744/pexels-photo-3373744.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '洁面',
    url: 'https://images.pexels.com/photos/3738355/pexels-photo-3738355.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '精华',
    url: 'https://images.pexels.com/photos/3735612/pexels-photo-3735612.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '面霜',
    url: 'https://images.pexels.com/photos/3735387/pexels-photo-3735387.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '口红',
    url: 'https://images.pexels.com/photos/3373744/pexels-photo-3373744.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '香水',
    url: 'https://images.pexels.com/photos/965989/pexels-photo-965989.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
]

const foodRules: Rule[] = [
  {
    keyword: '每日坚果',
    url: 'https://images.pexels.com/photos/1435736/pexels-photo-1435736.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '挂耳咖啡',
    url: 'https://images.pexels.com/photos/373888/pexels-photo-373888.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '咖啡豆',
    url: 'https://images.pexels.com/photos/917636/pexels-photo-917636.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '菜籽油',
    url: 'https://images.pexels.com/photos/414262/pexels-photo-414262.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '橄榄油',
    url: 'https://images.pexels.com/photos/208088/pexels-photo-208088.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '小麦粉',
    url: 'https://images.pexels.com/photos/4198320/pexels-photo-4198320.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '水饺',
    url: 'https://images.pexels.com/photos/716715/pexels-photo-716715.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '鸡翅',
    url: 'https://images.pexels.com/photos/4106483/pexels-photo-4106483.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '肥牛',
    url: 'https://images.pexels.com/photos/65175/pexels-photo-65175.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '虾仁',
    url: 'https://images.pexels.com/photos/3642711/pexels-photo-3642711.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '披萨',
    url: 'https://images.pexels.com/photos/2619967/pexels-photo-2619967.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '坚果',
    url: 'https://images.pexels.com/photos/1435736/pexels-photo-1435736.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '薯片',
    url: 'https://images.pexels.com/photos/1583884/pexels-photo-1583884.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '咖啡',
    url: 'https://images.pexels.com/photos/373888/pexels-photo-373888.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '红茶',
    url: 'https://images.pexels.com/photos/260733/pexels-photo-260733.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '大米',
    url: 'https://images.pexels.com/photos/4110251/pexels-photo-4110251.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
]

const sportRules: Rule[] = [
  {
    keyword: '跑步鞋 男',
    url: 'https://images.pexels.com/photos/2529157/pexels-photo-2529157.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '跑步鞋 女',
    url: 'https://images.pexels.com/photos/19090/pexels-photo.jpg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '短袖',
    url: 'https://images.pexels.com/photos/298863/pexels-photo-298863.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '压缩裤',
    url: 'https://images.pexels.com/photos/4164510/pexels-photo-4164510.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '臂包',
    url: 'https://images.pexels.com/photos/5711299/pexels-photo-5711299.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '折叠椅',
    url: 'https://images.pexels.com/photos/566483/pexels-photo-566483.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '野营灯',
    url: 'https://images.pexels.com/photos/439343/pexels-photo-439343.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '保温壶',
    url: 'https://images.pexels.com/photos/167092/pexels-photo-167092.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '餐具',
    url: 'https://images.pexels.com/photos/3184186/pexels-photo-3184186.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '哑铃',
    url: 'https://images.pexels.com/photos/1552252/pexels-photo-1552252.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '跳绳',
    url: 'https://images.pexels.com/photos/4133166/pexels-photo-4133166.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '阻力带',
    url: 'https://images.pexels.com/photos/6454082/pexels-photo-6454082.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '引体向上',
    url: 'https://images.pexels.com/photos/414032/pexels-photo-414032.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '公路自行车',
    url: 'https://images.pexels.com/photos/276517/pexels-photo-276517.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '山地车',
    url: 'https://images.pexels.com/photos/161172/bicycle-bike-pavement-ride-161172.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '跑步鞋',
    url: 'https://images.pexels.com/photos/2529157/pexels-photo-2529157.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '帐篷',
    url: 'https://images.pexels.com/photos/1687845/pexels-photo-1687845.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '瑜伽垫',
    url: 'https://images.pexels.com/photos/3822621/pexels-photo-3822621.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '哑铃',
    url: 'https://images.pexels.com/photos/1552252/pexels-photo-1552252.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
  {
    keyword: '自行车',
    url: 'https://images.pexels.com/photos/276517/pexels-photo-276517.jpeg?auto=compress&cs=tinysrgb&w=1200',
  },
]

const fallbackByCategory: Record<ProductCategoryHint, string> = {
  phone: 'https://images.pexels.com/photos/13570143/pexels-photo-13570143.jpeg?auto=compress&cs=tinysrgb&w=1200',
  computer: 'https://images.pexels.com/photos/18105/pexels-photo.jpg?auto=compress&cs=tinysrgb&w=1200',
  appliance: 'https://encrypted-tbn0.gstatic.com/shopping?q=tbn:ANd9GcTfmPOAkUxrAHGabZX6fbywDzGCZAp3pvRBLlB0cApRXxiciD4abVOIaTj7EwA9CgcqxRbsVz0ouE-iHACyQUZ-jnQrRjaFu_4lP4vZdVIf0lN08wxeq9-F2wPj3lxVxKxw_kuiBCc&usqp=CAc?auto=compress&cs=tinysrgb&w=1200',
  digital: 'https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-17-pro-max-colors.png?auto=compress&cs=tinysrgb&w=1200',
  daily: 'https://images.pexels.com/photos/3738089/pexels-photo-3738089.jpeg?auto=compress&cs=tinysrgb&w=1200',
  beauty: 'https://images.pexels.com/photos/3734881/pexels-photo-3734881.jpeg?auto=compress&cs=tinysrgb&w=1200',
  food: 'https://images.pexels.com/photos/1025804/pexels-photo-1025804.jpeg?auto=compress&cs=tinysrgb&w=1200',
  sport: 'https://images.pexels.com/photos/841130/pexels-photo-841130.jpeg?auto=compress&cs=tinysrgb&w=1200',
}

const applyRules = (name: string, rules: Rule[]): string | null => {
  const n = name.toLowerCase()
  for (const r of rules) {
    if (n.includes(r.keyword.toLowerCase())) return r.url
  }
  return null
}

export const getProductCover = (name: string, hint?: ProductCategoryHint): string | null => {
  const phone = applyRules(name, phoneRules)
  if (phone) return phone
  const computer = applyRules(name, computerRules)
  if (computer) return computer
  const appliance = applyRules(name, applianceRules)
  if (appliance) return appliance
  const digital = applyRules(name, digitalRules)
  if (digital) return digital
  const daily = applyRules(name, dailyRules)
  if (daily) return daily
  const beauty = applyRules(name, beautyRules)
  if (beauty) return beauty
  const food = applyRules(name, foodRules)
  if (food) return food
  const sport = applyRules(name, sportRules)
  if (sport) return sport
  if (hint) return fallbackByCategory[hint] || null
  return null
}

