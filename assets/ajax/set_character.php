<?php
// set_character.php - 设置当前角色
require_once '../../config.php';
require_once '../../auth.php';
require_once '../../db.php';

header('Content-Type: application/json');

if (!is_logged_in()) {
    echo json_encode(['success' => false, 'message' => '未登录']);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'message' => '请求方式错误']);
    exit;
}

$character_no = $_POST['character_no'] ?? '';
$server_id = $_SESSION['server_id'];
$user_no = $_SESSION['user_no'];

if (empty($character_no)) {
    echo json_encode(['success' => false, 'message' => '角色编号不能为空']);
    exit;
}

try {
    // 验证角色是否属于当前用户
    $db_character = get_db($server_id, 'character');
    $character = $db_character->fetch("
        SELECT character_no, character_name 
        FROM user_character 
        WHERE character_no = ? AND user_no = ?
    ", [$character_no, $user_no]);
    
    if (!$character) {
        echo json_encode(['success' => false, 'message' => '角色不存在或不属于您']);
        exit;
    }
    
    // 设置当前角色到session
    $_SESSION['current_character_no'] = $character_no;
    $_SESSION['current_character_name'] = $character['character_name'];
    
    echo json_encode([
        'success' => true, 
        'message' => '角色切换成功',
        'character' => [
            'no' => $character_no,
            'name' => $character['character_name']
        ]
    ]);
    
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => '系统错误：' . $e->getMessage()]);
}
