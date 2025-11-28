<?php
require_once 'auth.php';

$user = is_logged_in() ? get_current_user() : null;
?>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>游戏官网 - 首页</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <!-- 导航栏 -->
    <nav class="navbar">
        <div class="nav-brand">
            <i class="fas fa-gamepad"></i>
            <span>游戏官网</span>
        </div>
        <ul class="nav-menu">
            <li><a href="index.php" class="active"><i class="fas fa-home"></i> 首页</a></li>
            <li><a href="#"><i class="fas fa-newspaper"></i> 新闻</a></li>
            <li><a href="#"><i class="fas fa-download"></i> 下载</a></li>
            <?php if ($user): ?>
                <li><a href="user_center.php"><i class="fas fa-user"></i> 用户中心</a></li>
                <li><a href="pay/"><i class="fas fa-coins"></i> 充值</a></li>
                <li><a href="logout.php"><i class="fas fa-sign-out-alt"></i> 退出</a></li>
            <?php else: ?>
                <li><a href="login.php"><i class="fas fa-sign-in-alt"></i> 登录</a></li>
                <li><a href="register.php"><i class="fas fa-user-plus"></i> 注册</a></li>
            <?php endif; ?>
        </ul>
    </nav>

    <!-- 主内容区 -->
    <main class="main-content">
        <!-- 轮播图 -->
        <section class="hero">
            <div class="hero-content">
                <h1>欢迎来到游戏世界</h1>
                <p>开启你的冒险之旅</p>
                <?php if (!$user): ?>
                    <div class="hero-buttons">
                        <a href="register.php" class="btn btn-primary btn-lg">
                            <i class="fas fa-play"></i> 开始游戏
                        </a>
                        <a href="#" class="btn btn-outline btn-lg">
                            <i class="fas fa-download"></i> 下载客户端
                        </a>
                    </div>
                <?php else: ?>
                    <div class="hero-buttons">
                        <a href="pay/" class="btn btn-primary btn-lg">
                            <i class="fas fa-coins"></i> 立即充值
                        </a>
                        <a href="user_center.php" class="btn btn-outline btn-lg">
                            <i class="fas fa-user"></i> 用户中心
                        </a>
                    </div>
                <?php endif; ?>
            </div>
        </section>

        <!-- 特色功能 -->
        <section class="features">
            <div class="container">
                <h2>游戏特色</h2>
                <div class="feature-grid">
                    <div class="feature-card">
                        <div class="feature-icon">
                            <i class="fas fa-dragon"></i>
                        </div>
                        <h3>史诗剧情</h3>
                        <p>沉浸式的游戏剧情，带你进入奇幻世界</p>
                    </div>
                    <div class="feature-card">
                        <div class="feature-icon">
                            <i class="fas fa-users"></i>
                        </div>
                        <h3>多人在线</h3>
                        <p>与全球玩家一起冒险，结交好友</p>
                    </div>
                    <div class="feature-card">
                        <div class="feature-icon">
                            <i class="fas fa-trophy"></i>
                        </div>
                        <h3>竞技PK</h3>
                        <p>公平竞技，展现你的操作技巧</p>
                    </div>
                    <div class="feature-card">
                        <div class="feature-icon">
                            <i class="fas fa-gift"></i>
                        </div>
                        <h3>丰厚福利</h3>
                        <p>每日登录领取奖励，VIP专属特权</p>
                    </div>
                </div>
            </div>
        </section>

        <!-- VIP特权展示 -->
        <section class="vip-showcase">
            <div class="container">
                <h2>VIP特权系统</h2>
                <div class="vip-levels">
                    <?php foreach (array_slice($GLOBALS['vip_levels'], 1, 3) as $level => $config): ?>
                        <div class="vip-level-card">
                            <div class="vip-level-header">
                                <i class="<?php echo $config['icon']; ?>" style="color: <?php echo $config['color']; ?>"></i>
                                <h3><?php echo $config['name']; ?></h3>
                            </div>
                            <div class="vip-level-amount">
                                充值 ￥<?php echo $config['min_amount']; ?> 解锁
                            </div>
                            <ul class="vip-benefits">
                                <li><i class="fas fa-check"></i> 专属称号</li>
                                <li><i class="fas fa-check"></i> 每日礼包</li>
                                <li><i class="fas fa-check"></i> 经验加成</li>
                            </ul>
                        </div>
                    <?php endforeach; ?>
                </div>
                <div class="text-center">
                    <a href="pay/" class="btn btn-primary">
                        <i class="fas fa-crown"></i> 了解更多VIP特权
                    </a>
                </div>
            </div>
        </section>
    </main>

    <!-- 页脚 -->
    <footer class="footer">
        <div class="container">
            <div class="footer-content">
                <div class="footer-section">
                    <h4>游戏链接</h4>
                    <ul>
                        <li><a href="#">游戏下载</a></li>
                        <li><a href="#">新手指南</a></li>
                        <li><a href="#">游戏攻略</a></li>
                    </ul>
                </div>
                <div class="footer-section">
                    <h4>账号服务</h4>
                    <ul>
                        <li><a href="login.php">账号登录</a></li>
                        <li><a href="register.php">账号注册</a></li>
                        <li><a href="pay/">充值中心</a></li>
                    </ul>
                </div>
                <div class="footer-section">
                    <h4>联系我们</h4>
                    <ul>
                        <li><i class="fas fa-envelope"></i> support@example.com</li>
                        <li><i class="fab fa-qq"></i> 官方QQ群：123456789</li>
                    </ul>
                </div>
            </div>
            <div class="footer-bottom">
                <p>&copy; 2025 游戏官网. All rights reserved.</p>
            </div>
        </div>
    </footer>
</body>
</html>
