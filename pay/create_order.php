<?php
require_once '../config.php';
require_once '../db.php';
require_once 'alipay/AlipayMd5Pay.php';

session_start();
if (!isset($_SESSION['user_no'])) {
    header('Location: ../login.php');
    exit;
}

$user_no = $_SESSION['user_no'];
$server_id = $_SESSION['server_id'];

// 获取表单数据
$amount = floatval($_POST['amount']);
$currency_type = $_POST['currency_type'] ?? 'c_coin';

// 验证金额
if ($amount < MIN_AMOUNT || $amount > MAX_AMOUNT) {
    header('Location: index.php?error=invalid_amount');
    exit;
}

try {
    $db_account = get_db($server_id, 'account');
    $user = $db_account->query("SELECT user_id FROM USER_PROFILE WHERE user_no = ?", array($user_no))->fetch(PDO::FETCH_ASSOC);
    
    if ($user) {
        // 生成订单号
        $order_no = 'PAY' . date('YmdHis') . rand(1000, 9999);
        
        // 计算货币数量（包含赠送）
        $total_amount = $amount;
        foreach ($GLOBALS['recharge_bonuses'] as $bonus) {
            if ($amount >= $bonus['min_amount']) {
                $total_amount = $amount * $bonus['bonus_rate'];
            }
        }
        
        $coin_amount = intval($total_amount * ($currency_type == 'c_coin' ? $GLOBALS['currency_config']['c_coin']['ratio'] : $GLOBALS['currency_config']['b_coin']['ratio']));
        
        // 插入订单
        $db_account->query("INSERT INTO PayLog (Amount, UserName, UserID, PayTime, PayNo, ServerID, PayIP, Remark, GameCash, servicer, trade_status, currency_type) 
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", 
                            array(
                                $amount,
                                $user['user_id'],
                                $user_no,
                                date('Y-m-d H:i:s'),
                                $order_no,
                                $server_id,
                                $_SERVER['REMOTE_ADDR'],
                                $currency_type == 'c_coin' ? 'C币充值' : 'B币充值',
                                $coin_amount,
                                'alipay',
                                0,
                                $currency_type
                            ));
        
        // 生成支付URL
        $alipay = new AlipayMd5Pay();
        $params = array(
            'out_trade_no' => $order_no,
            'total_amount' => $amount,
            'subject' => $currency_type == 'c_coin' ? 'C币充值' : 'B币充值',
            'body' => $currency_type == 'c_coin' ? 'C币充值' : 'B币充值',
            'return_url' => SITE_URL . '/pay/return.php',  // 使用新的return.php
            'notify_url' => SITE_URL . '/pay/notify.php'
        );
        
        $paymentUrl = $alipay->generateAlipayRequest($params);
        
        // 跳转到支付页面
        header("Location: $paymentUrl");
        exit;
    }
} catch (Exception $e) {
    header('Location: index.php?error=create_failed');
    exit;
}
?>
