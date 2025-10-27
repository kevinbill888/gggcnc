<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

// 禁止缓存
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
header('Cache-Control: post-check=0, pre-check=0', false);
header('Pragma: no-cache');
header('Expires: 0');

// 引入根目录下的认证模块
require_once '../config.php';
require_once '../auth.php';
require_once '../db.php';

// 引入物品解析模块
require_once 'item_parser.php';

// 处理购买请求
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    if ($_POST['action'] === 'buy') {
        if (!is_logged_in()) {
            echo json_encode(['success' => false, 'message' => '请先登录']);
            exit;
        }
        
        $post_no = $_POST['post_no'];
        $character_no = $_POST['character_no'];
        $server_id = $_SESSION['server_id'];
        $user_no = $_SESSION['user_no'];
        
        // 添加调试信息
        error_log("Debug: Purchase request - post_no: $post_no, character_no: $character_no, user_no: $user_no");
        
        $result = handlePurchase($post_no, $character_no);
        echo json_encode($result);
        exit;
    }
}

// 检查登录状态
$is_logged_in = is_logged_in();
$user_no = $is_logged_in ? $_SESSION['user_no'] : null;
$server_id = $is_logged_in ? $_SESSION['server_id'] : null;

// 仓库管理员角色ID
$admin_character = get_admin_character($server_id);

// 获取当前角色信息
$current_character = null;
if ($is_logged_in && $server_id) {
    $db_character = get_db($server_id, 'character');
    
    // 优先从Session获取
    if (!empty($_SESSION['current_character_no'])) {
        $current_character = $db_character->fetch("
            SELECT character_no, character_name 
            FROM user_character 
            WHERE character_no = ? AND user_no = ?
        ", [$_SESSION['current_character_no'], $user_no]);
    }
    
    // 如果Session中没有，获取第一个角色
    if (!$current_character) {
        $current_character = $db_character->fetch("
            SELECT TOP 1 character_no, character_name 
            FROM user_character 
            WHERE user_no = ? 
            ORDER BY wlevel DESC
        ", [$user_no]);
        
        if ($current_character) {
            $_SESSION['current_character_no'] = $current_character['character_no'];
            $_SESSION['current_character_name'] = $current_character['character_name'];
        }
    }
}

// 创建物品解析器实例
if ($is_logged_in && $server_id) {
    $db_account = get_db($server_id, 'account');
    $db_character = get_db($server_id, 'character');
    $itemParser = new ItemParser($db_account, $db_character);
} else {
    $itemParser = null;
}

// 使用存储过程获取市场物品
function getMarketItems($server_id,$user_no, $admin_character,$itemParser) {
    try {
        if (!$server_id) {
            return array(
                'items' => array(),
                'user_cash' => 0,
                'user_b_coin' => 0,
                'error' => '请先选择服务器'
            );
        }
        
        $db_character = get_db($server_id, 'character');
        $db_cash = get_db($server_id, 'cash');
        
        // 获取用户余额
        $user_cash = 0;
        $user_b_coin = 0;
        
        if ($user_no) {
            $user =$db_cash->fetch(
                "SELECT amount, b_amount FROM user_cash WHERE user_no = ?",
                array($user_no)
            );
            
            if ($user) {
                $user_cash =$user['amount'] ?? 0;
                $user_b_coin =$user['b_amount'] ?? 0;
            }
        }
        
        // 使用存储过程获取市场物品
        $items =$db_character->fetchAll(
            "EXEC sp_GetMarketItems @AdminCharacter = ?",
            array($admin_character)
        );
        
        // 解析物品属性
        $market_items = array();
        foreach ($items as$item) {
            // 使用物品解析器解析物品属性
            $raw_attrs = '';
            if ($itemParser && !empty($item['item_name'])) {
                // 获取物品的info和byHeader
                $item_detail =$db_character->fetch(
                    "SELECT info, byHeader FROM USER_POSTBOX WHERE post_no = ?",
                    array($item['post_no'])
                );
                
                if ($item_detail) {
                    $raw_attrs =$itemParser->getItemDetailsJson(
                        $item['item_name'], 
                        $item_detail['info'], 
                        $item_detail['byHeader']
                    );
                }
            }
            
            // 检查是否买得起
            $can_afford =$user_b_coin >= $item['price'];
            
            $market_items[] = array(
                'post_no' => $item['post_no'],
                'windex' => $item['windex'],
                'item_name' => $item['item_name'],
                'sell_character_no' => $item['sell_character_no'],
                'seller_name' => $item['seller_name'],
                'price' => $item['price'],
                'post_time' => $item['post_time'],
                'post_title' => $item['post_title'],
                'body_text' => $item['body_text'],
                'raw_attrs' => $raw_attrs,
                'can_afford' => $can_afford
            );
        }
        
        return array(
            'items' => $market_items,
            'user_cash' => $user_cash,
            'user_b_coin' => $user_b_coin,
            'error' => null
        );
        
    } catch (Exception $e) {
        error_log("Error in getMarketItems: " . $e->getMessage());
        return array(
            'items' => array(),
            'user_cash' => 0,
            'user_b_coin' => 0,
            'error' => $e->getMessage()
        );
    }
}

// 处理购买/取回请求
function handlePurchase($post_no, $character_no) {
    try {
        $server_id = $_SESSION['server_id'];
        $user_no = $_SESSION['user_no'];
        
        $db_character = get_db($server_id, 'character');
        $db_account = get_db($server_id, 'account');
        $db_cash = get_db($server_id, 'cash');
        
        // 添加调试信息
        error_log("Debug: handlePurchase - post_no: $post_no, character_no: $character_no, user_no: $user_no");
        
        // 验证角色归属 - 确保角色属于当前用户
        $character = $db_character->fetch("
            SELECT user_no, character_name FROM user_character 
            WHERE character_no = ? AND user_no = ?
        ", [$character_no, $user_no]);
        
        if (!$character) {
            error_log("Debug: Character validation failed - character_no: $character_no, user_no: $user_no");
            throw new Exception('角色不属于您，请重新选择角色');
        }
        
        $character_name = $character['character_name'];
        error_log("Debug: Character validated - name: $character_name");
        
        // 获取物品信息
        $item = $db_character->fetch("
            SELECT post_no, Windex, sell_character_no, include_dil, 
                   ipt_time, post_title, body_text, info, byHeader
            FROM USER_POSTBOX 
            WHERE post_no = ?
        ", [$post_no]);

        if (!$item) {
            error_log("Debug: Item not found for post_no = " . $post_no);
            throw new Exception("物品不存在或已售出 (post_no: " . $post_no . ")");
        }
        
        // 确保获取到物品ID
        $windex = (int)($item['Windex'] ?? 0);
        if ($windex <= 0) {
            throw new Exception("物品ID无效 (Windex: $windex)");
        }
        
        // 判断是否本人取回
        $is_self_recall = ($item['sell_character_no'] == $character_no);
        
        if ($is_self_recall) {
            // 本人取回操作
            $db_character->exec("
                UPDATE USER_POSTBOX 
                SET character_no = ?,
                    from_char_nm = '系统管理员',
                    post_title = '装备取回成功',
                    body_text = '您已成功取回自己寄售的装备，请在90天内取出',
                    state_tag = 0,
                    ipt_time = GETDATE(),
                    expire_time = DATEADD(day, 90, GETDATE())
                WHERE post_no = ?
            ", [$character_no, $post_no]);
            
            $message = '装备取回成功！';
            
        } else {
            // 非本人购买操作
            // 1. 检查B币余额
            $user_balance = $db_cash->fetch("
                SELECT b_amount FROM user_cash WHERE user_no = ?
            ", [$user_no]);
            
            if (!$user_balance) {
                throw new Exception("未找到用户余额记录");
            }
            
            if ($user_balance['b_amount'] < $item['include_dil']) {
                throw new Exception("余额不足，需要 {$item['include_dil']} B币，当前余额：" . $user_balance['b_amount']);
            }
            
            // 2. 扣除B币
            $db_cash->exec("
                UPDATE user_cash SET b_amount = b_amount - ? WHERE user_no = ?
            ", [$item['include_dil'], $user_no]);
            
            // 3. 更新邮件给购买者
            $db_character->exec("
                UPDATE USER_POSTBOX 
                SET character_no = ?,
                    from_char_nm = '交易市场',
                    post_title = '购买成功',
                    body_text = '您已成功购买此装备，请在90天内取出',
                    state_tag = 0,
                    ipt_time = GETDATE(),
                    expire_time = DATEADD(day, 90, GETDATE())
                WHERE post_no = ?
            ", [$character_no, $post_no]);
            
            // 4. 给卖家加B币（80%）
            $seller_amount = intval($item['include_dil'] * 0.8);
            
            // 获取卖家信息
            $seller = $db_character->fetch("
                SELECT user_no, character_name FROM user_character WHERE character_no = ?
            ", [$item['sell_character_no']]);
            
            if ($seller) {
                $db_cash->exec("
                    UPDATE user_cash SET b_amount = b_amount + ? WHERE user_no = ?
                ", [$seller_amount, $seller['user_no']]);
            }
            
            // 5. 记录交易到 web_market 表
            $db_account->exec("
                INSERT INTO web_market (
                    buy_name, sell_name, IP, time, Money, Windex, 
                    buy_user_no, sell_user_no, actual_amount, status
                ) VALUES (?, ?, ?, GETDATE(), ?, ?, ?, ?, ?, 1)
            ", [
                $character_name,
                $seller['character_name'] ?? '未知卖家',
                $_SERVER['REMOTE_ADDR'],
                $item['include_dil'],
                $windex,
                $user_no,
                $seller['user_no'],
                $seller_amount,
                1
            ]);
            
            $message = '购买成功！';
        }
        
        return ['success' => true, 'message' => $message];
        
    } catch (Exception $e) {
        error_log("Debug: Purchase failed - " . $e->getMessage());
        return ['success' => false, 'message' => $e->getMessage()];
    }
}

// 获取页面数据
$market_data = getMarketItems($server_id, $user_no, $admin_character, $itemParser);

// 设置页面信息
$page_title = '游戏市场';
$breadcrumbs = [
    ['name' => '游戏市场', 'url' => site_url('market/')]
];

// 引入物品图标识别模块
require_once '../includes/item_icon_helper.php';

// 引入头部模板
include '../templates/header.php';
?>

<!-- 确保背景通透 -->
<style>
body {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%) !important;
}

/* 角色选择器样式 */
.character-selector {
    background: rgba(20, 20, 20, 0.9);
    backdrop-filter: blur(10px);
    border-radius: 12px;
    padding: 20px;
    margin-bottom: 30px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
}

.character-selector h3 {
    color: #f0f0f0;
    margin-bottom: 15px;
    font-size: 18px;
    display: flex;
    align-items: center;
    gap: 10px;
}

.character-selector h3 i {
    color: #4a9eff;
}

.character-options {
    display: flex;
    gap: 15px;
    flex-wrap: wrap;
}

.character-option {
    background: rgba(30, 30, 30, 0.8);
    border: 2px solid rgba(255, 255, 255, 0.1);
    border-radius: 8px;
    padding: 12px 20px;
    cursor: pointer;
    transition: all 0.3s ease;
    display: flex;
    align-items: center;
    gap: 10px;
    color: #e0e0e0;
}

.character-option:hover {
    background: rgba(74, 158, 255, 0.2);
    border-color: #4a9eff;
    transform: translateY(-2px);
}

.character-option.active {
    background: rgba(74, 158, 255, 0.3);
    border-color: #4a9eff;
    color: #4a9eff;
    font-weight: 600;
}

.character-option i {
    font-size: 20px;
}

.character-name {
    font-weight: 500;
}

.character-level {
    font-size: 12px;
    color: #888;
    margin-left: 5px;
}

/* 确保市场容器样式 */
.market-container {
    background: rgba(15, 15, 15, 0.85) !important;
    backdrop-filter: blur(20px) !important;
    color: #e0e0e0 !important;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif !important;
    padding: 30px !important;
    border-radius: 12px !important;
    margin: 30px auto !important;
    max-width: 1400px !important;
    box-shadow: 0 15px 50px rgba(0, 0, 0, 0.5) !important;
    border: 1px solid rgba(255, 255, 255, 0.15) !important;
    position: relative !important;
    z-index: 1 !important;
}

/* 横条式物品列表 */
.market-items-list {
    margin-top: 30px;
}

.market-item-row {
    display: flex;
    align-items: center;
    padding: 15px 20px;
    margin-bottom: 10px;
    background: rgba(30, 30, 30, 0.8);
    border-radius: 8px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    transition: all 0.3s ease;
    cursor: pointer;
    position: relative;
}

/* 隔行换色 */
.market-item-row:nth-child(even) {
    background: rgba(40, 40, 40, 0.8);
}

/* 鼠标悬停效果 */
.market-item-row:hover {
    background: rgba(74, 158, 255, 0.2) !important;
    border-color: #4a9eff !important;
    transform: translateX(5px);
    box-shadow: 0 5px 20px rgba(74, 158, 255, 0.3);
}

.market-item-icon {
    width: 50px;
    height: 50px;
    border-radius: 8px;
    margin-right: 20px;
    border: 2px solid rgba(255, 255, 255, 0.2);
    object-fit: cover;
    transition: all 0.3s ease;
}

.market-item-row:hover .market-item-icon {
    transform: scale(1.1);
    border-color: #4a9eff;
    box-shadow: 0 4px 12px rgba(74, 158, 255, 0.4);
}

.market-item-info {
    flex: 1;
    display: flex;
    align-items: center;
    gap: 30px;
}

.market-item-name {
    font-size: 16px;
    font-weight: 600;
    color: #f0f0f0;
    min-width: 200px;
    cursor: help;
    transition: color 0.3s ease;
}

.market-item-row:hover .market-item-name {
    color: #4a9eff;
}

.market-item-seller {
    color: #b0b0b0;
    min-width: 120px;
}

.market-item-time {
    color: #888;
    font-size: 14px;
    min-width: 150px;
}

.market-item-price {
    color: #ffc107;
    font-weight: 700;
    font-size: 18px;
    min-width: 100px;
    text-align: right;
}

.market-item-action {
    margin-left: 20px;
}

.market-btn-buy {
    padding: 8px 20px;
    background: linear-gradient(135deg, #4a9eff, #3a7ecc);
    border: none;
    border-radius: 6px;
    color: white;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
    box-shadow: 0 2px 8px rgba(74, 158, 255, 0.3);
}

.market-btn-buy:hover:not(:disabled) {
    background: linear-gradient(135deg, #5aa8ff, #4a8edd);
    transform: translateY(-2px);
    box-shadow: 0 4px 15px rgba(74, 158, 255, 0.4);
}

.market-btn-buy:disabled {
    background: #666;
    cursor: not-allowed;
    box-shadow: none;
}

/* 余额卡片样式 */
.balance-cards {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 20px;
    margin-bottom: 30px;
}

.balance-card {
    background: rgba(20, 20, 20, 0.8);
    padding: 25px;
    border-radius: 12px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(10px);
    text-align: center;
    transition: all 0.3s ease;
}

.balance-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
    border-color: #4a9eff;
}

.balance-icon {
    font-size: 36px;
    margin-bottom: 15px;
    display: block;
}

.balance-title {
    font-size: 14px;
    color: #b0b0b0;
    margin-bottom: 10px;
    text-transform: uppercase;
    letter-spacing: 1px;
}

.balance-amount {
    font-size: 28px;
    font-weight: 700;
    color: #f0f0f0;
}

.balance-card.c-coin .balance-icon { color: #ffc107; }
.balance-card.b-coin .balance-icon { color: #4a9eff; }
.balance-card.items-count .balance-icon { color: #28a745; }

/* 空状态 */
.empty-state {
    text-align: center;
    padding: 80px 20px;
    color: #b0b0b0;
}

.empty-state i {
    font-size: 80px;
    margin-bottom: 20px;
    opacity: 0.5;
    filter: drop-shadow(0 2px 4px rgba(0,0,0,0.5));
}

.empty-state h3 {
    font-size: 24px;
    margin-bottom: 10px;
    color: #e0e0e0;
}

.empty-state p {
    font-size: 16px;
    margin-bottom: 30px;
}

/* Tooltip样式 */
#mouseTooltip {
    position: fixed;
    display: none;
    z-index: 9999999;
    max-width: 520px;
    background: rgba(10, 10, 10, 0.96);
    color: #e0e0e0;
    padding: 0;
    border-radius: 8px;
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.6);
    font-size: 13px;
    pointer-events: none;
    line-height: 1.35;
    border: 1px solid rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(10px);
}

#mouseTooltip .tt-header {
    padding: 10px 12px;
    background: rgba(30, 30, 30, 0.9);
    border-radius: 8px 8px 0 0;
    font-weight: 700;
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
    color: #f0f0f0;
}

#mouseTooltip .tt-body {
    padding: 10px 12px;
}

#mouseTooltip .tt-line {
    margin: 6px 0;
    word-break: break-word;
    white-space: normal;
    display: flex;
    align-items: baseline;
}

#mouseTooltip .tt-name {
    color: #e0e0e0;
    margin-right: 8px;
    font-weight: 600;
}

#mouseTooltip .tt-plus {
    color: #f0f0f0;
    margin-right: 6px;
    font-weight: 700;
}

#mouseTooltip .tt-val {
    font-weight: 700;
}

.gt-group-title {
    margin-top: 8px;
    color: #b0b0b0;
    font-weight: 700;
}

.gt-gap {
    height: 8px;
}

/* 属性颜色 */
.attr-color-1 { color: #60a5fa !important; }
.attr-color-2 { color: #1d4ed8 !important; }
.attr-color-3 { color: #8b5cf6 !important; }
.attr-color-4 { color: #f59e0b !important; }
.attr-color-5, .attr-color-6, .attr-color-7, .attr-color-8, 
.attr-color-9, .attr-color-10, .attr-color-11, .attr-color-12, 
.attr-color-13, .attr-color-14, .attr-color-15, .attr-color-16 { 
    color: #ef4444 !important; 
}

.attr-socket {
    color: #ef4444 !important;
    font-weight: 700;
}

.muted {
    color: #6c757d !important;
}
</style>

<!-- 市场主容器 -->
<div class="market-container">
    <!-- 角色选择器 -->
    <?php if ($is_logged_in && $server_id): ?>
        <div class="character-selector">
            <h3><i class="fas fa-user"></i> 选择购买角色</h3>
            <div class="character-options">
                <?php 
                $characters = getUserCharacters($server_id, $user_no);
                foreach ($characters as $char): 
                ?>
                    <div class="character-option <?php echo ($current_character['character_no'] ?? '') == $char['character_no'] ? 'active' : ''; ?>" 
                         data-character-no="<?php echo $char['character_no']; ?>"
                         data-character-name="<?php echo htmlspecialchars($char['character_name']); ?>"
                         onclick="selectCharacter(this)">
                        <i class="fas fa-user-circle"></i>
                        <div>
                            <span class="character-name"><?php echo htmlspecialchars($char['character_name']); ?></span>
                            <span class="character-level">Lv.<?php echo $char['wlevel']; ?></span>
                        </div>
                    </div>
                <?php endforeach; ?>
            </div>
        </div>
    <?php endif; ?>
    
    <!-- 页面头部 -->
    <div class="page-header">
        <div class="page-title">
            <i class="fas fa-store"></i>
            游戏市场
        </div>
        <div class="page-subtitle">
            发现珍稀装备，打造最强角色
        </div>
    </div>
    
    <!-- 余额显示 -->
    <div class="balance-cards">
        <div class="balance-card c-coin">
            <i class="fas fa-coins balance-icon"></i>
            <div class="balance-title">C币</div>
            <div class="balance-amount"><?php echo number_format($market_data['user_cash']); ?></div>
        </div>
        <div class="balance-card b-coin">
            <i class="fas fa-gem balance-icon"></i>
            <div class="balance-title">B币</div>
            <div class="balance-amount"><?php echo number_format($market_data['user_b_coin']); ?></div>
        </div>
        <div class="balance-card items-count">
            <i class="fas fa-box balance-icon"></i>
            <div class="balance-title">市场物品</div>
            <div class="balance-amount"><?php echo count($market_data['items']); ?></div>
        </div>
    </div>
    
    <!-- 错误提示 -->
    <?php if (isset($market_data['error'])): ?>
        <div style="color: #ff6b6b; padding: 15px; background: rgba(220, 53, 69, 0.1); border-radius: 8px; margin-bottom: 20px; border: 1px solid rgba(220, 53, 69, 0.3);">
            <strong>错误:</strong> <?php echo $market_data['error']; ?>
        </div>
    <?php elseif (empty($market_data['items'])): ?>
        <div class="empty-state">
            <i class="fas fa-box-open"></i>
            <h3>市场暂无物品</h3>
            <p>请稍后再来查看</p>
        </div>
    <?php else: ?>
        <!-- 物品列表 - 横条式 -->
        <div class="market-items-list">
            <?php foreach ($market_data['items'] as $index => $item): ?>
                <div class="market-item-row" 
                     data-itemname="<?php echo htmlspecialchars($item['item_name']); ?>" 
                     data-rawattrs="<?php echo htmlspecialchars($item['raw_attrs']); ?>">
                    <img src="<?php echo getItemIconUrl($item['item_name']); ?>" 
                         alt="<?php echo htmlspecialchars($item['item_name']); ?>" 
                         class="market-item-icon">
                    <div class="market-item-info">
                        <div class="market-item-name"><?php echo htmlspecialchars($item['item_name']); ?></div>
                        <div class="market-item-seller">卖家: <?php echo htmlspecialchars($item['seller_name']); ?></div>
                        <div class="market-item-time"><?php echo date('Y-m-d H:i', strtotime($item['post_time'])); ?></div>
                        <div class="market-item-price"><?php echo number_format($item['price']); ?> B币</div>
                    </div>
                    <div class="market-item-action">
                        <button class="market-btn-buy" 
                                onclick="buyItem('<?php echo $item['post_no']; ?>')"
                                <?php echo !$item['can_afford'] || !$is_logged_in ? 'disabled' : ''; ?>>
                            <?php 
                            if (!$is_logged_in) {
                                echo '请登录';
                            } elseif ($item['can_afford']) {
                                echo '购买';
                            } else {
                                echo '余额不足';
                            }
                            ?>
                        </button>
                    </div>
                </div>
            <?php endforeach; ?>
        </div>
    <?php endif; ?>
</div>

<script>
// 检查是否是购买成功后的刷新
const urlParams = new URLSearchParams(window.location.search);
const purchaseSuccess = urlParams.get('purchase_success');
const purchaseMessage = urlParams.get('purchase_message');

// 如果有购买成功参数，显示提示
if (purchaseSuccess === '1' && purchaseMessage) {
    // 立即显示提示，不等待DOMContentLoaded
    const message = decodeURIComponent(purchaseMessage);
    console.log('显示购买成功提示:', message);
    
    // 创建一个临时的提示元素
    const tempToast = document.createElement('div');
    tempToast.style.cssText = `
        position: fixed;
        top: 80px;
        right: 20px;
        background: #28a745;
        color: white;
        padding: 12px 20px;
        border-radius: 8px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.3);
        z-index: 9999999;
        animation: slideIn 0.3s ease;
        max-width: 300px;
        font-weight: 500;
    `;
    tempToast.textContent = '✅ ' + message;
    document.body.appendChild(tempToast);
    
    // 3秒后移除
    setTimeout(() => {
        tempToast.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => {
            if (tempToast.parentNode) {
                tempToast.parentNode.removeChild(tempToast);
            }
        }, 300);
    }, 3000);
    
    // 清除URL参数
    const newUrl = window.location.pathname;
    window.history.replaceState({}, document.title, newUrl);
}

// 强制显示Loading
document.addEventListener('DOMContentLoaded', function() {
    const overlay = document.getElementById('loadingOverlay');
    if (overlay) {
        overlay.style.display = 'flex';
        LoadingManager.simulateProgress();
    }
});

// 页面加载完成后隐藏Loading
window.addEventListener('load', function() {
    setTimeout(() => {
        if (typeof hideLoading === 'function') {
            hideLoading();
        }
    }, 500);
});

// 当前选中的角色
let selectedCharacterNo = '<?php echo $current_character['character_no'] ?? ''; ?>';
let selectedCharacterName = '<?php echo $current_character['character_name'] ?? ''; ?>';

// 选择角色
function selectCharacter(element) {
    // 移除所有active类
    document.querySelectorAll('.character-option').forEach(el => {
        el.classList.remove('active');
    });
    
    // 添加active类到当前元素
    element.classList.add('active');
    
    // 更新选中的角色
    selectedCharacterNo = element.dataset.characterNo;
    selectedCharacterName = element.dataset.characterName;
    
    console.log('Selected character:', selectedCharacterName, 'ID:', selectedCharacterNo);
    
    // 更新Session（通过AJAX）
    fetch('<?php echo site_url('assets/ajax/set_character.php'); ?>', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'character_no=' + selectedCharacterNo + '&character_name=' + encodeURIComponent(selectedCharacterName)
    }).then(response => response.json()).then(data => {
        if (data.success) {
            console.log('Character updated in session');
        }
    });
}

// 购买物品
function buyItem(postNo) {
    if (!<?php echo $is_logged_in ? 'true' : 'false'; ?>) {
        showToast('请先登录后再购买', 'error');
        setTimeout(() => {
            window.location.href = '<?php echo site_url('login.php'); ?>';
        }, 1000);
        return;
    }
    
    if (!selectedCharacterNo) {
        showToast('请先选择购买角色', 'error');
        return;
    }
    
    console.log('Debug: Buying item - postNo:', postNo, 'characterNo:', selectedCharacterNo, 'characterName:', selectedCharacterName);
    
    if (confirm(`确定要用角色【${selectedCharacterName}】购买这个物品吗？`)) {
        // 显示Loading
        showLoading('购买中...');
        
        const btn = event.target;
        const originalText = btn.innerHTML;
        const itemRow = btn.closest('.market-item-row');
        
        // 立即禁用按钮
        btn.innerHTML = '购买中...';
        btn.disabled = true;
        
        // 使用当前页面的URL
        const currentUrl = window.location.href;
        
        fetch(currentUrl, {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: 'action=buy&post_no=' + postNo + '&character_no=' + selectedCharacterNo
        })
        .then(response => {
            console.log('Raw response:', response);
            console.log('Response status:', response.status);
            return response.text();
        })
        .then(text => {
            console.log('Response text:', text);
            try {
                const data = JSON.parse(text);
                console.log('Parsed response:', data);
                if (data.success) {
                    // 隐藏Loading
                    hideLoading();
                    
                    // 显示成功提示 - 使用更直接的方式
                    const successToast = document.createElement('div');
                    successToast.style.cssText = `
                        position: fixed;
                        top: 50%;
                        left: 50%;
                        transform: translate(-50%, -50%);
                        background: linear-gradient(135deg, #28a745, #20c997);
                        color: white;
                        padding: 20px 40px;
                        border-radius: 12px;
                        box-shadow: 0 10px 40px rgba(40, 167, 69, 0.5);
                        z-index: 9999999;
                        font-size: 18px;
                        font-weight: 600;
                        animation: bounceIn 0.5s ease;
                        text-align: center;
                    `;
                    successToast.innerHTML = `
                        <div style="font-size: 48px; margin-bottom: 10px;">✅</div>
                        <div>${data.message}</div>
                        <div style="font-size: 14px; margin-top: 10px; opacity: 0.9;">页面将在2秒后刷新</div>
                    `;
                    
                    // 添加动画样式
                    if (!document.getElementById('successToastStyles')) {
                        const style = document.createElement('style');
                        style.id = 'successToastStyles';
                        style.textContent = `
                            @keyframes bounceIn {
                                0% { transform: translate(-50%, -50%) scale(0.3); opacity: 0; }
                                50% { transform: translate(-50%, -50%) scale(1.05); }
                                70% { transform: translate(-50%, -50%) scale(0.9); }
                                100% { transform: translate(-50%, -50%) scale(1); opacity: 1; }
                            }
                            @keyframes fadeOut {
                                from { opacity: 1; }
                                to { opacity: 0; }
                            }
                        `;
                        document.head.appendChild(style);
                    }
                    
                    document.body.appendChild(successToast);
                    
                    // 更新按钮状态 - 保持禁用
                    btn.innerHTML = '✅ 已购买';
                    btn.style.background = '#28a745';
                    btn.style.cursor = 'not-allowed';
                    
                    // 如果有物品行，添加已购买标记
                    if (itemRow) {
                        itemRow.style.opacity = '0.6';
                        itemRow.style.pointerEvents = 'none';
                        const badge = document.createElement('div');
                        badge.style.cssText = `
                            position: absolute;
                            top: 10px;
                            right: 10px;
                            background: #28a745;
                            color: white;
                            padding: 4px 8px;
                            border-radius: 4px;
                            font-size: 12px;
                            font-weight: 600;
                        `;
                        badge.textContent = '已购买';
                        itemRow.style.position = 'relative';
                        itemRow.appendChild(badge);
                    }
                    
                    // 2秒后刷新页面
                    setTimeout(() => {
                        successToast.style.animation = 'fadeOut 0.3s ease';
                        setTimeout(() => {
                            location.reload();
                        }, 300);
                    }, 2000);
                    
                } else {
                    hideLoading();
                    showToast('❌ ' + data.message, 'error');
                    btn.innerHTML = originalText;
                    btn.disabled = false;
                }
            } catch (e) {
                console.error('JSON parse error:', e);
                console.error('Response was not JSON:', text);
                hideLoading();
                showToast('❌ 服务器返回错误：' + text, 'error');
                btn.innerHTML = originalText;
                btn.disabled = false;
            }
        })
        .catch(error => {
            console.error('Fetch error:', error);
            console.error('Error details:', error.message);
            hideLoading();
            showToast('❌ 购买失败，请稍后重试\n错误信息：' + error.message, 'error');
            btn.innerHTML = originalText;
            btn.disabled = false;
        });
    }
}


// Tooltip功能
(function () {
    // 创建tooltip容器
    var tooltip = document.getElementById('mouseTooltip');
    if (!tooltip) {
        tooltip = document.createElement('div');
        tooltip.id = 'mouseTooltip';
        tooltip.style.display = 'none';
        document.body.appendChild(tooltip);
    }
    
    // 构建tooltip
    function buildTooltipFromRaw(title, rawAttrs) {
        tooltip.innerHTML = '';
        
        var header = document.createElement('div');
        header.className = 'tt-header';
        header.textContent = title || '';
        tooltip.appendChild(header);
        
        var body = document.createElement('div');
        body.className = 'tt-body';
        tooltip.appendChild(body);
        
        var data;
        try {
            data = JSON.parse(rawAttrs);
        } catch (e) {
            data = { name: title, qty: '1', attrs: [], sockets: [] };
        }
        
        // 数量
        var q = document.createElement('div');
        q.className = 'tt-line';
        q.innerHTML = 
            '<span class="tt-name">数量</span>' + 
            '<span class="tt-plus"></span>' + 
            '<span class="tt-val">' + (data.qty || '1') + '</span>';
        body.appendChild(q);
        
        // 属性
        var tA = document.createElement('div');
        tA.className = 'tt-line gt-group-title';
        tA.textContent = '属性';
        body.appendChild(tA);
        
        if (data.attrs && data.attrs.length > 0) {
            for (var i = 0; i < data.attrs.length; i++) {
                var a = data.attrs[i];
                var line = document.createElement('div');
                line.className = 'tt-line';
                var col = 'attr-color-' + (i + 1);
                if (i + 1 > 4) col = 'attr-color-4';
                line.innerHTML = 
                    '<span class="tt-name">' + (a.desc || '') + '</span>' + 
                    '<span class="tt-plus">+</span>' + 
                    '<span class="tt-val ' + col + '">' + (a.value || '') + '</span>';
                body.appendChild(line);
            }
        } else {
            var lineN = document.createElement('div');
            lineN.className = 'tt-line';
            lineN.innerHTML = 
                '<span class="tt-name"></span>' + 
                '<span class="tt-plus"></span>' + 
                '<span class="tt-val muted">无</span>';
            body.appendChild(lineN);
        }
        
        // 间隔
        var sp = document.createElement('div');
        sp.className = 'gt-gap';
        body.appendChild(sp);
        
        // 镶嵌
        var tS = document.createElement('div');
        tS.className = 'tt-line gt-group-title';
        tS.textContent = '镶嵌';
        body.appendChild(tS);
        
        if (data.sockets && data.sockets.length > 0) {
            for (var j = 0; j < data.sockets.length; j++) {
                var s = data.sockets[j];
                var line2 = document.createElement('div');
                line2.className = 'tt-line';
                line2.innerHTML = 
                    '<span class="tt-name">' + (s.name || '') + '</span>' + 
                    '<span class="tt-plus">+</span>' + 
                    '<span class="tt-val attr-socket">' + (s.value || '') + '</span>';
                body.appendChild(line2);
            }
        } else {
            var line2N = document.createElement('div');
            line2N.className = 'tt-line';
            line2N.innerHTML = 
                '<span class="tt-name"></span>' + 
                '<span class="tt-plus"></span>' + 
                '<span class="tt-val attr-socket">无镶嵌</span>';
            body.appendChild(line2N);
        }
    }
    
    // 鼠标移动
    function moveWith(e) {
        var rect = tooltip.getBoundingClientRect();
        var x = e.clientX + 12;
        var y = e.clientY + 12;
        var W = window.innerWidth || document.documentElement.clientWidth;
        var H = window.innerHeight || document.documentElement.clientHeight;
        
        if (x + rect.width > W) x = e.clientX - rect.width - 12;
        if (y + rect.height > H) y = e.clientY - rect.height - 12;
        if (x < 2) x = 2;
        if (y < 2) y = 2;
        
        tooltip.style.left = x + 'px';
        tooltip.style.top = y + 'px';
    }
    
    // 绑定事件
    function bindCards() {
        var cards = document.querySelectorAll('.market-item-row');
        
        for (var i = 0; i < cards.length; i++) {
            var el = cards[i];
            if (el._ttBound) continue;
            el._ttBound = true;
            
            // 绑定tooltip
            el.addEventListener('mouseenter', function (e) {
                var title = this.getAttribute('data-itemname') || '';
                var raw = this.getAttribute('data-rawattrs') || '';
                buildTooltipFromRaw(title, raw);
                tooltip.style.display = 'block';
                moveWith(e);
            });
            
            el.addEventListener('mousemove', moveWith);
            
            el.addEventListener('mouseleave', function () {
                tooltip.style.display = 'none';
            });
        }
    }
    
    // 初始化
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', bindCards);
    } else {
        bindCards();
    }
})();

// 页面加载完成后初始化
document.addEventListener('DOMContentLoaded', function() {
    console.log('=== 角色选择调试信息 ===');
    console.log('当前角色编号:', selectedCharacterNo);
    console.log('当前角色名称:', selectedCharacterName);
    
    if (selectedCharacterNo) {
        console.log('✓ 角色已选择，编号:', selectedCharacterNo);
    } else {
        console.log('✗ 未选择角色');
    }
});
</script>

<?php include '../templates/footer.php'; ?>
