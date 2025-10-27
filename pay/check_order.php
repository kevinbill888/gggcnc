<?php
// 创建 pay/check_order.php
require_once '../config.php';
require_once '../db.php';

session_start();
if (!isset($_SESSION['user_no'])) {
    die('请先登录');
}

$user_no = $_SESSION['user_no'];
$server_id = $_SESSION['server_id'];

echo "<h2>订单检查</h2>";

$db_account = get_db($server_id, 'account');

// 查看最近的订单
$orders = $db_account->fetchAll("SELECT TOP 5 * FROM PayLog WHERE UserID = ? ORDER BY ID DESC", array($user_no));

echo "<h3>最近5个订单：</h3>";
echo "<table border='1'>";
echo "<tr><th>订单号</th><th>金额</th><th>状态</th><th>货币类型</th><th>到账数量</th><th>时间</th></tr>";

foreach ($orders as $order) {
    echo "<tr>";
    echo "<td>" . $order['PayNo'] . "</td>";
    echo "<td>" . $order['Amount'] . "</td>";
    echo "<td>" . ($order['trade_status'] == 1 ? '成功' : '待支付') . "</td>";
    echo "<td>" . ($order['currency_type'] ?? '未知') . "</td>";
    echo "<td>" . $order['GameCash'] . "</td>";
    echo "<td>" . $order['PayTime'] . "</td>";
    echo "</tr>";
}
echo "</table>";

// 查看VIP信息
$vip = $db_account->fetch("SELECT * FROM User_VIP WHERE user_no = ?", array($user_no));
if ($vip) {
    echo "<h3>VIP信息：</h3>";
    echo "<p>等级：" . $vip['vip_level'] . "</p>";
    echo "<p>累计充值：" . $vip['total_recharge'] . "</p>";
}

// 查看货币余额
$db_cash = get_db($server_id, 'cash');
$cash = $db_cash->fetch("SELECT * FROM User_Cash WHERE user_no = ?", array($user_no));
if ($cash) {
    echo "<h3>货币余额：</h3>";
    echo "<p>C币：" . $cash['C_Coin'] . "</p>";
    echo "<p>B币：" . $cash['B_Coin'] . "</p>";
}
?>
