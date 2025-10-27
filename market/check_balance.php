<?php
require_once 'config.php';

header('Content-Type: application/json');

try {
    // 获取用户B币余额
    $stmt = $db_cash->prepare("SELECT b_amount FROM user_cash WHERE user_no = ?");
    $stmt->execute(array($user_no));
    $balance = $stmt->fetch(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'ok' => true,
        'b_coin' => $balance['b_amount'] ?? 0
    ]);
} catch (Exception $e) {
    echo json_encode(['ok' => false, 'msg' => '获取余额失败']);
}
?>
