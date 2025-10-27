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
            
            // 检查背包中的物品
            $bag_item = $db_character->fetch("
                SELECT * FROM user_bag 
                WHERE character_no = ? AND line_no = ? AND windex = ?
            ", [$character_no, $line_no, $old_id]);
            
            if (!$bag_item) {
                echo json_encode(['success' => false, 'message' => '背包中未找到该装备']);
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
                
                // 2. 升级装备
                $stmt = $db_character->prepare("
                    UPDATE user_bag SET windex = ? 
                    WHERE character_no = ? AND line_no = ? AND windex = ?
                ");
                $stmt->execute([$new_id, $character_no, $line_no, $old_id]);
                
                // 3. 记录日志
                $db_account = get_db($server_id, 'account');
                $log_text = "装备升级: " . $exchange_item['oldname'] . " -> " . $exchange_item['newname'] . " - 消耗: " . $exchange_item['needcash'] . "商城币";
                $ip = $_SERVER['REMOTE_ADDR'] ?? '';
                
                $stmt = $db_account->prepare("
                    INSERT INTO adminlog (admin, datetime, ip, username, adminlog, logtype) 
                    VALUES (?, GETDATE(), ?, ?, ?, 3)
                ");
                $stmt->execute([$_SESSION['username'], $ip, $character_no, $log_text]);
                
                // 提交事务
                $db_character->commit();
                $db_cash->commit();
                
                echo json_encode([
                    'success' => true, 
                    'message' => '装备升级成功！' . $exchange_item['oldname'] . ' → ' . $exchange_item['newname']
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
/* 装备熔炼页面样式 */
.exchange-container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
    position: relative;
}

.exchange-header {
    text-align: center;
    margin-bottom: 30px;
}

.exchange-title {
    font-size: 32px;
    font-weight: 800;
    color: #fff;
    text-shadow: 0 0 20px rgba(74, 158, 255, 0.5);
    margin-bottom: 10px;
}

.exchange-subtitle {
    font-size: 16px;
    color: #b0b0b0;
}

/* 主布局 - 左右分栏 */
.exchange-main-layout {
    display: flex;
    gap: 30px;
    align-items: flex-start;
}

/* 左侧角色选择器 */
.character-sidebar {
    flex: 0 0 33.333%;
    max-width: 400px;
    position: sticky;
    top: 20px;
}

.character-selector {
    background: rgba(20, 20, 20, 0.9);
    backdrop-filter: blur(10px);
    border-radius: 12px;
    padding: 20px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
}

.character-selector h3 {
    color: #f0f0f0;
    margin-bottom: 20px;
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
    flex-direction: column;
    gap: 12px;
}

.character-option {
    background: rgba(30, 30, 30, 0.8);
    border: 2px solid rgba(255, 255, 255, 0.1);
    border-radius: 8px;
    padding: 15px;
    cursor: pointer;
    transition: all 0.3s ease;
    display: flex;
    align-items: center;
    gap: 12px;
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
    font-size: 24px;
}

.character-info {
    flex: 1;
}

.character-name {
    font-weight: 500;
    font-size: 16px;
    margin-bottom: 4px;
}

.character-level {
    font-size: 12px;
    color: #888;
}

/* 右侧内容区域 */
.exchange-content {
    flex: 0 0 66.667%;
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

/* 升级列表 */
.exchange-list-container {
    background: rgba(20, 20, 20, 0.9);
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
    gap: 10px;
}

.exchange-list-header i {
    color: #4a9eff;
}

.exchange-list-table {
    width: 100%;
    border-collapse: separate;
    border-spacing: 0;
    background: rgba(25, 25, 35, 0.6);
    border-radius: 8px;
    overflow: hidden;
}

.exchange-list-table th {
    background: linear-gradient(135deg, rgba(40, 50, 70, 0.9), rgba(30, 40, 60, 0.9));
    color: #e0e0e0;
    padding: 12px;
    text-align: center;
    font-weight: 600;
    font-size: 14px;
    border-bottom: 1px solid rgba(74, 158, 255, 0.3);
}

.exchange-list-table td {
    padding: 12px;
    text-align: center;
    border-bottom: 1px solid rgba(74, 158, 255, 0.1);
    color: #b0b0b0;
}

.exchange-list-table tr:last-child td {
    border-bottom: none;
}

.exchange-list-table tr:hover {
    background-color: rgba(74, 158, 255, 0.1);
}

.old-item-name, .new-item-name {
    font-weight: 500;
    color: #e0e0e0;
}

.need-cash {
    font-weight: 600;
    color: #ffc107;
}

/* 用户背包 */
.user-bag-container {
    background: rgba(20, 20, 20, 0.9);
    backdrop-filter: blur(10px);
    border-radius: 12px;
    padding: 20px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
}

.user-bag-header {
    color: #f0f0f0;
    margin-bottom: 15px;
    font-size: 18px;
    display: flex;
    align-items: center;
    gap: 10px;
}

.user-bag-header i {
    color: #4a9eff;
}

.user-bag-table {
    width: 100%;
    border-collapse: separate;
    border-spacing: 0;
    background: rgba(25, 25, 35, 0.6);
    border-radius: 8px;
    overflow: hidden;
}

.user-bag-table th {
    background: linear-gradient(135deg, rgba(40, 50, 70, 0.9), rgba(30, 40, 60, 0.9));
    color: #e0e0e0;
    padding: 12px;
    text-align: center;
    font-weight: 600;
    font-size: 14px;
    border-bottom: 1px solid rgba(74, 158, 255, 0.3);
}

.user-bag-table td {
    padding: 12px;
    text-align: center;
    border-bottom: 1px solid rgba(74, 158, 255, 0.1);
    color: #b0b0b0;
}

.user-bag-table tr:last-child td {
    border-bottom: none;
}

.user-bag-table tr:hover {
    background-color: rgba(74, 158, 255, 0.1);
}

.bag-item-name {
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
}

.exchange-btn:hover {
    background: linear-gradient(135deg, #5aa8ff, #4a8edd);
    transform: translateY(-2px);
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

/* Toast提示 */
.toast {
    position: fixed;
    top: 80px;
    right: 20px;
    padding: 15px 20px;
    border-radius: 8px;
    color: white;
    font-weight: 500;
    z-index: 9999999;
    animation: slideIn 0.3s ease;
    max-width: 300px;
}

.toast.success {
    background: #28a745;
    box-shadow: 0 4px 12px rgba(40, 167, 69, 0.3);
}

.toast.error {
    background: #dc3545;
    box-shadow: 0 4px 12px rgba(220, 53, 69, 0.3);
}

@keyframes slideIn {
    from { transform: translateX(100%); opacity: 0; }
    to { transform: translateX(0); opacity: 1; }
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
    
    .exchange-list-table, .user-bag-table {
        font-size: 12px;
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

<div class="exchange-container">
    <!-- 页面头部 -->
    <div class="exchange-header">
        <div class="exchange-title">
            <i class="fas fa-fire"></i>
            装备熔炼
        </div>
        <div class="exchange-subtitle">
            将您的装备升级为更强大的形态
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
                    <span>请将需要升级的装备放在角色背包中，然后选择角色进行升级操作</span>
                </div>
            </div>
            
            <!-- 升级列表 -->
            <div class="exchange-list-container">
                <div class="exchange-list-header">
                    <i class="fas fa-list"></i>
                    装备升级列表
                </div>
                <table class="exchange-list-table">
                    <thead>
                        <tr>
                            <th>当前装备</th>
                            <th>升级后装备</th>
                            <th>所需商城币</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php if (empty($exchange_list)): ?>
                            <tr>
                                <td colspan="3" class="no-items">暂无升级配置</td>
                            </tr>
                        <?php else: ?>
                            <?php foreach ($exchange_list as $index => $item): ?>
                                <tr class="<?php echo $index % 2 === 0 ? 'even' : 'odd'; ?>">
                                    <td class="old-item-name"><?php echo htmlspecialchars($item['oldname']); ?></td>
                                    <td class="new-item-name"><?php echo htmlspecialchars($item['newname']); ?></td>
                                    <td class="need-cash"><?php echo number_format($item['needcash']); ?></td>
                                </tr>
                            <?php endforeach; ?>
                        <?php endif; ?>
                    </tbody>
                </table>
            </div>
            
            <!-- 用户背包 -->
            <div class="user-bag-container">
                <div class="user-bag-header">
                    <i class="fas fa-backpack"></i>
                    我的背包 - 可升级装备
                </div>
                <div id="userBagContent">
                    <div class="no-items">请先选择角色</div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
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
            // 加载用户背包
            loadUserBag();
        }
    });
}

// 加载用户背包
function loadUserBag() {
    if (!selectedCharacterNo) {
        document.getElementById('userBagContent').innerHTML = '<div class="no-items">请先选择角色</div>';
        return;
    }
    
    showLoading('加载背包数据...');
    
    fetch('<?php echo site_url('assets/ajax/get_user_bag.php'); ?>', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'character_no=' + selectedCharacterNo + '&server_id=<?php echo $server_id; ?>'
    })
    .then(response => response.json())
    .then(data => {
        hideLoading();
        
        if (data.success) {
            renderUserBag(data.items);
        } else {
            document.getElementById('userBagContent').innerHTML = '<div class="no-items">' + data.message + '</div>';
        }
    })
    .catch(error => {
        hideLoading();
        console.error('Load bag error:', error);
        document.getElementById('userBagContent').innerHTML = '<div class="no-items">加载失败</div>';
    });
}

// 渲染用户背包
function renderUserBag(items) {
    let html = '<table class="user-bag-table"><thead><tr><th>装备名称</th><th>操作</th></tr></thead><tbody>';
    
    if (items.length === 0) {
        html += '<tr><td colspan="2" class="no-items">您的背包中没有可升级的装备</td></tr>';
    } else {
        items.forEach(item => {
            html += '<tr>';
            html += '<td class="bag-item-name">' + htmlspecialchars(item.item_name) + '</td>';
            html += '<td>';
            html += '<button class="exchange-btn" onclick="confirmExchange(';
            html += item.line_no + ', ' + item.windex + ', ' + item.new_id + ', ' + item.need_cash + ', \'' + htmlspecialchars(item.item_name) + '\')">';
            html += '升级装备';
            html += '</button>';
            html += '</td>';
            html += '</tr>';
        });
    }
    
    html += '</tbody></table>';
    document.getElementById('userBagContent').innerHTML = html;
}

// 确认装备升级
function confirmExchange(lineNo, oldId, newId, needCash, itemName) {
    // 先获取用户余额
    getUserCashBalance(function(userCash) {
        var canAfford = parseInt(userCash) >= parseInt(needCash);
        var statusHtml = canAfford ? 
            '<span style="color: #27ae60; font-weight: bold;">余额充足</span>' : 
            '<span style="color: #dc3545; font-weight: bold;">余额不足</span>';
        
        var confirmHtml = '<div style="text-align: left; padding: 15px; background: #f8f9fa; border-radius: 8px; margin: 15px 0;">' +
            '<p><strong>🛡️ 装备名称:</strong> ' + itemName + '</p>' +
            '<p><strong>💰 所需商城币:</strong> ' + needCash + ' 点</p>' +
            '<p><strong>👤 您的余额:</strong> ' + userCash + ' 点</p>' +
            '<p><strong>📊 状态:</strong> ' + statusHtml + '</p>' +
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
            html: confirmHtml + '<p style="color: #e67e22; margin-top: 10px;">确认要升级这件装备吗？</p>',
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

// 执行装备升级
function performExchange(lineNo, oldId, newId) {
    fetch('', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'action=exchange_item&character_no=' + selectedCharacterNo + '&line_no=' + lineNo + '&old_id=' + oldId + '&new_id=' + newId
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            swal({
                title: "升级成功!",
                text: data.message,
                type: "success",
                confirmButtonText: "确定"
            }).then(() => {
                // 重新加载背包
                loadUserBag();
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
        method: 'GET',
        dataType: 'text'
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

// 显示Toast提示
function showToast(message, type = 'info') {
    const toast = document.createElement('div');
    toast.className = 'toast ' + type;
    toast.textContent = message;
    document.body.appendChild(toast);
    
    // 3秒后移除
    setTimeout(() => {
        toast.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        }, 300);
    }, 3000);
}

// 页面加载完成后自动加载背包
document.addEventListener('DOMContentLoaded', function() {
    if (selectedCharacterNo) {
        loadUserBag();
    }
});
</script>

<?php include '../templates/footer.php'; ?>
