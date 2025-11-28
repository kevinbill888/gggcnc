<?php
require_once 'auth.php';

// 如果已经登录，跳转到用户中心
if (is_logged_in()) {
    header('Location: user_center.php');
    exit;
}

$error = '';
$success = '';
$servers = get_available_servers();

// 处理登录
if ($_POST) {
    $username = trim($_POST['username']);
    $password = $_POST['password'];
    $server_id = $_POST['server_id'];
    
    // 调试输出（生产环境应删除）
    error_log("登录尝试 - 用户: $username, 服务器: $server_id");
    
    if (empty($username) || empty($password)) {
        $error = '请输入用户名和密码';
    } elseif (empty($server_id)) {
        $error = '请选择服务器';
    } else {
        $result = login($username, $password, $server_id);
        if ($result['success']) {
            // 如果有保存的跳转URL，跳转到那里
            $redirect = $_SESSION['redirect_url'] ?? 'user_center.php';
            unset($_SESSION['redirect_url']);
            header('Location: ' . $redirect);
            exit;
        } else {
            $error = $result['message'];
            // 调试输出
            error_log("登录失败: " . $result['message']);
        }
    }
}

// 处理注册成功后的消息
if (isset($_GET['registered']) && $_GET['registered'] == '1') {
    $success = '注册成功，请登录';
}
?>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>用户登录 - 游戏官网</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="css/style.css">
</head>
<body class="auth-page">
    <div class="auth-container">
        <div class="auth-box">
            <div class="auth-header">
                <h1><i class="fas fa-gamepad"></i> 游戏官网</h1>
                <p>欢迎回来</p>
            </div>
            
            <?php if ($error): ?>
                <div class="alert alert-error">
                    <i class="fas fa-exclamation-circle"></i>
                    <?php echo htmlspecialchars($error); ?>
                </div>
            <?php endif; ?>
            
            <?php if ($success): ?>
                <div class="alert alert-success">
                    <i class="fas fa-check-circle"></i>
                    <?php echo htmlspecialchars($success); ?>
                </div>
            <?php endif; ?>
            
            <form class="auth-form" method="post">
                <div class="form-group">
                    <label for="server_id">
                        <i class="fas fa-server"></i>
                        选择服务器 <span class="required">*</span>
                    </label>
                    <select id="server_id" name="server_id" required>
                        <option value="">请选择服务器</option>
                        <?php foreach ($servers as $server): ?>
                            <option value="<?php echo $server['id']; ?>" 
                                    <?php echo (isset($_POST['server_id']) && $_POST['server_id'] == $server['id']) ? 'selected' : ''; ?>
                                    <?php echo ($server['id'] == DEFAULT_SERVER_ID) ? 'selected' : ''; ?>>
                                <?php echo htmlspecialchars($server['name']); ?>
                                <?php if ($server['status'] == 'hot'): ?>
                                    <span class="server-tag hot">新服</span>
                                <?php elseif ($server['status'] == 'recommend'): ?>
                                    <span class="server-tag recommend">推荐</span>
                                <?php endif; ?>
                            </option>
                        <?php endforeach; ?>
                    </select>
                </div>
                
                <div class="form-group">
                    <label for="username">
                        <i class="fas fa-user"></i>
                        用户名
                    </label>
                    <input type="text" id="username" name="username" 
                           value="<?php echo htmlspecialchars($_POST['username'] ?? ''); ?>" 
                           required autofocus>
                </div>
                
                <div class="form-group">
                    <label for="password">
                        <i class="fas fa-lock"></i>
                        密码
                    </label>
                    <input type="password" id="password" name="password" required>
                </div>
                
                <div class="form-options">
                    <label class="checkbox">
                        <input type="checkbox" name="remember">
                        <span>记住我</span>
                    </label>
                    <a href="#" class="forgot-password">忘记密码？</a>
                </div>
                
                <button type="submit" class="btn btn-primary btn-block">
                    <i class="fas fa-sign-in-alt"></i>
                    登录
                </button>
            </form>
            
            <div class="auth-footer">
                <p>还没有账号？ <a href="register.php">立即注册</a></p>
            </div>
        </div>
    </div>
</body>
</html>
