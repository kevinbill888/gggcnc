</main>
    
    <!-- 底部 -->
    <footer class="footer">
        <div class="container">
            <div class="row">
                <div class="col-md-4">
                    <h5><i class="fas fa-gamepad"></i> <?php echo SITE_NAME; ?></h5>
                    <p>专业的游戏服务平台，为玩家提供最优质的游戏体验。</p>
                    <div class="social-links">
                        <a href="#"><i class="fab fa-facebook"></i></a>
                        <a href="#"><i class="fab fa-twitter"></i></a>
                        <a href="#"><i class="fab fa-instagram"></i></a>
                        <a href="#"><i class="fab fa-discord"></i></a>
                    </div>
                </div>
                
                <div class="col-md-4">
                    <h5>快速链接</h5>
                    <ul class="footer-links">
                        <li><a href="<?php echo site_url('market/'); ?>">寄售市场</a></li>
                        <li><a href="<?php echo site_url('gift.php'); ?>">领取礼包</a></li>
                        <li><a href="<?php echo site_url('exchange.php'); ?>">兑换C币</a></li>
                        <li><a href="<?php echo site_url('lottery.php'); ?>">幸运抽奖</a></li>
                    </ul>
                </div>
                
                <div class="col-md-4">
                    <h5>联系我们</h5>
                    <ul class="footer-contact">
                        <li><i class="fas fa-envelope"></i> support@example.com</li>
                        <li><i class="fas fa-phone"></i> +86 123 4567 8900</li>
                        <li><i class="fas fa-map-marker-alt"></i> 中国上海市</li>
                    </ul>
                </div>
            </div>
            
            <div class="footer-bottom">
                <div class="row">
                    <div class="col-md-6">
                        <p>&copy; <?php echo date('Y'); ?> <?php echo SITE_NAME; ?>. All rights reserved.</p>
                    </div>
                    <div class="col-md-6 text-md-end">
                        <p>
                            <a href="<?php echo site_url('terms.php'); ?>">服务条款</a> | 
                            <a href="<?php echo site_url('privacy.php'); ?>">隐私政策</a>
                        </p>
                    </div>
                </div>
            </div>
        </div>
    </footer>
    
    <!-- JavaScript -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="<?php echo site_url('assets/js/main.js'); ?>"></script>
    <script src="<?php echo site_url('assets/js/loading.js'); ?>"></script>
    
    <?php if (isset($extra_js)): ?>
        <?php echo $extra_js; ?>
    <?php endif; ?>
    
    <script>
        // 页面功能初始化
        document.addEventListener('DOMContentLoaded', function() {
            console.log('页面加载完成，初始化功能...');
            
            // 1. 角色切换功能 - 移除自动刷新
            const characterItems = document.querySelectorAll('.character-item');
            console.log('找到角色项数量:', characterItems.length);
            
            characterItems.forEach(item => {
                item.addEventListener('click', function(e) {
                    e.preventDefault();
                    const characterNo = this.dataset.characterNo;
                    const characterName = this.dataset.characterName;
                    
                    console.log('点击角色:', characterNo, characterName);
                    
                    // 更新显示的角色名
                    const currentCharacterName = document.getElementById('currentCharacterName');
                    if (currentCharacterName) {
                        currentCharacterName.textContent = characterName;
                        console.log('更新角色名显示:', characterName);
                    }
                    
                    // 发送AJAX请求设置当前角色
                    fetch('<?php echo site_url('assets/ajax/set_character.php'); ?>', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/x-www-form-urlencoded',
                        },
                        body: 'character_no=' + encodeURIComponent(characterNo)
                    })
                    .then(response => {
                        console.log('角色切换响应状态:', response.status);
                        return response.text().then(text => {
                            console.log('角色切换原始响应:', text);
                            try {
                                return JSON.parse(text);
                            } catch (e) {
                                console.error('JSON解析失败:', e);
                                throw new Error('服务器响应格式错误: ' + text);
                            }
                        });
                    })
                    .then(data => {
                        console.log('角色切换解析后的数据:', data);
                        if (data.success) {
                            console.log('角色切换成功');
                            // 显示成功提示，但不自动刷新
                            showToast('角色切换成功', 'success');
                        } else {
                            console.error('角色切换失败:', data.message);
                            showToast('角色切换失败：' + data.message, 'error');
                        }
                    })
                    .catch(error => {
                        console.error('角色切换错误:', error);
                        showToast('角色切换失败，请稍后重试', 'error');
                    });
                });
            });
            
            // 2. 退出登录功能
            const logoutBtn = document.getElementById('logoutBtn');
            if (logoutBtn) {
                logoutBtn.addEventListener('click', function(e) {
                    e.preventDefault();
                    logout();
                });
            }
            
            // 3. 检查登录状态
            checkLoginStatus();
        });
        
        // 退出登录函数
        function logout() {
            if (confirm('确定要退出登录吗？')) {
                console.log('开始退出登录...');
                
                fetch('<?php echo site_url('assets/ajax/logout.php'); ?>', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                    }
                })
                .then(response => {
                    console.log('退出登录响应状态:', response.status);
                    return response.text().then(text => {
                        console.log('退出登录原始响应:', text);
                        try {
                            return JSON.parse(text);
                        } catch (e) {
                            console.error('JSON解析失败:', e);
                            throw new Error('服务器响应格式错误: ' + text);
                        }
                    });
                })
                .then(data => {
                    console.log('退出登录解析后的数据:', data);
                    if (data.success) {
                        showToast('退出成功', 'success');
                        setTimeout(() => {
                            window.location.href = '<?php echo site_url('login.php'); ?>';
                        }, 1000);
                    } else {
                        showToast('退出失败：' + data.message, 'error');
                    }
                })
                .catch(error => {
                    console.error('退出登录错误:', error);
                    showToast('退出失败，请稍后重试', 'error');
                });
            }
        }
        
        // 检查登录状态
        function checkLoginStatus() {
            const loginLink = document.getElementById('loginLink');
            const userMenu = document.getElementById('userMenu');
            
            if (loginLink && userMenu) {
                // 如果有用户菜单，隐藏登录链接
                if (userMenu.style.display !== 'none') {
                    loginLink.style.display = 'none';
                }
            }
        }
        
        // 全局错误处理
        window.addEventListener('error', function(e) {
            console.error('页面错误:', e.error);
        });
        
        // 全局未处理的Promise错误
        window.addEventListener('unhandledrejection', function(e) {
            console.error('未处理的Promise错误:', e.reason);
        });
    </script>
</body>
</html>
