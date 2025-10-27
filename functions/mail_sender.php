<?php
// mail_sender.php - 邮件发送函数库
error_reporting(E_ALL);
ini_set('display_errors', 1);

// hex2bin兼容性函数（PHP 5.4以下版本需要）
if (!function_exists('hex2bin')) {
    function hex2bin($data) {
        return pack('H*', $data);
    }
}

/**
 * 发送物品到邮箱
 * @param PDO $db_character 数据库连接
 * @param string $character_no 角色ID
 * @param string $post_title 邮件标题
 * @param int $wIndex 物品ID
 * @param int $item_count 物品数量
 * @param string $body_text 邮件内容
 * @return bool 是否成功
 */
function sendItemToMailbox($db_character, $character_no, $post_title, $wIndex, $item_count, $body_text = '') {
    try {
        // 生成邮件编号
        $post_no = date('ymdHis') . substr(mt_rand(1000, 9999), 0, 4);
        
        // 使用CONVERT函数处理二进制数据（参考成功代码）
        $sql = "INSERT INTO user_postbox (
            character_no, post_no, from_char_nm, post_sort, 
            post_title, body_text, state_tag, item_tag, 
            byHeader, wIndex, dwSerialNumber, info, 
            dil_tag, include_dil, ipt_time, expire_time, 
            upt_time, reg_bindate, exp_bindate, byRebirthFlag, 
            coupon_no, promotion_no, sell_character_no
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 
            CONVERT(binary(16), '0x00000000000000000000000000000000'), 
            CONVERT(varbinary(25), ?), 
            ?, ?, ?, ?, ?, 
            CONVERT(binary(4), '0x00000000'), 
            CONVERT(binary(4), '0x00000000'), 
            ?, ?, ?, ?)";
        
        $stmt = $db_character->prepare($sql);
        
        // 物品数量转十六进制
        $item_count_hex = '0x' . str_pad(dechex($item_count), 4, '0', STR_PAD_LEFT);
        
        // 23个参数，与成功代码完全一致
        $params = [
            $character_no,                              // 1. 角色ID
            $post_no,                                   // 2. 邮件编号
            'CNCTZ-DK',                                 // 3. 发送者名称
            4,                                          // 4. 邮件类型（礼包发放）
            $post_title,                                // 5. 邮件标题
            $body_text ?: '礼包奖励，请及时领取',     // 6. 邮件内容
            0,                                          // 7. 状态标记（未读）
            1,                                          // 8. 物品标记（有物品）
            1,                                          // 9. 物品头部信息
            $wIndex,                                    // 10. 物品ID
            $item_count_hex,                            // 11. 物品数量（十六进制字符串）
            0,                                          // 12. 金币标记（无）
            0,                                          // 13. 包含金币数量
            date('Y-m-d H:i:s'),                       // 14. 发送时间
            date('Y-m-d H:i:s', strtotime('+90 days')), // 15. 过期时间
            null,                                       // 16. 更新时间
            1,                                          // 17. 转生标记
            null,                                       // 18. 优惠券编号
            null,                                       // 19. 活动编号
            null                                        // 20. 出售角色编号
        ];
        
        $result = $stmt->execute($params);
        
        if (!$result) {
            $errorInfo = $stmt->errorInfo();
            error_log("发送物品到邮箱失败: " . json_encode($errorInfo));
            return false;
        }
        
        return true;
        
    } catch (Exception $e) {
        error_log("sendItemToMailbox Error: " . $e->getMessage());
        return false;
    }
}

/**
 * 发送游戏币到邮箱
 * @param PDO $db_character 数据库连接
 * @param string $character_no 角色ID
 * @param int $money 游戏币数量
 * @param string $post_title 邮件标题
 * @param string $body_text 邮件内容
 * @return bool 是否成功
 */
function sendMoneyToMailbox($db_character, $character_no, $money, $post_title = '游戏币奖励', $body_text = '') {
    try {
        // 生成邮件编号
        $post_no = date('ymdHis') . substr(mt_rand(1000, 9999), 0, 4);
        
        // 使用CONVERT函数处理二进制数据（参考成功代码）
        $sql = "INSERT INTO user_postbox (
            character_no, post_no, from_char_nm, post_sort, 
            post_title, body_text, state_tag, item_tag, 
            byHeader, wIndex, dwSerialNumber, info, 
            dil_tag, include_dil, ipt_time, expire_time, 
            upt_time, reg_bindate, exp_bindate, byRebirthFlag, 
            coupon_no, promotion_no, sell_character_no
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 
            CONVERT(binary(16), '0x00000000000000000000000000000000'), 
            CONVERT(varbinary(25), ''), 
            ?, ?, ?, ?, ?, 
            CONVERT(binary(4), '0x00000000'), 
            CONVERT(binary(4), '0x00000000'), 
            ?, ?, ?, ?)";
        
        $stmt = $db_character->prepare($sql);
        
        $params = [
            $character_no,                              // 1. 角色ID
            $post_no,                                   // 2. 邮件编号
            'CNCTZ-DK',                                 // 3. 发送者名称
            4,                                          // 4. 邮件类型
            $post_title,                                // 5. 邮件标题
            $body_text ?: '礼包奖励，请及时领取',     // 6. 邮件内容
            0,                                          // 7. 状态标记
            1,                                          // 8. 物品标记
            1,                                          // 9. 物品头部信息
            0,                                          // 10. 物品ID（游戏币是0）
            1,                                          // 11. 金币标记（游戏币需要设为1）
            $money,                                     // 12. 包含金币数量
            date('Y-m-d H:i:s'),                       // 13. 发送时间
            date('Y-m-d H:i:s', strtotime('+90 days')), // 14. 过期时间
            null,                                       // 15. 更新时间
            1,                                          // 16. 转生标记
            null,                                       // 17. 优惠券编号
            null,                                       // 18. 活动编号
            null                                        // 19. 出售角色编号
        ];
        
        $result = $stmt->execute($params);
        
        if (!$result) {
            $errorInfo = $stmt->errorInfo();
            error_log("发送游戏币到邮箱失败: " . json_encode($errorInfo));
            return false;
        }
        
        return true;
        
    } catch (Exception $e) {
        error_log("sendMoneyToMailbox Error: " . $e->getMessage());
        return false;
    }
}

/**
 * 发送商城币到用户账户
 * @param PDO $db_cash 数据库连接
 * @param string $user_no 用户ID
 * @param int $cash 商城币数量
 * @return bool 是否成功
 */
function sendCashToAccount($db_cash, $user_no, $cash) {
    try {
        // 检查用户是否已有记录
        $check = $db_cash->fetch("
            SELECT amount FROM user_cash WHERE user_no = ?
        ", [$user_no]);
        
        if ($check) {
            // 更新现有记录
            $stmt = $db_cash->prepare("
                UPDATE user_cash SET amount = amount + ? WHERE user_no = ?
            ");
            $result = $stmt->execute([$cash, $user_no]);
        } else {
            // 创建新记录
            $stmt = $db_cash->prepare("
                INSERT INTO user_cash (user_no, amount) VALUES (?, ?)
            ");
            $result = $stmt->execute([$user_no, $cash]);
        }
        
        if (!$result) {
            $errorInfo = $stmt->errorInfo();
            error_log("发送商城币失败: " . json_encode($errorInfo));
            return false;
        }
        
        return true;
        
    } catch (Exception $e) {
        error_log("sendCashToAccount Error: " . $e->getMessage());
        return false;
    }
}

/**
 * 发送礼包（组合函数）
 * @param array $server_config 服务器配置
 * @param string $user_no 用户ID
 * @param string $character_no 角色ID
 * @param array $gift 礼包信息
 * @return array 返回发送结果
 */
function sendGiftPackage($server_config, $user_no, $character_no, $gift) {
    $results = [
        'item' => false,
        'cash' => false,
        'money' => false,
        'errors' => []
    ];
    
    try {
        // 获取数据库连接
        $db_character = get_db($server_config['id'], 'character');
        $db_cash = get_db($server_config['id'], 'cash');
        
        // 1. 发送物品
        if ($gift['item_id'] > 0) {
            $post_title = $gift['min_level'] . '级礼包';
            $body_text = '您已成功领取【' . $gift['item_name'] . '】，请在90天内取出，逾期自动删除。';
            
            if (sendItemToMailbox($db_character, $character_no, $post_title, $gift['item_id'], $gift['item_count'], $body_text)) {
                $results['item'] = true;
            } else {
                $results['errors'][] = '物品发送失败';
            }
        }
        
        // 2. 发送商城币
        if ($gift['Cash'] > 0) {
            if (sendCashToAccount($db_cash, $user_no, $gift['Cash'])) {
                $results['cash'] = true;
            } else {
                $results['errors'][] = '商城币发送失败';
            }
        }
        
        // 3. 发送游戏币
        if ($gift['Money'] > 0) {
            $post_title = '游戏币奖励';
            $body_text = '您已成功领取游戏币奖励，请在90天内取出，逾期自动删除。';
            
            if (sendMoneyToMailbox($db_character, $character_no, $gift['Money'], $post_title, $body_text)) {
                $results['money'] = true;
            } else {
                $results['errors'][] = '游戏币发送失败';
            }
        }
        
    } catch (Exception $e) {
        error_log("sendGiftPackage Error: " . $e->getMessage());
        $results['errors'][] = $e->getMessage();
    }
    
    return $results;
}
