<!--#include file="inc/conn.asp"-->
<!--#include file="inc/md5.asp"-->
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>注册账号 - <%=ServerName%></title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
            min-height: 100vh;
            font-family: 'Microsoft YaHei', Arial, sans-serif;
            padding: 20px 0;
        }
        
        .register-container {
            max-width: 900px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .register-header {
            text-align: center;
            margin-bottom: 30px;
        }
        
        .register-title {
            font-size: 32px;
            font-weight: bold;
            color: #ffffff;
            text-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);
            margin-bottom: 10px;
        }
        
        .register-subtitle {
            color: #bdc3c7;
            font-size: 16px;
        }
        
        .register-card {
            background: linear-gradient(135deg, #2c3e50, #34495e);
            border-radius: 15px;
            padding: 30px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.4);
            border: 2px solid #3498db;
            position: relative;
        }
        
        .form-row {
            display: flex;
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .form-group {
            flex: 1;
        }
        
        .form-label {
            display: block;
            color: #ecf0f1;
            font-size: 14px;
            font-weight: 600;
            margin-bottom: 8px;
        }
        
        .form-label i {
            margin-right: 8px;
            color: #3498db;
        }
        
        .form-input {
            width: 100%;
            padding: 12px 15px;
            border: 2px solid rgba(74, 158, 255, 0.3);
            border-radius: 8px;
            background: rgba(255, 255, 255, 0.1);
            color: #ffffff;
            font-size: 14px;
            transition: all 0.3s ease;
        }
        
        .form-input:focus {
            outline: none;
            border-color: #3498db;
            background: rgba(255, 255, 255, 0.15);
            box-shadow: 0 0 15px rgba(52, 152, 219, 0.4);
        }
        
        .form-input::placeholder {
            color: rgba(255, 255, 255, 0.5);
        }
        
        .error-tip {
            color: #e74c3c;
            font-size: 12px;
            margin-top: 5px;
            display: none;
        }
        
        /* 拖动验证码 */
        .captcha-container {
            width: 100%;
            height: 50px;
            background: rgba(255, 255, 255, 0.1);
            border: 2px solid rgba(74, 158, 255, 0.3);
            border-radius: 8px;
            position: relative;
            overflow: hidden;
            cursor: pointer;
        }
        
        .captcha-bg {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, #3498db, #9b59b6);
            opacity: 0.1;
        }
        
        .captcha-text {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            color: #ecf0f1;
            font-size: 14px;
            pointer-events: none;
            z-index: 1;
        }
        
        .captcha-slider {
            position: absolute;
            top: 2px;
            left: 2px;
            width: 46px;
            height: 46px;
            background: linear-gradient(135deg, #3498db, #2980b9);
            border-radius: 6px;
            cursor: pointer;
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 2;
        }
        
        .captcha-slider:hover {
            background: linear-gradient(135deg, #2980b9, #1f618d);
        }
        
        .captcha-slider i {
            color: #ffffff;
            font-size: 18px;
        }
        
        .captcha-success {
            background: linear-gradient(135deg, #27ae60, #229954) !important;
        }
        
        .captcha-success .captcha-text {
            color: #27ae60;
        }
        
        /* 密码强度 */
        .password-strength {
            display: flex;
            gap: 5px;
            margin-top: 8px;
        }
        
        .strength-bar {
            flex: 1;
            height: 6px;
            background: rgba(255, 255, 255, 0.2);
            border-radius: 3px;
            transition: all 0.3s ease;
        }
        
        .strength-bar.weak {
            background: #e74c3c;
        }
        
        .strength-bar.medium {
            background: #f39c12;
        }
        
        .strength-bar.strong {
            background: #27ae60;
        }
        
        /* 提交按钮 */
        .submit-btn {
            width: 100%;
            padding: 15px;
            background: linear-gradient(135deg, #3498db 0%, #2980b9 100%);
            color: #ffffff;
            border: none;
            border-radius: 10px;
            font-size: 18px;
            font-weight: bold;
            cursor: pointer;
            transition: all 0.3s ease;
            text-transform: uppercase;
            letter-spacing: 2px;
            margin-top: 20px;
        }
        
        .submit-btn:hover {
            background: linear-gradient(135deg, #2980b9 0%, #1f618d 100%);
            transform: translateY(-2px);
            box-shadow: 0 8px 20px rgba(52, 152, 219, 0.4);
        }
        
        .submit-btn:disabled {
            background: #7f8c8d;
            cursor: not-allowed;
            transform: none;
        }
        
        /* 协议提示 */
        .agreement-notice {
            background: linear-gradient(135deg, rgba(231, 76, 60, 0.1) 0%, rgba(192, 57, 43, 0.1) 100%);
            border: 1px solid rgba(231, 76, 60, 0.3);
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 25px;
        }
        
        .agreement-title {
            color: #e74c3c;
            font-size: 16px;
            font-weight: bold;
            margin-bottom: 12px;
        }
        
        .agreement-list {
            list-style: none;
            padding: 0;
            margin: 0;
        }
        
        .agreement-list li {
            color: #ecf0f1;
            font-size: 14px;
            line-height: 1.6;
            margin-bottom: 8px;
            padding-left: 20px;
            position: relative;
        }
        
        .agreement-list li::before {
            content: '▸';
            position: absolute;
            left: 0;
            color: #e74c3c;
        }
        
        /* 弹窗样式 */
        .modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.8);
            z-index: 9999;
            display: none;
        }
        
        .modal-box {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: linear-gradient(135deg, #2c3e50, #34495e);
            border-radius: 15px;
            padding: 0;
            min-width: 400px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
            border: 2px solid #3498db;
            z-index: 10000;
            display: none;
        }
        
        .modal-header {
            padding: 20px;
            border-radius: 15px 15px 0 0;
            text-align: center;
        }
        
        .modal-header.success {
            background: linear-gradient(135deg, #27ae60, #229954);
        }
        
        .modal-header.error {
            background: linear-gradient(135deg, #e74c3c, #c0392b);
        }
        
        .modal-title {
            color: #ffffff;
            font-size: 20px;
            font-weight: bold;
            margin: 0;
        }
        
        .modal-body {
            padding: 30px;
            text-align: center;
        }
        
        .modal-message {
            color: #ecf0f1;
            font-size: 16px;
            margin-bottom: 20px;
        }
        
        .modal-btn {
            padding: 10px 30px;
            background: linear-gradient(135deg, #3498db, #2980b9);
            color: #ffffff;
            border: none;
            border-radius: 8px;
            font-size: 14px;
            font-weight: bold;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        
        .modal-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
        }
        
        /* 加载动画 */
        .loading {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            text-align: center;
            z-index: 10001;
            display: none;
        }
        
        .loading-spinner {
            width: 50px;
            height: 50px;
            border: 3px solid rgba(255, 255, 255, 0.3);
            border-top: 3px solid #3498db;
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        
        .loading-text {
            color: #ffffff;
            margin-top: 10px;
            font-size: 14px;
        }
        
        @media (max-width: 768px) {
            .form-row {
                flex-direction: column;
                gap: 0;
            }
            
            .register-card {
                padding: 20px;
            }
            
            .modal-box {
                min-width: 90%;
            }
        }
    </style>
</head>
<body>
    <div class="register-container">
        <div class="register-header">
            <h1 class="register-title">
                <i class="fas fa-gamepad"></i>
                <%=ServerName%> 账号注册
            </h1>
            <p class="register-subtitle">创建您的游戏通行证，开启冒险之旅</p>
        </div>
        
        <div class="register-card">
            <div class="agreement-notice">
                <div class="agreement-title">
                    <i class="fas fa-exclamation-triangle"></i>
                    注册须知
                </div>
                <ul class="agreement-list">
                    <li>请使用真实有效的邮箱和手机号，以便账号安全和找回密码</li>
                    <li>每个手机号最多可注册5个游戏账号</li>
                    <li>请妥善保管您的账号密码，切勿与他人分享</li>
                </ul>
            </div>
            
            <form id="registerForm">
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">
                            <i class="fas fa-user"></i>
                            账号
                        </label>
                        <input type="text" class="form-input" name="username" 
                               id="username" placeholder="请输入5-16位账号" required>
                        <div class="error-tip" id="usernameError"></div>
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">
                            <i class="fas fa-envelope"></i>
                            邮箱
                        </label>
                        <input type="email" class="form-input" name="email" 
                               id="email" placeholder="请输入邮箱地址" required>
                        <div class="error-tip" id="emailError"></div>
                    </div>
                </div>
                
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">
                            <i class="fas fa-lock"></i>
                            密码
                        </label>
                        <input type="password" class="form-input" name="password" 
                               id="password" placeholder="请输入6-18位密码" required>
                        <div class="password-strength">
                            <div class="strength-bar" id="strength1"></div>
                            <div class="strength-bar" id="strength2"></div>
                            <div class="strength-bar" id="strength3"></div>
                        </div>
                        <div class="error-tip" id="passwordError"></div>
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">
                            <i class="fas fa-lock"></i>
                            重复密码
                        </label>
                        <input type="password" class="form-input" name="repassword" 
                               id="repassword" placeholder="请再次输入密码" required>
                        <div class="error-tip" id="repasswordError"></div>
                    </div>
                </div>
                
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">
                            <i class="fas fa-mobile-alt"></i>
                            手机号
                        </label>
                        <input type="tel" class="form-input" name="phone" 
                               id="phone" placeholder="请输入11位手机号" required>
                        <div class="error-tip" id="phoneError"></div>
                    </div>
                    
                    <div class="form-group">
                        <label class="form-label">
                            <i class="fas fa-shield-alt"></i>
                            拖动验证
                        </label>
                        <div class="captcha-container" id="captchaContainer">
                            <div class="captcha-bg"></div>
                            <div class="captcha-text">请向右拖动完成验证</div>
                            <div class="captcha-slider" id="captchaSlider">
                                <i class="fas fa-chevron-right"></i>
                            </div>
                        </div>
                        <div class="error-tip" id="captchaError"></div>
                    </div>
                </div>
                
                <button type="submit" class="submit-btn" id="submitBtn">
                    <i class="fas fa-user-plus"></i>
                    立即注册
                </button>
            </form>
        </div>
    </div>
    
    <!-- 弹窗 -->
    <div class="modal-overlay" id="modalOverlay"></div>
    <div class="modal-box" id="modalBox">
        <div class="modal-header" id="modalHeader">
            <h3 class="modal-title" id="modalTitle">提示</h3>
        </div>
        <div class="modal-body">
            <div class="modal-message" id="modalMessage">操作成功！</div>
            <button class="modal-btn" id="modalBtn">确定</button>
        </div>
    </div>
    
    <!-- 加载动画 -->
    <div class="loading" id="loading">
        <div class="loading-spinner"></div>
        <div class="loading-text">正在注册中...</div>
    </div>
    
    <script src="https://cdn.staticfile.org/jquery/1.8.3/jquery.min.js"></script>
    <script>
        $(document).ready(function() {
            let isCaptchaVerified = false;
            let isDragging = false;
            let startX = 0;
            
            // 拖动验证码
            const slider = document.getElementById('captchaSlider');
            const container = document.getElementById('captchaContainer');
            const containerWidth = container.offsetWidth;
            const sliderWidth = slider.offsetWidth;
            const maxDistance = containerWidth - sliderWidth - 4;
            
            slider.addEventListener('mousedown', startDrag);
            slider.addEventListener('touchstart', startDrag);
            
            function startDrag(e) {
                isDragging = true;
                startX = e.type.includes('mouse') ? e.clientX : e.touches[0].clientX;
                slider.style.transition = 'none';
                e.preventDefault();
            }
            
            document.addEventListener('mousemove', drag);
            document.addEventListener('touchmove', drag);
            
            function drag(e) {
                if (!isDragging) return;
                
                const currentX = e.type.includes('mouse') ? e.clientX : e.touches[0].clientX;
                const distance = currentX - startX;
                const translateX = Math.max(0, Math.min(distance, maxDistance));
                
                slider.style.transform = `translateX(${translateX}px)`;
                
                if (translateX >= maxDistance * 0.9) {
                    verifySuccess();
                }
            }
            
            document.addEventListener('mouseup', endDrag);
            document.addEventListener('touchend', endDrag);
            
            function endDrag() {
                if (!isDragging) return;
                isDragging = false;
                slider.style.transition = 'transform 0.3s ease';
                
                if (!isCaptchaVerified) {
                    slider.style.transform = 'translateX(0)';
                }
            }
            
            function verifySuccess() {
                isCaptchaVerified = true;
                slider.classList.add('captcha-success');
                slider.innerHTML = '<i class="fas fa-check"></i>';
                container.classList.add('captcha-success');
                slider.style.transform = `translateX(${maxDistance}px)`;
                document.getElementById('captchaError').style.display = 'none';
            }
            
            // 密码强度检测
            $('#password').on('input', function() {
                const password = $(this).val();
                $('.strength-bar').removeClass('weak medium strong');
                
                if (password.length >= 6) {
                    $('#strength1').addClass('weak');
                    if (password.length >= 8 && /[A-Z]/.test(password) && /[0-9]/.test(password)) {
                        $('#strength2').addClass('medium');
                        if (password.length >= 10 && /[^A-Za-z0-9]/.test(password)) {
                            $('#strength3').addClass('strong');
                        }
                    }
                }
            });
            
            // 显示弹窗
            function showModal(type, title, message, callback) {
                const overlay = document.getElementById('modalOverlay');
                const modal = document.getElementById('modalBox');
                const header = document.getElementById('modalHeader');
                const titleEl = document.getElementById('modalTitle');
                const messageEl = document.getElementById('modalMessage');
                const btn = document.getElementById('modalBtn');
                
                header.className = 'modal-header ' + type;
                titleEl.textContent = title;
                messageEl.textContent = message;
                
                overlay.style.display = 'block';
                modal.style.display = 'block';
                
                function closeModal() {
                    overlay.style.display = 'none';
                    modal.style.display = 'none';
                    if (callback) callback();
                }
                
                overlay.onclick = closeModal;
                btn.onclick = closeModal;
            }
            
            // 表单提交
            $('#registerForm').on('submit', function(e) {
                e.preventDefault();
                
                $('.error-tip').hide();
                
                const username = $('#username').val().trim();
                const email = $('#email').val().trim();
                const password = $('#password').val();
                const repassword = $('#repassword').val();
                const phone = $('#phone').val().trim();
                
                let hasError = false;
                
                if (username.length < 5 || username.length > 16) {
                    $('#usernameError').text('账号长度必须在5-16位之间').show();
                    hasError = true;
                } else if (!/^[a-zA-Z0-9_]+$/.test(username)) {
                    $('#usernameError').text('账号只能包含字母、数字和下划线').show();
                    hasError = true;
                }
                
                if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
                    $('#emailError').text('请输入有效的邮箱地址').show();
                    hasError = true;
                }
                
                if (password.length < 6 || password.length > 18) {
                    $('#passwordError').text('密码长度必须在6-18位之间').show();
                    hasError = true;
                }
                
                if (password !== repassword) {
                    $('#repasswordError').text('两次输入的密码不一致').show();
                    hasError = true;
                }
                
                if (!/^1[3-9]\d{9}$/.test(phone)) {
                    $('#phoneError').text('请输入有效的手机号码').show();
                    hasError = true;
                }
                
                if (!isCaptchaVerified) {
                    $('#captchaError').text('请完成拖动验证').show();
                    hasError = true;
                }
                
                if (hasError) return;
                
                // 显示加载
                $('#loading').show();
                $('#submitBtn').prop('disabled', true);
                
                // 提交数据
                var postCandidates = ['register_save.asp', '/new12/register_save.asp'];
                var postData = {
                    username: username,
                    email: email,
                    password: password,
                    phone: phone
                };

                function tryPostAt(index) {
                    if (index >= postCandidates.length) {
                        $('#loading').hide();
                        $('#submitBtn').prop('disabled', false);
                        showModal('error', '网络错误', '网络连接失败，请检查网络后重试 (所有候选路径均失败)');
                        return;
                    }
                    var url = postCandidates[index];
                    console.log('尝试注册 POST ->', url, postData);
                    $.ajax({
                        url: url,
                        type: 'POST',
                        data: postData,
                        complete: function() {
                            $('#loading').hide();
                            $('#submitBtn').prop('disabled', false);
                        },
                        success: function(response) {
                            console.log('Response:', response); // 调试信息

                            if (response.indexOf('success') !== -1) {
                                showModal('success', '注册成功', '恭喜您，账号注册成功！即将跳转到首页...', function() {
                                    window.location.href = 'index.asp';
                                });
                            } else if (response.indexOf('username_exists') !== -1) {
                                showModal('error', '注册失败', '该账号已被注册，请更换其他账号');
                            } else if (response.indexOf('email_exists') !== -1) {
                                showModal('error', '注册失败', '该邮箱已被使用，请更换其他邮箱');
                            } else if (response.indexOf('phone_limit') !== -1) {
                                showModal('error', '注册失败', '该手机号注册次数已达上限（最多5个账号）');
                            } else {
                                showModal('error', '注册失败', '注册失败，请检查信息后重试');
                            }

                            // 重置验证码
                            if (response.indexOf('success') === -1) {
                                resetCaptcha();
                            }
                        },
                        error: function(xhr, status, error) {
                            console.warn('POST 到 ' + url + ' 返回错误: ' + xhr.status + ' ' + status);
                            if (xhr && xhr.status === 404) {
                                tryPostAt(index + 1);
                            } else {
                                console.log('AJAX Error:', error); // 调试信息
                                showModal('error', '网络错误', '网络连接失败，请检查网络后重试');
                                resetCaptcha();
                            }
                        }
                    });
                }

                tryPostAt(0);
            });
            
            // 重置验证码
            function resetCaptcha() {
                isCaptchaVerified = false;
                slider.classList.remove('captcha-success');
                slider.innerHTML = '<i class="fas fa-chevron-right"></i>';
                container.classList.remove('captcha-success');
                slider.style.transform = 'translateX(0)';
            }
        });
    </script>
    
</body>
</html>
