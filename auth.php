<?php

require_once 'db.php';

// 启动会话
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

/**
 * 验证密码（支持明文和MD5）
 * @param string $input_password 输入的密码
 * @param string $stored_password 数据库存储的密码
 * @return bool
 */
function verify_password($input_password, $stored_password) {
    // 如果存储的是32位，可能是MD5
    if (strlen($stored_password) == 32) {
        return md5($input_password) === $stored_password;
    }
    // 否则直接比较（明文）
    return $input_password === $stored_password;
}

/**
 * 用户登录
 * @param string $username 用户名
 * @param string $password 密码
 * @param string $server_id 服务器ID
 * @return array 登录结果
 */
function login($username, $password, $server_id) {
    $db_account = get_db($server_id, 'account');
    
    // 查询用户
    $user = $db_account->query(
        "SELECT user_no, user_id, user_pwd, login_flag FROM USER_PROFILE WHERE user_id = ?", 
        array($username)
    )->fetch(PDO::FETCH_ASSOC);
    
    if (!$user) {
        return array('success' => false, 'message' => '用户名不存在');
    }
    
    // 使用新的密码验证函数
    if (!verify_password($password, $user['user_pwd'])) {
        return array('success' => false, 'message' => '密码错误');
    }
    
    // 检查账号状态
    if ($user['login_flag'] == 1) {
        return array('success' => false, 'message' => '账号已被封禁');
    }
    
    // 设置会话
    $_SESSION['user_no'] = $user['user_no'];
    $_SESSION['user_id'] = $user['user_id'];
    $_SESSION['server_id'] = $server_id;
    $_SESSION['logged_in'] = true;
    $_SESSION['login_time'] = time();
    
    // 更新最后登录时间
    $db_account->query(
        "UPDATE USER_PROFILE SET login_time = GETDATE(), login_tag = 'Y' WHERE user_no = ?",
        array($user['user_no'])
    );
    
    return array('success' => true, 'message' => '登录成功');
}

/**
 * 用户注册
 * @param array $data 注册数据
 * @param string $server_id 服务器ID
 * @return array 注册结果
 */
function register($data, $server_id) {
    $db_account = get_db($server_id, 'account');
    
    // 检查用户名是否已存在
    $exists = $db_account->query(
        "SELECT user_id FROM USER_PROFILE WHERE user_id = ?",
        array($data['username'])
    )->fetch(PDO::FETCH_ASSOC);
    
    if ($exists) {
        return array('success' => false, 'message' => '用户名已存在');
    }
    
    // 生成用户编号
    $user_no = generateUserNo($server_id);
    
    // 密码使用MD5加密（因为现有系统使用MD5）
    $password = md5($data['password']);
    
    // 插入用户数据
    $insert_data = array(
        'user_no' => $user_no,
        'user_id' => $data['username'],
        'user_pwd' => $password,
        'user_mail' => $data['email'] ?? '',
        'user_qq' => $data['qq'] ?? '',
        'reg_time' => date('Y-m-d H:i:s'),
        'regip' => $_SERVER['REMOTE_ADDR'],
        'login_flag' => 0,
        'login_tag' => 'N',
        'user_type' => '1',
        'server_id' => $server_id,
        'auth_tag' => 0,
        'isGift' => 0
    );
    
    $columns = implode(',', array_keys($insert_data));
    $placeholders = implode(',', array_fill(0, count($insert_data), '?'));
    $sql = "INSERT INTO USER_PROFILE ($columns) VALUES ($placeholders)";
    
    try {
        $db_account->query($sql, array_values($insert_data));
        
        // 创建VIP记录
        $db_account->insert('User_VIP', array(
            'user_no' => $user_no,
            'vip_level' => 0,
            'total_recharge' => 0,
            'update_time' => date('Y-m-d H:i:s')
        ));
        
        return array('success' => true, 'message' => '注册成功');
    } catch (Exception $e) {
        return array('success' => false, 'message' => '注册失败：' . $e->getMessage());
    }
}

/**
 * 生成用户编号
 */
function generateUserNo($server_id) {
    $db_account = get_db($server_id, 'account');
    
    do {
        $user_no = 'U' . $server_id . date('Ymd') . rand(100000, 999999);
        $exists = $db_account->query(
            "SELECT user_no FROM USER_PROFILE WHERE user_no = ?",
            array($user_no)
        )->fetch(PDO::FETCH_ASSOC);
    } while ($exists);
    
    return $user_no;
}

/**
 * 检查用户是否登录
 * @return bool
 */
function is_logged_in() {
    return isset($_SESSION['logged_in']) && $_SESSION['logged_in'] === true;
}

/**
 * 获取当前用户信息
 * @return array|null
 */
function get_logged_user() {
    if (!is_logged_in()) {
        return null;
    }
    
    $server_id = $_SESSION['server_id'];
    $db_account = get_db($server_id, 'account');
    
    return $db_account->query(
        "SELECT * FROM USER_PROFILE WHERE user_no = ?",
        array($_SESSION['user_no'])
    )->fetch(PDO::FETCH_ASSOC);
}

/**
 * 用户登出
 */
function logout() {
    // 清除会话
    $_SESSION = array();
    
    // 删除会话cookie
    if (ini_get("session.use_cookies")) {
        $params = session_get_cookie_params();
        setcookie(session_name(), '', time() - 42000,
            $params["path"], $params["domain"],
            $params["secure"], $params["httponly"]
        );
    }
    
    // 销毁会话
    session_destroy();
}

/**
 * 需要登录才能访问
 */
function require_login() {
    if (!is_logged_in()) {
        // 保存当前URL，登录后跳转回来
        $_SESSION['redirect_url'] = $_SERVER['REQUEST_URI'];
        header('Location: login.php');
        exit;
    }
}

/**
 * 获取用户VIP信息
 */
function get_user_vip($user_no, $server_id) {
    $db_account = get_db($server_id, 'account');
    
    $vip = $db_account->query(
        "SELECT * FROM User_VIP WHERE user_no = ?",
        array($user_no)
    )->fetch(PDO::FETCH_ASSOC);
    
    if (!$vip) {
        $vip = array('vip_level' => 0, 'total_recharge' => 0);
    }
    
    return $vip;
}

/**
 * 获取当前用户的服务器ID
 */
function get_current_server_id() {
    return $_SESSION['server_id'] ?? DEFAULT_SERVER_ID;
}
?>
