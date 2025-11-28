<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

// 记录所有错误
error_log("=== 寄售请求开始 ===");
error_log("POST数据: " . print_r($_POST, true));

require_once '../config.php';
require_once '../auth.php';
require_once '../db.php';

header('Content-Type: application/json');

try {
    if (!is_logged_in()) {
        throw new Exception('未登录');
    }
    
    $server_id = $_SESSION['server_id'];
    $user_no = $_SESSION['user_no'];
    $character_no = $_POST['character_no'] ?? '';
    $line_no = $_POST['line_no'] ?? '';
    $price = $_POST['price'] ?? '';
    
    error_log("参数: server_id=$server_id, user_no=$user_no, character_no=$character_no, line_no=$line_no, price=$price");
    
    if (!$character_no || !$line_no || !$price) {
        throw new Exception('参数不完整');
    }
    
    $db_character = get_db($server_id, 'character');
    
    // 验证角色归属
    $char = $db_character->fetch("
        SELECT user_no FROM user_character 
        WHERE character_no = ? AND user_no = ?
    ", [$character_no, $user_no]);
    
    if (!$char) {
        throw new Exception('角色不属于您');
    }
    
    // 获取仓库物品
    $item = $db_character->fetch("
        SELECT wIndex, dwSerialNumber, byHeader, info 
        FROM user_storage 
        WHERE character_no = ? AND line_no = ?
    ", [$character_no, $line_no]);
    
    if (!$item) {
        throw new Exception('仓库中不存在该物品');
    }
    
    error_log("找到物品: " . print_r($item, true));
    
    // 生成唯一编号
    $post_no = date('YmdHis') . substr(md5(uniqid()), 0, 6);
    
    // 开始事务
    $db_character->beginTransaction();
    
    // 简化插入，避免二进制数据问题
    $sql = "INSERT INTO USER_POSTBOX (
        character_no, post_no, sell_character_no, wIndex, 
        dwSerialNumber, byHeader, info, include_dil, 
        from_char_nm, post_sort, post_title, body_text,
        state_tag, item_tag, dil_tag, ipt_time, expire_time
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, GETDATE(), DATEADD(day, 90, GETDATE()))";
    
    // 处理可能为空的字段
    $dwSerial = $item['dwSerialNumber'] ?? '00000000000000000000000000000000000';
    $info = $item['info'] ?? '';
    
    $stmt = $db_character->prepare($sql);
    
    // 手动绑定参数
    $stmt->bindValue(1, 'E24080630000000032');
    $stmt->bindValue(2, $post_no);
    $stmt->bindValue(3, $character_no);
    $stmt->bindValue(4, $item['wIndex']);
    $stmt->bindValue(5, $dwSerial);
    $stmt->bindValue(6, $item['byHeader']);
    $stmt->bindValue(7, $info, PDO::PARAM_LOB);
    $stmt->bindValue(8, $price);
    $stmt->bindValue(9, '出售道具');
    $stmt->bindValue(10, 0);
    $stmt->bindValue(11, '自助寄售道具');
    $stmt->bindValue(12, '90天内未出售请自行取回,否则自动删除');
    $stmt->bindValue(13, 0);
    $stmt->bindValue(14, 1);
    $stmt->bindValue(15, 0);
    
    $result = $stmt->execute();
    
    if (!$result) {
        $error = $stmt->errorInfo();
        throw new Exception('插入失败: ' . $error[2]);
    }
    
    // 从仓库删除
    $db_character->exec("
        DELETE FROM user_storage 
        WHERE character_no = ? AND line_no = ?
    ", [$character_no, $line_no]);
    
    // 提交事务
    $db_character->commit();
    
    error_log("寄售成功");
    echo json_encode(['success' => true, 'message' => '寄售成功！']);
    
} catch (Exception $e) {
    if (isset($db_character)) {
        $db_character->rollBack();
    }
    error_log("寄售失败: " . $e->getMessage());
    error_log("错误追踪: " . $e->getTraceAsString());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
