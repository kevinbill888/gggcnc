<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'config.php';

// 检查session是否已启动
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// 生成验证码
function generateCode() {
    return strval(rand(1000, 9999));
}

// 初始化验证码
if (!isset($_SESSION['code'])) {
    $_SESSION['code'] = generateCode();
}

// 处理登录
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = trim($_POST['username']);
    $password = trim($_POST['password']);
    $code = trim($_POST['code']);
    
    echo "<h3>调试信息：</h3>";
    echo "<p>用户名: " . htmlspecialchars($username) . "</p>";
    echo "<p>密码: " . htmlspecialchars($password) . "</p>";
    echo "<p>验证码: " . htmlspecialchars($code) . "</p>";
    echo "<p>Session验证码: " . ($_SESSION['code'] ?? '未设置') . "</p>";
    
    // 验证码检查
    if (!isset($_SESSION['code']) || $code !== $_SESSION['code']) {
        echo "<p style='color: red;'>验证码错误</p>";
    } else {
        echo "<p style='color: green;'>验证码正确</p>";
        
        // 尝试数据库查询
        try {
            // 检查表是否存在
            $stmt = $conn_c->query("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'");
            $tables = $stmt->fetchAll(PDO::FETCH_COLUMN);
            echo "<h4>数据库表列表：</h4>";
            echo "<pre>" . print_r($tables, true) . "</pre>";
            
            // 查找用户相关表
            $user_tables = array_filter($tables, function($table) {
                return strpos(strtolower($table), 'user') !== false;
            });
            echo "<h4>用户相关表：</h4>";
            echo "<pre>" . print_r($user_tables, true) . "</pre>";
            
            // 尝试查询用户
            if (!empty($user_tables)) {
                $table = reset($user_tables);
                echo "<h4>尝试查询表: $table</h4>";
                
                $stmt = $conn_c->prepare("SELECT TOP 5 * FROM $table");
                $stmt->execute();
                $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
                echo "<pre>" . print_r($users, true) . "</pre>";
                
                // 尝试登录
                $stmt = $conn_c->prepare("SELECT * FROM $table WHERE username = ?");
                $stmt->execute(array($username));
                $user = $stmt->fetch(PDO::FETCH_ASSOC);
                
                if ($user) {
                    echo "<p style='color: green;'>找到用户:</p>";
                    echo "<pre>" . print_r($user, true) . "</pre>";
                    
                    // 检查密码
                    if ($user['password'] === $password) {
                        echo "<p style='color: green;'>密码匹配！</p>";
                    } else {
                        echo "<p style='color: red;'>密码不匹配</p>";
                        echo "<p>输入密码: $password</p>";
                        echo "<p>数据库密码: " . $user['password'] . "</p>";
                    }
                } else {
                    echo "<p style='color: red;'>未找到用户</p>";
                }
            }
        } catch (Exception $e) {
            echo "<p style='color: red;'>数据库错误: " . $e->getMessage() . "</p>";
        }
    }
    
    // 重新生成验证码
    $_SESSION['code'] = generateCode();
    echo "<p>新的验证码: " . $_SESSION['code'] . "</p>";
} else {
    // 初始化验证码
    if (!isset($_SESSION['code'])) {
        $_SESSION['code'] = generateCode();
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>登录测试</title>
    <style>
        body { font-family: Arial; padding: 20px; }
        .form-group { margin: 10px 0; }
        label { display: inline-block; width: 80px; }
        input { padding: 5px; }
        .code-img { border: 1px solid #ccc; padding: 5px; background: #f0f0f0; }
    </style>
</head>
<body>
    <h1>登录测试页面</h1>
    
    <?php if (!isset($_POST['username'])): ?>
    <p>当前验证码: <strong><?php echo $_SESSION['code']; ?></strong></p>
    <?php endif; ?>
    
    <form method="post">
        <div class="form-group">
            <label>用户名:</label>
            <input type="text" name="username" required>
        </div>
        <div class="form-group">
            <label>密码:</label>
            <input type="password" name="password" required>
        </div>
        <div class="form-group">
            <label>验证码:</label>
            <input type="text" name="code" required>
            <span class="code-img"><?php echo $_SESSION['code']; ?></span>
        </div>
        <div class="form-group">
            <button type="submit">登录测试</button>
            <button type="button" onclick="location.reload()">刷新验证码</button>
        </div>
    </form>
    
    <hr>
    <h3>数据库连接测试：</h3>
    <?php
    if ($conn_c) {
        echo "<p style='color: green;'>✓ character数据库连接成功</p>";
    } else {
        echo "<p style='color: red;'>✗ character数据库连接失败</p>";
    }
    
    if ($conn) {
        echo "<p style='color: green;'>✓ account数据库连接成功</p>";
    } else {
        echo "<p style='color: red;'>✗ account数据库连接失败</p>";
    }
    
    if ($conn_b) {
        echo "<p style='color: green;'>✓ cash数据库连接成功</p>";
    } else {
        echo "<p style='color: red;'>✗ cash数据库连接失败</p>";
    }
    ?>
</body>
</html>
