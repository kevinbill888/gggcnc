<?php
// add_sale.php - 寄售新物品页面
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once '../config.php';
require_once '../auth.php';
require_once '../db.php';
require_once '../includes/item_icon_helper.php';  // 引入图标识别模块

if (!is_logged_in()) {
    header('Location: ' . site_url('login.php'));
    exit;
}

$server_id = $_SESSION['server_id'];
$user_no = $_SESSION['user_no'];

// 获取用户发布物品数量信息
$user_market_info = checkUserMarketItemsCount($server_id, $user_no);

// 检查 parseItemAttributes 函数是否存在
if (!function_exists('parseItemAttributes')) {
    function parseItemAttributes($info, $byHeader) {
        $hexInfo = bin2hex($info);
        if (substr($hexInfo, 0, 2) === '30') {
            $hexInfo = substr($hexInfo, 2);
        }
        $hexInfo = strtoupper($hexInfo);
        
        $byHeaderVal = intval($byHeader ?? 0);
        $qty = "1";
        
        if ($byHeaderVal == 1) {
            $qty = substr($hexInfo, 0, 8);
            $qty = hexdec($qty);
            if ($qty > 5000) {
                $qty = 1;
            }
        }
        
        return "数量: " . $qty . "\n属性\n属性: 无\n----\n镶嵌\n镶嵌: 无镶嵌\n";
    }
}

// 获取仓库物品
function getStorageItems($server_id, $character_no) {
    $db_character = get_db($server_id, 'character');
    $db_account = get_db($server_id, 'account');
    
    try {
        $stmt = $db_character->prepare("
            SELECT line_no, wIndex, info, byHeader 
            FROM user_storage 
            WHERE character_no = ? 
            ORDER BY line_no
        ");
        $stmt->execute([$character_no]);
        $items = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        $formatted_items = [];
        foreach ($items as $item) {
            try {
                $item_stmt = $db_account->prepare("
                    SELECT item_name FROM web_items WHERE windex = ?
                ");
                $item_stmt->execute([$item['wIndex']]);
                $item_info = $item_stmt->fetch(PDO::FETCH_ASSOC);
                
                $raw_attrs = parseItemAttributes($item['info'], $item['byHeader']);
                
                $formatted_items[] = [
                    'line_no' => $item['line_no'],
                    'windex' => $item['wIndex'],
                    'item_name' => $item_info['item_name'] ?? '未知物品',
                    'raw_attrs' => $raw_attrs,
                    'can_sell' => true
                ];
                
            } catch (Exception $e) {
                error_log("处理物品失败: " . $e->getMessage());
                continue;
            }
        }
        
        return $formatted_items;
        
    } catch (Exception $e) {
        error_log("getStorageItems Error: " . $e->getMessage());
        return [];
    }
}

// 寄售物品函数 - 参考调试文件的实现
function sellItem($server_id, $user_no, $character_no, $line_no, $price) {
    error_log("=== 开始寄售流程 ===");
    error_log("参数: server_id=$server_id, user_no=$user_no, character_no=$character_no, line_no=$line_no, price=$price");
    
    try {
        // 首先检查发布限制
        $market_info = checkUserMarketItemsCount($server_id, $user_no);
        if (!$market_info['allowed']) {
            throw new Exception("您已达到发布上限（{$market_info['max']}件），请先取回一些物品");
        }
        
        // 验证价格
        if (!is_numeric($price) || $price < 1 || $price > 99999999) {
            throw new Exception("价格格式错误，请输入1-99999999之间的数字");
        }
        error_log("价格验证通过");
        
        // 获取数据库连接
        $db_character = get_db($server_id, 'character');
        if (!$db_character) {
            throw new Exception("无法连接到角色数据库");
        }
        error_log("数据库连接成功");
        
        // 验证角色归属
        $char = $db_character->fetch("
            SELECT user_no, character_name FROM user_character 
            WHERE character_no = ? AND user_no = ?
        ", [$character_no, $user_no]);
        
        if (!$char) {
            throw new Exception('角色不属于您');
        }
        error_log("角色验证通过: " . $char['character_name']);
        
        // 获取仓库物品 - 关键修复：不转换line_no类型
        error_log("查询仓库物品: character_no=$character_no, line_no=$line_no");
        
        // 使用字符串匹配，因为line_no是nvarchar类型
        $item = $db_character->fetch("
            SELECT wIndex, dwSerialNumber, byHeader, info 
            FROM user_storage 
            WHERE character_no = ? AND line_no = ?
        ", [$character_no, $line_no]);
        
        if (!$item) {
            // 查看所有仓库物品用于调试
            $all_items = $db_character->fetchAll("
                SELECT line_no, wIndex FROM user_storage 
                WHERE character_no = ?
            ", [$character_no]);
            error_log("该角色所有仓库物品: " . json_encode($all_items));
            throw new Exception('仓库中不存在该物品 (位置: ' . $line_no . ')');
        }
        error_log("找到物品: wIndex={$item['wIndex']}");
        
        // 生成唯一编号
        $post_no = date('ymdHis') . substr(mt_rand(1000, 9999), 0, 4);
        error_log("生成post_no: $post_no");
        
        // 获取管理员ID
        $admin_character = get_admin_character($server_id);
        error_log("管理员ID: $admin_character");
        
        // 开始事务
        error_log("开始事务");
        $db_character->beginTransaction();
        
        try {
            // 插入到市场 - 简化SQL，参考调试文件
            error_log("插入USER_POSTBOX表");
            
            $sql = "INSERT INTO USER_POSTBOX (
                character_no, post_no, sell_character_no, wIndex, 
                include_dil, from_char_nm, post_sort, post_title, body_text,
                state_tag, item_tag, dil_tag, ipt_time, expire_time
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, GETDATE(), DATEADD(day, 90, GETDATE()))";
            
            $stmt = $db_character->prepare($sql);
            
            // 截断过长的字段
            $post_no = substr($post_no, 0, 18);
            $from_char_nm = substr($char['character_name'], 0, 50);
            $post_title = substr('自助寄售道具', 0, 100);
            $body_text = substr('90天内未出售请自行取回,否则自动删除', 0, 200);
            
            // 绑定参数
            $stmt->bindValue(1, $admin_character);
            $stmt->bindValue(2, $post_no);
            $stmt->bindValue(3, $character_no);
            $stmt->bindValue(4, $item['wIndex']);
            $stmt->bindValue(5, $price);
            $stmt->bindValue(6, $from_char_nm);
            $stmt->bindValue(7, 0);
            $stmt->bindValue(8, $post_title);
            $stmt->bindValue(9, $body_text);
            $stmt->bindValue(10, 0);
            $stmt->bindValue(11, 1);
            $stmt->bindValue(12, 0);
            
            $result = $stmt->execute();
            
            if (!$result) {
                $error = $stmt->errorInfo();
                throw new Exception('插入失败: ' . $error[2]);
            }
            error_log("插入成功");
            
            // 从仓库删除 - 同样不转换类型
            error_log("从仓库删除物品");
            $delete_stmt = $db_character->prepare("
                DELETE FROM user_storage 
                WHERE character_no = ? AND line_no = ?
            ");
            $delete_result = $delete_stmt->execute([$character_no, $line_no]);
            
            if (!$delete_result) {
                $error = $delete_stmt->errorInfo();
                throw new Exception('删除失败: ' . $error[2]);
            }
            error_log("删除成功");
            
            // 提交事务
            error_log("提交事务");
            $db_character->commit();
            
            error_log("寄售成功: 角色{$character_no} 位置{$line_no} 价格{$price}");
            
            return ['success' => true, 'message' => '装备寄售成功！90天内有效期，未出售请自行取回。'];
            
        } catch (Exception $e) {
            $db_character->rollBack();
            throw $e;
        }
        
    } catch (Exception $e) {
        error_log("寄售失败: " . $e->getMessage());
        error_log("详细错误: " . $e->getTraceAsString());
        return ['success' => false, 'message' => $e->getMessage()];
    }
}

// 生成唯一编号
function generatePostNo() {
    $timestamp = date('YmdHis');
    $random = '';
    $chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for ($i = 0; $i < 6; $i++) {
        $random .= $chars[rand(0, strlen($chars) - 1)];
    }
    return $timestamp . $random;
}

// 处理AJAX请求 - 确保返回JSON格式
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    // 清除所有之前的输出
    if (ob_get_level()) {
        ob_clean();
    }
    
    header('Content-Type: application/json; charset=utf-8');
    
    try {
        $action = $_POST['action'];
        error_log("收到AJAX请求: " . $action);
        
        if ($action == 'get_storage') {
            $character_no = $_POST['character_no'];
            error_log("查询角色仓库: " . $character_no);
            
            $items = getStorageItems($server_id, $character_no);
            
            $response = [
                'success' => true, 
                'items' => $items,
                'market_info' => checkUserMarketItemsCount($server_id, $user_no),
                'debug' => [
                    'character_no' => $character_no,
                    'server_id' => $server_id,
                    'item_count' => count($items)
                ]
            ];
            echo json_encode($response, JSON_UNESCAPED_UNICODE);
            
        } elseif ($action == 'sell_item') {
            $character_no = $_POST['character_no'];
            $line_no = $_POST['line_no'];
            $price = $_POST['price'];
            
            error_log("寄售请求 - 角色: $character_no, 位置: $line_no, 价格: $price");
            
            // 调用寄售函数
            $result = sellItem($server_id, $user_no, $character_no, $line_no, $price);
            
            // 确保返回有效的JSON
            echo json_encode($result, JSON_UNESCAPED_UNICODE);
        }
        
    } catch (Exception $e) {
        error_log("AJAX Error: " . $e->getMessage());
        
        // 确保即使出错也返回JSON格式
        $error_response = [
            'success' => false, 
            'message' => $e->getMessage(),
            'trace' => $e->getTraceAsString()
        ];
        echo json_encode($error_response, JSON_UNESCAPED_UNICODE);
    }
    exit;
}

$page_title = '寄售物品 - 游戏市场';
$breadcrumbs = [
    ['name' => '游戏市场', 'url' => site_url('market/')],
    ['name' => '我的寄售', 'url' => site_url('market/sell.php')],
    ['name' => '寄售物品', 'url' => site_url('market/add_sale.php')]
];

include '../templates/header.php';

$characters = getUserCharacters($server_id, $user_no);
?>

<style>
/* 发布限制提示样式 */
.market-limit-info {
    background: rgba(20, 20, 20, 0.9);
    padding: 15px 20px;
    border-radius: 8px;
    margin-bottom: 20px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.market-limit-text {
    color: #e0e0e0;
    font-size: 14px;
}

.market-limit-count {
    font-weight: 600;
    color: #4a9eff;
}

.market-limit-warning {
    color: #ffc107;
}

.market-limit-full {
    color: #dc3545;
}

/* 加载动画样式 */
.market-loading {
    display: flex;
    justify-content: center;
    align-items: center;
    padding: 40px;
}

.market-spinner {
    width: 40px;
    height: 40px;
    border: 4px solid rgba(255, 255, 255, 0.1);
    border-top: 4px solid #4a9eff;
    border-radius: 50%;
    animation: spin 1s linear infinite;
}

@keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
}

/* 禁用状态样式 */
.market-item-disabled {
    opacity: 0.5;
    pointer-events: none;
}

.market-item-disabled .market-btn-success {
    background: #666 !important;
    cursor: not-allowed !important;
}
</style>

<div class="market-container">
    <div class="market-page-container">
        <!-- 页面头部 -->
        <div class="market-page-header">
            <div class="market-page-title">
                <i class="fas fa-store"></i>
                寄售系统
            </div>
            <div class="market-server-info">
                服务器: <?php echo get_server_info($server_id)['name']; ?> | 管理员ID: <?php echo get_admin_character($server_id); ?>
            </div>
        </div>
        
        <!-- 用户发布限制提示 -->
        <div class="market-limit-info">
            <div class="market-limit-text">
                <i class="fas fa-info-circle"></i>
                您当前已发布 <span class="market-limit-count"><?php echo $user_market_info['count']; ?></span> 件物品
                （最多可发布 <span class="market-limit-count"><?php echo $user_market_info['max']; ?></span> 件）
            </div>
            <?php if (!$user_market_info['allowed']): ?>
                <div class="market-limit-full">
                    <i class="fas fa-exclamation-triangle"></i> 已达到上限
                </div>
            <?php elseif ($user_market_info['count'] >= $user_market_info['max'] * 0.8): ?>
                <div class="market-limit-warning">
                    <i class="fas fa-exclamation-circle"></i> 即将达到上限
                </div>
            <?php endif; ?>
        </div>
        
        <!-- 主内容区 -->
        <div class="market-main-container">
            <!-- 左侧角色列表 -->
            <div class="market-character-panel">
                <div class="market-panel-header">
                    <div class="market-panel-title">
                        <i class="fas fa-users"></i>
                        选择角色
                    </div>
                </div>
                <div class="market-character-list">
                    <?php foreach ($characters as $char): ?>
                    <div class="market-character-card" 
                         data-character-no="<?php echo $char['character_no']; ?>"
                         onclick="selectCharacter(this)">
                        <div class="market-character-name"><?php echo htmlspecialchars($char['character_name']); ?></div>
                        <div class="market-character-level">等级: <?php echo $char['wlevel']; ?></div>
                    </div>
                    <?php endforeach; ?>
                </div>
            </div>
            
            <!-- 右侧仓库 -->
            <div class="market-storage-panel">
                <div class="market-storage-header">
                    <div class="market-panel-title">
                        <i class="fas fa-warehouse"></i>
                        仓库物品
                    </div>
                </div>
                <div class="market-storage-content" id="storageContent">
                    <div class="market-empty-state">
                        <i class="fas fa-mouse-pointer"></i>
                        <p>请先选择一个角色</p>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- 自定义弹窗 - 不使用Bootstrap模态框 -->
<div id="customModal" style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.8); z-index: 999999999;">
    <div style="position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); background: #1e1e1e; color: #e0e0e0; border-radius: 15px; padding: 0; min-width: 400px; box-shadow: 0 10px 40px rgba(0,0,0,0.5);">
        <div style="padding: 20px; border-bottom: 1px solid rgba(255,255,255,0.1);">
            <h5 style="margin: 0; color: #e0e0e0;">确认寄售</h5>
        </div>
        <div style="padding: 20px;" id="customModalContent">
            <!-- 内容将动态插入 -->
        </div>
        <div style="padding: 15px 20px; border-top: 1px solid rgba(255,255,255,0.1); text-align: right;">
            <button type="button" id="cancelBtn" style="background: #6c757d; color: white; border: none; padding: 8px 16px; margin-right: 10px; border-radius: 5px; cursor: pointer;">取消</button>
            <button type="button" id="confirmBtn" style="background: #007bff; color: white; border: none; padding: 8px 16px; border-radius: 5px; cursor: pointer;">确认寄售</button>
        </div>
    </div>
</div>

<?php include '../templates/footer.php'; ?>

<link rel="stylesheet" href="../assets/css/market.css">

<script>
// 页面加载时显示Loading
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

let selectedCharacter = null;
let currentLineNo = null;
let marketInfo = null;

function selectCharacter(card) {
    // 移除其他选中状态
    document.querySelectorAll('.market-character-card').forEach(c => {
        c.classList.remove('active');
    });
    
    // 添加选中状态
    card.classList.add('active');
    
    selectedCharacter = card.dataset.characterNo;
    
    // 加载仓库物品
    loadStorageItems(selectedCharacter);
}

function loadStorageItems(characterNo) {
    const container = document.getElementById('storageContent');
    
    // 显示加载动画
    container.innerHTML = '<div class="market-loading"><div class="market-spinner"></div></div>';
    
    console.log('开始加载仓库物品，角色:', characterNo);
    
    fetch('', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'action=get_storage&character_no=' + characterNo
    })
    .then(response => {
        console.log('收到响应:', response);
        return response.json();
    })
    .then(data => {
        console.log('解析的数据:', data);
        
        if (data.success) {
            marketInfo = data.market_info;
            displayItems(data.items, data.market_info);
        } else {
            container.innerHTML = '<div class="market-empty-state"><i class="fas fa-exclamation-triangle"></i><p>加载失败：' + data.message + '</p></div>';
        }
    })
    .catch(error => {
        console.error('错误:', error);
        container.innerHTML = '<div class="market-empty-state"><i class="fas fa-exclamation-triangle"></i><p>网络错误：' + error.message + '</p></div>';
    });
}

function displayItems(items, marketInfo) {
    const container = document.getElementById('storageContent');
    
    if (items.length === 0) {
        container.innerHTML = '<div class="market-empty-state"><i class="fas fa-box-open"></i><p>仓库为空</p></div>';
        return;
    }
    
    let html = '<div class="market-storage-grid">';
    items.forEach(item => {
        // 检查是否还能发布
        const canSell = marketInfo && marketInfo.allowed;
        const disabledClass = canSell ? '' : 'market-item-disabled';
        
        html += `
            <div class="market-storage-item ${disabledClass}" onclick="${canSell ? `showSellModal('${item.line_no}', '${item.item_name}')` : 'showLimitWarning()'}">
                <div class="market-item-icon">
                    <i class="fas fa-cube"></i>
                </div>
                <div class="market-item-info">
                    <div class="market-item-name">${item.item_name}</div>
                    <div class="market-item-id">ID: ${item.windex}</div>
                    <div class="market-item-position">位置: ${item.line_no}</div>
                </div>
                <div class="market-item-action">
                    <button class="market-btn-success" ${!canSell ? 'disabled' : ''}>
                        <i class="fas fa-tag"></i> ${canSell ? '寄售' : '已达上限'}
                    </button>
                </div>
            </div>
        `;
    });
    html += '</div>';
    
    container.innerHTML = html;
}

function showLimitWarning() {
    if (marketInfo && !marketInfo.allowed) {
        alert(`您已达到发布上限（${marketInfo.max}件），请先取回一些物品后再寄售。`);
    }
}

function showSellModal(lineNo, itemName) {
    currentLineNo = lineNo;
    
    const content = `
        <h6>寄售物品：${itemName}</h6>
        <div style="margin-bottom: 15px;">
            <label style="display: block; margin-bottom: 5px; color: #e0e0e0;">寄售价格：</label>
            <input type="number" id="sellPrice" style="width: 100%; padding: 8px; background: rgba(255,255,255,0.1); border: 1px solid rgba(255,255,255,0.3); color: white; border-radius: 5px;" 
                   min="1" max="99999999" placeholder="请输入价格" autocomplete="off">
            <small style="color: #999; font-size: 12px;">价格范围：1-99999999</small>
        </div>
        ${marketInfo ? `
            <div style="padding: 10px; background: rgba(74, 158, 255, 0.1); border-radius: 5px; margin-bottom: 15px;">
                <small style="color: #4a9eff;">
                    当前已发布 ${marketInfo.count}/${marketInfo.max} 件物品
                    ${!marketInfo.allowed ? '<br><span style="color: #dc3545;">已达到发布上限！</span>' : ''}
                </small>
            </div>
        ` : ''}
    `;
    
    document.getElementById('customModalContent').innerHTML = content;
    document.getElementById('customModal').style.display = 'block';
    
    // 聚焦到输入框
    setTimeout(() => {
        document.getElementById('sellPrice').focus();
    }, 100);
    
    // 绑定事件
    document.getElementById('cancelBtn').onclick = hideModal;
    document.getElementById('confirmBtn').onclick = confirmSell;
    
    // 点击背景关闭
    document.getElementById('customModal').onclick = function(e) {
        if (e.target === this) {
            hideModal();
        }
    };
    
    // ESC键关闭
    document.onkeydown = function(e) {
        if (e.key === 'Escape') {
            hideModal();
        }
    };
}

function hideModal() {
    document.getElementById('customModal').style.display = 'none';
    document.onkeydown = null;
}

function confirmSell() {
    const price = document.getElementById('sellPrice').value;
    
    if (!price || price < 1 || price > 99999999) {
        alert('请输入有效的价格（1-99999999）');
        return;
    }
    
    // 检查发布限制
    if (marketInfo && !marketInfo.allowed) {
        alert(`您已达到发布上限（${marketInfo.max}件），请先取回一些物品后再寄售。`);
        return;
    }
    
    // 显示加载状态
    const modalContent = document.getElementById('customModalContent');
    const originalContent = modalContent.innerHTML;
    modalContent.innerHTML = '<div style="text-align: center; padding: 20px;"><div class="market-spinner" style="margin: 0 auto 10px;"></div><p>正在寄售...</p></div>';
    
    console.log('发送寄售请求:', {
        character_no: selectedCharacter,
        line_no: currentLineNo,
        price: price
    });
    
    fetch('', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: `action=sell_item&character_no=${selectedCharacter}&line_no=${currentLineNo}&price=${price}`
    })
    .then(response => {
        console.log('收到响应:', response);
        // 检查响应是否为JSON格式
        const contentType = response.headers.get('content-type');
        if (contentType && contentType.includes('application/json')) {
            return response.json();
        } else {
            // 如果不是JSON，读取文本内容
            return response.text().then(text => {
                console.log('非JSON响应:', text);
                throw new Error('服务器返回非JSON格式: ' + text);
            });
        }
    })
    .then(data => {
        console.log('解析的数据:', data);
        
        if (data.success) {
            alert(data.message);
            hideModal();
            // 重新加载仓库物品
            loadStorageItems(selectedCharacter);
            // 更新页面上的发布数量信息
            updateMarketLimitInfo();
        } else {
            alert('寄售失败：' + data.message);
            // 恢复模态框内容
            modalContent.innerHTML = originalContent;
            // 重新绑定事件
            document.getElementById('sellPrice').focus();
            document.getElementById('confirmBtn').onclick = confirmSell;
        }
    })
    .catch(error => {
        console.error('错误:', error);
        alert('寄售失败：' + error.message);
        modalContent.innerHTML = originalContent;
        document.getElementById('sellPrice').focus();
        document.getElementById('confirmBtn').onclick = confirmSell;
    });
}

function updateMarketLimitInfo() {
    // 刷新页面以更新发布数量
    setTimeout(() => {
        location.reload();
    }, 1000);
}
</script>
