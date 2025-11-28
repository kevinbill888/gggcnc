<?php
session_start();

header('Content-Type: application/json; charset=utf-8');

$x = (int)($_POST['x'] ?? 0);
$y = (int)($_POST['y'] ?? 0);

if (isset($_SESSION['click_captcha'])) {
    $captcha = $_SESSION['click_captcha'];
    
    // 检查时间
    if (time() - $captcha['time'] < 300) {
        // 获取目标数字位置
        $targetNum = $captcha['numbers'][$captcha['target_index']];
        $targetX = $targetNum['x'] + 25; // 数字中心
        $targetY = $targetNum['y'] + 12; // 数字中心
        
        $distance = sqrt(pow($x - $targetX, 2) + pow($y - $targetY, 2));
        
        // 允许40像素的误差
        if ($distance <= 40) {
            $_SESSION['captcha_verified'] = true;
            unset($_SESSION['click_captcha']);
            echo json_encode(['success' => true]);
            exit;
        }
    }
}

echo json_encode(['success' => false]);
?>
