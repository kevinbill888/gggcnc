<?php
// 创建 pay/loginout.php
session_start();

// 销毁所有会话数据
session_destroy();

// 清除会话cookie
if (isset($_COOKIE[session_name()])) {
    setcookie(session_name(), '', time() - 3600, '/');
}

// 跳转到登录页面
header('Location: ../login.php');
exit;
?>
