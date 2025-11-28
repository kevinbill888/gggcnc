<?php
// 检查session是否已经启动
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

require_once '../config.php';
require_once '../auth.php';
require_once '../db.php';
?>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo $page_title ?? '游戏门户网站'; ?></title>
    
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <!-- 自定义样式 -->
    <link rel="stylesheet" href="<?php echo site_url('assets/css/main.css'); ?>">
    <link rel="stylesheet" href="<?php echo site_url('assets/css/navbar.css'); ?>">
    <!-- Loading样式 -->
    <link rel="stylesheet" href="<?php echo site_url('assets/css/loading.css'); ?>">
    <!-- 市场页面专用CSS -->
    <?php if (strpos($_SERVER['REQUEST_URI'], '/market/') !== false): ?>
    <link rel="stylesheet" href="<?php echo site_url('assets/css/market.css'); ?>">
    <?php endif; ?>
    
    <!-- 视频背景样式 -->
    <style>
        /* 背景图片层 */
        .bg-image-layer {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            z-index: -3;
            background-image: url('<?php echo getRandomBackground(); ?>');
            background-size: cover;
            background-position: center;
            background-repeat: no-repeat;
            background-attachment: fixed;
        }
        
        /* 视频背景容器 */
        .video-background {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            z-index: -2;
            overflow: hidden;
            background: transparent;
        }
        
        .video-background video {
            position: absolute;
            top: 50%;
            left: 50%;
            min-width: 100%;
            min-height: 100%;
            width: 100vw;
            height: 100vh;
            transform: translate(-50%, -50%);
            object-fit: cover;
            opacity: 0.4;
            filter: brightness(0.3) contrast(1.2);
        }
        
        /* 视频背景遮罩层 */
        .video-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: linear-gradient(135deg, 
                rgba(15, 15, 15, 0.4) 0%, 
                rgba(26, 26, 26, 0.4) 50%,
                rgba(30, 30, 30, 0.4) 100%);
            z-index: -1;
            pointer-events: none;
        }
        
        /* 主内容区域调整 */
        body {
            padding-top: 126px !important;
            margin: 0 !important;
        }
        
        .main-content {
            position: relative;
            z-index: 1;
            padding-top: 0 !important;
            margin: 0 !important;
        }
        
        /* 导航栏光影效果 */
        .navbar::after {
            content: '';
            position: absolute;
            bottom: 0;
            left: 0;
            right: 0;
            height: 2px;
            background: linear-gradient(90deg, 
                transparent 0%, 
                rgba(255, 193, 7, 0.3) 20%, 
                rgba(255, 193, 7, 0.6) 50%, 
                rgba(255, 193, 7, 0.3) 80%, 
                transparent 100%);
            box-shadow: 0 0 20px rgba(255, 193, 7, 0.2);
        }

        /* 面包屑导航光影效果 */
        .sub-header::after {
            content: '';
            position: absolute;
            bottom: 0;
            left: 0;
            right: 0;
            height: 1px;
            background: linear-gradient(90deg, 
                transparent 0%, 
                rgba(74, 158, 255, 0.3) 20%, 
                rgba(74, 158, 255, 0.5) 50%, 
                rgba(74, 158, 255, 0.3) 80%, 
                transparent 100%);
            box-shadow: 0 0 10px rgba(74, 158, 255, 0.2);
        }
        
        /* 响应式导航 */
        @media (max-width: 991.98px) {
            .sub-header {
                top: auto !important;
                position: relative !important;
            }
            
            body {
                padding-top: 76px !important;
            }
        }
    </style>
    
    <?php if (isset($extra_css)): ?>
        <?php echo $extra_css; ?>
    <?php endif; ?>
</head>
<body>
<!-- Loading遮罩层 -->
<div class="loading-overlay" id="loadingOverlay">
    <div class="loading-container">
        <div class="loading-particles" id="particles"></div>
        <div class="loading-logo">CNCTZ</div>
        <div class="loading-text">加载中...</div>
        <div class="loading-spinner"></div>
        <div class="loading-progress">
            <div class="loading-progress-bar" id="progressBar"></div>
        </div>
    </div>
</div>

    <!-- 背景图片层 -->
    <div class="bg-image-layer"></div>
    
    <!-- 视频背景 -->
    <div class="video-background">
        <video autoplay muted loop playsinline>
            <source src="https://madebydesignesia.com/themes/aivent/video/2.mp4" type="video/mp4">
        </video>
    </div>
    <div class="video-overlay"></div>
    
    <!-- 导航栏 -->
    <nav class="navbar navbar-expand-lg navbar-dark">
        <div class="container">
            <a class="navbar-brand" href="<?php echo site_url('index.php'); ?>">
                <i class="fas fa-gamepad"></i>
                <?php echo defined('SITE_NAME') ? SITE_NAME : '游戏门户'; ?>
            </a>
            
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav me-auto">
                    <li class="nav-item">
                        <a class="nav-link" href="<?php echo site_url('index.php'); ?>">
                            <i class="fas fa-home"></i> 首页
                        </a>
                    </li>
                    <li class="nav-item dropdown">
                        <a class="nav-link dropdown-toggle" href="#" id="marketDropdown" role="button" data-bs-toggle="dropdown">
                            <i class="fas fa-store"></i> 市场
                        </a>
                        <ul class="dropdown-menu">
                            <li><a class="dropdown-item" href="<?php echo site_url('market/'); ?>"><i class="fas fa-shopping-cart"></i> 寄售市场</a></li>
                            <li><a class="dropdown-item" href="<?php echo site_url('market/sell.php'); ?>"><i class="fas fa-tag"></i> 我的寄售</a></li>
                        </ul>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link <?php echo ($_SERVER['PHP_SELF'] ?? '') == '/gift.php' ? 'active' : ''; ?>" href="<?php echo site_url('gift.php'); ?>">
                            <i class="fas fa-gift"></i> 领取礼包
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link <?php echo ($_SERVER['PHP_SELF'] ?? '') == '/exchange.php' ? 'active' : ''; ?>" href="<?php echo site_url('exchange.php'); ?>">
                            <i class="fas fa-exchange-alt"></i> 兑换C币
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link <?php echo ($_SERVER['PHP_SELF'] ?? '') == '/lottery.php' ? 'active' : ''; ?>" href="<?php echo site_url('lottery.php'); ?>">
                            <i class="fas fa-dice"></i> 幸运抽奖
                        </a>
                    </li>
                    <li class="nav-item dropdown">
                        <a class="nav-link dropdown-toggle" href="#" id="playerCenterDropdown" role="button" data-bs-toggle="dropdown">
                            <i class="fas fa-gamepad"></i> 玩家中心
                        </a>
                        <ul class="dropdown-menu">
                            <li><a class="dropdown-item" href="<?php echo site_url('upgrade.php'); ?>"><i class="fas fa-level-up-alt"></i> 角色转生</a></li>
                            <li><a class="dropdown-item" href="<?php echo site_url('changejob.php'); ?>"><i class="fas fa-user-tag"></i> 变更职业</a></li>
                            <li><a class="dropdown-item" href="<?php echo site_url('profile.php'); ?>"><i class="fas fa-user-cog"></i> 个人设置</a></li>
                            <li><a class="dropdown-item" href="<?php echo site_url('vip.php'); ?>"><i class="fas fa-crown"></i> 会员特权</a></li>
                            <li><hr class="dropdown-divider"></li>
                            <li><a class="dropdown-item" href="<?php echo site_url('market/my_items.php'); ?>"><i class="fas fa-box"></i> 我的寄售</a></li>
                            <li><a class="dropdown-item" href="<?php echo site_url('history.php'); ?>"><i class="fas fa-history"></i> 交易记录</a></li>
                        </ul>
                    </li>
                </ul>
                
                <ul class="navbar-nav">
                    <?php if (function_exists('is_logged_in') && is_logged_in()): ?>
                        <!-- 角色选择 -->
                        <li class="nav-item dropdown">
                            <a class="nav-link dropdown-toggle" href="#" id="characterDropdown" role="button" data-bs-toggle="dropdown">
                                <i class="fas fa-user"></i> 
                                <span id="currentCharacterName">选择角色</span>
                            </a>
                            <ul class="dropdown-menu" id="characterMenu">
                                <?php 
                                $characters = getUserCharacters($_SESSION['server_id'] ?? null, $_SESSION['user_no'] ?? null);
                                if (!empty($characters)):
                                    foreach ($characters as $char): 
                                ?>
                                    <li>
                                        <a class="dropdown-item character-item" 
                                           href="#" 
                                           data-character-no="<?php echo $char['character_no']; ?>"
                                           data-character-name="<?php echo htmlspecialchars($char['character_name']); ?>">
                                            <i class="fas fa-user-circle"></i>
                                            <?php echo htmlspecialchars($char['character_name']); ?>
                                            <small class="text-muted">Lv.<?php echo $char['wlevel']; ?></small>
                                        </a>
                                    </li>
                                <?php 
                                    endforeach;
                                else:
                                ?>
                                    <li><a class="dropdown-item" href="#">暂无角色</a></li>
                                <?php endif; ?>
                            </ul>
                        </li>
                        
                        <!-- 退出登录按钮 -->
                        <li class="nav-item">
                            <a class="nav-link logout-btn" href="#" onclick="logout()">
                                <i class="fas fa-sign-out-alt"></i> 
                                退出
                            </a>
                        </li>
                    <?php else: ?>
                        <li class="nav-item">
                            <a class="nav-link" href="<?php echo site_url('login.php'); ?>">
                                <i class="fas fa-sign-in-alt"></i> 登录
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="<?php echo site_url('index.php'); ?>">
                                <i class="fas fa-user-plus"></i> 注册
                            </a>
                        </li>
                    <?php endif; ?>
                </ul>
            </div>
        </div>
    </nav>
    
    <!-- 二级导航（面包屑） -->
    <div class="sub-header">
        <div class="container">
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb mb-0">
                    <li class="breadcrumb-item"><a href="<?php echo site_url('index.php'); ?>">首页</a></li>
                    <?php if (isset($breadcrumbs) && is_array($breadcrumbs)): ?>
                        <?php foreach ($breadcrumbs as $key => $crumb): ?>
                            <li class="breadcrumb-item <?php echo $key === count($breadcrumbs) - 1 ? 'active' : ''; ?>">
                                <?php if ($key < count($breadcrumbs) - 1): ?>
                                    <a href="<?php echo $crumb['url'] ?? '#'; ?>"><?php echo $crumb['name'] ?? ''; ?></a>
                                <?php else: ?>
                                    <?php echo $crumb['name'] ?? ''; ?>
                                <?php endif; ?>
                            </li>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </ol>
            </nav>
        </div>
    </div>
    
    <!-- 主要内容区域 -->
    <main class="main-content">
