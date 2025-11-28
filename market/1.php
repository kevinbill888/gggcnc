<?php
// gift_test.php - 礼包领取测试页面
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once '../config.php';
require_once '../auth.php';
require_once '../db.php';

// 检查登录状态
if (!is_logged_in()) {
    echo json_encode(['success' => false, 'message' => '未登录']);
    exit;
}

$server_id = $_SESSION['server_id'];
$user_no = $_SESSION['user_no'];

// 测试数据库连接
try {
    $db_character = get_db($server_id, 'character');
    echo json_encode(['success' => true, 'message' => '数据库连接成功']);
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => '数据库连接失败: ' . $e->getMessage()]);
    exit;
}

// 测试查询USER_PROFILE表
try {
    $stmt = $db_character->prepare("SELECT * FROM USER_PROFILE WHERE user_no = ?");
    $stmt->execute([$user_no]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($row) {
        echo json_encode([
            'success' => true, 
            'message' => '找到记录',
            'data' => $row
        ]);
    } else {
        echo json_encode([
            'success' => true, 
            'message' => '未找到记录，准备创建'
        ]);
    }
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => '查询失败: ' . $e->getMessage()]);
    exit;
}

// 测试插入记录
try {
    $stmt = $db_character->prepare("
        INSERT INTO USER_PROFILE (user_no, isGift) VALUES (?, ?)
    ");
    $result = $stmt->execute([$user_no, 0]);
    
    if ($result) {
        echo json_encode([
            'success' => true, 
            'message' => '插入成功'
        ]);
    } else {
        echo json_encode([
            'success' => false, 
            'message' => '插入失败'
        ]);
    }
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => '插入失败: ' . $e->getMessage()]);
    exit;
}

// 测试更新记录
try {
    $stmt = $db_character->prepare("
        UPDATE USER_PROFILE SET isGift = ? WHERE user_no = ?
    ");
    $result = $stmt->execute([1, $user_no]);
    
    if ($result) {
        echo json_encode([
            'success' => true, 
            'message' => '更新成功'
        ]);
    } else {
        echo json_encode([
            'success' => false, 
            'message' => '更新失败'
        ]);
    }
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => '更新失败: ' . $e->getMessage()]);
    exit;
}
?>
