<?php
// 创建 pay/full_test.php
require_once '../config.php';
require_once '../db.php';  // 添加这行
require_once 'alipay/AlipayMd5Pay.php';

session_start();
if (!isset($_SESSION['user_no'])) {
    die('请先登录');
}

echo "<h2>完整支付测试流程</h2>";

// 如果是提交表单
if ($_POST) {
    $amount = floatval($_POST['amount']);
    $order_no = 'TEST' . date('YmdHis') . rand(1000, 9999);
    
    // 保存测试订单到数据库
    $server_id = $_SESSION['server_id'];
    $db_account = get_db($server_id, 'account');
    
    $user = $db_account->query("SELECT user_id FROM USER_PROFILE WHERE user_no = ?", array($_SESSION['user_no']))->fetch(PDO::FETCH_ASSOC);
    
    $db_account->query("INSERT INTO PayLog (Amount, UserName, UserID, PayTime, PayNo, ServerID, PayIP, Remark, GameCash, servicer, trade_status) 
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", 
                        array(
                            $amount,
                            $user['user_id'],
                            $_SESSION['user_no'],
                            date('Y-m-d H:i:s'),
                            $order_no,
                            $server_id,
                            $_SERVER['REMOTE_ADDR'],
                            '测试订单',
                            $amount * 100,
                            'alipay',
                            0
                        ));
    
    // 生成支付URL
    $alipay = new AlipayMd5Pay();
    $params = array(
        'out_trade_no' => $order_no,
        'total_amount' => $amount,
        'subject' => '测试订单',
        'body' => '完整测试流程',
        'return_url' => SITE_URL . '/pay/debug_return.php',
        'notify_url' => SITE_URL . '/pay/notify.php'
    );
    
    $paymentUrl = $alipay->generateAlipayRequest($params);
    
    echo "<h3>订单创建成功！</h3>";
    echo "<p>订单号: $order_no</p>";
    echo "<p>金额: ￥$amount</p>";
    echo "<p><a href='$paymentUrl' target='_blank' style='font-size:18px;color:red;'>点击这里去支付</a></p>";
    echo "<p>支付完成后会自动跳转到 debug_return.php</p>";
    
    exit;
}

// 显示表单
?>
<form method="post">
    <h3>创建测试订单</h3>
    <p>
        <label>充值金额：</label>
        <input type="number" name="amount" value="0.01" min="0.01" max="10" step="0.01" required>
        <span>元</span>
    </p>
    <p>
        <button type="submit" style="font-size:16px;padding:10px 20px;">创建订单并支付</button>
    </p>
</form>

<hr>

<h3>测试说明：</h3>
<ol>
    <li>输入金额（建议0.01元）</li>
    <li>点击"创建订单并支付"</li>
    <li>在新窗口完成支付</li>
    <li>支付完成后会跳转到 debug_return.php</li>
    <li>查看返回的参数和验证结果</li>
</ol>

<h3>当前配置：</h3>
<p>SITE_URL: <?php echo SITE_URL; ?></p>
<p>Return URL: <?php echo SITE_URL; ?>/pay/debug_return.php</p>
<p>Notify URL: <?php echo SITE_URL; ?>/pay/notify.php</p>
