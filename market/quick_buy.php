<?php
require_once 'config.php';

header('Content-Type: application/json');

// 检查是否为POST请求
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['ok' => false, 'msg' => '非法请求']);
    exit;
}

// 获取表单数据
$post_no = $_POST['post_no'];
$character_no = $_POST['character_no'];
$user_no = $_SESSION['user_no'];

// 验证数据
if (empty($post_no) || empty($character_no)) {
    echo json_encode(['ok' => false, 'msg' => '参数错误']);
    exit;
}

try {
    // 开始事务
    $db_character->beginTransaction();
    $db_cash->beginTransaction();
    
    // 获取物品信息 - 修复表名问题
    $item = null;
    $tables_to_try = [
        ['db' => $db_character, 'table' => 'user_postbox'],
        ['db' => $db_market, 'table' => 'USER_POSTBOX'],
        ['db' => $db_character, 'table' => 'User_Postbox']
    ];
    
    foreach ($tables_to_try as $config) {
        try {
            $stmt = $config['db']->prepare("
                SELECT * FROM " . $config['table'] . " 
                WHERE post_no = ? AND character_no = 'admin_character'
            ");
            $stmt->execute(array($post_no));
            $item = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($item) {
                break;
            }
        } catch (Exception $e) {
            continue;
        }
    }
    
    if (!$item) {
        throw new Exception('物品不存在');
    }
    
    // 检查是否是自己的物品
    $is_self_item = ($item['sell_character_no'] == $character_no);
    
    // 获取用户B币余额
    $stmt = $db_cash->prepare("SELECT b_amount FROM user_cash WHERE user_no = ?");
    $stmt->execute(array($user_no));
    $balance = $stmt->fetch(PDO::FETCH_ASSOC);
    $user_b_coin = $balance['b_amount'] ?? 0;
    
    // 检查B币余额
    if ($user_b_coin < $item['include_dil']) {
        throw new Exception('B币不足');
    }
    
    // 扣除B币
    $db_cash->prepare("UPDATE user_cash SET b_amount = b_amount - ? WHERE user_no = ?")
        ->execute(array($item['include_dil'], $user_no));
    
    // 获取卖家信息
    $stmt = $db_character->prepare("
        SELECT user_no, character_name 
        FROM user_character 
        WHERE character_no = ?
    ");
    $stmt->execute(array($item['sell_character_no']));
    $seller = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // 计算手续费后的金额（B币交易不收手续费）
    $seller_amount = $item['include_dil'];
    
    // 给卖家转账B币
    $db_cash->prepare("UPDATE user_cash SET b_amount = b_amount + ? WHERE user_no = ?")
        ->execute(array($seller_amount, $seller['user_no']));
    
    // 更新邮件信息
    $target_char = $is_self_item ? $item['sell_character_no'] : $character_no;
    $title = $is_self_item ? '装备取回成功' : '恭喜:寄售购买成功';
    $body = $is_self_item ? '您已成功取回自己寄售的装备，请在90天内取出' : '您已成功购买此装备，请在90天内取出';
    
    // 使用正确的表名更新邮件
    $update_table = null;
    foreach ($tables_to_try as $config) {
        try {
            $stmt = $config['db']->prepare("
                UPDATE " . $config['table'] . " SET 
                    character_no = ?, 
                    from_char_nm = '交易市场', 
                    post_title = ?, 
                    body_text = ?, 
                    ipt_time = GETDATE(), 
                    expire_time = DATEADD(day, 90, GETDATE())
                WHERE post_no = ?
            ");
            $stmt->execute(array($target_char, $title, $body, $post_no));
            $update_table = $config['table'];
            break;
        } catch (Exception $e) {
            continue;
        }
    }
    
    // 删除原市场记录
    if ($update_table) {
        $db_character->prepare("DELETE FROM " . $update_table . " WHERE post_no = ? AND character_no = 'admin_character'")
            ->execute(array($post_no));
    }
    
    // 提交事务
    $db_character->commit();
    $db_cash->commit();
    
    // 记录日志
    $log_text = $is_self_item ? '取回自己的装备ID:' . $item['wIndex'] : '购买物品ID:' . $item['wIndex'] . ' 花费B币:' . $item['include_dil'];
    $stmt = $db_account->prepare("
        INSERT INTO adminlog (admin, datetime, ip, username, adminlog, logtype) 
        VALUES (?, GETDATE(), ?, ?, ?, ?, 3)
    ");
    $stmt->execute(array(
        $_SESSION['username'],
        $_SERVER['REMOTE_ADDR'],
        $character_no,
        $log_text
    ));
    
    $success_msg = $is_self_item ? '装备取回成功！装备已发送到您的邮箱，请前往游戏邮箱查收。' : 
        '装备购买成功！已扣除' . $item['include_dil'] . ' B币，装备已发送到您的邮箱，请前往游戏邮箱查收。';
    
    echo json_encode(['ok' => true, 'message' => $success_msg]);
    
} catch (Exception $e) {
    // 回滚事务
    if (isset($db_character)) {
        $db_character->rollBack();
    }
    if (isset($db_cash)) {
        $db_cash->rollBack();
    }
    
    echo json_encode(['ok' => false, 'msg' => '购买失败：' . $e->getMessage()]);
}
?>
