<?php
// 更新Session中的角色信息
session_start();
require_once '../config.php';
require_once '../auth.php';

if (!is_logged_in()) {
    echo json_encode(['success' => false, 'message' => '未登录']);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $character_no = $_POST['character_no'] ?? '';
    $character_name = $_POST['character_name'] ?? '';
    
    if ($character_no && $character_name) {
        $_SESSION['current_character_no'] = $character_no;
        $_SESSION['current_character_name'] = $character_name;
        echo json_encode(['success' => true]);
    } else {
        echo json_encode(['success' => false, 'message' => '参数错误']);
    }
} else {
    echo json_encode(['success' => false, 'message' => '请求方式错误']);
}
