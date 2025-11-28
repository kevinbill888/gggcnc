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

// 处理注册
if ($_POST) {
    $data = array(
        'username' => trim($_POST['username']),
        'password' => $_POST['password'],
        'password_confirm' => $_POST['password_confirm'],
        'email' => trim($_POST['email']),
        'qq' => trim($_POST['qq'])
    );
    $server_id = $_POST['server_id'];
    
    // 验证
    if (empty($server_id)) {
        $error = '请选择服务器';
    } elseif (empty($data['username'])) {
        $error = '请输入用户名';
    } elseif (strlen($data['username']) < 3 || strlen($data['username']) > 20) {
        $error = '用户名长度为3-20个字符';
    } elseif (empty($data['password'])) {
        $error = '请输入密码';
    } elseif (strlen($data['password']) < 6) {
        $error = '密码至少6个字符';
    } elseif ($data['password'] !== $data['password_confirm']) {
        $error = '两次输入的密码不一致';
    } elseif (!empty($data['email']) && !filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
        $error = '邮箱格式不正确';
    } else {
        // 修复：传递2个参数（data数组和server_id）
        $result = register($data, $server_id);
        if ($result['success']) {
            header('Location: login.php?registered=1');
            exit;
        } else {
            $error = $result['message'];
        }
    }
}
?>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>用户注册 - 游戏官网</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="css/style.css">
</head>
<body class="auth-page">
    <div class="auth-container">
        <div class="auth-box">
            <div class="auth-header">
                <h1><i class="fas fa-gamepad"></i> 游戏官网</h1>
                <p>创建新账号</p>
            </div>
            
            <?php if ($error): ?>
                <div class="alert alert-error">
                    <i class="fas fa-exclamation-circle"></i>
                    <?php echo htmlspecialchars($error); ?>
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
                        用户名 <span class="required">*</span>
                    </label>
                    <input type="text" id="username" name="username" 
                           value="<?php echo htmlspecialchars($_POST['username'] ?? ''); ?>" 
                           required minlength="3" maxlength="20">
                    <small>3-20个字符，支持字母、数字、下划线</small>
                </div>
                
                <div class="form-group">
                    <label for="password">
                        <i class="fas fa-lock"></i>
                        密码 <span class="required">*</span>
                    </label>
                    <input type="password" id="password" name="password" 
                           required minlength="6">
                    <small>至少6个字符</small>
                </div>
                
                <div class="form-group">
                    <label for="password_confirm">
                        <i class="fas fa-lock"></i>
                        确认密码 <span class="required">*</span>
                    </label>
                    <input type="password" id="password_confirm" name="password_confirm" required>
                </div>
                
                <div class="form-group">
                    <label for="email">
                        <i class="fas fa-envelope"></i>
                        邮箱
                    </label>
                    <input type="email" id="email" name="email" 
                           value="<?php echo htmlspecialchars($_POST['email'] ?? ''); ?>">
                </div>
                
                <div class="form-group">
                    <label for="qq">
                        <i class="fab fa-qq"></i>
                        QQ号
                    </label>
                    <input type="text" id="qq" name="qq" 
                           value="<?php echo htmlspecialchars($_POST['qq'] ?? ''); ?>"
                           pattern="[0-9]{5,11}" title="请输入5-11位数字">
                </div>
                
                <div class="form-group">
                    <label class="checkbox">
                        <input type="checkbox" name="agree" required>
                        <span>我已阅读并同意 <a href="#">用户协议</a> 和 <a href="#">隐私政策</a></span>
                    </label>
                </div>
                
                <button type="submit" class="btn btn-primary btn-block">
                    <i class="fas fa-user-plus"></i>
                    立即注册
                </button>
            </form>
            
            <div class="auth-footer">
                <p>已有账号？ <a href="login.php">立即登录</a></p>
            </div>
        </div>
    </div>
</body>
</html>
