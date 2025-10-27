<?php
// 服务器配置
$servers = array(
    '1' => array(
        'id' => '1',
        'name' => '一区·新手村',
        'host' => '183.131.83.76,65101',
        'db_account' => 'account',
        'db_cash' => 'cash',
        'db_character' => 'character',
        'status' => 'hot',
        'open_time' => '2025-01-01',
        'user' => 'sa',
        'pass' => 'zzgm99w4$1',
        'admin_character' => 'E24080630000000032'  // 一区管理员角色ID
    ),
    '2' => array(
        'id' => '2',
        'name' => '二区·冒险城',
        'host' => '183.131.83.76,65101',
        'db_account' => 'account',
        'db_cash' => 'cash',
        'db_character' => 'character',
        'status' => 'normal',
        'open_time' => '2025-01-15',
        'user' => 'sa',
        'pass' => 'zzgm99w4$1',
        'admin_character' => 'E24080630000000032'  // 二区管理员角色ID（暂时相同）
    ),
    '3' => array(
        'id' => '3',
        'name' => '三区·龙之谷',
        'host' => '183.131.83.76,65101',
        'db_account' => 'account',
        'db_cash' => 'cash',
        'db_character' => 'character',
        'status' => 'recommend',
        'open_time' => '2025-02-01',
        'user' => 'sa',
        'pass' => 'zzgm99w4$1',
        'admin_character' => 'E24080630000000032'  // 三区管理员角色ID（暂时相同）
    )
);

// 市场配置
define('MARKET_MAX_ITEMS_PER_USER', 10); // 每个账号最多发布物品数量

// 默认服务器ID（可以设置为最新开的服务器）
define('DEFAULT_SERVER_ID', '3');

// 支付宝配置（使用MD5接口，和ASP相同）
define('ALIPAY_PARTNER', '2088002135244083'); // 合作身份者ID
define('ALIPAY_KEY', '6yzb1d5va5sgtl9ka0fzd8zsr8a2z50g'); // 安全检验码
define('ALIPAY_SELLER_EMAIL', 'love_zxd@163.com'); // 收款支付宝账号
define('ALIPAY_GATEWAY', 'https://www.alipay.com/cooperate/gateway.do'); // MD5接口网关
define('ALIPAY_CHARSET', 'gbk'); // 字符编码，ASP用的是gbk
define('ALIPAY_SIGN_TYPE', 'MD5'); // 签名方式
define('ALIPAY_INPUT_CHARSET', 'gbk'); // 输入字符集
define('ALIPAY_TRANSPORT', 'http'); // 访问模式

// 网站配置
define('SITE_NAME', '游戏官网');
define('SITE_URL', 'https://reg.cnctz.com/i');

// 禁止缓存
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Cache-Control: post-check=0, pre-check=0', false);
header('Pragma: no-cache');
header('Expires: 0');

// URL生成函数
function site_url($path = '') {
    return SITE_URL . '/' . ltrim($path, '/');
}

// 货币配置
$currency_config = array(
    'c_coin' => array(
        'name' => 'C币',
        'description' => '游戏币（绑定）',
        'ratio' => 100, // 1元=100C币
        'icon' => 'fas fa-coins',
        'color' => '#f39c12',
        'table_field' => 'C_Coin' // 数据库字段名
    ),
    'b_coin' => array(
        'name' => 'B币',
        'description' => '商城币',
        'ratio' => 100, // 1元=10B币
        'icon' => 'fas fa-gem',
        'color' => '#9b59b6',
        'table_field' => 'B_Coin' // 数据库字段名
    )
);

define('MIN_AMOUNT', 0.01); // 最低充值金额
define('MAX_AMOUNT', 50000); // 最高充值金额

// VIP等级配置
$vip_levels = array(
    0 => array('name' => '普通玩家', 'icon' => 'fas fa-user', 'color' => '#95a5a6'),
    1 => array('name' => 'VIP 1', 'icon' => 'fas fa-gem', 'color' => '#3498db', 'min_amount' => 50),
    2 => array('name' => 'VIP 2', 'icon' => 'fas fa-crown', 'color' => '#9b59b6', 'min_amount' => 200),
    3 => array('name' => 'VIP 3', 'icon' => 'fas fa-star', 'color' => '#f39c12', 'min_amount' => 500),
    4 => array('name' => 'VIP 4', 'icon' => 'fas fa-fire', 'color' => '#e67e22', 'min_amount' => 1000),
    5 => array('name' => 'VIP 5', 'icon' => 'fas fa-bolt', 'color' => '#e74c3c', 'min_amount' => 2000),
    6 => array('name' => 'VIP 6', 'icon' => 'fas fa-shield-alt', 'color' => '#8e44ad', 'min_amount' => 5000)
);

// 充值优惠配置
$recharge_bonuses = array(
    array('min_amount' => 100, 'bonus_rate' => 1.05),  // 100元送5%
    array('min_amount' => 500, 'bonus_rate' => 1.10),  // 500元送10%
    array('min_amount' => 1000, 'bonus_rate' => 1.15), // 1000元送15%
    array('min_amount' => 5000, 'bonus_rate' => 1.20)  // 5000元送20%
);

// 获取服务器管理员ID的函数
function get_admin_character($server_id) {
    global $servers;
    if (isset($servers[$server_id]['admin_character'])) {
        return $servers[$server_id]['admin_character'];
    }
    return 'E24080630000000032'; // 默认值
}

// 检查用户发布物品数量
function checkUserMarketItemsCount($server_id, $user_no) {
    if (!$server_id || !$user_no) {
        return ['allowed' => false, 'count' => 0, 'max' => MARKET_MAX_ITEMS_PER_USER];
    }
    
    $db_character = get_db($server_id, 'character');
    
    // 获取用户所有角色
    $characters = $db_character->fetchAll("
        SELECT character_no FROM user_character WHERE user_no = ?
    ", [$user_no]);
    
    if (empty($characters)) {
        return ['allowed' => true, 'count' => 0, 'max' => MARKET_MAX_ITEMS_PER_USER];
    }
    
    // 构建角色列表
    $character_list = [];
    foreach ($characters as $char) {
        $character_list[] = $char['character_no'];
    }
    
    // 获取管理员角色
    $admin_character = get_admin_character($server_id);
    
    // 统计该用户在市场的物品数量
    $placeholders = str_repeat('?,', count($character_list) - 1) . '?';
    $count = $db_character->fetch("
        SELECT COUNT(*) as total 
        FROM USER_POSTBOX 
        WHERE sell_character_no IN ($placeholders)
        AND character_no = ?
    ", array_merge($character_list, [$admin_character]));
    
    $total = $count['total'] ?? 0;
    
    return [
        'allowed' => $total < MARKET_MAX_ITEMS_PER_USER,
        'count' => $total,
        'max' => MARKET_MAX_ITEMS_PER_USER
    ];
}

// 全局函数 - 获取用户角色列表
function getUserCharacters($server_id, $user_no) {
    if (!$server_id || !$user_no) return [];
    try {
        $db_character = get_db($server_id, 'character');
        return $db_character->fetchAll("
            SELECT character_no, character_name, wlevel 
            FROM user_character 
            WHERE user_no = ? 
            ORDER BY wlevel DESC
        ", [$user_no]);
    } catch (Exception $e) {
        return [];
    }
}

// 全局函数 - 显示Toast提示
function showToast($message, $type = 'info') {
    echo "<script>
        if (typeof showToast === 'function') {
            showToast('$message', '$type');
        } else {
            alert('$message');
        }
    </script>";
}

// 全局函数 - 获取随机背景图片
function getRandomBackground() {
    $background_images = [
        'https://bpic.588ku.com/back_pic/06/12/54/38624af7c59f79c.jpg',
        'https://pic.616pic.com/bg_w1180/00/04/86/oCg6sW7CzV.jpg',
        'https://img.tukuppt.com/bg_grid/05/87/43/5kyd1f2IHH.jpg',
        'https://bpic.588ku.com/back_pic/06/12/39/21624128b27941b.jpg'
    ];
    return $background_images[array_rand($background_images)];
}

// 使用函数存在检查，避免重复定义
if (!function_exists('get_server_info')) {
    function get_server_info($server_id) {
        global $servers;
        return isset($servers[$server_id]) ? $servers[$server_id] : null;
    }
}

if (!function_exists('get_all_servers')) {
    function get_all_servers() {
        global $servers;
        return $servers;
    }
}

if (!function_exists('get_available_servers')) {
    function get_available_servers() {
        global $servers;
        $available = array();
        foreach ($servers as $server) {
            if ($server['status'] != 'maintain') {
                $available[$server['id']] = $server;
            }
        }
        return $available;
    }
}
?>
