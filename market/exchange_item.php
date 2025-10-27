<?php
// exchange_item.php - 物品兑换页面
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once '../config.php';
require_once '../auth.php';
require_once '../db.php';

// 检查登录状态
$is_logged_in = is_logged_in();

if (!$is_logged_in) {
    header('Location: ' . site_url('login.php'));
    exit;
}

$server_id = $_SESSION['server_id'];
$user_no = $_SESSION['user_no'];

// 获取当前角色ID
$current_character_no = $_SESSION['current_character_no'] ?? null;
$current_character_name = $_SESSION['current_character_name'] ?? '未选择角色';

// 获取当前角色完整信息
$current_character = null;
if ($current_character_no && $server_id) {
    $db_character = get_db($server_id, 'character');
    $current_character = $db_character->fetch("
        SELECT character_no, character_name, wlevel, wMasterLevel, ipt_time 
        FROM user_character 
        WHERE character_no = ? AND user_no = ?
    ", [$current_character_no, $user_no]);
}

// 获取装备升级列表
function getExchangeItemList($server_id) {
    $db_account = get_db($server_id, 'account');
    
    try {
        $stmt = $db_account->prepare("
            SELECT id, oldid, oldname, newid, newname, needcash 
            FROM WEB_ExchangeItem 
            ORDER BY id DESC
        ");
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (Exception $e) {
        error_log("getExchangeItemList Error: " . $e->getMessage());
        return [];
    }
}

// 获取用户角色列表
$characters = getUserCharacters($server_id, $user_no);

// 处理兑换请求
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    header('Content-Type: application/json');
    
    try {
        $action = $_POST['action'];
        
        if ($action === 'exchange_item') {
            $character_no = $_POST['character_no'];
            $line_no = intval($_POST['line_no']);
            $old_id = intval($_POST['old_id']);
            $new_id = intval($_POST['new_id']);
            
            // 获取数据库连接
            $db_character = get_db($server_id, 'character');
            $db_cash = get_db($server_id, 'cash');
            
            // 验证角色归属
            $char = $db_character->fetch("
                SELECT character_no, character_name, wlevel, wMasterLevel, ipt_time
                FROM user_character 
                WHERE character_no = ? AND user_no = ?
            ", [$character_no, $user_no]);
            
            if (!$char) {
                echo json_encode(['success' => false, 'message' => '角色信息错误']);
                exit;
            }
            
            // 获取升级配置
            $db_account = get_db($server_id, 'account');
            $exchange_item = $db_account->fetch("
                SELECT * FROM WEB_ExchangeItem 
                WHERE oldid = ? AND newid = ?
            ", [$old_id, $new_id]);
            
            if (!$exchange_item) {
                echo json_encode(['success' => false, 'message' => '升级配置不存在']);
                exit;
            }
            
            // 检查个人商店中的物品
            $store_item = $db_character->fetch("
                SELECT * FROM USER_STORE 
                WHERE character_no = ? AND line_no = ? AND wIndex = ?
            ", [$character_no, $line_no, $old_id]);
            
            if (!$store_item) {
                echo json_encode(['success' => false, 'message' => '商店中未找到该物品']);
                exit;
            }
            
            // 检查商城币余额
            $cash_info = $db_cash->fetch("
                SELECT amount FROM user_cash WHERE user_no = ?
            ", [$user_no]);
            
            if (!$cash_info || $cash_info['amount'] < $exchange_item['needcash']) {
                echo json_encode(['success' => false, 'message' => '商城币不足']);
                exit;
            }
            
            // 使用事务确保原子性
            $db_character->beginTransaction();
            $db_cash->beginTransaction();
            
            try {
                // 1. 扣除商城币
                $stmt = $db_cash->prepare("
                    UPDATE user_cash SET amount = amount - ? WHERE user_no = ?
                ");
                $stmt->execute([$exchange_item['needcash'], $user_no]);
                
                // 2. 删除商店物品
                $stmt = $db_character->prepare("
                    DELETE FROM USER_STORE 
                    WHERE character_no = ? AND line_no = ? AND wIndex = ?
                ");
                $stmt->execute([$character_no, $line_no, $old_id]);
                
                // 3. 发送升级后的物品到邮箱
                $stmt = $db_character->prepare("
                    INSERT INTO user_mail (character_no, mail_title, mail_content, sender_name, send_time, item_index, item_count, is_read)
                    VALUES (?, ?, ?, '系统', GETDATE(), ?, ?, 0)
                ");
                $stmt->execute([
                    $character_no,
                    "装备升级奖励",
                    "您的装备 " . $exchange_item['oldname'] . " 已成功升级为 " . $exchange_item['newname'] . "，请查收奖励物品。",
                    $new_id,
                    1
                ]);
                
                // 4. 记录日志
                $log_text = "装备升级: " . $exchange_item['oldname'] . " -> " . $exchange_item['newname'] . " - 消耗: " . $exchange_item['needcash'] . "商城币";
                $ip = $_SERVER['REMOTE_ADDR'] ?? '';
                
                $stmt = $db_account->prepare("
                    INSERT INTO adminlog (admin, datetime, ip, username, adminlog, logtype) 
                    VALUES (?, NOW(), ?, ?, ?, 3)
                ");
                $stmt->execute([$_SESSION['username'], $ip, $character_no, $log_text]);
                
                // 提交事务
                $db_character->commit();
                $db_cash->commit();
                
                echo json_encode([
                    'success' => true, 
                    'message' => '装备升级成功！升级后的物品已发送到邮箱'
                ]);
                
            } catch (Exception $e) {
                // 回滚事务
                $db_character->rollBack();
                $db_cash->rollBack();
                
                error_log("Exchange Error: " . $e->getMessage());
                echo json_encode(['success' => false, 'message' => '升级失败：' . $e->getMessage()]);
            }
        }
        
    } catch (Exception $e) {
        error_log("Main Error: " . $e->getMessage());
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
    exit;
}

// 获取页面数据
$exchange_list = getExchangeItemList($server_id);

// 设置页面信息
$page_title = '装备熔炼 - 游戏市场';
$breadcrumbs = [
    ['name' => '游戏市场', 'url' => site_url('market/')],
    ['name' => '装备熔炼', 'url' => site_url('market/exchange_item.php')]
];

include '../templates/header.php';
?>

<style>
/* 装备熔炼页面样式 - 优化布局 */
.exchange-container {
    max-width: 1400px;
    margin: 0 auto;
    padding: 20px;
    position: relative;
    background: linear-gradient(135deg, #0c0c0c 0%, #1a1a2e 50%, #16213e 100%);
    min-height: 100vh;
    color: #e0e0e0;
}

.exchange-header {
    text-align: center;
    margin-bottom: 30px;
    position: relative;
}

.exchange-title {
    font-size: 2.8em;
    font-weight: 700;
    color: #fff;
    text-shadow: 0 2px 10px rgba(0, 0, 0, 0.5);
    background: linear-gradient(135deg, #fbbf24 0%, #f59e0b 50%, #d97706 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
    margin-bottom: 10px;
    animation: hdrGlitch 3s infinite ease-in-out;
}

@keyframes hdrGlitch {
    0%, 100% { text-shadow: 0 0 0 rgba(255, 0, 85, .0), 0 0 0 rgba(0, 255, 170, .0); }
    20% { text-shadow: 2px 0 rgba(255, 0, 85, .25), -2px 0 rgba(0, 255, 170, .25); }
    40% { text-shadow: -2px 0 rgba(255, 0, 85, .25), 2px 0 rgba(0, 255, 170, .25); }
    60% { text-shadow: 1px 0 rgba(255, 0, 85, .25), -1px 0 rgba(0, 255, 170, .25); }
    80% { text-shadow: -1px 0 rgba(255, 0, 85, .25), 1px 0 rgba(0, 255, 170, .25); }
}

.exchange-subtitle {
    font-size: 1.2em;
    color: #cbd5e1;
    opacity: 0.9;
}

/* 统计栏 */
.stats-bar {
    background: linear-gradient(135deg, #1e293b 0%, #334155 100%);
    color: #e2e8f0;
    padding: 12px 30px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-size: 0.95em;
    border-radius: 10px;
    margin-bottom: 20px;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
}

.stats-item {
    display: flex;
    align-items: center;
    gap: 10px;
}

.stats-item i {
    color: #f59e0b;
}

/* 主布局 - 调整比例 */
.exchange-main-layout {
    display: flex;
    gap: 20px;
    align-items: flex-start;
}

/* 左侧角色选择器 - 进一步缩窄 */
.character-sidebar {
    flex: 0 0 20%; /* 从25%改为20% */
    max-width: 280px; /* 减小最大宽度 */
    position: sticky;
    top: 20px;
}

.character-selector {
    background: rgba(20, 20, 20, 0.95);
    backdrop-filter: blur(10px);
    border-radius: 12px;
    padding: 15px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
}

.character-selector h3 {
    color: #f0f0f0;
    margin-bottom: 15px;
    font-size: 16px;
    display: flex;
    align-items: center;
    gap: 8px;
}

.character-selector h3 i {
    color: #4a9eff;
}

.character-options {
    display: flex;
    flex-direction: column;
    gap: 8px;
}

.character-option {
    background: rgba(30, 30, 30, 0.8);
    border: 2px solid rgba(255, 255, 255, 0.1);
    border-radius: 8px;
    padding: 12px;
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

.character-info {
    flex: 1;
}

.character-name {
    font-weight: 500;
    font-size: 14px;
    margin-bottom: 2px;
}

.character-level {
    font-size: 11px;
    color: #888;
}

/* 右侧内容区域 - 增宽 */
.exchange-content {
    flex: 0 0 80%; /* 从75%改为80% */
    min-width: 0;
}

/* 提示信息 */
.notice-container {
    margin-bottom: 20px;
}

.exchange-notice {
    background: rgba(74, 158, 255, 0.1);
    border: 1px solid rgba(74, 158, 255, 0.3);
    border-radius: 8px;
    padding: 15px;
    color: #e0e0e0;
    font-size: 14px;
    text-align: center;
}

.exchange-notice i {
    color: #4a9eff;
    margin-right: 8px;
}

/* 升级列表 - 优化表格布局 */
.exchange-list-container {
    background: rgba(20, 20, 20, 0.95);
    backdrop-filter: blur(10px);
    border-radius: 12px;
    padding: 20px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
    margin-bottom: 20px;
}

.exchange-list-header {
    color: #f0f0f0;
    margin-bottom: 15px;
    font-size: 18px;
    display: flex;
    align-items: center;
    justify-content: space-between;
}

.exchange-list-header i {
    color: #4a9eff;
}

.view-all-btn {
    background: linear-gradient(135deg, #4a9eff, #3a7ecc);
    color: white;
    border: none;
    padding: 10px 20px;
    border-radius: 8px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
    font-size: 14px;
    box-shadow: 0 4px 12px rgba(74, 158, 255, 0.3);
}

.view-all-btn:hover {
    background: linear-gradient(135deg, #5aa8ff, #4a8edd);
    transform: translateY(-2px);
    box-shadow: 0 6px 16px rgba(74, 158, 255, 0.4);
}

/* CSS Grid 布局 - 优化列宽 */
.grid-container {
    display: grid;
    grid-template-columns: 60px 1fr 80px 1fr 180px 150px; /* 增加价格列宽度 */
    background: #111827;
    border-radius: 8px;
    overflow: hidden;
}

.grid-header {
    display: contents;
}

.grid-header-item {
    background: linear-gradient(135deg, #1e40af 0%, #1e3a8a 100%);
    color: #fbbf24;
    padding: 15px 12px;
    font-weight: 600;
    font-size: 14px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    border-bottom: 2px solid #f59e0b;
    position: sticky;
    top: 0;
    z-index: 10;
    text-align: center;
}

.grid-body {
    display: contents;
}

.grid-row {
    display: contents;
}

.grid-cell {
    padding: 12px 10px;
    color: #e5e7eb;
    border-bottom: 1px solid #2d3748;
    background: #1f2937;
    display: flex;
    align-items: center;
    transition: all 0.3s ease;
    font-size: 13px;
}

.grid-row:nth-child(even) .grid-cell {
    background: #18212f;
}

.grid-row:hover .grid-cell {
    background: linear-gradient(135deg, #2d3748 0%, #374151 100%);
    box-shadow: 0 5px 20px rgba(0, 0, 0, 0.4);
}

.grid-row:hover .grid-cell.arrow-cell {
    transform: none;
    background: inherit;
    box-shadow: none;
}

/* 滚动容器 */
.scrolling-container {
    max-height: 500px;
    overflow-y: auto;
    position: relative;
}

.scrolling-container::-webkit-scrollbar {
    width: 10px;
}

.scrolling-container::-webkit-scrollbar-track {
    background: #1f2937;
    border-radius: 5px;
}

.scrolling-container::-webkit-scrollbar-thumb {
    background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
    border-radius: 5px;
    border: 2px solid #1f2937;
}

/* 物品名称和图标样式 - 优化尺寸 */
.item-name {
    font-weight: 600;
    color: #f3f4f6;
    display: flex;
    align-items: center;
    gap: 8px;
}

.item-icon {
    width: 24px;
    height: 24px;
    background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
    border-radius: 5px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    font-size: 12px;
    font-weight: bold;
    box-shadow: 0 3px 6px rgba(99, 102, 241, 0.3);
    flex-shrink: 0;
}

.price-tag {
    background: linear-gradient(135deg, #eab308 0%, #f59e0b 100%);
    color: #1f2937;
    padding: 4px 8px;
    border-radius: 8px;
    font-weight: 700;
    font-size: 12px;
    display: inline-block;
    box-shadow: 0 3px 8px rgba(220, 38, 38, 0.4);
    position: relative;
    padding-left: 24px;
    text-shadow: 0 1px 0 rgba(255, 255, 255, .25);
    border: 2px solid #78350f;
    white-space: nowrap; /* 防止换行 */
}

.price-tag::before {
    content: "🪙";
    position: absolute;
    left: 6px;
    top: 50%;
    transform: translateY(-50%);
    filter: saturate(1.3) brightness(1.1);
    font-size: 10px;
}

/* 升级箭头特效 */
.upgrade-arrow {
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 20px;
    color: #f59e0b;
    position: relative;
    width: 100%;
    height: 100%;
}

.upgrade-arrow::before {
    content: "▶";
    font-family: monospace;
    color: #f59e0b;
    text-shadow: 0 0 8px rgba(245, 158, 11, .8);
    animation: arrowPulse 1.6s infinite;
}

@keyframes arrowPulse {
    0%, 100% { 
        transform: scale(1);
        opacity: 1;
    }
    50% { 
        transform: scale(1.2);
        opacity: 0.8;
    }
}

/* 热度星级 - 优化尺寸 */
.popularity-stars {
    display: flex;
    gap: 2px;
    align-items: center;
    flex-wrap: wrap;
}

.star {
    color: #fbbf24;
    font-size: 10px;
    text-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);
}

.hot-badge {
    background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%);
    color: white;
    padding: 3px 6px;
    border-radius: 8px;
    font-size: 10px;
    margin-left: 6px;
    animation: glow 2s infinite;
    font-weight: 600;
}

@keyframes glow {
    0%, 100% { box-shadow: 0 0 5px #dc2626; }
    50% { box-shadow: 0 0 15px #dc2626; }
}

/* 趋势箭头 */
.trend-arrow {
    margin-left: 4px;
    font-size: 12px;
    font-weight: bold;
    animation: trendPulse 1.5s infinite;
}

.trend-up {
    color: #10b981;
}

.trend-down {
    color: #ef4444;
}

@keyframes trendPulse {
    0%, 100% { 
        transform: scale(1);
        opacity: 1;
    }
    50% { 
        transform: scale(1.2);
        opacity: 0.8;
    }
}

/* 序号样式 - 优化尺寸 */
.index-icon {
    width: 24px;
    height: 24px;
    background: linear-gradient(135deg, #6b7280 0%, #4b5563 100%);
    border-radius: 5px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    font-size: 12px;
    font-weight: bold;
    box-shadow: 0 3px 6px rgba(107, 114, 128, 0.3);
    flex-shrink: 0;
}

/* 热门装备边框发光效果 */
.hot-item .grid-cell:not(.arrow-cell) {
    position: relative;
}

.hot-item .grid-cell:not(.arrow-cell)::before {
    content: "";
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    border: 1px solid transparent;
    border-radius: 4px;
    background: linear-gradient(90deg, #f59e0b, #fbbf24, #f59e0b) border-box;
    -webkit-mask: linear-gradient(#fff 0 0) padding-box, linear-gradient(#fff 0 0);
    -webkit-mask-composite: destination-out;
    mask-composite: exclude;
    animation: borderFlow 3s linear infinite;
    opacity: 0;
    transition: opacity 0.3s ease;
}

.hot-item:hover .grid-cell:not(.arrow-cell)::before {
    opacity: 1;
}

@keyframes borderFlow {
    0% { background-position: -200% 0; }
    100% { background-position: 200% 0; }
}

/* 用户商店 - 优化布局 */
.user-store-container {
    background: rgba(20, 20, 20, 0.95);
    backdrop-filter: blur(10px);
    border-radius: 12px;
    padding: 20px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
}

.user-store-header {
    color: #f0f0f0;
    margin-bottom: 15px;
    font-size: 18px;
    display: flex;
    align-items: center;
    gap: 10px;
}

.user-store-header i {
    color: #4a9eff;
}

.user-store-table {
    width: 100%;
    border-collapse: separate;
    border-spacing: 0;
    background: rgba(25, 25, 35, 0.6);
    border-radius: 8px;
    overflow: hidden;
}

.user-store-table th {
    background: linear-gradient(135deg, rgba(40, 50, 70, 0.9), rgba(30, 40, 60, 0.9));
    color: #e0e0e0;
    padding: 12px;
    text-align: center;
    font-weight: 600;
    font-size: 13px;
    border-bottom: 1px solid rgba(74, 158, 255, 0.3);
}

.user-store-table td {
    padding: 10px;
    text-align: center;
    border-bottom: 1px solid rgba(74, 158, 255, 0.1);
    color: #b0b0b0;
    font-size: 13px;
}

.user-store-table tr:last-child td {
    border-bottom: none;
}

.user-store-table tr:hover {
    background-color: rgba(74, 158, 255, 0.1);
}

.store-item-name {
    font-weight: 500;
    color: #e0e0e0;
}

.exchange-btn {
    background: linear-gradient(135deg, #4a9eff, #3a7ecc);
    color: white;
    border: none;
    padding: 8px 16px;
    border-radius: 6px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
    font-size: 12px;
    box-shadow: 0 3px 8px rgba(74, 158, 255, 0.3);
}

.exchange-btn:hover {
    background: linear-gradient(135deg, #5aa8ff, #4a8edd);
    transform: translateY(-2px);
    box-shadow: 0 5px 12px rgba(74, 158, 255, 0.4);
}

.exchange-btn:disabled {
    background: #6c757d;
    cursor: not-allowed;
    transform: none;
}

.no-items {
    text-align: center;
    color: #888;
    padding: 20px;
    font-size: 14px;
}

/* 全部升级列表弹窗 - 优化布局 */
.modal {
    display: none;
    position: fixed;
    z-index: 1000;
    left: 0;
    top: 0;
    width: 100%;
    height: 100%;
    background-color: rgba(0, 0, 0, 0.8);
    backdrop-filter: blur(5px);
}

.modal-content {
    background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
    margin: 10% auto; /* 从5%改为10%，让窗口更往下 */
    padding: 0;
    border: 1px solid #2d3748;
    border-radius: 15px;
    width: 95%;
    max-width: 1400px;
    max-height: 80vh; /* 从90vh改为80vh */
    overflow: hidden;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.7);
    position: relative;
}


.modal-header {
    background: linear-gradient(135deg, #1e3a8a 0%, #3730a3 50%, #5b21b6 100%);
    color: white;
    padding: 20px 30px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 2px solid #6366f1;
    position: sticky;
    top: 0;
    z-index: 10;
}

.modal-header h2 {
    margin: 0;
    font-size: 1.5em;
    color: #fbbf24;
}

.close {
    color: #fff;
    font-size: 32px; /* 增大关闭按钮 */
    font-weight: bold;
    cursor: pointer;
    transition: color 0.3s;
    background: rgba(255, 255, 255, 0.1);
    border: none;
    width: 40px;
    height: 40px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
}

.close:hover {
    color: #fff;
    background: rgba(255, 255, 255, 0.2);
}

.modal-body {
    padding: 20px;
    max-height: calc(90vh - 100px); /* 调整高度计算 */
    overflow-y: auto;
}

/* 加载动画 */
.loading-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.8);
    display: none;
    justify-content: center;
    align-items: center;
    z-index: 9999999;
}

.loading-content {
    text-align: center;
    color: white;
}

.loading-spinner {
    width: 50px;
    height: 50px;
    border: 4px solid rgba(255, 255, 255, 0.1);
    border-top: 4px solid #4a9eff;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin: 0 auto 20px;
}

@keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
}

/* 响应式设计 */
@media (max-width: 1200px) {
    .exchange-main-layout {
        flex-direction: column;
    }
    
    .character-sidebar {
        flex: none;
        max-width: 100%;
        position: static;
        margin-bottom: 20px;
    }
    
    .exchange-content {
        flex: none;
        width: 100%;
    }
    
    .character-options {
        flex-direction: row;
        flex-wrap: wrap;
    }
    
    .character-option {
        flex: 1;
        min-width: 200px;
    }
}

@media (max-width: 768px) {
    .exchange-container {
        padding: 15px;
    }
    
    .grid-container {
        grid-template-columns: 1fr;
    }
    
    .grid-header, .grid-body {
        display: block;
    }
    
    .grid-row {
        display: block;
        margin-bottom: 10px;
        border: 1px solid #2d3748;
        border-radius: 8px;
    }
    
    .grid-cell {
        padding: 10px;
        border-bottom: 1px solid #2d3748;
    }
    
    .character-options {
        flex-direction: column;
    }
    
    .character-option {
        min-width: auto;
    }
}
</style>

<!-- 加载动画遮罩 -->
<div id="loadingOverlay" class="loading-overlay" style="display: none;">
    <div class="loading-content">
        <div class="loading-spinner"></div>
        <div class="loading-text" id="loadingText">处理中...</div>
    </div>
</div>

<!-- 全部升级列表弹窗 -->
<div id="exchangeModal" class="modal">
    <div class="modal-content">
        <div class="modal-header">
            <h2>🔥 完整装备升级列表</h2>
            <button class="close">&times;</button>
        </div>
        <div class="modal-body">
            <div class="scrolling-container">
                <div class="grid-container" id="fullExchangeGrid">
                    <!-- 表头 -->
                    <div class="grid-header">
                        <div class="grid-header-item">#</div>
                        <div class="grid-header-item">🗡️ 当前物品</div>
                        <div class="grid-header-item">✨ 进化</div>
                        <div class="grid-header-item">⚡ 进化物品</div>
                        <div class="grid-header-item">💰 所需C币</div>
                        <div class="grid-header-item">🔥 熔炉热度</div>
                    </div>
                    <!-- 表体 -->
                    <div class="grid-body" id="fullTableBody">
                        <!-- 内容将通过JavaScript动态生成 -->
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="exchange-container">
    <!-- 页面头部 -->
    <div class="exchange-header">
        <div class="exchange-title">
            ⚔️ 装备熔炼系统
        </div>
        <div class="exchange-subtitle">
            将您的商店物品升级为更强大的形态
        </div>
    </div>
    
    <!-- 统计栏 -->
    <div class="stats-bar">
        <div class="stats-item">
            <i class="fas fa-server"></i>
            <span>分区: <strong><?php echo $server_id; ?></strong></span>
        </div>
        <div class="stats-item">
            <i class="fas fa-chess-knight"></i>
            <span>装备总数: <strong id="totalItems"><?php echo count($exchange_list); ?></strong></span>
        </div>
        <div class="stats-item">
            <i class="fas fa-fire"></i>
            <span>熔炉热度: <strong id="livePopularity">🔥 计算中...</strong></span>
        </div>
        <div class="stats-item">
            <i class="fas fa-users"></i>
            <span>在线勇士: <strong id="onlineCount">加载中...</strong></span>
        </div>
    </div>
    
    <!-- 主布局容器 -->
    <div class="exchange-main-layout">
        <!-- 左侧角色选择器 -->
        <div class="character-sidebar">
            <div class="character-selector">
                <h3><i class="fas fa-user"></i> 选择角色</h3>
                <div class="character-options">
                    <?php foreach ($characters as $char): ?>
                        <div class="character-option <?php echo ($current_character['character_no'] ?? '') == $char['character_no'] ? 'active' : ''; ?>" 
                             data-character-no="<?php echo $char['character_no']; ?>"
                             data-character-name="<?php echo htmlspecialchars($char['character_name']); ?>"
                             onclick="selectCharacter(this)">
                            <i class="fas fa-user-circle"></i>
                            <div class="character-info">
                                <div class="character-name"><?php echo htmlspecialchars($char['character_name']); ?></div>
                                <div class="character-level">Lv.<?php echo $char['wlevel']; ?></div>
                            </div>
                        </div>
                    <?php endforeach; ?>
                </div>
            </div>
        </div>
        
        <!-- 右侧内容区域 -->
        <div class="exchange-content">
            <!-- 提示信息 -->
            <div class="notice-container">
                <div class="exchange-notice">
                    <i class="fas fa-info-circle"></i>
                    <span>请将需要升级的物品放在个人商店中，然后选择角色进行升级操作</span>
                </div>
            </div>
            
            <!-- 升级列表 -->
            <div class="exchange-list-container">
                <div class="exchange-list-header">
                    <span><i class="fas fa-list"></i> 热门升级装备 (前10项)</span>
                    <button class="view-all-btn" onclick="showFullExchangeList()">
                        查看全部 (<?php echo count($exchange_list); ?>项)
                    </button>
                </div>
                <div class="scrolling-container">
                    <div class="grid-container" id="exchangeGrid">
                        <!-- 表头 -->
                        <div class="grid-header">
                            <div class="grid-header-item">#</div>
                            <div class="grid-header-item">🗡️ 当前物品</div>
                            <div class="grid-header-item">✨ 进化</div>
                            <div class="grid-header-item">⚡ 进化物品</div>
                            <div class="grid-header-item">💰 所需C币</div>
                            <div class="grid-header-item">🔥 熔炉热度</div>
                        </div>
                        <!-- 表体 -->
                        <div class="grid-body" id="tableBody">
                            <?php 
                            $display_items = array_slice($exchange_list, 0, 10);
                            foreach ($display_items as $index => $item): 
                                $starCount = rand(3, 5);
                                $itemClass = $starCount == 5 ? 'hot-item' : '';
                                $trendArrow = rand(0, 1) ? '↑' : '↓';
                                $trendClass = $trendArrow == '↑' ? 'trend-up' : 'trend-down';
                                $showHotBadge = rand(0, 1);
                            ?>
                            <div class="grid-row <?php echo $itemClass; ?>" data-index="<?php echo $index; ?>">
                                <div class="grid-cell">
                                    <div class="index-icon"><?php echo $index + 1; ?></div>
                                </div>
                                <div class="grid-cell">
                                    <div class="item-name">
                                        <div class="item-icon">⚔</div>
                                        <div class="item-name-container">
                                            <div class="item-text">
                                                <span style="color: #fbbf24;"><?php echo htmlspecialchars($item['oldname']); ?></span>
                                            </div>
                                            <div class="trend-arrow <?php echo $trendClass; ?>"><?php echo $trendArrow; ?></div>
                                        </div>
                                    </div>
                                </div>
                                <div class="grid-cell arrow-cell">
                                    <div class="upgrade-arrow"></div>
                                </div>
                                <div class="grid-cell">
                                    <div class="item-name">
                                        <div class="item-icon" style="background: linear-gradient(135deg, #10b981 0%, #059669 100%);">⚡</div>
                                        <span style="color: #10b981;"><?php echo htmlspecialchars($item['newname']); ?></span>
                                    </div>
                                </div>
                                <div class="grid-cell">
                                    <span class="price-tag"><?php echo number_format($item['needcash']); ?> C币</span>
                                </div>
                                <div class="grid-cell">
                                    <div class="popularity-stars">
                                        <?php for ($j = 1; $j <= 5; $j++): ?>
                                            <i class="fas fa-star star" style="<?php echo $j > $starCount ? 'color: #4b5563;' : ''; ?>"></i>
                                        <?php endfor; ?>
                                        <?php if ($showHotBadge): ?>
                                            <span class="hot-badge"><i class="fas fa-fire"></i>熔炼中</span>
                                        <?php endif; ?>
                                    </div>
                                </div>
                            </div>
                            <?php endforeach; ?>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- 用户商店 -->
            <div class="user-store-container">
                <div class="user-store-header">
                    <i class="fas fa-store"></i>
                    我的商店 - 可升级物品
                </div>
                <div id="userStoreContent">
                    <div class="no-items">请先选择角色</div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- 引入SweetAlert -->
<script src="https://cdn.jsdelivr.net/npm/sweetalert@1.1.3/dist/sweetalert.min.js"></script>

<script>
// 当前选中的角色
let selectedCharacterNo = '<?php echo $current_character['character_no'] ?? ''; ?>';
let selectedCharacterName = '<?php echo $current_character['character_name'] ?? ''; ?>';

// HTML转义函数
function escapeHtml(text) {
    var map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, function(m) { return map[m]; });
}

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
            // 加载用户商店
            loadUserStore();
        }
    });
}

// 加载用户商店
function loadUserStore() {
    if (!selectedCharacterNo) {
        document.getElementById('userStoreContent').innerHTML = '<div class="no-items">请先选择角色</div>';
        return;
    }
    
    showLoading('加载商店数据...');
    
    fetch('<?php echo site_url('assets/ajax/get_user_store.php'); ?>', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'character_no=' + selectedCharacterNo + '&server_id=<?php echo $server_id; ?>'
    })
    .then(response => {
        console.log('Response status:', response.status);
        
        // 检查响应是否为空
        if (!response) {
            throw new Error('服务器返回空响应');
        }
        
        // 获取响应文本
        return response.text();
    })
    .then(responseText => {
        console.log('Response text:', responseText);
        
        // 检查响应文本是否为空
        if (!responseText || responseText.trim() === '') {
            throw new Error('服务器返回空响应');
        }
        
        // 尝试解析JSON
        try {
            return JSON.parse(responseText);
        } catch (e) {
            console.error('JSON parse error:', e);
            console.error('Response text:', responseText);
            throw new Error('JSON解析失败: ' + e.message);
        }
    })
    .then(data => {
        console.log('Store data:', data);
        hideLoading();
        
        if (data && data.success) {
            renderUserStore(data.items || []);
        } else {
            document.getElementById('userStoreContent').innerHTML = '<div class="no-items">' + (data ? data.message : '加载失败') + '</div>';
        }
    })
    .catch(error => {
        console.error('Load store error:', error);
        hideLoading();
        document.getElementById('userStoreContent').innerHTML = '<div class="no-items">加载失败: ' + error.message + '</div>';
    });
}




// 渲染用户商店
function renderUserStore(items) {
    let html = '<table class="user-store-table"><thead><tr><th>物品名称</th><th>升级后</th><th>所需C币</th><th>商店价格</th><th>操作</th></tr></thead><tbody>';
    
    if (items.length === 0) {
        html += '<tr><td colspan="5" class="no-items">您的商店中没有可升级的物品</td></tr>';
    } else {
        items.forEach(item => {
            html += '<tr>';
            html += '<td class="store-item-name">' + escapeHtml(item.item_name) + '</td>';
            html += '<td class="store-item-name" style="color: #10b981;">' + escapeHtml(item.new_item_name) + '</td>';
            html += '<td><span class="price-tag">' + item.need_cash + ' C币</span></td>';
            html += '<td><span style="color: #f59e0b;">' + number_format(item.price) + '</span></td>';
            html += '<td>';
            html += '<button class="exchange-btn" onclick="confirmExchange(';
            html += item.line_no + ', ' + item.windex + ', ' + item.new_id + ', ' + item.need_cash + ', \'' + escapeHtml(item.item_name) + '\')">';
            html += '升级装备';
            html += '</button>';
            html += '</td>';
            html += '</tr>';
        });
    }
    
    html += '</tbody></table>';
    document.getElementById('userStoreContent').innerHTML = html;
}

// 显示完整升级列表 - 修复功能
function showFullExchangeList() {
    console.log('showFullExchangeList called');
    
    const modal = document.getElementById('exchangeModal');
    const gridBody = document.getElementById('fullTableBody');
    
    if (!modal || !gridBody) {
        console.error('Modal or gridBody not found');
        return;
    }
    
    // 生成完整列表
    let html = '';
    <?php foreach ($exchange_list as $index => $item): ?>
        html += '<div class="grid-row" data-index="<?php echo $index; ?>">';
        html += '<div class="grid-cell"><div class="index-icon"><?php echo $index + 1; ?></div></div>';
        html += '<div class="grid-cell">';
        html += '<div class="item-name">';
        html += '<div class="item-icon">⚔</div>';
        html += '<span style="color: #fbbf24;"><?php echo htmlspecialchars($item['oldname']); ?></span>';
        html += '</div>';
        html += '</div>';
        html += '<div class="grid-cell arrow-cell"><div class="upgrade-arrow"></div></div>';
        html += '<div class="grid-cell">';
        html += '<div class="item-name">';
        html += '<div class="item-icon" style="background: linear-gradient(135deg, #10b981 0%, #059669 100%);">⚡</div>';
        html += '<span style="color: #10b981;"><?php echo htmlspecialchars($item['newname']); ?></span>';
        html += '</div>';
        html += '</div>';
        html += '<div class="grid-cell"><span class="price-tag"><?php echo number_format($item['needcash']); ?> C币</span></div>';
        html += '<div class="grid-cell"><div class="popularity-stars">';
        <?php for ($j = 1; $j <= 5; $j++): ?>
            html += '<i class="fas fa-star star"></i>';
        <?php endfor; ?>
        html += '</div></div>';
        html += '</div>';
    <?php endforeach; ?>
    
    gridBody.innerHTML = html;
    modal.style.display = 'block';
    
    console.log('Modal displayed');
    
    // 初始化动态效果
    initDynamicEffects();
}

// 关闭弹窗
document.querySelector('.close').onclick = function() {
    document.getElementById('exchangeModal').style.display = 'none';
}

window.onclick = function(event) {
    const modal = document.getElementById('exchangeModal');
    if (event.target == modal) {
        modal.style.display = 'none';
    }
}

// 确认装备升级 - 修复功能
function confirmExchange(lineNo, oldId, newId, needCash, itemName) {
    console.log('confirmExchange called with:', {lineNo, oldId, newId, needCash, itemName});
    
    // 先获取用户余额
    getUserCashBalance(function(userCash) {
        var canAfford = parseInt(userCash) >= parseInt(needCash);
        var statusHtml = canAfford ? 
            '<span style="color: #27ae60; font-weight: bold;">余额充足</span>' : 
            '<span style="color: #dc3545; font-weight: bold;">余额不足</span>';
        
        var confirmHtml = '<div style="text-align: left; padding: 15px; background: #f8f9fa; border-radius: 8px; margin: 15px 0;">' +
            '<p><strong>🛡️ 物品名称:</strong> ' + itemName + '</p>' +
            '<p><strong>💰 所需商城币:</strong> ' + needCash + ' 点</p>' +
            '<p><strong>👤 您的余额:</strong> ' + userCash + ' 点</p>' +
            '<p><strong>📊 状态:</strong> ' + statusHtml + '</p>' +
            '<p style="color: #e67e22; margin-top: 10px;"><strong>⚠️ 注意:</strong> 升级后物品将发送到邮箱</p>' +
            '</div>';
        
        if (!canAfford) {
            swal({
                title: "余额不足",
                html: confirmHtml,
                type: "error",
                confirmButtonText: "确定",
                confirmButtonColor: "#e74c3c"
            });
            return;
        }
        
        swal({
            title: "确认装备升级",
            html: confirmHtml + '<p style="color: #e67e22; margin-top: 10px;">确认要升级这件物品吗？</p>',
            type: "warning",
            showCancelButton: true,
            confirmButtonColor: "#27ae60",
            cancelButtonColor: "#95a5a6",
            confirmButtonText: "确认升级",
            cancelButtonText: "取消",
            closeOnConfirm: false,
            showLoaderOnConfirm: true,
            allowOutsideClick: false
        }, function(isConfirm) {
            if (isConfirm) {
                // 显示处理中提示
                swal({
                    title: "升级进行中",
                    text: "正在处理装备升级，请稍候...",
                    type: "info",
                    showConfirmButton: false,
                    allowOutsideClick: false
                });
                
                // 执行升级
                performExchange(lineNo, oldId, newId);
            }
        });
    });
}

// 执行装备升级 - 修复功能
function performExchange(lineNo, oldId, newId) {
    console.log('performExchange called with:', {lineNo, oldId, newId});
    
    const formData = new FormData();
    formData.append('action', 'exchange_item');
    formData.append('character_no', selectedCharacterNo);
    formData.append('line_no', lineNo);
    formData.append('old_id', oldId);
    formData.append('new_id', newId);
    
    fetch('', {
        method: 'POST',
        body: formData
    })
    .then(response => response.json())
    .then(data => {
        console.log('Exchange response:', data);
        if (data.success) {
            swal({
                title: "升级成功!",
                text: data.message,
                type: "success",
                confirmButtonText: "确定"
            }).then(() => {
                // 重新加载商店
                loadUserStore();
            });
        } else {
            swal({
                title: "升级失败",
                text: data.message,
                type: "error",
                confirmButtonText: "确定"
            });
        }
    })
    .catch(error => {
        console.error('Exchange error:', error);
        swal({
            title: "升级失败",
            text: "网络错误，请稍后重试",
            type: "error",
            confirmButtonText: "确定"
        });
    });
}

// 获取用户商城币余额
function getUserCashBalance(callback) {
    fetch('<?php echo site_url('assets/ajax/get_user_cash.php'); ?>', {
        method: 'GET'
    })
    .then(response => response.text())
    .then(data => {
        callback(data.trim());
    })
    .catch(error => {
        console.error('Get cash error:', error);
        callback('0');
    });
}

// 显示Loading
function showLoading(text = '处理中...') {
    const overlay = document.getElementById('loadingOverlay');
    const loadingText = document.getElementById('loadingText');
    if (overlay) {
        overlay.style.display = 'flex';
        if (loadingText) loadingText.textContent = text;
    }
}

// 隐藏Loading
function hideLoading() {
    const overlay = document.getElementById('loadingOverlay');
    if (overlay) {
        overlay.style.display = 'none';
    }
}

// 动态效果初始化
function initDynamicEffects() {
    // 更新实时热度
    updateLivePopularity();
    
    // 智能更新表格
    setInterval(smartUpdateTable, 3000);
    
    // 获取在线人数
    getOnlineCount();
    setInterval(getOnlineCount, 10000);
}

// 更新实时热度
function updateLivePopularity() {
    var totalStars = 0;
    var starElements = document.querySelectorAll('.fa-star:not(.far)');
    
    if (starElements.length > 0) {
        totalStars = starElements.length;
        var totalPossibleStars = document.querySelectorAll('.popularity-stars').length * 5;
        var avgStars = (totalStars / totalPossibleStars * 100).toFixed(0);
        var popularityText;
        
        if (avgStars >= 80) {
            popularityText = '<span style="color: #ef4444;">🔥 熔岩沸腾</span>';
        } else if (avgStars >= 60) {
            popularityText = '<span style="color: #f59e0b;">🔥 烈焰燃烧</span>';
        } else if (avgStars >= 40) {
            popularityText = '<span style="color: #eab308;">🔥 炉火正旺</span>';
        } else {
            popularityText = '<span style="color: #84cc16;">🔥 温暖炉火</span>';
        }
        
        document.getElementById('livePopularity').innerHTML = popularityText;
    }
}

// 智能更新表格
function smartUpdateTable() {
    var allRows = document.querySelectorAll('#tableBody .grid-row');
    var totalRows = allRows.length;
    
    if (totalRows === 0) return;
    
    // 更新1-2行
    var updateCount = Math.floor(Math.random() * 2) + 1;
    
    for (var i = 0; i < updateCount; i++) {
        var targetIndex = Math.floor(Math.random() * totalRows);
        var targetRow = allRows[targetIndex];
        
        // 更新趋势箭头
        var trendArrow = targetRow.querySelector('.trend-arrow');
        if (trendArrow) {
            var randomValue = Math.random();
            if (randomValue > 0.4) {
                trendArrow.innerHTML = '↑';
                trendArrow.className = 'trend-arrow trend-up';
            } else {
                trendArrow.innerHTML = '↓';
                trendArrow.className = 'trend-arrow trend-down';
            }
        }
        
        // 添加更新动画
        targetRow.style.animation = 'rowUpdateHighlight 1.5s ease-out';
        setTimeout(function() {
            targetRow.style.animation = '';
        }, 1500);
    }
}

// 获取在线人数
function getOnlineCount() {
    // 模拟在线人数
    var baseCount = 258;
    var now = new Date();
    var hour = now.getHours();
    var dynamicFactor = 1.0;
    
    // 根据时间段计算动态系数
    if (hour >= 19 && hour < 23) {
        dynamicFactor = 1.15 + (Math.random() * 0.05);
    } else if (hour >= 14 && hour < 18) {
        dynamicFactor = 1.10 + (Math.random() * 0.05);
    } else if (hour >= 11 && hour < 14) {
        dynamicFactor = 1.05 + (Math.random() * 0.05);
    } else if (hour >= 8 && hour < 11) {
        dynamicFactor = 1.00 + (Math.random() * 0.05);
    } else if (hour >= 0 && hour < 6) {
        dynamicFactor = 0.90 + (Math.random() * 0.05);
    } else {
        dynamicFactor = 0.98 + (Math.random() * 0.04);
    }
    
    var finalCount = Math.round(baseCount * dynamicFactor);
    var totalChangePercent = Math.round(((finalCount - baseCount) / baseCount) * 100);
    
    var displayText = finalCount + ' <span class="online-count">';
    if (totalChangePercent > 0) {
        displayText += '+' + totalChangePercent + '%';
    } else if (totalChangePercent < 0) {
        displayText += totalChangePercent + '%';
    } else {
        displayText += '±0%';
    }
    displayText += '</span>';
    
    document.getElementById('onlineCount').innerHTML = displayText;
}

// 添加行更新动画
var style = document.createElement('style');
style.textContent = `
    @keyframes rowUpdateHighlight {
        0% { 
            background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
            transform: scale(1.02);
        }
        100% { 
            background: inherit;
            transform: scale(1);
        }
    }
`;
document.head.appendChild(style);

// 数字格式化函数
function number_format(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

// 页面加载完成后初始化
document.addEventListener('DOMContentLoaded', function() {
    console.log('DOM loaded');
    if (selectedCharacterNo) {
        loadUserStore();
    }
    initDynamicEffects();
});
</script>

<?php include '../templates/footer.php'; ?>
