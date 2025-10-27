<?php
require_once '../../config.php';
require_once '../../db.php';

header('Content-Type: application/json');

$keyword = $_GET['keyword'] ?? '';
if (strlen($keyword) < 2) {
    echo json_encode(['success' => false, 'message' => '关键词太短']);
    exit;
}

try {
    $db_character = get_db(SERVER_ID, 'character');
    
    $characters = $db_character->fetchAll("
        SELECT TOP 20 
            c.character_no, 
            c.character_name, 
            c.wlevel, 
            u.user_id
        FROM user_character c
        INNER JOIN user_profile u ON c.user_no = u.user_no
        WHERE c.character_name LIKE ? OR u.user_id LIKE ?
        ORDER BY c.wlevel DESC
    ", ["%{$keyword}%", "%{$keyword}%"]);
    
    echo json_encode(['success' => true, 'characters' => $characters]);
    
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>
