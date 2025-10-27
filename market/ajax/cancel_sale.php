<?php
// ajax/cancel_sale.php - 取回寄售物品
require_once '../../config.php';
require_once '../../auth.php';
require_once '../../db.php';

if (!is_logged_in()) {
    echo json_encode(['success' => false, 'message' => '未登录']);
    exit;
}

if ($_POST['post_no']) {
    $server_id = $_SESSION['server_id'];
    $user_no = $_SESSION['user_no'];
    $post_no = $_POST['post_no'];
    
    $db_character = get_db($server_id, 'character');
    
    try {
        // 验证物品归属
        $item = $db_character->fetch("
            SELECT p.*, c.user_no 
            FROM USER_POSTBOX p
            LEFT JOIN user_character c ON p.sell_character_no = c.character_no
            WHERE p.post_no = ? AND c.user_no = ?
        ", [$post_no, $user_no]);
        
        if (!$item) {
            throw new Exception('物品不存在或不属于您');
        }
        
        // 开始事务
        $db_character->beginTransaction();
        
        // 将物品放回仓库
        $db_character->exec("
            INSERT INTO user_storage (
                character_no, line_no, wIndex, byHeader, info,
                dwSerialNumber, upt_time
            ) VALUES (?, ?, ?, ?, ?, ?, GETDATE())
        ", [
            $item['sell_character_no'],
            0, // 需要找空位
            $item['wIndex'],
            $item['byHeader'],
            $item['info'],
            $item['dwSerialNumber']
        ]);
        
        // 删除寄售记录
        $db_character->exec("
            DELETE FROM USER_POSTBOX 
            WHERE post_no = ?
        ", [$post_no]);
        
        $db_character->commit();
        
        echo json_encode(['success' => true, 'message' => '物品已取回到仓库']);
        
    } catch (Exception $e) {
        $db_character->rollBack();
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
}
