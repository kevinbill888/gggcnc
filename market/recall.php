<?php
require_once '../auth.php';

if (!is_logged_in()) {
    echo json_encode(['success' => false, 'message' => '请先登录']);
    exit;
}

$post_no = $_POST['post_no'] ?? '';
$character_no = $_POST['character_no'] ?? '';

if (empty($post_no) || empty($character_no)) {
    echo json_encode(['success' => false, 'message' => '参数不完整']);
    exit;
}

$server_id = get_current_server_id();

try {
    $db_character = get_db($server_id, 'character');
    $db_account = get_db($server_id, 'account');
    $db_cash = get_db($server_id, 'cash');
    
    $db_character->beginTransaction();
    $db_account->beginTransaction();
    $db_cash->beginTransaction();
    
    // 查询寄售记录
    $post = $db_character->fetch(
        "SELECT * FROM USER_POSTBOX WHERE post_no = ? AND character_no = 'E24080630000000032'",
        [$post_no]
    );
    
    if (!$post) {
        throw new Exception('该装备已被购买或不存在');
    }
    
    $is_self_recall = ($post['sell_character_no'] === $character_no);
    
    // 验证角色归属
    $character = $db_character->fetch(
        "SELECT user_no, character_name FROM user_character WHERE character_no = ? AND user_no = ?",
        [$character_no, $_SESSION['user_no']]
    );
    
    if (!$character) {
        throw new Exception('角色不属于您');
    }
    
    $user_no = $character['user_no'];
    $character_name = $character['character_name'];
    
    // 非本人购买需要检查B币
    if (!$is_self_recall) {
        $cash = $db_cash->fetch(
            "SELECT b_amount FROM user_cash WHERE user_no = ?",
            [$user_no]
        );
        
        if (!$cash || $cash['b_amount'] < $post['include_dil']) {
            throw new Exception("B币不足！需要：{$post['include_dil']}，当前：" . ($cash['b_amount'] ?? 0));
        }
        
        // 扣除B币
        $db_cash->exec(
            "UPDATE user_cash SET b_amount = b_amount - ? WHERE user_no = ?",
            [$post['include_dil'], $user_no]
        );
        
        // 获取卖家信息
        $seller = $db_character->fetch(
            "SELECT user_no, character_name FROM user_character WHERE character_no = ?",
            [$post['sell_character_no']]
        );
        
        if ($seller) {
            $seller_amount = intval($post['include_dil'] * 0.8);
            $db_cash->exec(
                "UPDATE user_cash SET amount = amount + ? WHERE user_no = ?",
                [$seller_amount, $seller['user_no']]
            );
        }
    }
    
    // 更新邮件信息
    $from_char_nm = $is_self_recall ? '系统管理员' : '交易市场';
    $post_title = $is_self_recall ? '装备取回成功' : '恭喜:寄售购买成功';
    $body_text = $is_self_recall 
        ? '您已成功取回自己寄售的装备，请在90天内取出，否则自动删除物品无法恢复'
        : '您已成功购买此装备，请在90天内取出，否则自动删除物品无法恢复';
    
    $db_character->exec(
        "UPDATE USER_POSTBOX 
         SET character_no = ?, from_char_nm = ?, post_title = ?, body_text = ?, 
             state_tag = 0, ipt_time = GETDATE(), expire_time = DATEADD(day, 90, GETDATE())
         WHERE post_no = ?",
        [$character_no, $from_char_nm, $post_title, $body_text, $post_no]
    );
    
    $db_character->commit();
    $db_account->commit();
    $db_cash->commit();
    
    $success_message = $is_self_recall 
        ? '装备取回成功！装备已发送到您的邮箱，请前往游戏邮箱查收。'
        : "装备购买成功！已扣除{$post['include_dil']}B币（含20%手续费），装备已发送到您的邮箱，请前往游戏邮箱查收。";
    
    echo json_encode([
        'success' => true,
        'message' => $success_message,
        'redirect' => '1.php'
    ]);
    
} catch (Exception $e) {
    $db_character->rollBack();
    $db_account->rollBack();
    $db_cash->rollBack();
    
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
