<?php
require_once 'config.php';

// 检查是否为POST请求
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: sell.php');
    exit;
}

// 获取表单数据
$line_no = intval($_POST['line_no']);
$character_no = $_POST['character_no'];
$price = intval($_POST['price']);
$description = trim($_POST['description'] ?? '');

// 验证数据
if ($line_no <= 0 || $price <= 0 || $price > 99999999) {
    die('<script>alert("参数错误"); history.back();</script>');
}

try {
    // 开始事务
    $db_character->beginTransaction();
    
    // 获取仓库物品信息
    $stmt = $db_character->prepare("
        SELECT * FROM user_storage 
        WHERE character_no = ? AND line_no = ?
    ");
    $stmt->execute(array($character_no, $line_no));
    $item = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$item) {
        throw new Exception('物品不存在');
    }
    
    // 生成唯一寄售编号
    $post_no = generate_unique_sn();
    
    // 添加到市场表
    $stmt = $db_market->prepare("
        INSERT INTO USER_POSTBOX (
            character_no, sell_character_no, post_no, wIndex, 
            dwSerialNumber, byHeader, info, include_dil, 
            from_char_nm, post_title, body_text, 
            state_tag, item_tag, dil_tag, ipt_time, expire_time
        ) VALUES (
            'admin_character', ?, ?, ?, ?, ?, ?, ?, ?, 
            ?, ?, ?, ?, ?, GETDATE(), DATEADD(day, 90, GETDATE())
        )
    ");
    
    $stmt->execute(array(
        $character_no,  // sell_character_no
        $character_no,  // character_no (admin_character)
        $post_no,
        $item['wIndex'],
        $item['dwSerialNumber'],
        $item['byHeader'],
        $item['info'],
        $price,
        '自助寄售',
        '寄售装备',
        $description ?: '90天内未出售请自行取回,否则自动删除',
        0, // state_tag
        1, // item_tag
        0, // dil_tag
    ));
    
    // 从仓库删除物品
    $stmt = $db_character->prepare("
        DELETE FROM user_storage 
        WHERE character_no = ? AND line_no = ?
    ");
    $stmt->execute(array($character_no, $line_no));
    
    // 提交事务
    $db_character->commit();
    
    // 记录日志
    $log_text = "寄售物品ID:{$item['wIndex']} 价格:{$price}";
    $stmt = $db_account->prepare("
        INSERT INTO adminlog (admin, datetime, ip, username, adminlog, logtype) 
        VALUES (?, GETDATE(), ?, ?, ?, 3)
    ");
    $stmt->execute(array(
        $_SESSION['username'],
        $_SERVER['REMOTE_ADDR'],
        $character_no,
        $log_text
    ));
    
    echo '<script>alert("装备寄售成功！90天内有效期，未出售请自行取回。"); location.href="index.php";</script>';
    
} catch (Exception $e) {
    // 回滚事务
    if (isset($db_character)) {
        $db_character->rollBack();
    }
    
    echo '<script>alert("寄售失败：' . $e->getMessage() . '"); history.back();</script>';
}
?>
