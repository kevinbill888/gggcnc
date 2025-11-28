<?php
require_once 'config.php';

header('Content-Type: application/json');

$post_no = $_GET['post_no'] ?? '';

if (empty($post_no)) {
    echo json_encode(['ok' => false, 'msg' => '参数错误']);
    exit;
}

try {
    // 尝试从user_postbox表获取
    $stmt = $db_character->query("
        SELECT p.*, c.character_name, i.item_name 
        FROM user_postbox p 
        LEFT JOIN user_character c ON p.sell_character_no = c.character_no 
        LEFT JOIN web_items i ON p.wIndex = i.wIndex 
        WHERE p.post_no = '$post_no'
    ");
    $item = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // 如果没找到，尝试从USER_POSTBOX表获取
    if (!$item) {
        $stmt = $db_market->query("
            SELECT p.*, c.character_name, i.item_name 
            FROM USER_POSTBOX p 
            LEFT JOIN USER_CHARACTER c ON p.sell_character_no = c.character_no 
            LEFT JOIN web_items i ON p.wIndex = i.wIndex 
            WHERE p.post_no = '$post_no'
        ");
        $item = $stmt->fetch(PDO::FETCH_ASSOC);
    }
    
    if (!$item) {
        echo json_encode(['ok' => false, 'msg' => '物品不存在']);
        exit;
    }
    
    // 使用Char.asp的算法解析物品属性
    $item_details = BuildItemDetailsJson($item['item_name'], $item['info'], $item['byHeader']);
    $item_data = json_decode($item_details, true);
    
    // 生成HTML
    $html = '
        <div class="item-detail">
            <div class="detail-row">
                <span class="detail-label">物品名称：</span>
                <span class="detail-value">' . htmlspecialchars($item['item_name']) . '</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">卖家：</span>
                <span class="detail-value">' . mask_role_name($item['character_name']) . '</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">价格：</span>
                <span class="detail-value price">' . number_format($item['include_dil']) . ' 金币</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">数量：</span>
                <span class="detail-value">' . $item_data['qty'] . '</span>
            </div>
            <div class="detail-attributes">
                <h4>物品属性</h4>
                <div class="attr-list">';
    
    // 显示属性
    if (!empty($item_data['attrs'])) {
        foreach ($item_data['attrs'] as $attr) {
            $html .= '<span class="attr-item">' . htmlspecialchars($attr['desc']) . ' +' . $attr['value'] . '</span>';
        }
    } else {
        $html .= '<span class="attr-empty">无属性</span>';
    }
    
    $html .= '
                </div>
            </div>
            <div class="detail-sockets">
                <h4>镶嵌宝石</h4>
                <div class="socket-list">';
    
    // 显示镶嵌
    if (!empty($item_data['sockets'])) {
        foreach ($item_data['sockets'] as $socket) {
            $html .= '<span class="socket-item">' . htmlspecialchars($socket['name']) . ' +' . htmlspecialchars($socket['value']) . '</span>';
        }
    } else {
        $html .= '<span class="socket-empty">无镶嵌</span>';
    }
    
    $html .= '
                </div>
            </div>
        </div>
    ';
    
    echo json_encode(['ok' => true, 'html' => $html]);
    
} catch (Exception $e) {
    echo json_encode(['ok' => false, 'msg' => '获取详情失败：' . $e->getMessage()]);
}
?>
