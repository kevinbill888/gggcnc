<?php
require_once '../config.php';
require_once '../db.php';
require_once 'alipay/AlipayMd5Pay.php';

// 记录日志
error_log("=== 支付宝返回开始 ===");
error_log("时间: " . date('Y-m-d H:i:s'));
error_log("GET参数: " . print_r($_GET, true));

$alipay = new AlipayMd5Pay();

// 获取支付宝GET参数
$params = $_GET;

if (empty($params)) {
    error_log("没有收到支付宝返回参数");
    header('Location: index.php?error=no_params');
    exit;
}

// 验证签名
$sign_valid = $alipay->verifySign($params);
error_log("签名验证结果: " . ($sign_valid ? '成功' : '失败'));

if (!$sign_valid) {
    error_log("签名验证失败");
    header('Location: index.php?error=sign');
    exit;
}

// 检查支付状态
if (isset($params['trade_status']) && ($params['trade_status'] == 'TRADE_SUCCESS' || $params['trade_status'] == 'TRADE_FINISHED')) {
    $out_trade_no = $params['out_trade_no'];
    $trade_no = $params['trade_no'];
    $total_fee = $params['total_fee'];
    
    error_log("支付成功: $out_trade_no");
    
    // 立即处理订单（确保即时到账）
    $order_processed = false;
    $already_processed = false;
    
    foreach (get_all_servers() as $server) {
        $db_account = get_db($server['id'], 'account');
        $order = $db_account->query("SELECT * FROM PayLog WHERE PayNo = ?", array($out_trade_no))->fetch(PDO::FETCH_ASSOC);
        
        if ($order) {
            error_log("找到订单，服务器: " . $server['name']);
            
            // 检查是否已经处理过
            if ($order['trade_status'] == 1) {
                error_log("订单已处理过，直接跳转");
                $already_processed = true;
                break;
            }
            
            try {
                $db_account->beginTransaction();
                
                // 更新订单状态为已支付，设置 vipid=1 表示已自动到账
                $db_account->query("UPDATE PayLog SET trade_status = 1, PayTime = ?, servicer = ?, vipid = 1 WHERE PayNo = ?", 
                    array(date('Y-m-d H:i:s'), $trade_no, $out_trade_no));
                
                $user_no = $order['UserID'];
                $amount = $order['Amount'];
                $currency_type = $order['currency_type'] ?? 'c_coin';
                $coin_amount = $order['GameCash'];
                
                error_log("准备发放货币: 用户=$user_no, 数量=$coin_amount");
                
                // 更新VIP信息
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
                
                // 发放货币 - 使用正确的表结构
                $db_cash = get_db($server['id'], 'cash');
                
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
                
                error_log("订单处理完成: $out_trade_no");
                
                $db_account->commit();
                $order_processed = true;
                
            } catch (Exception $e) {
                $db_account->rollBack();
                error_log("订单处理失败: " . $e->getMessage());
            }
            break;
        }
    }
    
    if ($already_processed) {
        // 订单已处理，直接跳转
        header('Location: index.php?success=1&trade_no=' . urlencode($trade_no) . '&out_trade_no=' . urlencode($out_trade_no) . '&status=processed');
    } elseif ($order_processed) {
        // 跳转到成功页面
        header('Location: index.php?success=1&trade_no=' . urlencode($trade_no) . '&out_trade_no=' . urlencode($out_trade_no));
    } else {
        // 订单可能已处理或找不到
        header('Location: index.php?success=1&trade_no=' . urlencode($trade_no) . '&out_trade_no=' . urlencode($out_trade_no) . '&status=processed');
    }
} else {
    error_log("支付失败: " . ($params['trade_status'] ?? 'unknown'));
    header('Location: index.php?error=pay_failed&trade_status=' . urlencode($params['trade_status'] ?? 'unknown'));
}

error_log("=== 支付宝返回结束 ===\n");
?>
