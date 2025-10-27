<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>检查config.php文件</h1>";

// 检查config.php是否存在
if (file_exists('config.php')) {
    echo "<p style='color: green;'>✓ config.php 文件存在</p>";
    
    // 读取config.php内容
    $content = file_get_contents('config.php');
    echo "<h2>config.php 内容（部分）：</h2>";
    echo "<pre style='background: #f0f0f0; padding: 10px;'>";
    // 只显示前1000个字符
    echo htmlspecialchars(substr($content, 0, 1000)) . "...";
    echo "</pre>";
    
    // 检查数据库连接变量
    if (strpos($content, '$conn') !== false) {
        echo "<p style='color: green;'>✓ 找到 \$conn 变量</p>";
    }
    if (strpos($content, '$conn_c') !== false) {
        echo "<p style='color: green;'>✓ 找到 \$conn_c 变量</p>";
    }
    if (strpos($content, '$conn_b') !== false) {
        echo "<p style='color: green;'>✓ 找到 \$conn_b 变量</p>";
    }
    
} else {
    echo "<p style='color: red;'>✗ config.php 文件不存在</p>";
}

// 尝试包含config.php
echo "<h2>尝试加载config.php：</h2>";
try {
    require_once 'config.php';
    echo "<p style='color: green;'>✓ config.php 加载成功</p>";
    
    // 检查全局变量
    $vars = get_defined_vars();
    echo "<h3>已定义的变量：</h3>";
    foreach ($vars as $name => $value) {
        if (strpos($name, 'conn') === 0) {
            echo "<p>\$$name: " . (is_resource($value) || is_object($value) ? "连接对象" : "null/其他") . "</p>";
        }
    }
    
} catch (Exception $e) {
    echo "<p style='color: red;'>✗ config.php 加载失败: " . $e->getMessage() . "</p>";
}
?>
