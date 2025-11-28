<?php
require_once 'config.php';

// 检查是否为POST请求
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: buy.php');
    exit;
}

// 获取表单数据
$post_no = $_POST['post_no'];
$character_no = $_POST['receive_character'];
$user_no = $_SESSION['user_no'];

// 验证数据
if (empty($post_no) || empty($character_no)) {
    die('<script>alert("参数错误"); history.back();</script>');
}

try {
    // 开始事务
    $db_character->beginTransaction();
    $db_cash->beginTransaction();
    
    // 获取物品信息
    $stmt = $db_character->prepare("
        SELECT * FROM user_postbox 
        WHERE post_no = ? AND character_no = 'admin_character'
    ");
    $stmt->execute(array($post_no));
    $item = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$item) {
        throw new Exception('物品不存在');
    }
    
    // 检查是否是自己的物品
    $is_self_item = ($item['sell_character_no'] == $character_no);
    
    // 如果不是自己的物品，检查余额
    if (!$is_self_item) {
        $stmt = $db_cash->prepare("SELECT free_amount FROM user_cash WHERE user_no = ?");
        $stmt->execute(array($user_no));
        $balance = $stmt->fetch(PDO::FETCH_ASSOC);
        $user_balance = $balance['free_amount'] ?? 0;
        
        if ($user_balance < $item['include_dil']) {
            throw new Exception('余额不足');
        }
        
        // 扣除买家金币
        $db_cash->prepare("UPDATE user_cash SET free_amount = free_amount - ? WHERE user_no = ?")
            ->execute(array($item['include_dil'], $user_no));
        
        // 获取卖家信息
        $stmt = $db_character->prepare("
            SELECT user_no, character_name 
            FROM user_character 
            WHERE character_no = ?
        ");
        $stmt->execute(array($item['sell_character_no']));
        $seller = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // 计算手续费后的金额
        $seller_amount = intval($item['include_dil'] * 0.8);
        
        // 给卖家转账（80%）
        $db_cash->prepare("UPDATE user_cash SET free_amount = free_amount + ? WHERE user_no = ?")
            ->execute(array($seller_amount, $seller['user_no']));
        
        // 记录交易日志
        $buyer_ip = $_SERVER['REMOTE_ADDR'];
        $stmt = $db_character->prepare("
            SELECT character_name FROM user_character WHERE character_no = ?
        ");
        $stmt->execute(array($character_no));
        $buyer_char = $stmt->fetch(PDO::FETCH_ASSOC);
        
        $log_sql = "INSERT INTO web_market (buy_name, sell_name, IP, time, Money, Windex, buy_user_no, sell_user_no, actual_amount, status) VALUES (?, ?, ?, GETDATE(), ?, ?, ?, ?, ?, 1)";
        $db_market->prepare($log_sql)->execute(array(
            $buyer_char['character_name'],
            $seller['character_name'],
            $buyer_ip,
            $item['include_dil'],
            $item['wIndex'],
            $user_no,
            $seller['user_no'],
            $seller_amount
        ));
    }
    
    // 更新邮件信息
    $target_char = $is_self_item ? $item['sell_character_no'] : $character_no;
    $title = $is_self_item ? '装备取回成功' : '恭喜:寄售购买成功';
    $body = $is_self_item ? '您已成功取回自己寄售的装备，请在90天内取出' : '您已成功购买此装备，请在90天内取出';
    
    $stmt = $db_character->prepare("
        UPDATE user_postbox SET 
            character_no = ?, 
            from_char_nm = '交易市场', 
            post_title = ?, 
            body_text = ?, 
            ipt_time = GETDATE(), 
            expire_time = DATEADD(day, 90, GETDATE())
        WHERE post_no = ?
    ");
    $stmt->execute(array($target_char, $title, $body, $post_no));
    
    // 删除原市场记录
    $db_character->prepare("DELETE FROM user_postbox WHERE post_no = ? AND character_no = 'admin_character'")
        ->execute(array($post_no));
    
    // 提交事务
    $db_character->commit();
    $db_cash->commit();
    
    // 记录日志
    $log_text = $is_self_item ? '取回自己的装备ID:' . $item['wIndex'] : '购买物品ID:' . $item['wIndex'] . ' 花费金币:' . $item['include_dil'];
    $stmt = $db_account->prepare("
        INSERT INTO adminlog (admin, datetime, ip, username, adminlog, logtype) 
        VALUES (?, GETDATE(), ?, ?, ?, 3)
    ");
    $stmt->execute(array(
        $_SESSION['username'],
        $_SERVER['REMOTE_ADDR'],
        $character_no,
        $log_text
    ));
    
    $success_msg = $is_self_item ? '装备取回成功！装备已发送到您的邮箱，请前往游戏邮箱查收。' : 
        '装备购买成功！已扣除' . $item['include_dil'] . '金币（含20%手续费），卖家实际收到' . $seller_amount . '金币，装备已发送到您的邮箱，请前往游戏邮箱查收。';
    
    echo '<script>alert("' . $success_msg . '"); location.href="index.php";</script>';
    
} catch (Exception $e) {
    // 回滚事务
    if (isset($db_character)) {
        $db_character->rollBack();
    }
    if (isset($db_cash)) {
        $db_cash->rollBack();
    }
    
    echo '<script>alert("操作失败：' . $e->getMessage() . '"); history.back();</script>';
}
?>
