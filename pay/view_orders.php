<?php
// 创建 pay/view_orders.php
require_once '../config.php';
require_once '../db.php';  // 确保包含这个文件

session_start();
if (!isset($_SESSION['user_no'])) {
    die('请先登录');
}

$user_no = $_SESSION['user_no'];
$server_id = $_SESSION['server_id'];

echo "<h2>我的订单</h2>";

$db_account = get_db($server_id, 'account');
$orders = $db_account->fetchAll("SELECT TOP 10 * FROM PayLog WHERE UserID = ? ORDER BY ID DESC", array($user_no));

if ($orders) {
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>订单号</th><th>金额</th><th>状态</th><th>时间</th><th>操作</th></tr>";
    foreach ($orders as $order) {
        echo "<tr>";
        echo "<td>" . $order['PayNo'] . "</td>";
        echo "<td>￥" . $order['Amount'] . "</td>";
        echo "<td>" . ($order['trade_status'] == 1 ? '<span style="color:green">已支付</span>' : '<span style="color:red">未支付</span>') . "</td>";
        echo "<td>" . $order['PayTime'] . "</td>";
        echo "<td>";
        if ($order['trade_status'] == 0) {
            echo "<a href='simple_full_test.php'>重新支付</a>";
        }
        echo "</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p>没有订单</p>";
}

echo "<p><a href='index.php'>返回充值首页</a></p>";
?>
