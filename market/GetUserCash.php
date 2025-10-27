<?php
require_once '../auth.php';

if (!is_logged_in()) {
    echo '0';
    exit;
}

$server_id = get_current_server_id();
$db_cash = get_db($server_id, 'cash');

$cash = $db_cash->fetch(
    "SELECT amount FROM user_cash WHERE user_no = ?",
    [$_SESSION['user_no']]
);

echo $cash ? $cash['amount'] : '0';
?>
