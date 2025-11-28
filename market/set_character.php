<?php
require_once 'config.php';

header('Content-Type: text/plain');

session_start();
$character_id = $_POST['character_id'] ?? '';
$user_no = $_SESSION['user_no'] ?? '';

if (empty($character_id) || empty($user_no)) {
    echo 'ERROR';
    exit;
}

try {
    // 验证角色是否属于当前用户
    $stmt = $db_character->prepare("
        SELECT COUNT(*) as cnt 
        FROM user_character 
        WHERE user_no = ? AND character_no = ?
    ");
    $stmt->execute(array($user_no, $character_id));
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($result['cnt'] > 0) {
        $_SESSION['current_character_id'] = $character_id;
        echo 'OK';
    } else {
        echo 'ERROR';
    }
} catch (Exception $e) {
    echo 'ERROR';
}
?>
