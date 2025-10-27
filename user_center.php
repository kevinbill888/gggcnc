<?php
require_once 'auth.php';
require_login();

$user = get_logged_user();
$server_id = get_current_server_id();
$vip_info = get_user_vip($user['user_no'], $server_id);

// 获取充值记录
$db_account = get_db($server_id, 'account');
$recharge_history = $db_account->query(
    "SELECT TOP 5 * FROM PayLog WHERE UserID = ? ORDER BY ID DESC", 
    array($user['user_no'])
)->fetchAll(PDO::FETCH_ASSOC);

// 计算VIP等级
$current_vip = 0;
foreach ($GLOBALS['vip_levels'] as $level => $config) {
    if (isset($config['min_amount']) && $vip_info['total_recharge'] >= $config['min_amount']) {
        $current_vip = $level;
    }
}

// 获取服务器信息
$server_info = get_server_info($server_id);

// 获取用户货币余额
$c_coin = 0;
$b_coin = 0;
try {
    $db_cash = get_db($server_id, 'cash');
    $cash_info = $db_cash->query("SELECT * FROM user_cash WHERE user_no = ?", array($user['user_no']))->fetch(PDO::FETCH_ASSOC);
    if ($cash_info) {
        $c_coin = $cash_info['amount'] ?? 0;
        $b_coin = $cash_info['b_amount'] ?? 0;
    }
} catch (Exception $e) {
    // 使用默认值
}

// 获取用户角色
$characters = array();
try {
    $db_character = get_db($server_id, 'character');
    $characters = $db_character->query("SELECT Character_no, Character_name, bypcClass FROM User_Character WHERE user_no = ?", array($user['user_no']))->fetchAll(PDO::FETCH_ASSOC);
} catch (Exception $e) {
    $characters = array();
}

// 设置页面变量
$page_title = '用户中心 - ' . SITE_NAME;
$page_css = 'user_center';
$current_page = 'user_center.php';

// 包含导航模板
require_once 'nav_template.php';
?>

<!-- 用户中心主体内容 -->
<div class="container">
    <!-- 用户信息卡片 -->
    <div class="game-card user-profile-card">
        <div class="user-avatar-section">
            <div class="user-avatar">
                <i class="fas fa-user-circle"></i>
            </div>
            <div class="user-level-badge">
                <i class="<?php echo $GLOBALS['vip_levels'][$current_vip]['icon']; ?>"></i>
                <span><?php echo $GLOBALS['vip_levels'][$current_vip]['name']; ?></span>
            </div>
        </div>
        
        <div class="user-details">
            <h2 class="user-name"><?php echo htmlspecialchars($user['user_id']); ?></h2>
            <div class="user-meta">
                <div class="meta-item">
                    <i class="fas fa-fingerprint"></i>
                    <span>身份号：</span>
                    <span class="highlight"><?php echo htmlspecialchars($user['user_no']); ?></span>
                </div>
                <div class="meta-item">
                    <i class="fas fa-server"></i>
                    <span>服务器：</span>
                    <span class="highlight"><?php echo htmlspecialchars($server_info['name']); ?></span>
                </div>
                <div class="meta-item">
                    <i class="fas fa-calendar-alt"></i>
                    <span>注册时间：</span>
                    <span><?php echo date('Y-m-d', strtotime($user['reg_time'])); ?></span>
                </div>
                <div class="meta-item">
                    <i class="fas fa-clock"></i>
                    <span>最后登录：</span>
                    <span><?php echo $user['login_time'] ? date('Y-m-d H:i', strtotime($user['login_time'])) : '从未登录'; ?></span>
                </div>
            </div>
        </div>
        
        <div class="user-actions">
            <a href="pay/" class="btn-game btn-primary">
                <i class="fas fa-coins"></i>
                <span>立即充值</span>
            </a>
            <a href="change_password.php" class="btn-game btn-secondary">
                <i class="fas fa-key"></i>
                <span>修改密码</span>
            </a>
        </div>
    </div>

    <!-- 货币余额和角色选择卡片 -->
    <div class="game-card balance-card">
        <h3 class="card-title">
            <i class="fas fa-wallet"></i>
            <span>账户信息</span>
        </h3>
        <div class="balance-grid">
            <div class="balance-item c-coin">
                <div class="balance-icon">
                    <i class="fas fa-coins"></i>
                </div>
                <div class="balance-info">
                    <h4>C币（游戏币）</h4>
                    <p class="balance-amount"><?php echo number_format($c_coin); ?></p>
                </div>
            </div>
            <div class="balance-item b-coin">
                <div class="balance-icon">
                    <i class="fas fa-gem"></i>
                </div>
                <div class="balance-info">
                    <h4>B币（商城币）</h4>
                    <p class="balance-amount"><?php echo number_format($b_coin); ?></p>
                </div>
            </div>
            <div class="balance-item character-select">
                <div class="balance-icon">
                    <i class="fas fa-user-ninja"></i>
                </div>
                <div class="balance-info">
                    <h4>当前角色</h4>
                    <div class="character-dropdown">
                        <?php if ($characters): ?>
                            <select id="characterSelect" class="game-select">
                                <?php foreach ($characters as $char): ?>
                                    <option value="<?php echo $char['Character_no']; ?>">
                                        <?php echo htmlspecialchars($char['Character_name']); ?> (<?php echo htmlspecialchars($char['bypcClass']); ?>)
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        <?php else: ?>
                            <select id="characterSelect" class="game-select" disabled>
                                <option>暂无角色</option>
                            </select>
                        <?php endif; ?>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- VIP进度卡片 -->
    <div class="game-card vip-progress-card">
        <h3 class="card-title">
            <i class="fas fa-crown"></i>
            <span>VIP等级进度</span>
        </h3>
        <div class="vip-progress-container">
            <div class="current-vip-info">
                <div class="current-vip-level">
                    <i class="<?php echo $GLOBALS['vip_levels'][$current_vip]['icon']; ?>"></i>
                    <span><?php echo $GLOBALS['vip_levels'][$current_vip]['name']; ?></span>
                </div>
                <div class="vip-stats">
                    <div class="stat">
                        <span class="label">累计充值</span>
                        <span class="value">￥<?php echo number_format($vip_info['total_recharge'], 2); ?></span>
                    </div>
                    <?php 
                    if ($current_vip < 6 && isset($GLOBALS['vip_levels'][$current_vip + 1]['min_amount'])): 
                    ?>
                        <div class="stat">
                            <span class="label">距离下一等级</span>
                            <span class="value highlight">￥<?php echo number_format($GLOBALS['vip_levels'][$current_vip + 1]['min_amount'] - $vip_info['total_recharge'], 2); ?></span>
                        </div>
                    <?php endif; ?>
                </div>
            </div>
            
            <div class="vip-levels">
                <?php foreach ($GLOBALS['vip_levels'] as $level => $config): ?>
                    <?php if ($level > 0): ?>
                        <div class="vip-level-item <?php echo $current_vip >= $level ? 'active' : ''; ?>">
                            <div class="level-icon">
                                <i class="<?php echo $config['icon']; ?>"></i>
                            </div>
                            <div class="level-info">
                                <span class="level-name"><?php echo $config['name']; ?></span>
                                <span class="level-amount">￥<?php echo $config['min_amount']; ?></span>
                            </div>
                        </div>
                    <?php endif; ?>
                <?php endforeach; ?>
            </div>
        </div>
    </div>

    <!-- 最近充值记录卡片 -->
    <div class="game-card recharge-history-card">
        <h3 class="card-title">
            <i class="fas fa-history"></i>
            <span>最近充值记录</span>
        </h3>
        <?php if ($recharge_history): ?>
            <div class="table-responsive">
                <table class="game-table">
                    <thead>
                        <tr>
                            <th>订单号</th>
                            <th>充值金额</th>
                            <th>到账数量</th>
                            <th>状态</th>
                            <th>时间</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($recharge_history as $record): ?>
                            <tr>
                                <td><?php echo htmlspecialchars($record['PayNo']); ?></td>
                                <td>￥<?php echo number_format($record['Amount'], 2); ?></td>
                                <td><?php echo number_format($record['GameCash']); ?></td>
                                <td>
                                    <?php if ($record['trade_status'] == 1): ?>
                                        <span class="status-badge success">成功</span>
                                    <?php elseif ($record['trade_status'] == 0): ?>
                                        <span class="status-badge pending">待支付</span>
                                    <?php else: ?>
                                        <span class="status-badge failed">失败</span>
                                    <?php endif; ?>
                                </td>
                                <td><?php echo date('Y-m-d H:i', strtotime($record['PayTime'])); ?></td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
            <div class="card-footer">
                <a href="pay/" class="btn-game btn-outline">
                    <i class="fas fa-list"></i>
                    <span>查看全部</span>
                </a>
            </div>
        <?php else: ?>
            <div class="empty-state">
                <i class="fas fa-receipt"></i>
                <p>暂无充值记录</p>
                <a href="pay/" class="btn-game btn-small">立即充值</a>
            </div>
        <?php endif; ?>
    </div>
</div>

<style>
/* 用户中心特定样式 */
.user-profile-card {
    display: grid;
    grid-template-columns: auto 1fr auto;
    gap: 40px;
    align-items: center;
    padding: 40px;
    margin-bottom: 30px;
}

.user-avatar-section {
    position: relative;
}

.user-avatar {
    width: 120px;
    height: 120px;
    background: linear-gradient(45deg, var(--primary-color), var(--secondary-color));
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 60px;
    color: white;
    animation: pulse 2s infinite;
    box-shadow: 0 0 30px rgba(0,255,255,0.5);
}

.user-level-badge {
    position: absolute;
    bottom: -10px;
    right: -10px;
    background: linear-gradient(45deg, var(--accent-color), var(--secondary-color));
    border-radius: 20px;
    padding: 8px 16px;
    display: flex;
    align-items: center;
    gap: 8px;
    font-weight: bold;
    font-size: 14px;
    box-shadow: 0 0 20px rgba(255,215,0,0.5);
}

.user-details h2.user-name {
    font-size: 36px;
    margin-bottom: 20px;
    background: linear-gradient(45deg, var(--primary-color), var(--secondary-color));
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    text-transform: uppercase;
    letter-spacing: 2px;
}

.user-meta {
    display: grid;
    gap: 12px;
}

.meta-item {
    display: flex;
    align-items: center;
    gap: 10px;
    color: var(--text-secondary);
}

.meta-item i {
    color: var(--primary-color);
    width: 20px;
}

.meta-item .highlight {
    color: var(--primary-color);
    font-weight: bold;
    text-shadow: 0 0 10px rgba(0,255,255,0.5);
}

.user-actions {
    display: flex;
    flex-direction: column;
    gap: 15px;
}

/* 货币余额和角色选择卡片 */
.balance-card {
    margin-bottom: 30px;
}

.balance-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 30px;
    margin-top: 20px;
}

.balance-item {
    display: flex;
    align-items: center;
    gap: 20px;
    padding: 25px;
    background: rgba(22,33,62,0.5);
    border: 1px solid var(--border-color);
    border-radius: 15px;
    transition: all 0.3s ease;
}

.balance-item:hover {
    transform: translateY(-5px);
    box-shadow: 0 0 20px rgba(0,255,255,0.3);
}

.balance-item.c-coin {
    border-color: rgba(255,215,0,0.3);
}

.balance-item.c-coin:hover {
    box-shadow: 0 0 20px rgba(255,215,0,0.3);
}

.balance-item.b-coin {
    border-color: rgba(255,105,180,0.3);
}

.balance-item.b-coin:hover {
    box-shadow: 0 0 20px rgba(255,105,180,0.3);
}

.balance-item.character-select {
    border-color: rgba(0,255,255,0.3);
}

.balance-item.character-select:hover {
    box-shadow: 0 0 20px rgba(0,255,255,0.3);
}

.balance-icon {
    width: 60px;
    height: 60px;
    background: linear-gradient(45deg, var(--primary-color), var(--secondary-color));
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 24px;
    color: white;
}

.balance-item.c-coin .balance-icon {
    background: linear-gradient(45deg, #ffd700, #ffed4e);
}

.balance-item.b-coin .balance-icon {
    background: linear-gradient(45deg, #ff69b4, #ff1493);
}

.balance-item.character-select .balance-icon {
    background: linear-gradient(45deg, #00ffff, #0099cc);
}

.balance-info h4 {
    font-size: 18px;
    margin-bottom: 5px;
    color: var(--text-secondary);
}

.balance-amount {
    font-size: 28px;
    font-weight: bold;
    color: var(--primary-color);
}

.character-dropdown {
    margin-top: 5px;
}

.game-select {
    width: 100%;
    padding: 10px 15px;
    background: rgba(22,33,62,0.8);
    border: 1px solid var(--border-color);
    border-radius: 8px;
    color: var(--text-primary);
    font-size: 16px;
    cursor: pointer;
    transition: all 0.3s ease;
}

.game-select:focus {
    outline: none;
    border-color: var(--primary-color);
    box-shadow: 0 0 10px rgba(0,255,255,0.5);
}

.game-select option {
    background: #1a1a2e;
    color: var(--text-primary);
}

/* VIP进度卡片 */
.vip-progress-card {
    margin-bottom: 30px;
}

.vip-progress-container {
    margin-top: 20px;
}

.current-vip-info {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 30px;
    padding: 20px;
    background: rgba(22,33,62,0.5);
    border-radius: 15px;
}

.current-vip-level {
    display: flex;
    align-items: center;
    gap: 15px;
    font-size: 24px;
    font-weight: bold;
    color: var(--primary-color);
}

.current-vip-level i {
    font-size: 32px;
}

.vip-stats {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 20px;
}

.stat {
    text-align: right;
}

.stat .label {
    display: block;
    color: var(--text-secondary);
    margin-bottom: 5px;
}

.stat .value {
    font-size: 20px;
    font-weight: bold;
    color: var(--text-primary);
}

.stat .value.highlight {
    color: var(--accent-color);
    text-shadow: 0 0 10px rgba(255,215,0,0.5);
}

.vip-levels {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 15px;
}

.vip-level-item {
    display: flex;
    align-items: center;
    gap: 15px;
    padding: 15px;
    background: rgba(22,33,62,0.3);
    border: 1px solid rgba(255,255,255,0.1);
    border-radius: 10px;
    transition: all 0.3s ease;
}

.vip-level-item.active {
    background: rgba(0,255,255,0.1);
    border-color: var(--primary-color);
    box-shadow: 0 0 15px rgba(0,255,255,0.3);
}

.level-icon {
    width: 40px;
    height: 40px;
    background: rgba(22,33,62,0.5);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 18px;
    color: var(--text-secondary);
}

.vip-level-item.active .level-icon {
    background: var(--primary-color);
    color: white;
}

.level-info {
    display: flex;
    flex-direction: column;
    gap: 5px;
}

.level-name {
    font-weight: bold;
    color: var(--text-primary);
}

.level-amount {
    font-size: 14px;
    color: var(--text-secondary);
}

/* 充值记录卡片 */
.recharge-history-card {
    margin-bottom: 30px;
}

.table-responsive {
    margin-top: 20px;
    overflow-x: auto;
}

.status-badge {
    display: inline-block;
    padding: 5px 12px;
    border-radius: 20px;
    font-size: 12px;
    font-weight: bold;
    text-transform: uppercase;
}

.status-badge.success {
    background: rgba(76,175,80,0.2);
    color: #4caf50;
    border: 1px solid rgba(76,175,80,0.5);
}

.status-badge.pending {
    background: rgba(255,152,0,0.2);
    color: #ff9800;
    border: 1px solid rgba(255,152,0,0.5);
}

.status-badge.failed {
    background: rgba(244,67,54,0.2);
    color: #f44336;
    border: 1px solid rgba(244,67,54,0.5);
}

.card-footer {
    margin-top: 20px;
    text-align: center;
}

.empty-state {
    text-align: center;
    padding: 40px;
    color: var(--text-secondary);
}

.empty-state i {
    font-size: 48px;
    margin-bottom: 15px;
    display: block;
    color: var(--text-secondary);
}

/* 按钮变体 */
.btn-game.btn-small {
    padding: 8px 20px;
    font-size: 14px;
}

.btn-game.btn-outline {
    background: transparent;
    border: 2px solid var(--primary-color);
    color: var(--primary-color);
}

.btn-game.btn-outline:hover {
    background: var(--primary-color);
    color: var(--bg-dark);
}

/* 响应式设计 */
@media (max-width: 768px) {
    .user-profile-card {
        grid-template-columns: 1fr;
        text-align: center;
        gap: 30px;
    }
    
    .user-actions {
        flex-direction: row;
        justify-content: center;
    }
    
    .current-vip-info {
        flex-direction: column;
        gap: 20px;
        text-align: center;
    }
    
    .vip-stats {
        grid-template-columns: 1fr;
        text-align: center;
    }
    
    .balance-grid {
        grid-template-columns: 1fr;
    }
}
</style>

<?php
// 包含页脚模板
require_once 'footer_template.php';
?>
