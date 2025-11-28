<?php
session_start();
$_SESSION['code'] = strval(rand(1000, 9999));
echo $_SESSION['code'];
?>
