<?php
require_once 'include/init.php';

// 检查登录状态
if (!Auth::getInstance()->isLoggedIn()) {
    header('Location: login.php');
    exit;
}

// 创建市场实例
$market = new Market();

// 处理请求
$action = $_GET['action'] ?? 'index';
switch ($action) {
    case 'index':
        $market->index();
        break;
    case 'buy':
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $market->buyItem($_POST['post_no'], $_POST['character_no']);
        }
        break;
    default:
        $market->index();
        break;
}
