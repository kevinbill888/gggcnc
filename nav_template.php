<?php
// 获取当前页面名称，用于高亮显示
$current_page = basename($_SERVER['PHP_SELF']);
?>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo isset($page_title) ? $page_title : '游戏官网'; ?></title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="css/common.css">
    <link rel="stylesheet" href="css/<?php echo isset($page_css) ? $page_css : 'style'; ?>.css">
    <style>
        /* 游戏风格导航栏 - 全局样式 */
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Orbitron', 'Arial', sans-serif;
            background: #0a0a0a;
            color: #fff;
            overflow-x: hidden;
        }
        
        /* 导航栏样式 */
        .gaming-nav {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            background: linear-gradient(180deg, rgba(10,10,10,0.95) 0%, rgba(20,20,20,0.9) 100%);
            backdrop-filter: blur(10px);
            border-bottom: 2px solid #00ffff;
            box-shadow: 0 4px 20px rgba(0,255,255,0.3);
            z-index: 1000;
            transition: all 0.3s ease;
        }
        
        .gaming-nav.scrolled {
            background: rgba(10,10,10,0.98);
            box-shadow: 0 8px 30px rgba(0,255,255,0.5);
        }
        
        .nav-container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 0 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            height: 80px;
        }
        
        .nav-brand {
            display: flex;
            align-items: center;
            gap: 15px;
            text-decoration: none;
            color: #fff;
            font-size: 24px;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: 2px;
            position: relative;
        }
        
        .nav-brand::before {
            content: '';
            position: absolute;
            top: -5px;
            left: -5px;
            right: -5px;
            bottom: -5px;
            background: linear-gradient(45deg, #00ffff, #ff00ff, #00ffff);
            border-radius: 10px;
            opacity: 0;
            z-index: -1;
            transition: opacity 0.3s ease;
            animation: gradient-rotate 3s linear infinite;
        }
        
        @keyframes gradient-rotate {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        
        .nav-brand:hover::before {
            opacity: 0.3;
        }
        
        .nav-brand i {
            font-size: 32px;
            background: linear-gradient(45deg, #00ffff, #ff00ff);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            animation: glow 2s ease-in-out infinite alternate;
        }
        
        @keyframes glow {
            from { filter: drop-shadow(0 0 5px #00ffff); }
            to { filter: drop-shadow(0 0 20px #ff00ff); }
        }
        
        .nav-menu {
            display: flex;
            list-style: none;
            gap: 10px;
            align-items: center;
        }
        
        .nav-item {
            position: relative;
        }
        
        .nav-link {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 12px 20px;
            color: #fff;
            text-decoration: none;
            font-size: 14px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 1px;
            border-radius: 5px;
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
        }
        
        .nav-link::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(0,255,255,0.4), transparent);
            transition: left 0.5s ease;
        }
        
        .nav-link:hover::before {
            left: 100%;
        }
        
        .nav-link:hover {
            background: rgba(0,255,255,0.1);
            color: #00ffff;
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0,255,255,0.3);
        }
        
        .nav-link.active {
            background: linear-gradient(45deg, rgba(0,255,255,0.2), rgba(255,0,255,0.2));
            color: #00ffff;
            box-shadow: 0 0 20px rgba(0,255,255,0.5);
        }
        
        .nav-link i {
            font-size: 16px;
        }
        
        /* 用户信息区域 - 移除了货币余额显示 */
        .nav-user {
            display: flex;
            align-items: center;
        }
        
        .user-menu {
            position: relative;
        }
        
        .user-avatar {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: linear-gradient(45deg, #00ffff, #ff00ff);
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        
        .user-avatar:hover {
            transform: scale(1.1);
            box-shadow: 0 0 20px rgba(0,255,255,0.5);
        }
        
        .user-dropdown {
            position: absolute;
            top: 100%;
            right: 0;
            margin-top: 10px;
            background: rgba(20,20,20,0.95);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(0,255,255,0.3);
            border-radius: 10px;
            min-width: 200px;
            opacity: 0;
            visibility: hidden;
            transform: translateY(-10px);
            transition: all 0.3s ease;
        }
        
        .user-dropdown.active {
            opacity: 1;
            visibility: visible;
            transform: translateY(0);
        }
        
        .dropdown-item {
            display: block;
            padding: 12px 20px;
            color: #fff;
            text-decoration: none;
            transition: all 0.3s ease;
            border-bottom: 1px solid rgba(255,255,255,0.1);
        }
        
        .dropdown-item:last-child {
            border-bottom: none;
        }
        
        .dropdown-item:hover {
            background: rgba(0,255,255,0.1);
            color: #00ffff;
            padding-left: 25px;
        }
        
        .dropdown-item i {
            margin-right: 10px;
            width: 20px;
        }
        
        /* 移动端菜单按钮 */
        .mobile-menu-btn {
            display: none;
            flex-direction: column;
            gap: 4px;
            background: none;
            border: none;
            cursor: pointer;
            padding: 5px;
        }
        
        .mobile-menu-btn span {
            width: 25px;
            height: 3px;
            background: #00ffff;
            transition: all 0.3s ease;
        }
        
        .mobile-menu-btn.active span:nth-child(1) {
            transform: rotate(45deg) translate(5px, 5px);
        }
        
        .mobile-menu-btn.active span:nth-child(2) {
            opacity: 0;
        }
        
        .mobile-menu-btn.active span:nth-child(3) {
            transform: rotate(-45deg) translate(7px, -6px);
        }
        
        /* 主内容区域 */
        .main-content {
            margin-top: 80px;
            min-height: calc(100vh - 80px);
            background: linear-gradient(135deg, #0a0a0a 0%, #1a1a2e 100%);
        }
        
        /* 响应式设计 */
        @media (max-width: 768px) {
            .nav-container {
                padding: 0 15px;
            }
            
            .nav-brand {
                font-size: 20px;
            }
            
            .nav-brand i {
                font-size: 24px;
            }
            
            .nav-menu {
                position: fixed;
                top: 80px;
                left: -100%;
                width: 100%;
                height: calc(100vh - 80px);
                background: rgba(10,10,10,0.98);
                flex-direction: column;
                gap: 0;
                padding: 20px;
                transition: left 0.3s ease;
            }
            
            .nav-menu.active {
                left: 0;
            }
            
            .nav-item {
                width: 100%;
            }
            
            .nav-link {
                width: 100%;
                padding: 15px 20px;
                border-bottom: 1px solid rgba(255,255,255,0.1);
            }
            
            .nav-user {
                margin-top: auto;
                padding-top: 20px;
                border-top: 1px solid rgba(255,255,255,0.1);
            }
            
            .mobile-menu-btn {
                display: flex;
            }
        }
    </style>
</head>
<body>
    <!-- 游戏风格导航栏 -->
    <nav class="gaming-nav" id="gamingNav">
        <div class="nav-container">
            <!-- 品牌Logo -->
            <a href="index.php" class="nav-brand">
                <i class="fas fa-gamepad"></i>
                <span><?php echo SITE_NAME; ?></span>
            </a>
            
            <!-- 导航菜单 -->
            <ul class="nav-menu" id="navMenu">
                <li class="nav-item">
                    <a href="index.php" class="nav-link <?php echo $current_page == 'index.php' ? 'active' : ''; ?>">
                        <i class="fas fa-home"></i>
                        <span>首页</span>
                    </a>
                </li>
                <li class="nav-item">
                    <a href="user_center.php" class="nav-link <?php echo $current_page == 'user_center.php' ? 'active' : ''; ?>">
                        <i class="fas fa-user"></i>
                        <span>用户中心</span>
                    </a>
                </li>
                <li class="nav-item">
                    <a href="pay/index.php" class="nav-link <?php echo strpos($current_page, 'pay/') !== false ? 'active' : ''; ?>">
                        <i class="fas fa-coins"></i>
                        <span>充值中心</span>
                    </a>
                </li>
                <li class="nav-item">
                    <a href="market/index.php" class="nav-link <?php echo strpos($current_page, 'market/') !== false ? 'active' : ''; ?>">
                        <i class="fas fa-store"></i>
                        <span>寄售市场</span>
                    </a>
                </li>
                <li class="nav-item">
                    <a href="ranking.php" class="nav-link <?php echo $current_page == 'ranking.php' ? 'active' : ''; ?>">
                        <i class="fas fa-trophy"></i>
                        <span>排行榜</span>
                    </a>
                </li>
                
                <!-- 用户信息区域 - 移除了货币余额显示 -->
                <div class="nav-user">
                    <div class="user-menu">
                        <div class="user-avatar" onclick="toggleUserMenu()">
                            <i class="fas fa-user"></i>
                        </div>
                        <div class="user-dropdown" id="userDropdown">
                            <a href="user_center.php" class="dropdown-item">
                                <i class="fas fa-user"></i>个人中心
                            </a>
                            <a href="pay/index.php" class="dropdown-item">
                                <i class="fas fa-coins"></i>充值中心
                            </a>
                            <a href="change_password.php" class="dropdown-item">
                                <i class="fas fa-key"></i>修改密码
                            </a>
                            <a href="logout.php" class="dropdown-item">
                                <i class="fas fa-sign-out-alt"></i>退出登录
                            </a>
                        </div>
                    </div>
                </div>
            </ul>
            
            <!-- 移动端菜单按钮 -->
            <button class="mobile-menu-btn" id="mobileMenuBtn" onclick="toggleMobileMenu()">
                <span></span>
                <span></span>
                <span></span>
            </button>
        </div>
    </nav>
    
    <!-- 主内容区域 -->
    <div class="main-content">
