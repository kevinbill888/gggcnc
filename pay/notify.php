<?php
require_once '../config.php';
require_once '../db.php';
require_once 'alipay/AlipayMd5Pay.php';

// 关闭所有输出缓冲
while (ob_get_level()) {
    ob_end_clean();
}

// 记录日志
$log_file = __DIR__ . '/alipay_notify.log';
$log_data = "=== " . date('Y-m-d H:i:s') . " ===\n";
$log_data .= "POST数据: " . file_get_contents('php://input') . "\n";
$log_data .= "POST参数: " . print_r($_POST, true) . "\n";
$log_data .= "GET参数: " . print_r($_GET, true) . "\n";
$log_data .= "REMOTE_ADDR: " . $_SERVER['REMOTE_ADDR'] . "\n\n";
file_put_contents($log_file, $log_data, FILE_APPEND | LOCK_EX);

$alipay = new AlipayMd5Pay();

// 获取支付宝POST参数
$params = $_POST;

if (empty($params)) {
    error_log("没有收到POST参数");
    echo 'fail';
    exit;
}

// 验证签名
$sign_valid = $alipay->verifySign($params);
error_log("签名验证结果: " . ($sign_valid ? '成功' : '失败'));

if (!$sign_valid) {
    error_log("签名验证失败");
    echo 'fail';
    exit;
}

// 处理业务逻辑
$out_trade_no = $params['out_trade_no'];
$trade_status = $params['trade_status'];
$total_fee = $params['total_fee'];
$trade_no = $params['trade_no'];

error_log("处理订单: $out_trade_no, 状态: $trade_status");

if ($trade_status == 'TRADE_SUCCESS' || $trade_status == 'TRADE_FINISHED') {
    // 先获取订单信息
    $order = null;
    $server_id = null;
    
    foreach (get_all_servers() as $server) {
        $db_account = get_db($server['id'], 'account');
        $order = $db_account->query("SELECT * FROM PayLog WHERE PayNo = ?", array($out_trade_no))->fetch(PDO::FETCH_ASSOC);
        if ($order) {
            $server_id = $server['id'];
            error_log("在服务器 " . $server['name'] . " 找到订单");
            break;
        }
    }
    
    if ($order && $server_id) {
        try {
            $db_account = get_db($server_id, 'account');
            $db_account->beginTransaction();
            
            // 检查订单是否已经处理过
            if ($order['trade_status'] == 1) {
                error_log("订单已处理过: $out_trade_no");
                echo 'success';
                exit;
            }
            
            // 更新订单状态，设置 vipid=1 表示已自动到账
            $sql = "UPDATE PayLog SET trade_status = 1, PayTime = ?, servicer = ?, vipid = 1 WHERE PayNo = ? AND trade_status = 0";
            $stmt = $db_account->query($sql, array(date('Y-m-d H:i:s'), $trade_no, $out_trade_no));
            
            if ($stmt->rowCount() > 0) {
                error_log("订单状态更新成功");
                
                $user_no = $order['UserID'];
                $amount = $order['Amount'];
                $currency_type = $order['currency_type'] ?? 'c_coin';
                $coin_amount = $order['GameCash'];
                
                error_log("准备发放货币: 用户=$user_no, 数量=$coin_amount");
                
                // 更新用户VIP信息
                $current_vip = $db_account->query("SELECT vip_level, total_recharge FROM User_VIP WHERE user_no = ?", array($user_no))->fetch(PDO::FETCH_ASSOC);
                
                if (!$current_vip) {
                    $db_account->insert('User_VIP', array(
                        'user_no' => $user_no,
                        'vip_level' => 0,
                        'total_recharge' => 0
                    ));
                    $current_vip = array('vip_level' => 0, 'total_recharge' => 0);
                }
                
                // 获取历史充值总额
                $total_recharged = $db_account->query("SELECT SUM(Amount) as total FROM PayLog WHERE UserID = ? AND trade_status = 1", array($user_no))->fetch(PDO::FETCH_ASSOC);
                $new_total = $total_recharged['total'] + $amount;
                
                // 计算新的VIP等级
                $new_vip_level = 0;
                foreach ($GLOBALS['vip_levels'] as $level => $config) {
                    if (isset($config['min_amount']) && $new_total >= $config['min_amount']) {
                        $new_vip_level = $level;
                    }
                }
                
                // 更新VIP信息
                $db_account->update('User_VIP',
                    array(
                        'total_recharge' => $new_total,
                        'vip_level' => $new_vip_level,
                        'update_time' => date('Y-m-d H:i:s')
                    ),
                    'user_no = ?',
                    array($user_no)
                );
                
                // 发放货币
                $db_cash = get_db($server_id, 'cash');
                
                if ($currency_type == 'c_coin') {
                    // 更新C币 (amount字段)
                    try {
                        $cash_info = $db_cash->query("SELECT * FROM user_cash WHERE user_no = ?", array($user_no))->fetch(PDO::FETCH_ASSOC);
                        if ($cash_info) {
                            $db_cash->query("UPDATE user_cash SET amount = amount + ? WHERE user_no = ?", array($coin_amount, $user_no));
                            error_log("C币已发放: +$coin_amount");
                        } else {
                            $db_cash->insert('user_cash', array(
                                'user_no' => $user_no,
                                'group_id' => 'default',
                                'amount' => $coin_amount,
                                'free_amount' => 0,
                                'b_amount' => 0
                            ));
                            error_log("创建账户并发放C币: $coin_amount");
                        }
                    } catch (Exception $e) {
                        error_log("C币发放失败: " . $e->getMessage());
                    }
                } elseif ($currency_type == 'b_coin') {
                    // 更新B币 (b_amount字段)
                    try {
                        $cash_info = $db_cash->query("SELECT * FROM user_cash WHERE user_no = ?", array($user_no))->fetch(PDO::FETCH_ASSOC);
                        if ($cash_info) {
                            $db_cash->query("UPDATE user_cash SET b_amount = b_amount + ? WHERE user_no = ?", array($coin_amount, $user_no));
                            error_log("B币已发放: +$coin_amount");
                        } else {
                            $db_cash->insert('user_cash', array(
                                'user_no' => $user_no,
                                'group_id' => 'default',
                                'amount' => 0,
                                'free_amount' => 0,
                                'b_amount' => $coin_amount
                            ));
                            error_log("创建账户并发放B币: $coin_amount");
                        }
                    } catch (Exception $e) {
                        error_log("B币发放失败: " . $e->getMessage());
                    }
                }
                
                error_log("订单处理成功: $out_trade_no");
            }
            
            $db_account->commit();
            error_log("事务提交成功");
            
        } catch (Exception $e) {
            $db_account->rollBack();
            error_log("订单处理失败: " . $e->getMessage());
            echo 'fail: ' . $e->getMessage();
            exit;
        }
    } else {
        error_log("未找到订单: $out_trade_no");
        echo 'fail: order not found';
        exit;
    }
}

// 输出成功响应
echo 'success';
?>
