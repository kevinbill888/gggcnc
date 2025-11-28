<?php
// 使用根目录的配置
require_once '../config.php';
require_once '../db.php';

// 检查用户是否登录
session_start();
if (!isset($_SESSION['user_no'])) {
    header('Location: ../login.php');
    exit;
}

$user_no = $_SESSION['user_no'];
$server_id = $_SESSION['server_id'];

// 获取数据库连接
$db_account = get_db($server_id, 'account');
$db_cash = get_db($server_id, 'cash');
$db_character = get_db($server_id, 'character');

// 从 account 数据库获取用户信息
$user = $db_account->query("SELECT * FROM USER_PROFILE WHERE user_no = ?", array($user_no))->fetch(PDO::FETCH_ASSOC);

// 从 account 数据库获取用户VIP信息
$vip_info = $db_account->query("SELECT * FROM User_VIP WHERE user_no = ?", array($user_no))->fetch(PDO::FETCH_ASSOC);
if (!$vip_info) {
    $vip_info = array('vip_level' => 0, 'total_recharge' => 0);
}

// 从 account 数据库获取充值记录（只显示已支付和失败的订单）
$recharge_history = $db_account->query("SELECT TOP 10 * FROM PayLog WHERE UserID = ? AND trade_status != 0 ORDER BY ID DESC", array($user_no))->fetchAll(PDO::FETCH_ASSOC);

// 获取用户货币余额 - 使用正确的表结构
$c_coin = 0;
$b_coin = 0;
try {
    // 从user_cash表获取
    $cash_info = $db_cash->query("SELECT * FROM user_cash WHERE user_no = ?", array($user_no))->fetch(PDO::FETCH_ASSOC);
    if ($cash_info) {
        $c_coin = $cash_info['amount'] ?? 0;
        $b_coin = $cash_info['b_amount'] ?? 0;
    }
} catch (Exception $e) {
    // 如果表不存在，尝试从角色表获取
    try {
        $character = $db_character->query("SELECT TOP 1 * FROM User_Character WHERE user_no = ?", array($user_no))->fetch(PDO::FETCH_ASSOC);
        if ($character) {
            $c_coin = $character['dwmoney'] ?? 0; // 游戏币
            $b_coin = $character['B_Coin'] ?? 0; // 商城币
        }
    } catch (Exception $e2) {
        // 都不存在则使用默认值
    }
}

// 从 character 数据库获取用户角色
$characters = array();
try {
    $characters = $db_character->query("SELECT Character_no, Character_name, bypcClass FROM User_Character WHERE user_no = ?", array($user_no))->fetchAll(PDO::FETCH_ASSOC);
} catch (Exception $e) {
    // 如果表不存在，使用空数组
}

// 计算当前VIP等级（修复 min_amount 警告）
$current_vip = 0;
foreach ($GLOBALS['vip_levels'] as $level => $config) {
    // 检查 min_amount 是否存在
    if (isset($config['min_amount']) && $vip_info['total_recharge'] >= $config['min_amount']) {
        $current_vip = $level;
    }
}

// 处理支付结果消息（修复未定义变量警告）
$success_msg = '';
$error_msg = '';
if (isset($_GET['success'])) {
    $success_msg = '支付成功！货币已实时到账！';
    if (isset($_GET['trade_no'])) {
        $success_msg .= ' 交易号：' . htmlspecialchars($_GET['trade_no']);
    }
    if (isset($_GET['out_trade_no'])) {
        $success_msg .= ' 订单号：' . htmlspecialchars($_GET['out_trade_no']);
    }
}
if (isset($_GET['error'])) {
    switch($_GET['error']) {
        case 'no_params':
            $error_msg = '没有收到支付参数';
            break;
        case 'sign':
            $error_msg = '签名验证失败';
            break;
        case 'pay_failed':
            $error_msg = '支付失败';
            break;
        default:
            $error_msg = '支付过程中出现错误';
    }
}
?>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>充值中心 - <?php echo SITE_NAME; ?></title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="css/style.css">
    <style>
        /* 调整容器宽度，与用户中心保持一致 */
        .container {
            max-width: 1200px;
            margin: 20px auto;
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        /* 重新设计header区域 */
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
            position: relative;
            overflow: hidden;
        }
        
        .header::before {
            content: '';
            position: absolute;
            top: -50%;
            right: -50%;
            width: 200%;
            height: 200%;
            background: radial-gradient(circle, rgba(255,255,255,0.1) 0%, transparent 70%);
            animation: rotate 30s linear infinite;
        }
        
        @keyframes rotate {
            from { transform: rotate(0deg); }
            to { transform: rotate(360deg); }
        }
        
        .header-content {
            position: relative;
            z-index: 1;
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            flex-wrap: wrap;
            gap: 20px;
        }
        
        .header-left {
            flex: 1;
        }
        
        .header h1 {
            margin: 0 0 20px 0;
            font-size: 28px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .user-info-compact {
            display: flex;
            flex-direction: column;
            gap: 15px;
        }
        
        .user-account-row {
            display: flex;
            align-items: center;
            gap: 15px;
            flex-wrap: wrap;
        }
        
        .user-account-label {
            font-size: 16px;
            opacity: 0.9;
        }
        
        .user-account-value {
            font-size: 18px;
            font-weight: bold;
        }
        
        /* VIP徽章改小 */
        .vip-badge-inline {
            display: flex;
            align-items: center;
            gap: 5px;
            background: rgba(255,215,0,0.2);
            border: 1px solid rgba(255,215,0,0.5);
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 12px;
            animation: pulse 2s infinite;
        }
        
        @keyframes pulse {
            0% { transform: scale(1); }
            50% { transform: scale(1.05); }
            100% { transform: scale(1); }
        }
        
        /* 底部一行显示所有信息 */
        .bottom-info-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-top: 10px;
            gap: 20px;
        }
        
        .balance-section {
            display: flex;
            gap: 15px;
            align-items: center;
        }
        
        .coin-display {
            position: relative;
            background: rgba(255,255,255,0.15);
            border: 2px solid rgba(255,255,255,0.3);
            border-radius: 25px;
            padding: 8px 15px;
            display: flex;
            align-items: center;
            gap: 8px;
            transition: all 0.3s ease;
            animation: glow 2s ease-in-out infinite alternate;
        }
        
        @keyframes glow {
            from {
                box-shadow: 0 0 5px rgba(255,255,255,0.5), 0 0 10px rgba(255,255,255,0.3);
            }
            to {
                box-shadow: 0 0 10px rgba(255,255,255,0.8), 0 0 20px rgba(255,255,255,0.5);
            }
        }
        
        .coin-display:hover {
            transform: scale(1.05);
            background: rgba(255,255,255,0.25);
        }
        
        .coin-display.c-coin {
            background: linear-gradient(135deg, rgba(255,215,0,0.3), rgba(255,215,0,0.1));
            border-color: rgba(255,215,0,0.5);
        }
        
        .coin-display.b-coin {
            background: linear-gradient(135deg, rgba(255,105,180,0.3), rgba(255,105,180,0.1));
            border-color: rgba(255,105,180,0.5);
        }
        
        .coin-label {
            font-size: 12px;
            opacity: 0.9;
        }
        
        .coin-icon {
            font-size: 18px;
        }
        
        .coin-value {
            font-size: 16px;
            font-weight: bold;
            min-width: 60px;
            text-align: right;
        }
        
        .right-section {
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .character-select-bottom {
            display: flex;
            align-items: center;
            gap: 5px;
            white-space: nowrap;
        }
        
        .character-select-bottom label {
            font-size: 14px;
            opacity: 0.9;
            white-space: nowrap;
        }
        
        .character-select-bottom select {
            padding: 5px 10px;
            border-radius: 5px;
            border: none;
            background: rgba(255,255,255,0.2);
            color: white;
            font-size: 14px;
            cursor: pointer;
            min-width: 150px;
        }
        
        .character-select-bottom select option {
            background: #764ba2;
            color: white;
        }
        
        .logout-small {
            color: white;
            text-decoration: none;
            padding: 5px 10px;
            border-radius: 5px;
            background: rgba(220,53,69,0.8);
            transition: all 0.3s;
            font-size: 12px;
            display: flex;
            align-items: center;
            gap: 3px;
            white-space: nowrap;
        }
        
        .logout-small:hover {
            background: rgba(220,53,69,1);
        }
        
        .header-right {
            display: flex;
            flex-direction: column;
            align-items: flex-end;
            gap: 15px;
        }
        
        .header-top-actions a {
            color: white;
            text-decoration: none;
            padding: 8px 15px;
            border-radius: 5px;
            transition: all 0.3s;
            font-size: 14px;
            display: flex;
            align-items: center;
            gap: 5px;
            background: rgba(255,255,255,0.2);
        }
        
        .header-top-actions a:hover {
            background: rgba(255,255,255,0.3);
        }
        
        /* 充值表单区域 - 整体靠右 */
        .recharge-form {
            display: flex;
            flex-direction: column;
            align-items: flex-end;
        }
        
        .recharge-form > h2 {
            align-self: flex-start;
            width: 100%;
        }
        
        .recharge-form-inner {
            width: 100%;
            max-width: 800px;
        }
        
        /* 调整充值金额显示区域 - 整个容器30% */
        .submit-section {
            display: flex;
            justify-content: flex-end;
            align-items: flex-start;
            gap: 20px;
            width: 100%;
        }
        
        .order-summary {
            flex: 0 0 30%;
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            border: 1px solid #e9ecef;
        }
        
        .order-summary p {
            margin: 10px 0;
            display: flex;
            justify-content: space-between;
            font-size: 16px;
        }
        
        .order-summary span {
            font-weight: bold;
            color: #333;
        }
        
        .submit-button-container {
            flex: 0 0 30%;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        /* 美化弹窗样式 */
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0,0,0,0.5);
            animation: fadeIn 0.3s;
        }
        
        .modal-content {
            background-color: #fefefe;
            margin: 10% auto;
            padding: 0;
            border-radius: 10px;
            width: 90%;
            max-width: 500px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.3);
            animation: slideIn 0.3s;
            overflow: hidden;
        }
        
        .modal-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            text-align: center;
        }
        
        .modal-header h2 {
            margin: 0;
            font-size: 24px;
        }
        
        .modal-body {
            padding: 30px;
            text-align: center;
        }
        
        .modal-icon {
            font-size: 64px;
            color: #4caf50;
            margin-bottom: 20px;
        }
        
        .modal-message {
            font-size: 18px;
            color: #333;
            margin-bottom: 10px;
        }
        
        .modal-detail {
            font-size: 14px;
            color: #666;
            margin-bottom: 20px;
        }
        
        .modal-footer {
            padding: 20px;
            background: #f5f5f5;
            text-align: center;
        }
        
        .modal-btn {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 12px 30px;
            font-size: 16px;
            border-radius: 25px;
            cursor: pointer;
            transition: transform 0.2s;
        }
        
        .modal-btn:hover {
            transform: scale(1.05);
        }
        
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        @keyframes slideIn {
            from {
                transform: translateY(-50px);
                opacity: 0;
            }
            to {
                transform: translateY(0);
                opacity: 1;
            }
        }
        
        /* 调整充值按钮样式 */
        .btn-recharge {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 15px 60px;
            font-size: 20px;
            border-radius: 30px;
            cursor: pointer;
            transition: all 0.3s;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
            width: 100%;
        }
        
        .btn-recharge:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(102, 126, 234, 0.5);
        }
        
        /* 响应式调整 */
        @media (max-width: 768px) {
            .container {
                margin: 10px;
                padding: 15px;
            }
            
            .header {
                padding: 20px;
            }
            
            .header-content {
                flex-direction: column;
            }
            
            .header-left, .header-right {
                width: 100%;
            }
            
            .bottom-info-row {
                flex-direction: column;
                gap: 15px;
                align-items: stretch;
            }
            
            .balance-section, .right-section {
                justify-content: center;
            }
            
            .recharge-form {
                align-items: stretch;
            }
            
            .recharge-form-inner {
                max-width: 100%;
            }
            
            .submit-section {
                flex-direction: column;
            }
            
            .order-summary, .submit-button-container {
                flex: 1;
                width: 100%;
            }
            
            .modal-content {
                width: 95%;
                margin: 5% auto;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <header class="header">
            <div class="header-content">
                <div class="header-left">
                    <h1><i class="fas fa-coins"></i> 充值中心</h1>
                    <div class="user-info-compact">
                        <div class="user-account-row">
                            <span class="user-account-label">账号：</span>
                            <span class="user-account-value"><?php echo htmlspecialchars($user['user_id']); ?></span>
                            <div class="vip-badge-inline">
                                <i class="<?php echo $GLOBALS['vip_levels'][$current_vip]['icon']; ?>"></i>
                                <span><?php echo $GLOBALS['vip_levels'][$current_vip]['name']; ?></span>
                            </div>
                        </div>
                        
                        <div class="bottom-info-row">
                            <div class="balance-section">
                                <div class="coin-display c-coin">
                                    <span class="coin-label">C币</span>
                                    <i class="fas fa-coins coin-icon"></i>
                                    <span class="coin-value"><?php echo number_format($c_coin); ?></span>
                                </div>
                                <div class="coin-display b-coin">
                                    <span class="coin-label">B币</span>
                                    <i class="fas fa-gem coin-icon"></i>
                                    <span class="coin-value"><?php echo number_format($b_coin); ?></span>
                                </div>
                            </div>
                            
                            <div class="right-section">
                                <div class="character-select-bottom">
                                    <label>当前角色：</label>
                                    <?php if ($characters): ?>
                                        <select id="characterSelect">
                                            <?php foreach ($characters as $char): ?>
                                                <option value="<?php echo $char['Character_no']; ?>">
                                                    <?php echo htmlspecialchars($char['Character_name']); ?> (<?php echo htmlspecialchars($char['bypcClass']); ?>)
                                                </option>
                                            <?php endforeach; ?>
                                        </select>
                                    <?php else: ?>
                                        <select disabled>
                                            <option>暂无角色</option>
                                        </select>
                                    <?php endif; ?>
                                </div>
                                <a href="logout.php" class="logout-small">
                                    <i class="fas fa-sign-out-alt"></i> 退出
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="header-right">
                    <div class="header-top-actions">
                        <a href="../user_center.php">
                            <i class="fas fa-home"></i> 用户中心
                        </a>
                    </div>
                </div>
            </div>
        </header>

        <main class="main">
            <!-- 显示消息 -->
            <?php if ($success_msg): ?>
                <div class="alert alert-success">
                    <i class="fas fa-check-circle"></i>
                    <?php echo $success_msg; ?>
                </div>
            <?php endif; ?>
            
            <?php if ($error_msg): ?>
                <div class="alert alert-error">
                    <i class="fas fa-exclamation-circle"></i>
                    <?php echo $error_msg; ?>
                </div>
            <?php endif; ?>

            <!-- VIP进度条 -->
            <section class="vip-progress">
                <h2>您的VIP等级</h2>
                <div class="progress-bar">
                    <?php foreach ($GLOBALS['vip_levels'] as $level => $config): ?>
                        <?php if ($level > 0): ?>
                            <div class="progress-item <?php echo $current_vip >= $level ? 'active' : ''; ?>">
                                <div class="progress-icon">
                                    <i class="<?php echo $config['icon']; ?>"></i>
                                </div>
                                <div class="progress-info">
                                    <span class="level-name"><?php echo $config['name']; ?></span>
                                    <span class="level-amount">￥<?php echo $config['min_amount'] ?? 0; ?></span>
                                </div>
                            </div>
                        <?php endif; ?>
                    <?php endforeach; ?>
                </div>
                <div class="current-status">
                    <p>当前累计充值：<strong>￥<?php echo number_format($vip_info['total_recharge'], 2); ?></strong></p>
                    <?php 
                    // 修复：检查是否有下一等级
                    if ($current_vip < 6 && isset($GLOBALS['vip_levels'][$current_vip + 1]['min_amount'])): 
                    ?>
                        <p>距离下一等级还需：<strong>￥<?php echo number_format($GLOBALS['vip_levels'][$current_vip + 1]['min_amount'] - $vip_info['total_recharge'], 2); ?></strong></p>
                    <?php endif; ?>
                </div>
            </section>

            <!-- 充值表单 -->
            <section class="recharge-form">
                <h2>快速充值</h2>
                <div class="recharge-form-inner">
                    <form id="rechargeForm" action="create_order.php" method="post">
                        <!-- 货币类型选择 -->
                        <div class="currency-type">
                            <h3>选择充值类型</h3>
                            <div class="currency-options">
                                <div class="currency-option c-coin active" data-type="c_coin">
                                    <div class="icon"><i class="fas fa-coins"></i></div>
                                    <div class="name">C币</div>
                                    <div class="ratio">1元 = <?php echo $GLOBALS['currency_config']['c_coin']['ratio']; ?>C币</div>
                                    <div class="description"><?php echo $GLOBALS['currency_config']['c_coin']['description']; ?></div>
                                </div>
                                <div class="currency-option b-coin" data-type="b_coin">
                                    <div class="icon"><i class="fas fa-gem"></i></div>
                                    <div class="name">B币</div>
                                    <div class="ratio">1元 = <?php echo $GLOBALS['currency_config']['b_coin']['ratio']; ?>B币</div>
                                    <div class="description"><?php echo $GLOBALS['currency_config']['b_coin']['description']; ?></div>
                                </div>
                            </div>
                            <input type="hidden" id="currencyType" name="currency_type" value="c_coin">
                        </div>

                        <div class="amount-options">
                            <h3>选择充值金额</h3>
                            <div class="amount-grid">
                                <?php 
                                $amounts = array(0.01, 10, 50, 100, 200, 500, 1000, 2000, 5000);
                                foreach ($amounts as $amount): 
                                ?>
                                    <button type="button" class="amount-btn" data-amount="<?php echo $amount; ?>">
                                        ￥<?php echo $amount; ?>
                                        <?php 
                                        $bonus = 0;
                                        foreach ($GLOBALS['recharge_bonuses'] as $b) {
                                            if ($amount >= $b['min_amount']) {
                                                $bonus = ($amount * $b['bonus_rate']) - $amount;
                                            }
                                        }
                                        if ($bonus > 0): ?>
                                            <span class="bonus">+￥<?php echo number_format($bonus, 2); ?></span>
                                        <?php endif; ?>
                                    </button>
                                <?php endforeach; ?>
                            </div>
                            <div class="custom-amount">
                                <label>自定义金额：</label>
                                <input type="number" id="customAmount" name="amount" min="<?php echo MIN_AMOUNT; ?>" max="<?php echo MAX_AMOUNT; ?>" step="0.01" placeholder="输入充值金额">
                                <span class="unit">元</span>
                            </div>
                        </div>

                        <div class="payment-method">
                            <h3>支付方式</h3>
                            <div class="payment-options">
                                <label class="payment-option active">
                                    <input type="radio" name="payment" value="alipay" checked>
                                    <i class="fab fa-alipay"></i>
                                    <span>支付宝</span>
                                </label>
                            </div>
                        </div>

                        <div class="submit-section">
                            <div class="order-summary">
                                <p>充值金额：<span id="displayAmount">￥0.00</span></p>
                                <p>赠送金额：<span id="displayBonus">￥0.00</span></p>
                                <p>到账<span id="currencyName">C币</span>：<span id="displayTotal">0</span></p>
                            </div>
                            <div class="submit-button-container">
                                <button type="submit" class="btn-recharge">
                                    <i class="fas fa-credit-card"></i> 立即充值
                                </button>
                            </div>
                        </div>
                    </form>
                </div>
            </section>

            <!-- 充值记录 -->
            <section class="recharge-history">
                <h2>充值记录</h2>
                <div class="history-table">
                    <table>
                        <thead>
                            <tr>
                                <th>订单号</th>
                                <th>充值类型</th>
                                <th>充值金额</th>
                                <th>到账数量</th>
                                <th>支付方式</th>
                                <th>状态</th>
                                <th>时间</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($recharge_history as $record): ?>
                                <tr>
                                    <td><?php echo htmlspecialchars($record['PayNo']); ?></td>
                                    <td>
                                        <?php 
                                        // 从currency_type字段获取，如果没有则从Remark解析
                                        $currency_type = $record['currency_type'] ?? 'c_coin';
                                        if ($currency_type == 'b_coin' || (isset($record['Remark']) && strpos($record['Remark'], 'B币') !== false)) {
                                            echo 'B币';
                                        } else {
                                            echo 'C币';
                                        }
                                        ?>
                                    </td>
                                    <td>￥<?php echo number_format($record['Amount'], 2); ?></td>
                                    <td><?php echo number_format($record['GameCash']); ?></td>
                                    <td><i class="fab fa-alipay"></i> 支付宝</td>
                                    <td>
                                        <?php if ($record['trade_status'] == 1): ?>
                                            <span class="status success">成功</span>
                                        <?php else: ?>
                                            <span class="status failed">失败</span>
                                        <?php endif; ?>
                                    </td>
                                    <td><?php echo date('Y-m-d H:i:s', strtotime($record['PayTime'])); ?></td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </section>
        </main>
    </div>

    <!-- 成功提示弹窗 -->
    <div id="successModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <h2><i class="fas fa-check-circle"></i> 充值成功</h2>
            </div>
            <div class="modal-body">
                <div class="modal-icon">
                    <i class="fas fa-check-circle"></i>
                </div>
                <div class="modal-message">恭喜您，充值成功！</div>
                <div class="modal-detail">货币已实时到账，请查看您的余额</div>
                <div class="modal-detail" id="orderInfo"></div>
            </div>
            <div class="modal-footer">
                <button class="modal-btn" onclick="closeModal()">确定</button>
            </div>
        </div>
    </div>

    <script>
        // 货币类型选择
        document.querySelectorAll('.currency-option').forEach(option => {
            option.addEventListener('click', function() {
                document.querySelectorAll('.currency-option').forEach(o => o.classList.remove('active'));
                this.classList.add('active');
                document.getElementById('currencyType').value = this.dataset.type;
                
                // 更新显示的货币名称
                const currencyName = this.querySelector('.name').textContent;
                document.getElementById('currencyName').textContent = currencyName;
                
                // 更新到账数量
                updateSummary();
            });
        });

        // 金额选择
        document.querySelectorAll('.amount-btn').forEach(btn => {
            btn.addEventListener('click', function() {
                document.querySelectorAll('.amount-btn').forEach(b => b.classList.remove('active'));
                this.classList.add('active');
                document.getElementById('customAmount').value = this.dataset.amount;
                updateSummary();
            });
        });

        // 自定义金额输入
        document.getElementById('customAmount').addEventListener('input', updateSummary);

        function updateSummary() {
            const amount = parseFloat(document.getElementById('customAmount').value) || 0;
            const currencyType = document.getElementById('currencyType').value;
            
            // 获取汇率
            const ratios = {
                'c_coin': <?php echo $GLOBALS['currency_config']['c_coin']['ratio']; ?>,
                'b_coin': <?php echo $GLOBALS['currency_config']['b_coin']['ratio']; ?>
            };
            
            // 计算赠送金额
            let bonus = 0;
            <?php foreach ($GLOBALS['recharge_bonuses'] as $b): ?>
                if (amount >= <?php echo $b['min_amount']; ?>) {
                    bonus = amount * <?php echo $b['bonus_rate']; ?> - amount;
                }
            <?php endforeach; ?>
            
            const totalAmount = amount + bonus;
            const totalCoins = Math.floor(totalAmount * ratios[currencyType]);
            
            document.getElementById('displayAmount').textContent = '￥' + amount.toFixed(2);
            document.getElementById('displayBonus').textContent = '￥' + bonus.toFixed(2);
            document.getElementById('displayTotal').textContent = totalCoins.toLocaleString();
        }

        // 表单提交 - 直接跳转（不再弹窗）
        document.getElementById('rechargeForm').addEventListener('submit', function(e) {
            const amount = parseFloat(document.getElementById('customAmount').value);
            
            if (amount < <?php echo MIN_AMOUNT; ?>) {
                alert('最低充值金额为 ￥<?php echo MIN_AMOUNT; ?>');
                e.preventDefault();
                return;
            }
            
            if (amount > <?php echo MAX_AMOUNT; ?>) {
                alert('最高充值金额为 ￥<?php echo MAX_AMOUNT; ?>');
                e.preventDefault();
                return;
            }
            
            // 正常提交，直接跳转
        });

        // 关闭弹窗
        function closeModal() {
            document.getElementById('successModal').style.display = 'none';
        }

        // 显示成功弹窗
        function showSuccessModal() {
            const urlParams = new URLSearchParams(window.location.search);
            if (urlParams.get('success') === '1') {
                const tradeNo = urlParams.get('trade_no') || '';
                const outTradeNo = urlParams.get('out_trade_no') || '';
                
                document.getElementById('orderInfo').innerHTML = 
                    tradeNo ? `<small>交易号：${tradeNo}</small><br><small>订单号：${outTradeNo}</small>` : '';
                
                // 显示弹窗
                document.getElementById('successModal').style.display = 'block';
                
                // 清除URL参数
                if (window.history.replaceState) {
                    const newUrl = window.location.pathname;
                    window.history.replaceState({}, document.title, newUrl);
                }
            }
        }

        // 页面加载时检查是否需要显示成功弹窗
        window.addEventListener('load', showSuccessModal);

        // 点击弹窗外部关闭
        window.onclick = function(event) {
            const modal = document.getElementById('successModal');
            if (event.target == modal) {
                modal.style.display = 'none';
            }
        }

        // 初始化
        updateSummary();
    </script>
</body>
</html>
