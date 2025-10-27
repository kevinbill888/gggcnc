<!--#include file="inc/conn.asp"-->
<!--#include file="inc/md5.asp"-->
<%
Response.ContentType = "text/html; charset=UTF-8"
%>
<style>
/* 滑动验证码样式 */
.captcha-container {
    position: relative;
    width: 100%;
    height: 40px;
    background: #f7f9fa;
    border: 1px solid #e4e7eb;
    border-radius: 4px;
    margin-top: 5px;
    overflow: hidden;
}

.captcha-text {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    color: #999;
    font-size: 14px;
    pointer-events: none;
    transition: opacity 0.3s;
    z-index: 1;
}

.captcha-slider {
    position: absolute;
    top: 0;
    left: 0;
    width: 40px;
    height: 38px;
    background: #fff;
    border: 1px solid #e4e7eb;
    border-radius: 4px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 16px;
    color: #666;
    transition: all 0.3s;
    z-index: 2;
}

.captcha-slider:hover {
    background: #f0f0f0;
}

.captcha-container.captcha-success {
    background: #52ccba;
    border-color: #52ccba;
}

.captcha-container.captcha-success .captcha-text {
    color: #fff;
    opacity: 0;
}

.captcha-slider.captcha-success {
    background: #52ccba;
    border-color: #52ccba;
    color: #fff;
}

/* 大区选择样式 */
.form-input {
    background-color: #fff !important;
    color: #333 !important;
    border: 1px solid #ddd !important;
    padding: 10px !important;
    width: 100% !important;
    border-radius: 4px !important;
}

.form-input option {
    background-color: #fff !important;
    color: #333 !important;
}
</style>

<div class="register-form">
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
        <!-- 添加大区选择 -->
        <div class="form-group">
            <label class="form-label">
                <i class="fas fa-server"></i>
                选择大区
            </label>
            <select class="form-input" name="Dkserver" id="Dkserver" required>
                <option value="">请选择游戏大区</option>
                <option value="1">乱世挑战（大区1）</option>
                <option value="2">赤焰挑战（大区2）</option>
            </select>
            <div class="error-tip" id="serverError"></div>
        </div>
        
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

<script src="https://cdn.staticfile.org/jquery/1.8.3/jquery.min.js"></script>
<script>
$(document).ready(function() {
    let isCaptchaVerified = false;
    let isDragging = false;
    let startX = 0;
    
    // 拖动验证码
    let slider = document.getElementById('captchaSlider');
    let container = document.getElementById('captchaContainer');

    // 在运行时计算最大可移动距离（防止模态初始隐藏导致 offsetWidth 为 0）
    function getMaxDistance() {
        if (!container || !slider) return 0;
        const containerWidth = container.offsetWidth;
        const sliderWidth = slider.offsetWidth;
        return Math.max(0, containerWidth - sliderWidth - 4);
    }

    // 将事件绑定放入初始化函数，如果元素暂时不可用则重试（例如模态先隐藏、后插入DOM）
    function initSliderBindings(attempt) {
        attempt = attempt || 0;
        if (!slider) slider = document.getElementById('captchaSlider');
        if (!container) container = document.getElementById('captchaContainer');
        if (!slider || !container) {
            if (attempt < 10) {
                setTimeout(function() { initSliderBindings(attempt + 1); }, 100);
            }
            return;
        }

        slider.addEventListener('mousedown', startDrag);
        // touch 事件加上 passive: false，便于调用 preventDefault()
        slider.addEventListener('touchstart', function(e) { startDrag(e); }, { passive: false });

        document.addEventListener('mousemove', drag);
        document.addEventListener('touchmove', function(e) { drag(e); }, { passive: false });

        document.addEventListener('mouseup', endDrag);
        document.addEventListener('touchend', endDrag);
    }

    // 启动事件绑定尝试
    initSliderBindings();

    function startDrag(e) {
        if (!slider) return;
        isDragging = true;
        startX = (e.type && e.type.indexOf('mouse') !== -1) ? e.clientX : (e.touches && e.touches[0] && e.touches[0].clientX) || 0;
        slider.style.transition = 'none';
        if (e.preventDefault) e.preventDefault();
    }
    
    function drag(e) {
        if (!isDragging || !slider) return;

        const currentX = (e.type && e.type.indexOf('mouse') !== -1) ? e.clientX : (e.touches && e.touches[0] && e.touches[0].clientX) || 0;
        const distance = currentX - startX;
        const maxDistance = getMaxDistance();
        const translateX = Math.max(0, Math.min(distance, maxDistance));

        slider.style.transform = 'translateX(' + translateX + 'px)';

        if (maxDistance > 0 && translateX >= maxDistance * 0.9) {
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
        // 使用运行时计算的最大距离，避免作用域问题
        var md = getMaxDistance();
        slider.style.transform = 'translateX(' + md + 'px)';
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
    
    // 表单提交
    $('#registerForm').on('submit', function(e) {
        e.preventDefault();
        
        $('.error-tip').hide();
        
        const server = $('#Dkserver').val();
        const username = $('#username').val().trim();
        const email = $('#email').val().trim();
        const password = $('#password').val();
        const repassword = $('#repassword').val();
        const phone = $('#phone').val().trim();
        
        let hasError = false;
        
        if (server === '') {
            $('#serverError').text('请选择游戏大区').show();
            hasError = true;
        }
        
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
        if (typeof parent.gameModal !== 'undefined') {
            parent.gameModal.showLoading();
        }
        
        // 提交数据（改为明确路径并增强错误信息以便调试）
        // 使用重试候选 URL 的 POST helper，避免路径错误导致 404
        var postCandidates = ['register_save.asp', '/new12/register_save.asp'];
        var postData = {
            Dkserver: server,
            username: username,
            email: email,
            password: password,
            phone: phone
        };

        function tryPostAt(index) {
            if (index >= postCandidates.length) {
                $('#submitBtn').prop('disabled', false);
                parent.gameModal.showError('网络错误，请检查网络后重试 (所有候选路径均失败)');
                return;
            }
            var url = postCandidates[index];
            console.log('尝试注册 POST ->', url, postData);
            $.ajax({
                url: url,
                type: 'POST',
                data: postData,
                success: function(response) {
                    $('#submitBtn').prop('disabled', false);
                    if (response.indexOf('success') !== -1) {
                        parent.gameModal.showSuccess('注册成功！即将跳转到首页...', function() {
                            window.top.location.href = 'index.asp';
                        });
                    } else if (response.indexOf('username_exists') !== -1) {
                        parent.gameModal.showError('该账号已被注册，请更换其他账号');
                    } else if (response.indexOf('email_exists') !== -1) {
                        parent.gameModal.showError('该邮箱已被使用，请更换其他邮箱');
                    } else if (response.indexOf('phone_limit') !== -1) {
                        parent.gameModal.showError('该手机号注册次数已达上限');
                    } else if (response.indexOf('error:') === 0) {
                        parent.gameModal.showError('注册失败：' + response);
                    } else {
                        parent.gameModal.showError('注册失败：' + response);
                    }
                },
                error: function(xhr, status, error) {
                    console.warn('POST 到 ' + url + ' 返回错误: ' + xhr.status + ' ' + status);
                    // 如果是 404，尝试下一个候选路径
                    if (xhr && xhr.status === 404) {
                        tryPostAt(index + 1);
                    } else {
                        $('#submitBtn').prop('disabled', false);
                        var serverMsg = '';
                        try { serverMsg = xhr.responseText || ''; } catch(e) { serverMsg = ''; }
                        console.error('注册 AJAX 错误: 状态=' + xhr.status + ', statusText=' + status + ', error=' + error + '\n响应文本:' + serverMsg);
                        parent.gameModal.showError('网络错误，请检查网络后重试 (状态: ' + xhr.status + ')');
                    }
                }
            });
        }

        tryPostAt(0);
    });
});
</script>
