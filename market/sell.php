<?php
// sell.php - 我的寄售页面
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

// 在获取交易记录前，获取当前选择的角色
$current_character_no = $_SESSION['current_character_no'] ?? null;
$current_character_name = $_SESSION['current_character_name'] ?? '未选择角色';

// 获取我的寄售物品
function getMySales($server_id, $user_no) {
    $db_character = get_db($server_id, 'character');
    $db_account = get_db($server_id, 'account');
    
    try {
        // 获取用户的所有角色
        $characters = $db_character->fetchAll("
            SELECT character_no, character_name 
            FROM user_character 
            WHERE user_no = ?
        ", [$user_no]);
        
        $character_nos = array_column($characters, 'character_no');
        
        if (empty($character_nos)) {
            return [];
        }
        
        // 获取管理员ID
        $admin_character = get_admin_character($server_id);
        
        // 构建IN查询
        $placeholders = str_repeat('?,', count($character_nos) - 1) . '?';
        
        // 查询寄售物品 - 从USER_POSTBOX表中查询sell_character_no
        $sql = "SELECT p.*, c.character_name 
                FROM USER_POSTBOX p
                LEFT JOIN user_character c ON p.sell_character_no = c.character_no
                WHERE p.sell_character_no IN ({$placeholders})
                AND p.character_no = ?  -- 确保是管理员账号的postbox
                ORDER BY p.ipt_time DESC";
        
        $params = array_merge($character_nos, [$admin_character]);
        $stmt = $db_character->prepare($sql);
        $stmt->execute($params);
        $items = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // 获取物品名称
        foreach ($items as &$item) {
            $item_info = $db_account->fetch("
                SELECT item_name FROM web_items WHERE windex = ?
            ", [$item['wIndex']]);
            $item['item_name'] = $item_info['item_name'] ?? '未知物品';
        }
        
        return $items;
        
    } catch (Exception $e) {
        error_log("getMySales Error: " . $e->getMessage());
        return [];
    }
}

// 获取交易记录 - 根据实际数据库结构修复
function getTradeHistory($server_id, $user_no) {
    $db_account = get_db($server_id, 'account');
    $db_character = get_db($server_id, 'character');
    
    try {
        // 根据web_market表结构查询
        // buy_user_no: 买家用户编号
        // sell_user_no: 卖家用户编号
        $sql = "SELECT * FROM web_market 
                WHERE buy_user_no = ? OR sell_user_no = ?
                ORDER BY time DESC";
        
        $stmt = $db_account->prepare($sql);
        $stmt->execute([$user_no, $user_no]);
        $trades = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        error_log("查询到交易记录数: " . count($trades));
        
        // 格式化交易记录
        foreach ($trades as &$trade) {
            // 获取物品名称
            if (isset($trade['Windex'])) {
                try {
                    $item_info = $db_account->fetch("
                        SELECT item_name FROM web_items WHERE windex = ?
                    ", [$trade['Windex']]);
                    $trade['item_name'] = $item_info['item_name'] ?? '物品ID:' . $trade['Windex'];
                } catch (Exception $e) {
                    $trade['item_name'] = '物品ID:' . $trade['Windex'];
                }
            } else {
                $trade['item_name'] = '未知物品';
            }
            
            // 判断交易类型
            $trade['type'] = 'sell'; // 默认为出售
            if ($trade['buy_user_no'] == $user_no) {
                $trade['type'] = 'buy'; // 当前用户是买家
            }
            
            // 设置状态
            $trade['status_text'] = '已完成';
            if (isset($trade['status'])) {
                if ($trade['status'] == 1) {
                    $trade['status_text'] = '已完成';
                } else {
                    $trade['status_text'] = '处理中';
                }
            }
            
            // 处理时间
            $trade['trade_time'] = $trade['time'] ?? date('Y-m-d H:i:s');
            
            // 处理金额 - 使用Money字段
            $trade['amount'] = $trade['Money'] ?? 0;
            
            // 添加交易双方信息
            $trade['buyer_name'] = $trade['buy_name'] ?? '未知买家';
            $trade['seller_name'] = $trade['sell_name'] ?? '未知卖家';
        }
        
        return $trades;
        
    } catch (Exception $e) {
        error_log("getTradeHistory Error: " . $e->getMessage());
        error_log("错误堆栈: " . $e->getTraceAsString());
        return [];
    }
}

// 处理AJAX请求
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    header('Content-Type: application/json');
    
    try {
        $action = $_POST['action'];
        
        if ($action == 'cancel_sale') {
            $post_no = $_POST['post_no'];
            
            $db_character = get_db($server_id, 'character');
            $admin_character = get_admin_character($server_id);
            
            // 获取物品信息
            $item = $db_character->fetch("
                SELECT wIndex, sell_character_no, include_dil, from_char_nm
                FROM USER_POSTBOX 
                WHERE post_no = ? AND character_no = ?
            ", [$post_no, $admin_character]);
            
            if (!$item) {
                throw new Exception('物品不存在或已售出');
            }
            
            // 验证是否是当前用户的物品
            $user_chars = $db_character->fetchAll("
                SELECT character_no FROM user_character WHERE user_no = ?
            ", [$user_no]);
            
            $user_char_nos = array_column($user_chars, 'character_no');
            if (!in_array($item['sell_character_no'], $user_char_nos)) {
                throw new Exception('无权操作此物品');
            }
            
            // 简单的UPDATE操作：将character_no更新为寄售者的角色ID
            // 这样物品就会出现在寄售者的邮箱中
            $result = $db_character->exec("
                UPDATE USER_POSTBOX 
                SET character_no = ?,
                    from_char_nm = '系统管理员',
                    post_title = '装备取回成功',
                    body_text = '您已成功取回自己寄售的装备，请在90天内取出',
                    state_tag = 0,
                    ipt_time = GETDATE(),
                    expire_time = DATEADD(day, 90, GETDATE())
                WHERE post_no = ?
            ", [$item['sell_character_no'], $post_no]);
            
            if ($result) {
                echo json_encode(['success' => true, 'message' => '物品已取回到邮箱']);
            } else {
                throw new Exception('取回失败');
            }
        }
        
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
    exit;
}

$page_title = '我的寄售 - 游戏市场';
$breadcrumbs = [
    ['name' => '游戏市场', 'url' => site_url('market/')],
    ['name' => '我的寄售', 'url' => site_url('market/sell.php')]
];

include '../templates/header.php';

$my_sales = getMySales($server_id, $user_no);
$trade_history = getTradeHistory($server_id, $user_no);
?>

<style>
/* 加载动画样式 */
.loading-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.8);
    display: flex;
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

.loading-text {
    font-size: 16px;
    font-weight: 500;
}

@keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
}

/* 按钮加载状态 */
.btn-loading {
    position: relative;
    pointer-events: none;
    opacity: 0.7;
}

.btn-loading::after {
    content: '';
    position: absolute;
    width: 16px;
    height: 16px;
    margin: auto;
    border: 2px solid transparent;
    border-top-color: #ffffff;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    top: 0;
    left: 0;
    bottom: 0;
    right: 0;
}
</style>

<!-- 加载动画遮罩 -->
<div id="loadingOverlay" class="loading-overlay" style="display: none;">
    <div class="loading-content">
        <div class="loading-spinner"></div>
        <div class="loading-text" id="loadingText">加载中...</div>
    </div>
</div>

<div class="my-sales-container">
    <!-- 页面头部 -->
    <div class="page-header">
        <div class="page-title">
            <i class="fas fa-store"></i>
            我的寄售
        </div>
        <div class="page-subtitle">
            查看您寄售的物品和交易记录
        </div>
    </div>
    
    <!-- 操作按钮 -->
    <div class="action-buttons">
        <a href="<?php echo site_url('market/add_sale.php'); ?>" class="btn-custom">
            <i class="fas fa-plus-circle"></i>
            寄售新物品
        </a>
        <a href="<?php echo site_url('market/'); ?>" class="btn-custom">
            <i class="fas fa-shopping-cart"></i>
            浏览市场
        </a>
    </div>
    
    <!-- 标签页 -->
    <ul class="nav nav-tabs" id="myTabs" role="tablist">
        <li class="nav-item" role="presentation">
            <button class="nav-link active" id="sales-tab" data-bs-toggle="tab" data-bs-target="#sales" type="button">
                <i class="fas fa-tag"></i> 我的寄售
            </button>
        </li>
        <li class="nav-item" role="presentation">
            <button class="nav-link" id="history-tab" data-bs-toggle="tab" data-bs-target="#history" type="button">
                <i class="fas fa-history"></i> 交易记录
            </button>
        </li>
    </ul>
    
    <div class="tab-content" id="myTabContent">
        <!-- 我的寄售 -->
        <div class="tab-pane fade show active" id="sales">
            <?php if (empty($my_sales)): ?>
                <div class="empty-state">
                    <i class="fas fa-box-open"></i>
                    <h3>暂无寄售物品</h3>
                    <p>您还没有寄售任何物品</p>
                    <a href="<?php echo site_url('market/add_sale.php'); ?>" class="btn-custom">
                        <i class="fas fa-plus-circle"></i>
                        去寄售物品
                    </a>
                </div>
            <?php else: ?>
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>物品</th>
                                <th>寄售角色</th>
                                <th>价格</th>
                                <th>寄售时间</th>
                                <th>到期时间</th>
                                <th>操作</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($my_sales as $item): ?>
                                <tr>
                                    <td>
                                        <img src="<?php echo getItemIconUrl($item['item_name']); ?>" 
                                             alt="<?php echo htmlspecialchars($item['item_name']); ?>" 
                                             class="item-icon-small">
                                        <?php echo htmlspecialchars($item['item_name']); ?>
                                    </td>
                                    <td><?php echo htmlspecialchars($item['character_name']); ?></td>
                                    <td style="color: #ffc107; font-weight: 600;">
                                        <?php echo number_format($item['include_dil']); ?>
                                    </td>
                                    <td><?php echo date('Y-m-d H:i', strtotime($item['ipt_time'])); ?></td>
                                    <td><?php echo date('Y-m-d H:i', strtotime($item['expire_time'])); ?></td>
                                    <td>
                                        <button class="btn-action" id="cancelBtn-<?php echo $item['post_no']; ?>" 
                                                onclick="cancelSale('<?php echo $item['post_no']; ?>')">
                                            <i class="fas fa-undo"></i> 取回
                                        </button>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            <?php endif; ?>
        </div>
        
        <!-- 交易记录 -->
        <div class="tab-pane fade" id="history">
            <?php if (empty($trade_history)): ?>
                <div class="empty-state">
                    <i class="fas fa-history"></i>
                    <h3>暂无交易记录</h3>
                    <p>您还没有任何交易记录</p>
                </div>
            <?php else: ?>
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>时间</th>
                                <th>物品</th>
                                <th>交易类型</th>
                                <th>交易对象</th>
                                <th>金额</th>
                                <th>状态</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($trade_history as $trade): ?>
                                <tr>
                                    <td><?php echo date('Y-m-d H:i', strtotime($trade['trade_time'])); ?></td>
                                    <td>
                                        <img src="<?php echo getItemIconUrl($trade['item_name']); ?>" 
                                             alt="<?php echo htmlspecialchars($trade['item_name']); ?>" 
                                             class="item-icon-small">
                                        <?php echo htmlspecialchars($trade['item_name']); ?>
                                    </td>
                                    <td>
                                        <?php if ($trade['type'] == 'sell'): ?>
                                            <span class="badge bg-success">出售</span>
                                        <?php else: ?>
                                            <span class="badge bg-info">购买</span>
                                        <?php endif; ?>
                                    </td>
                                    <td>
                                        <?php 
                                        if ($trade['type'] == 'sell') {
                                            echo htmlspecialchars($trade['buyer_name']);
                                        } else {
                                            echo htmlspecialchars($trade['seller_name']);
                                        }
                                        ?>
                                    </td>
                                    <td style="color: #ffc107; font-weight: 600;">
                                        <?php echo number_format($trade['amount']); ?>
                                    </td>
                                    <td>
                                        <?php if ($trade['status_text'] == '已完成'): ?>
                                            <span class="badge bg-success">已完成</span>
                                        <?php else: ?>
                                            <span class="badge bg-warning">处理中</span>
                                        <?php endif; ?>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            <?php endif; ?>
        </div>
    </div>
</div>

<?php include '../templates/footer.php'; ?>

<script>
// 页面加载时显示Loading
document.addEventListener('DOMContentLoaded', function() {
    const overlay = document.getElementById('loadingOverlay');
    if (overlay) {
        overlay.style.display = 'flex';
        // 模拟进度
        simulateProgress();
    }
});

// 模拟进度条
function simulateProgress() {
    let progress = 0;
    const interval = setInterval(() => {
        progress += Math.random() * 15;
        if (progress >= 100) {
            progress = 100;
            clearInterval(interval);
        }
    }, 200);
}

// 页面加载完成后隐藏Loading
window.addEventListener('load', function() {
    setTimeout(() => {
        hideLoading();
    }, 500);
});

// 显示Loading
function showLoading(text = '加载中...') {
    const overlay = document.getElementById('loadingOverlay');
    const loadingText = document.getElementById('loadingText');
    if (overlay) {
        overlay.style.display = 'flex';
        if (loadingText) loadingText.textContent = text;
        simulateProgress();
    }
}

// 隐藏Loading
function hideLoading() {
    setTimeout(() => {
        const overlay = document.getElementById('loadingOverlay');
        if (overlay) {
            overlay.style.opacity = '0';
            overlay.style.transition = 'opacity 0.5s ease';
            setTimeout(() => {
                overlay.style.display = 'none';
                overlay.style.opacity = '1';
            }, 500);
        }
    }, 300);
}

// 取回物品
function cancelSale(postNo) {
    if (!confirm('确定要取回这个物品吗？')) {
        return;
    }
    
    const btn = document.getElementById('cancelBtn-' + postNo);
    const originalText = btn.innerHTML;
    
    // 显示按钮加载状态
    btn.classList.add('btn-loading');
    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> 取回中...';
    btn.disabled = true;
    
    // 显示页面加载
    showLoading('正在取回物品...');
    
    fetch('', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'action=cancel_sale&post_no=' + postNo
    })
    .then(response => {
        console.log('响应状态:', response.status);
        return response.text().then(text => {
            console.log('原始响应:', text);
            try {
                return JSON.parse(text);
            } catch (e) {
                console.error('JSON解析失败:', e);
                throw new Error('服务器响应格式错误: ' + text);
            }
        });
    })
    .then(data => {
        console.log('解析后的数据:', data);
        hideLoading();
        
        if (data.success) {
            // 创建成功提示
            const toast = document.createElement('div');
            toast.style.cssText = `
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
            toast.textContent = '✅ ' + data.message;
            document.body.appendChild(toast);
            
            // 3秒后移除提示
            setTimeout(() => {
                toast.style.animation = 'slideOut 0.3s ease';
                setTimeout(() => {
                    if (toast.parentNode) {
                        toast.parentNode.removeChild(toast);
                    }
                }, 300);
            }, 3000);
            
            // 延迟刷新页面
            setTimeout(() => {
                location.reload();
            }, 1000);
        } else {
            // 恢复按钮状态
            btn.classList.remove('btn-loading');
            btn.innerHTML = originalText;
            btn.disabled = false;
            
            // 创建错误提示
            const toast = document.createElement('div');
            toast.style.cssText = `
                position: fixed;
                top: 80px;
                right: 20px;
                background: #dc3545;
                color: white;
                padding: 12px 20px;
                border-radius: 8px;
                box-shadow: 0 4px 12px rgba(0,0,0,0.3);
                z-index: 9999999;
                animation: slideIn 0.3s ease;
                max-width: 300px;
                font-weight: 500;
            `;
            toast.textContent = '❌ ' + data.message;
            document.body.appendChild(toast);
            
            // 3秒后移除提示
            setTimeout(() => {
                toast.style.animation = 'slideOut 0.3s ease';
                setTimeout(() => {
                    if (toast.parentNode) {
                        toast.parentNode.removeChild(toast);
                    }
                }, 300);
            }, 3000);
        }
    })
    .catch(error => {
        console.error('错误详情:', error);
        hideLoading();
        
        // 恢复按钮状态
        btn.classList.remove('btn-loading');
        btn.innerHTML = originalText;
        btn.disabled = false;
        
        alert('网络错误：' + error.message);
    });
}

// 添加动画样式
if (!document.getElementById('toastAnimations')) {
    const style = document.createElement('style');
    style.id = 'toastAnimations';
    style.textContent = `
        @keyframes slideIn {
            from { transform: translateX(100%); opacity: 0; }
            to { transform: translateX(0); opacity: 1; }
        }
        @keyframes slideOut {
            from { transform: translateX(0); opacity: 1; }
            to { transform: translateX(100%); opacity: 0; }
        }
    `;
    document.head.appendChild(style);
}
</script>
