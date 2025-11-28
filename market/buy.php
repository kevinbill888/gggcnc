<?php
require_once 'config.php';

// 处理购买请求
if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['post_no'])) {
    $post_no =$_GET['post_no'];
    $user_no =$_SESSION['user_no'];
    
    try {
        // 开始事务
        $db_character->beginTransaction();
        $db_cash->beginTransaction();
        
        // 1. 获取物品信息
        $stmt =$db_character->prepare("SELECT * FROM user_postbox WHERE post_no = ? AND character_no = 'admin_character'");
        $stmt->execute(array($post_no));
        $item =$stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$item) {
            throw new Exception("物品不存在");
        }
        
        // 2. 检查用户余额
        $stmt =$db_cash->prepare("SELECT b_amount FROM user_cash WHERE user_no = ?");
        $stmt->execute(array($user_no));
        $balance =$stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$balance ||$balance['b_amount'] < $item['include_dil']) {
            throw new Exception("余额不足");
        }
        
        // 3. 扣除用户余额
        $stmt =$db_cash->prepare("UPDATE user_cash SET b_amount = b_amount - ? WHERE user_no = ?");
        $stmt->execute(array($item['include_dil'], $user_no));
        
        // 4. 将物品转移到用户邮箱
        $stmt =$db_character->prepare("UPDATE user_postbox SET character_no = ? WHERE post_no = ?");
        $stmt->execute(array($user_no, $post_no));
        
        // 5. 记录交易日志
        $stmt =$db_character->prepare("INSERT INTO user_postbox (character_no, post_no, from_char_nm, post_sort, post_title, body_text, state_tag, item_tag, wIndex, include_dil, ipt_time) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, GETDATE())");
        $stmt->execute(array(
            $user_no,
            'LOG_' . time(),
            '系统',
            2, // 交易记录
            '购买物品',
            '购买了 ' . $item['wIndex'],
            1, // 已确认
            1,
            $item['wIndex'],
            $item['include_dil'],
            $item['include_dil']
        ));
        
        // 提交事务
        $db_character->commit();
        $db_cash->commit();
        
        $success = true;
        $message = "购买成功！物品已发送到您的邮箱";
        
    } catch (Exception $e) {
        // 回滚事务
        $db_character->rollBack();
        $db_cash->rollBack();
        
        $success = false;
        $message = "购买失败: " .$e->getMessage();
    }
    
    // 显示结果
    header('Content-Type: application/json');
    echo json_encode(array('success' => $success, 'message' =>$message));
    exit;
}
?>