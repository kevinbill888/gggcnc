<?php
require_once '../config.php';
require_once '../db.php';

// 记录日志
$log_file = __DIR__ . '/clean_orders.log';
$log_data = "=== " . date('Y-m-d H:i:s') . " ===\n";

// 清理5分钟前的待支付订单
foreach (get_all_servers() as $server) {
    $db_account = get_db($server['id'], 'account');
    
    try {
        // 删除5分钟前的待支付订单
        $sql = "DELETE FROM PayLog WHERE trade_status = 0 AND PayTime < DATEADD(minute, -5, GETDATE())";
        $stmt = $db_account->query($sql);
        $count = $stmt->rowCount();
        
        if ($count > 0) {
            $log_data .= "服务器 " . $server['name'] . ": 删除了 $count 条待支付订单\n";
        }
    } catch (Exception $e) {
        $log_data .= "服务器 " . $server['name'] . " 清理失败: " . $e->getMessage() . "\n";
    }
}

file_put_contents($log_file, $log_data, FILE_APPEND | LOCK_EX);
echo "清理完成\n";
?>
