<?php
// 开启session
session_start();

// 引入配置
require_once '../../config.php';

// 设置响应头
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

try {
    // 清除所有session数据
    $_SESSION = array();
    
    // 删除session cookie
    if (ini_get("session.use_cookies")) {
        $params = session_get_cookie_params();
        setcookie(session_name(), '', time() - 42000,
            $params["path"], $params["domain"],
            $params["secure"], $params["httponly"]
        );
    }
    
    // 销毁session
    session_destroy();
    
    // 返回成功
    echo json_encode(['success' => true, 'message' => '退出成功']);
    
} catch (Exception $e) {
    // 返回错误
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>
