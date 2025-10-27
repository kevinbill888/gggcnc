    </div>
    
    <!-- 游戏风格页脚 -->
    <footer class="gaming-footer">
        <div class="footer-container">
            <div class="footer-content">
                <div class="footer-section">
                    <h3>游戏导航</h3>
                    <ul>
                        <li><a href="index.php"><i class="fas fa-home"></i>首页</a></li>
                        <li><a href="user_center.php"><i class="fas fa-user"></i>用户中心</a></li>
                        <li><a href="pay/index.php"><i class="fas fa-coins"></i>充值中心</a></li>
                        <li><a href="market/index.php"><i class="fas fa-store"></i>寄售市场</a></li>
                    </ul>
                </div>
                <div class="footer-section">
                    <h3>游戏支持</h3>
                    <ul>
                        <li><a href="download.php"><i class="fas fa-download"></i>游戏下载</a></li>
                        <li><a href="guide.php"><i class="fas fa-book"></i>新手指南</a></li>
                        <li><a href="faq.php"><i class="fas fa-question-circle"></i>常见问题</a></li>
                        <li><a href="contact.php"><i class="fas fa-envelope"></i>联系我们</a></li>
                    </ul>
                </div>
                <div class="footer-section">
                    <h3>社区互动</h3>
                    <ul>
                        <li><a href="#"><i class="fab fa-qq"></i>QQ群</a></li>
                        <li><a href="#"><i class="fab fa-weixin"></i>微信群</a></li>
                        <li><a href="#"><i class="fab fa-weibo"></i>微博</a></li>
                        <li><a href="#"><i class="fab fa-discord"></i>Discord</a></li>
                    </ul>
                </div>
                <div class="footer-section">
                    <h3>关于我们</h3>
                    <p><?php echo SITE_NAME; ?> - 最专业的游戏服务平台</p>
                    <div class="social-links">
                        <a href="#"><i class="fab fa-qq"></i></a>
                        <a href="#"><i class="fab fa-weixin"></i></a>
                        <a href="#"><i class="fab fa-weibo"></i></a>
                    </div>
                </div>
            </div>
            <div class="footer-bottom">
                <p>&copy; <?php echo date('Y'); ?> <?php echo SITE_NAME; ?>. All rights reserved.</p>
            </div>
        </div>
    </footer>
    
    <style>
        /* 页脚样式 */
        .gaming-footer {
            background: linear-gradient(180deg, rgba(10,10,10,0.95) 0%, #0a0a0a 100%);
            border-top: 2px solid #00ffff;
            padding: 40px 0 20px;
            margin-top: 50px;
        }
        
        .footer-container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 0 20px;
        }
        
        .footer-content {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 30px;
            margin-bottom: 30px;
        }
        
        .footer-section h3 {
            color: #00ffff;
            font-size: 18px;
            margin-bottom: 15px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .footer-section ul {
            list-style: none;
        }
        
        .footer-section ul li {
            margin-bottom: 10px;
        }
        
        .footer-section ul li a {
            color: #888;
            text-decoration: none;
            display: flex;
            align-items: center;
            gap: 10px;
            transition: all 0.3s ease;
        }
        
        .footer-section ul li a:hover {
            color: #00ffff;
            transform: translateX(5px);
        }
        
        .footer-section p {
            color: #888;
            line-height: 1.6;
        }
        
        .social-links {
            display: flex;
            gap: 15px;
            margin-top: 15px;
        }
        
        .social-links a {
            width: 40px;
            height: 40px;
            background: rgba(0,255,255,0.1);
            border: 1px solid rgba(0,255,255,0.3);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #00ffff;
            transition: all 0.3s ease;
        }
        
        .social-links a:hover {
            background: rgba(0,255,255,0.2);
            transform: scale(1.1);
            box-shadow: 0 0 15px rgba(0,255,255,0.5);
        }
        
        .footer-bottom {
            text-align: center;
            padding-top: 20px;
            border-top: 1px solid rgba(255,255,255,0.1);
            color: #666;
        }
        
        @media (max-width: 768px) {
            .footer-content {
                grid-template-columns: 1fr;
                text-align: center;
            }
            
            .social-links {
                justify-content: center;
            }
        }
    </style>
    
    <!-- JavaScript -->
    <script>
        // 导航栏滚动效果
        window.addEventListener('scroll', function() {
            const nav = document.getElementById('gamingNav');
            if (window.scrollY > 50) {
                nav.classList.add('scrolled');
            } else {
                nav.classList.remove('scrolled');
            }
        });
        
        // 移动端菜单切换
        function toggleMobileMenu() {
            const menu = document.getElementById('navMenu');
            const btn = document.getElementById('mobileMenuBtn');
            menu.classList.toggle('active');
            btn.classList.toggle('active');
        }
        
        // 用户菜单切换
        function toggleUserMenu() {
            const dropdown = document.getElementById('userDropdown');
            dropdown.classList.toggle('active');
        }
        
        // 点击外部关闭下拉菜单
        document.addEventListener('click', function(e) {
            const userMenu = document.querySelector('.user-menu');
            if (!userMenu.contains(e.target)) {
                document.getElementById('userDropdown').classList.remove('active');
            }
        });
        
        // 动态更新货币余额（可选）
        function updateBalance() {
            // 这里可以添加AJAX请求来实时更新余额
            // fetch('api/get_balance.php').then(response => response.json()).then(data => {
            //     document.getElementById('navCCoin').textContent = data.c_coin;
            //     document.getElementById('navBCoin').textContent = data.b_coin;
            // });
        }
        
        // 每30秒更新一次余额
        setInterval(updateBalance, 30000);
    </script>
</body>
</html>
