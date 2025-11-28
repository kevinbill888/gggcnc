<?php
// 创建 pay/debug_return.php
require_once '../config.php';
require_once '../db.php';
require_once 'alipay/AlipayMd5Pay.php';

echo "<h2>支付返回调试</h2>";
echo "<p>当前时间: " . date('Y-m-d H:i:s') . "</p>";
echo "<p>访问URL: " . $_SERVER['REQUEST_URI'] . "</p>";
echo "<p>HTTP_REFERER: " . ($_SERVER['HTTP_REFERER'] ?? '无') . "</p>";

// 显示所有GET参数
echo "<h3>收到的GET参数:</h3>";
if (empty($_GET)) {
    echo "<p style='color:red;'>没有收到任何GET参数</p>";
    echo "<p>说明：你是直接访问此页面，而不是从支付宝跳转回来的。</p>";
    echo "<p><a href='strict_test.php'>点击这里创建测试订单</a></p>";
} else {
    echo "<pre>" . print_r($_GET, true) . "</pre>";
    
    $alipay = new AlipayMd5Pay();
    
    // 验证签名
    $result = $alipay->verifySign($_GET);
    echo "<h3>签名验证: " . ($result ? '成功' : '失败') . "</h3>";
    
    if ($result && isset($_GET['trade_status']) && $_GET['trade_status'] == 'TRADE_SUCCESS') {
        echo "<p style='color:green; font-size:18px;'>支付成功！</p>";
        
        // 尝试更新订单状态
        $out_trade_no = $_GET['out_trade_no'];
        $total_fee = $_GET['total_fee'];
        $trade_no = $_GET['trade_no'];
        
        echo "<p>订单号: $out_trade_no</p>";
        echo "<p>交易号: $trade_no</p>";
        echo "<p>金额: ￥$total_fee</p>";
        
        // 查找订单（遍历所有服务器）
        $order_found = false;
        $order_updated = false;
        
        foreach (get_all_servers() as $server) {
            $db_account = get_db($server['id'], 'account');
            $order = $db_account->query("SELECT * FROM PayLog WHERE PayNo = ?", array($out_trade_no))->fetch(PDO::FETCH_ASSOC);
            
            if ($order) {
                $order_found = true;
                echo "<p style='color:blue;'>找到订单，服务器: " . $server['name'] . "</p>";
                echo "<p>用户ID: " . $order['UserID'] . "</p>";
                echo "<p>订单金额: " . $order['Amount'] . "</p>";
                echo "<p>当前状态: " . ($order['trade_status'] == 1 ? '已支付' : '未支付') . "</p>";
                
                // 更新状态
                if ($order['trade_status'] == 0) {
                    try {
                        $db_account->beginTransaction();
                        
                        // 更新订单状态
                        $stmt = $db_account->query(
                            "UPDATE PayLog SET trade_status = 1, PayTime = ?, servicer = ? WHERE PayNo = ?", 
                            array(date('Y-m-d H:i:s'), $trade_no, $out_trade_no)
                        );
                        
                        if ($stmt->rowCount() > 0) {
                            echo "<p style='color:green;'>订单状态已更新为已支付</p>";
                            $order_updated = true;
                            
                            // 如果是正式订单（不是测试订单），发放货币
                            if (strpos($out_trade_no, 'TEST') !== 0 && strpos($out_trade_no, 'STRICT') !== 0 && strpos($out_trade_no, 'SIMPLE') !== 0) {
                                $user_no = $order['UserID'];
                                $amount = $order['Amount'];
                                $currency_type = $order['currency_type'] ?? 'c_coin';
                                $coin_amount = $order['GameCash'];
                                
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
                                
                                // 更新PayLog表中的VIP等级
                                $db_account->query("UPDATE PayLog SET vipid = ? WHERE PayNo = ?", array($new_vip_level, $out_trade_no));
                                
                                // 根据货币类型发放
                                $db_cash = get_db($server['id'], 'cash');
                                
                                if ($currency_type == 'c_coin') {
                                    // C币 - 更新 amount 字段
                                    $user_cash = $db_cash->query("SELECT * FROM user_cash WHERE user_no = ?", array($user_no))->fetch(PDO::FETCH_ASSOC);
                                    
                                    if ($user_cash) {
                                        $db_cash->query("UPDATE user_cash SET amount = amount + ? WHERE user_no = ?", array($coin_amount, $user_no));
                                        echo "<p style='color:green;'>C币已发放: +$coin_amount</p>";
                                    } else {
                                        $db_cash->insert('user_cash', array(
                                            'user_no' => $user_no,
                                            'amount' => $coin_amount,
                                            'B_amount' => 0,
                                            'update_time' => date('Y-m-d H:i:s')
                                        ));
                                        echo "<p style='color:green;'>创建账户并发放C币: $coin_amount</p>";
                                    }
                                } elseif ($currency_type == 'b_coin') {
                                    // B币 - 更新 B_amount 字段
                                    $user_cash = $db_cash->query("SELECT * FROM user_cash WHERE user_no = ?", array($user_no))->fetch(PDO::FETCH_ASSOC);
                                    
                                    if ($user_cash) {
                                        $db_cash->query("UPDATE user_cash SET B_amount = B_amount + ? WHERE user_no = ?", array($coin_amount, $user_no));
                                        echo "<p style='color:green;'>B币已发放: +$coin_amount</p>";
                                    } else {
                                        $db_cash->insert('user_cash', array(
                                            'user_no' => $user_no,
                                            'amount' => 0,
                                            'B_amount' => $coin_amount,
                                            'update_time' => date('Y-m-d H:i:s')
                                        ));
                                        echo "<p style='color:green;'>创建账户并发放B币: $coin_amount</p>";
                                    }
                                }
                            } else {
                                echo "<p style='color:orange;'>测试订单，不发放货币</p>";
                            }
                        }
                        
                        $db_account->commit();
                    } catch (Exception $e) {
                        $db_account->rollBack();
                        echo "<p style='color:red;'>更新失败: " . $e->getMessage() . "</p>";
                    }
                } else {
                    echo "<p style='color:orange;'>订单已经是已支付状态</p>";
                }
                break;
            }
        }
        
        if (!$order_found) {
            echo "<p style='color:red;'>未找到订单: $out_trade_no</p>";
            echo "<p>这可能是因为：</p>";
            echo "<ul>";
            echo "<li>订单号不匹配</li>";
            echo "<li>订单保存在其他服务器</li>";
            echo "<li>测试订单没有保存到数据库</li>";
            echo "</ul>";
        }
        
        echo "<p><a href='index.php?success=1'>返回充值页面</a></p>";
    } else {
        echo "<p style='color:red;'>支付失败或签名验证失败</p>";
        echo "<p><a href='index.php?error=pay_failed'>返回充值页面</a></p>";
    }
    
    // 显示签名调试信息
    echo "<h3>签名调试:</h3>";
    $params = $_GET;
    $sign = $params['sign'] ?? '';
    unset($params['sign']);
    unset($params['sign_type']);
    
    ksort($params);
    $signString = '';
    foreach ($params as $key => $value) {
        $signString .= $key . '=' . $value . '&';
    }
    $signString = rtrim($signString, '&');
    $signString .= ALIPAY_KEY;
    
    echo "<p>签名字符串:</p>";
    echo "<textarea style='width:100%;height:200px;'>" . htmlspecialchars($signString) . "</textarea>";
    echo "<p>计算的MD5: " . md5($signString) . "</p>";
    echo "<p>收到的签名: $sign</p>";
}

echo "<hr>";
echo "<p><a href='strict_test.php'>返回测试页面</a> | <a href='index.php'>返回充值首页</a></p>";
?>
