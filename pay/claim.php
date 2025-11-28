<?php
require_once '../config.php';
require_once '../db.php';

session_start();
if (!isset($_SESSION['user_no'])) {
    header('Location: ../login.php');
    exit;
}

$user_no = $_SESSION['user_no'];
$server_id = $_SESSION['server_id'];

// 初始化变量
$success = '';
$error = '';

// 处理领取请求（虽然现在不会有待领取的订单，但保留功能以防万一）
if ($_POST && isset($_POST['order_no'])) {
    $order_no = $_POST['order_no'];
    $db_account = get_db($server_id, 'account');
    $order = $db_account->query("SELECT * FROM PayLog WHERE PayNo = ? AND UserID = ? AND trade_status = 1", array($order_no, $user_no))->fetch(PDO::FETCH_ASSOC);
    
    if ($order) {
        try {
            $db_account->beginTransaction();
            
            $coin_amount = $order['GameCash'];
            $currency_type = $order['currency_type'] ?? 'c_coin';
            
            // 发放货币 - 使用正确的表结构
            $db_cash = get_db($server_id, 'cash');
            
            if ($currency_type == 'c_coin') {
                // 更新C币 (amount字段)
                $cash_info = $db_cash->query("SELECT * FROM user_cash WHERE user_no = ?", array($user_no))->fetch(PDO::FETCH_ASSOC);
                if ($cash_info) {
                    $db_cash->query("UPDATE user_cash SET amount = amount + ? WHERE user_no = ?", array($coin_amount, $user_no));
                } else {
                    $db_cash->insert('user_cash', array(
                        'user_no' => $user_no,
                        'group_id' => 'default',
                        'amount' => $coin_amount,
                        'free_amount' => 0,
                        'b_amount' => 0
                    ));
                }
            } elseif ($currency_type == 'b_coin') {
                // 更新B币 (b_amount字段)
                $cash_info = $db_cash->query("SELECT * FROM user_cash WHERE user_no = ?", array($user_no))->fetch(PDO::FETCH_ASSOC);
                if ($cash_info) {
                    $db_cash->query("UPDATE user_cash SET b_amount = b_amount + ? WHERE user_no = ?", array($coin_amount, $user_no));
                } else {
                    $db_cash->insert('user_cash', array(
                        'user_no' => $user_no,
                        'group_id' => 'default',
                        'amount' => 0,
                        'free_amount' => 0,
                        'b_amount' => $coin_amount
                    ));
                }
            }
            
            // 标记为已领取（设置vipid为3，表示已手动领取）
            $db_account->query("UPDATE PayLog SET vipid = 3 WHERE PayNo = ?", array($order_no));
            
            $db_account->commit();
            $success = "领取成功！";
            
        } catch (Exception $e) {
            $db_account->rollBack();
            $error = "领取失败: " . $e->getMessage();
        }
    } else {
        $error = "订单不存在或已领取";
    }
}

// 查找已支付但未领取的订单（使用 ISNULL 函数处理 SQL Server）
$db_account = get_db($server_id, 'account');
$unclaimed_orders = $db_account->fetchAll("SELECT * FROM PayLog WHERE UserID = ? AND trade_status = 1 AND (ISNULL(vipid, 0) = 0) ORDER BY ID DESC", array($user_no));
?>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>领取充值 - <?php echo SITE_NAME; ?></title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <div class="container">
        <header class="header">
            <h1><i class="fas fa-gift"></i> 领取充值</h1>
            <a href="index.php" class="btn-back">返回充值中心</a>
        </header>
        
        <main class="main">
            <?php if ($success): ?>
                <div class="alert alert-success">
                    <i class="fas fa-check-circle"></i>
                    <?php echo $success; ?>
                </div>
            <?php endif; ?>
            
            <?php if ($error): ?>
                <div class="alert alert-error">
                    <i class="fas fa-exclamation-circle"></i>
                    <?php echo $error; ?>
                </div>
            <?php endif; ?>
            
            <div class="alert" style="text-align: center; padding: 40px; background: #e8f5e9;">
                <i class="fas fa-check-circle" style="font-size: 48px; color: #4caf50; margin-bottom: 20px;"></i>
                <p style="color: #2e7d32; font-size: 18px;">所有充值已自动到账，无需领取</p>
                <p style="color: #666; margin-top: 10px;">如有问题，请联系客服</p>
            </div>
            
            <?php if ($unclaimed_orders): ?>
                <!-- 这个部分理论上不会显示，但保留以防万一 -->
                <section class="recharge-history" style="margin-top: 30px;">
                    <h2>待领取的充值</h2>
                    <div class="history-table">
                        <table>
                            <thead>
                                <tr>
                                    <th>订单号</th>
                                    <th>充值类型</th>
                                    <th>充值金额</th>
                                    <th>到账数量</th>
                                    <th>时间</th>
                                    <th>操作</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php foreach ($unclaimed_orders as $order): ?>
                                    <tr>
                                        <td><?php echo htmlspecialchars($order['PayNo']); ?></td>
                                        <td>
                                            <?php 
                                            $currency_type = $order['currency_type'] ?? 'c_coin';
                                            echo $currency_type == 'c_coin' ? 'C币' : 'B币';
                                            ?>
                                        </td>
                                        <td>￥<?php echo number_format($order['Amount'], 2); ?></td>
                                        <td><?php echo number_format($order['GameCash']); ?></td>
                                        <td><?php echo date('Y-m-d H:i:s', strtotime($order['PayTime'])); ?></td>
                                        <td>
                                            <button class="btn-recharge" onclick="claim('<?php echo $order['PayNo']; ?>')">领取</button>
                                        </td>
                                    </tr>
                                <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                </section>
            <?php endif; ?>
        </main>
    </div>
    
    <form id="claim_form" method="post" style="display: none;">
        <input type="hidden" id="order_no" name="order_no">
    </form>
    
    <script>
        function claim(orderNo) {
            if (confirm('确定要领取订单 ' + orderNo + ' 的货币吗？')) {
                document.getElementById('order_no').value = orderNo;
                document.getElementById('claim_form').submit();
            }
        }
    </script>
</body>
</html>
