<!DOCTYPE html>
<head>
<title>-=:::CNCTZ挑战:::=-|打造最好最稳定的挑战世界!</title>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta name="description" content="全国最好的挑战,全新15职业挑战A24版本,新职业龙骑士,战场系统,封印系统,职业平衡,多线加速,BGP线路保障各种网络不卡,稳定的服务器组让您在游戏中流畅PK,打怪!"/>
    <meta name="keywords" content="挑战,新挑战,网通挑战,挑战官网,最新挑战私服,挑战,13职业挑战"/>
    <meta name="date" content="2025-3-7"/>
    <link rel="icon" type="image/png" href="static/image/favicon.png">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="static/css/bootstrap.min.css">
    <link rel="stylesheet" href="static/css/goodgames.min.css"> 
    <link rel="stylesheet" type="text/css" href="static/css/style.css" /> 
    <link rel="stylesheet" type="text/css" href="static/css/sweetalert.css" />
    
    <link rel="stylesheet" type="text/css" href="static/css/brands.min.css" />
    <link rel="stylesheet" type="text/css" href="static/css/fontawesome.min.css" />
    <link rel="stylesheet" type="text/css" href="static/css/solid.min.css" />
    <link rel="stylesheet" href="tc/popup.css">
<!-- 在head标签中引入CSS -->
<link rel="stylesheet" href="static/css/modal.css">
    <script type="text/javascript" src="https://cdn.staticfile.org/jquery/1.8.3/jquery.min.js"></script>
    <script type="text/javascript" src="static/js/sweetalert.min.js"></script>

    <style>

/* ========== 游戏风格弹窗框架 ========== */

/* 弹窗遮罩层 */
.modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    /* 修改这里：让背景更暗，从 0.9 改为 0.95 */
    background: radial-gradient(ellipse at center, rgba(0,0,0,0.95) 0%, rgba(0,0,0,0.98) 100%);
    z-index: 9999;
    display: none;
    /* 修改这里：增加模糊度，从 8px 改为 10px */
    backdrop-filter: blur(10px);
    animation: modalOverlayFadeIn 0.5s ease;
}


@keyframes modalOverlayFadeIn {
    from { 
        opacity: 0;
        backdrop-filter: blur(0px);
    }
    to { 
        opacity: 1;
        backdrop-filter: blur(8px);
    }
}

/* ========== 修改位置：弹窗容器背景色 ========== */
.modal-container {
    position: fixed;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    /* 修改这里：让背景更暗，调整渐变色 */
    background: linear-gradient(135deg, #0f1419 0%, #1a1f2e 50%, #0f1419 100%);
    border-radius: 20px;
    box-shadow: 
        0 25px 50px rgba(0, 0, 0, 0.8),  /* 修改这里：增加阴影透明度 */
        0 0 100px rgba(52, 152, 219, 0.1), /* 修改这里：降低发光强度 */
        inset 0 1px 0 rgba(255, 255, 255, 0.05); /* 修改这里：降低高光 */
    border: 2px solid transparent;
    background-image: 
        linear-gradient(#1a1f2e, #1a1f2e),
        linear-gradient(135deg, #3498db, #9b59b6);
    background-origin: border-box;
    background-clip: padding-box, border-box;
    z-index: 10000;
    display: none;
    overflow: hidden;
    animation: modalSlideIn 0.6s cubic-bezier(0.25, 0.8, 0.25, 1);
}

@keyframes modalSlideIn {
    from {
        opacity: 0;
        transform: translate(-50%, -45%) scale(0.8) rotateX(10deg);
    }
    to {
        opacity: 1;
        transform: translate(-50%, -50%) scale(1) rotateX(0deg);
    }
}

/* 弹窗尺寸变体 */
.modal-container.small {
    width: 450px;
    max-width: 90vw;
    max-height: 80vh;
}

.modal-container.medium {
    width: 650px;
    max-width: 90vw;
    max-height: 85vh;
}

.modal-container.large {
    width: 850px;
    max-width: 95vw;
    max-height: 90vh;
}

.modal-container.fullscreen {
    width: 95vw;
    height: 95vh;
    max-width: 95vw;
    max-height: 95vh;
}

/* ========== 修改位置：弹窗头部背景色 ========== */
.modal-container .modal-header {
    padding: 25px 30px;
    /* 修改这里：降低头部背景透明度 */
    background: linear-gradient(135deg, rgba(52, 152, 219, 0.1) 0%, rgba(155, 89, 182, 0.1) 100%);
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
    position: relative;
    display: flex;
    align-items: center;
    justify-content: space-between;
}

.modal-container .modal-header::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 2px;
    background: linear-gradient(90deg, #3498db, #9b59b6, #3498db);
    background-size: 200% 100%;
    animation: headerGlow 3s ease-in-out infinite;
}

@keyframes headerGlow {
    0%, 100% { background-position: 0% 50%; }
    50% { background-position: 100% 50%; }
}

.modal-container .modal-title {
    color: #ffffff;
    font-size: 22px;
    font-weight: bold;
    margin: 0;
    text-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    gap: 12px;
}

.modal-container .modal-title i {
    font-size: 24px;
    color: #3498db;
    animation: titleIconPulse 2s ease-in-out infinite;
}

@keyframes titleIconPulse {
    0%, 100% { 
        transform: scale(1);
        filter: drop-shadow(0 0 5px rgba(52, 152, 219, 0.5));
    }
    50% { 
        transform: scale(1.1);
        filter: drop-shadow(0 0 15px rgba(52, 152, 219, 0.8));
    }
}

/* 关闭按钮 */
.modal-container .modal-close {
    width: 40px;
    height: 40px;
    background: linear-gradient(135deg, rgba(231, 76, 60, 0.2) 0%, rgba(192, 57, 43, 0.2) 100%);
    border: 1px solid rgba(231, 76, 60, 0.3);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: all 0.3s ease;
    color: #e74c3c;
    font-size: 18px;
}

.modal-container .modal-close:hover {
    background: linear-gradient(135deg, rgba(231, 76, 60, 0.4) 0%, rgba(192, 57, 43, 0.4) 100%);
    transform: rotate(90deg) scale(1.1);
    box-shadow: 0 0 20px rgba(231, 76, 60, 0.5);
}

/* 弹窗内容区 */
.modal-container .modal-body {
    padding: 30px;
    max-height: calc(100vh - 200px);
    overflow-y: auto;
    position: relative;
}

/* 自定义滚动条 */
.modal-container .modal-body::-webkit-scrollbar {
    width: 8px;
}

.modal-container .modal-body::-webkit-scrollbar-track {
    background: rgba(255, 255, 255, 0.05);
    border-radius: 4px;
}

.modal-container .modal-body::-webkit-scrollbar-thumb {
    background: linear-gradient(135deg, #3498db, #9b59b6);
    border-radius: 4px;
}

.modal-container .modal-body::-webkit-scrollbar-thumb:hover {
    background: linear-gradient(135deg, #2980b9, #8e44ad);
}

/* 加载动画 */
.modal-container .modal-loading {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    text-align: center;
    z-index: 10001;
}

.modal-container .modal-loading-spinner {
    width: 60px;
    height: 60px;
    border: 3px solid rgba(52, 152, 219, 0.2);
    border-top: 3px solid #3498db;
    border-radius: 50%;
    animation: modalSpin 1s linear infinite;
    margin: 0 auto 15px;
}

@keyframes modalSpin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
}

.modal-container .modal-loading-text {
    color: #3498db;
    font-size: 16px;
    font-weight: bold;
    text-shadow: 0 0 10px rgba(52, 152, 219, 0.5);
}

/* 特殊效果 */
.modal-container .modal-glow {
    position: absolute;
    top: -2px;
    left: -2px;
    right: -2px;
    bottom: -2px;
    background: linear-gradient(45deg, #3498db, #9b59b6, #e74c3c, #f39c12, #3498db);
    background-size: 400% 400%;
    border-radius: 20px;
    z-index: -1;
    animation: modalGlow 10s ease infinite;
    opacity: 0.7;
}

@keyframes modalGlow {
    0%, 100% { background-position: 0% 50%; }
    50% { background-position: 100% 50%; }
}

/* 错误提示 */
.modal-container .modal-error {
    background: linear-gradient(135deg, rgba(231, 76, 60, 0.1) 0%, rgba(192, 57, 43, 0.1) 100%);
    border: 1px solid rgba(231, 76, 60, 0.3);
    border-radius: 10px;
    padding: 15px;
    margin: 15px 0;
    color: #e74c3c;
    text-align: center;
    animation: errorShake 0.5s ease;
}

@keyframes errorShake {
    0%, 100% { transform: translateX(0); }
    25% { transform: translateX(-10px); }
    75% { transform: translateX(10px); }
}

/* 成功提示 */
.modal-container .modal-success {
    background: linear-gradient(135deg, rgba(39, 174, 96, 0.1) 0%, rgba(34, 153, 84, 0.1) 100%);
    border: 1px solid rgba(39, 174, 96, 0.3);
    border-radius: 10px;
    padding: 15px;
    margin: 15px 0;
    color: #27ae60;
    text-align: center;
    animation: successBounce 0.6s ease;
}

@keyframes successBounce {
    0% { transform: scale(0.8); opacity: 0; }
    50% { transform: scale(1.05); }
    100% { transform: scale(1); opacity: 1; }
}

/* 注册表单样式 */
.modal-container .register-form {
    max-width: 100%;
}

.modal-container .form-row {
    display: flex;
    gap: 15px;
    margin-bottom: 20px;
}

.modal-container .form-group {
    flex: 1;
}

.modal-container .form-label {
    display: block;
    color: #ecf0f1;
    font-size: 14px;
    font-weight: 600;
    margin-bottom: 8px;
}

.modal-container .form-label i {
    margin-right: 8px;
    color: #3498db;
}

.modal-container .form-input {
    width: 100%;
    padding: 12px 15px;
    border: 2px solid rgba(74, 158, 255, 0.3);
    border-radius: 8px;
    background: rgba(255, 255, 255, 0.1);
    color: #ffffff;
    font-size: 14px;
    transition: all 0.3s ease;
    box-sizing: border-box;
}

.modal-container .form-input:focus {
    outline: none;
    border-color: #3498db;
    background: rgba(255, 255, 255, 0.15);
    box-shadow: 0 0 15px rgba(52, 152, 219, 0.4);
}

.modal-container .form-input::placeholder {
    color: rgba(255, 255, 255, 0.5);
}

.modal-container .error-tip {
    color: #e74c3c;
    font-size: 12px;
    margin-top: 5px;
    display: none;
}

.modal-container .captcha-container {
    width: 100%;
    height: 50px;
    background: rgba(255, 255, 255, 0.1);
    border: 2px solid rgba(74, 158, 255, 0.3);
    border-radius: 8px;
    position: relative;
    overflow: hidden;
    cursor: pointer;
}

.modal-container .captcha-text {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    color: #ecf0f1;
    font-size: 14px;
    pointer-events: none;
    z-index: 1;
}

.modal-container .captcha-slider {
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

.modal-container .captcha-slider i {
    color: #ffffff;
    font-size: 18px;
}

.modal-container .captcha-success {
    background: linear-gradient(135deg, #27ae60, #229954) !important;
}

.modal-container .captcha-success .captcha-text {
    color: #27ae60 !important;
}

.modal-container .password-strength {
    display: flex;
    gap: 5px;
    margin-top: 8px;
}

.modal-container .strength-bar {
    flex: 1;
    height: 6px;
    background: rgba(255, 255, 255, 0.2);
    border-radius: 3px;
    transition: all 0.3s ease;
}

.modal-container .strength-bar.weak { 
    background: #31100c; 
}

.modal-container .strength-bar.medium { 
    background: #f39c12; 
}

.modal-container .strength-bar.strong { 
    background: #27ae60; 
}

.modal-container .submit-btn {
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

.modal-container .submit-btn:hover {
    background: linear-gradient(135deg, #2980b9 0%, #1f618d 100%);
    transform: translateY(-2px);
    box-shadow: 0 8px 20px rgba(52, 152, 219, 0.4);
}

.modal-container .submit-btn:disabled {
    background: #7f8c8d;
    cursor: not-allowed;
    transform: none;
}

.modal-container .agreement-notice {
    background: linear-gradient(135deg, rgba(231, 76, 60, 0.1) 0%, rgba(192, 57, 43, 0.1) 100%);
    border: 1px solid rgba(231, 76, 60, 0.3);
    border-radius: 10px;
    padding: 20px;
    margin-bottom: 25px;
}

.modal-container .agreement-title {
    color: #e74c3c;
    font-size: 16px;
    font-weight: bold;
    margin-bottom: 12px;
}

.modal-container .agreement-list {
    list-style: none;
    padding: 0;
    margin: 0;
}

.modal-container .agreement-list li {
    color: #ecf0f1;
    font-size: 14px;
    line-height: 1.6;
    margin-bottom: 8px;
    padding-left: 20px;
    position: relative;
}

.modal-container .agreement-list li::before {
    content: '▸';
    position: absolute;
    left: 0;
    color: #e74c3c;
}

/* 响应式设计 */
@media (max-width: 768px) {
    .modal-container.small,
    .modal-container.medium,
    .modal-container.large {
        width: 95vw;
        max-height: 90vh;
    }
    
    .modal-container .modal-header {
        padding: 20px;
    }
    
    .modal-container .modal-body {
        padding: 20px;
    }
    
    .modal-container .modal-title {
        font-size: 18px;
    }
    
    .modal-container .modal-close {
        width: 35px;
        height: 35px;
        font-size: 16px;
    }
    
    .modal-container .form-row {
        flex-direction: column;
        gap: 0;
    }
}








/* ========== 抽奖页面样式 ========== */
.modal-container .lottery-container {
    text-align: center;
    padding: 20px;
}

.modal-container .lottery-header h2 {
    color: #ffffff;
    font-size: 28px;
    margin-bottom: 20px;
    text-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);
}

.modal-container .lottery-info {
    color: #bdc3c7;
    margin-bottom: 30px;
}

.modal-container .lottery-info p {
    margin: 5px 0;
    font-size: 16px;
}

.modal-container .lottery-wheel-container {
    position: relative;
    margin: 0 auto 30px;
    width: 400px;
}

.modal-container .lottery-wheel {
    position: relative;
    width: 400px;
    height: 400px;
    margin: 0 auto 20px;
}

.modal-container .lottery-pointer {
    position: absolute;
    top: -30px;
    left: 50%;
    transform: translateX(-50%);
    font-size: 40px;
    color: #e74c3c;
    text-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);
    z-index: 10;
}

.modal-container .lottery-btn {
    width: 200px;
    height: 60px;
    background: linear-gradient(135deg, #e74c3c, #c0392b);
    border: none;
    border-radius: 30px;
    color: #ffffff;
    font-size: 20px;
    font-weight: bold;
    cursor: pointer;
    transition: all 0.3s ease;
    box-shadow: 0 5px 15px rgba(231, 76, 60, 0.3);
    margin: 0 auto;
    display: block;
}

.modal-container .lottery-btn:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(231, 76, 60, 0.4);
}

.modal-container .lottery-btn:disabled {
    background: #7f8c8d;
    cursor: not-allowed;
    transform: none;
}

.modal-container .lottery-rules,
.modal-container .lottery-records {
    background: rgba(255, 255, 255, 0.05);
    border-radius: 10px;
    padding: 20px;
    margin-top: 20px;
    text-align: left;
}

.modal-container .lottery-rules h3,
.modal-container .lottery-records h3 {
    color: #3498db;
    font-size: 18px;
    margin-bottom: 15px;
}

.modal-container .lottery-rules ul {
    list-style: none;
    padding: 0;
    margin: 0;
}

.modal-container .lottery-rules li {
    color: #ecf0f1;
    padding: 5px 0;
    padding-left: 20px;
    position: relative;
}

.modal-container .lottery-rules li::before {
    content: '▸';
    position: absolute;
    left: 0;
    color: #3498db;
}

.modal-container .record-list {
    max-height: 200px;
    overflow-y: auto;
}

.modal-container .record-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 10px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
    color: #ecf0f1;
}

.modal-container .record-prize {
    color: #f39c12;
    font-weight: bold;
}

.modal-container .record-time {
    color: #95a5a6;
    font-size: 14px;
}

@media (max-width: 768px) {
    .modal-container .lottery-wheel-container {
        width: 300px;
    }
    
    .modal-container .lottery-wheel,
    .modal-container #wheelCanvas {
        width: 300px !important;
        height: 300px !important;
    }
}

/* ========== 幸运大抽奖链接样式 ========== */
.lottery-link {
    position: relative;
    background: linear-gradient(135deg, #e74c3c, #c0392b) !important;
    color: #fff !important;
    font-weight: bold;
    padding: 8px 15px !important;
    border-radius: 6px !important;
    transition: all 0.3s ease !important;
    box-shadow: 0 2px 4px rgba(231, 76, 60, 0.3) !important;
    text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.3) !important;
    overflow: hidden;
    display: inline-flex;
    align-items: center;
    gap: 8px;
    animation: lotteryPulse 2s infinite;
}

@keyframes lotteryPulse {
    0% {
        box-shadow: 0 2px 4px rgba(231, 76, 60, 0.3);
        transform: scale(1);
    }
    50% {
        box-shadow: 0 2px 8px rgba(231, 76, 60, 0.6);
        transform: scale(1.02);
    }
    100% {
        box-shadow: 0 2px 4px rgba(231, 76, 60, 0.3);
        transform: scale(1);
    }
}

/* ========== 幸运大抽奖链接样式 ========== */
.lottery-link {
    position: relative;
    background: linear-gradient(135deg, #e74c3c, #c0392b) !important;
    color: #fff !important;
    font-weight: bold;
    padding: 8px 15px !important;
    border-radius: 6px !important;
    transition: all 0.3s ease !important;
    box-shadow: 0 2px 4px rgba(231, 76, 60, 0.3) !important;
    text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.3) !important;
    overflow: hidden;
    display: inline-flex;
    align-items: center;
    gap: 8px;
    animation: lotteryPulse 2s infinite;
    width: 100%; /* 宽度100%自适应 */
    justify-content: center; /* 文字居中 */
    box-sizing: border-box; /* 包含padding在宽度内 */
}

/* 左侧菜单中的抽奖链接 */
.dropdown .lottery-link {
    width: calc(100% - 20px); /* 留出边距 */
    margin: 0 10px; /* 左右各10px边距 */
}

/* 右侧菜单中的抽奖链接 */
.right-menu .lottery-link,
.user-menu .lottery-link {
    width: calc(100% - 20px);
    margin: 0 10px;
}

/* 如果导航菜单有固定宽度 */
.navbar .lottery-link,
.nk-nav .lottery-link {
    width: 100%;
    margin: 0;
}

@keyframes lotteryPulse {
    0% {
        box-shadow: 0 2px 4px rgba(231, 76, 60, 0.3);
        transform: scale(1);
    }
    50% {
        box-shadow: 0 2px 8px rgba(231, 76, 60, 0.6);
        transform: scale(1.02);
    }
    100% {
        box-shadow: 0 2px 4px rgba(231, 76, 60, 0.3);
        transform: scale(1);
    }
}
/* 抽奖导航菜单 */
.lottery-link::before {
    content: '';
    position: absolute;
    top: 0;
    left: -100%;
    width: 100%;
    height: 100%;
    background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.3), transparent);
    transition: left 0.5s ease;
}

.lottery-link:hover::before {
    left: 100%;
}

.lottery-link:hover {
    background: linear-gradient(135deg, #c0392b, #a93226) !important;
    transform: translateY(-2px) scale(1.05) !important;
    box-shadow: 0 4px 12px rgba(231, 76, 60, 0.5) !important;
    color: #fff !important;
}

.lottery-link:active {
    transform: translateY(0) scale(0.98) !important;
    box-shadow: 0 1px 3px rgba(231, 76, 60, 0.4) !important;
}

/* 骰子图标动画 */
.lottery-link .dice-icon {
    display: inline-block;
    font-size: 16px;
    animation: diceRoll 3s infinite;
}

@keyframes diceRoll {
    0%, 100% { transform: rotate(0deg); }
    25% { transform: rotate(90deg); }
    50% { transform: rotate(180deg); }
    75% { transform: rotate(270deg); }
}

/* 悬浮提示效果 */
.lottery-link::after {
    content: '点击抽奖';
    position: absolute;
    bottom: -30px;
    left: 50%;
    transform: translateX(-50%);
    background: rgba(0, 0, 0, 0.8);
    color: #fff;
    padding: 4px 8px;
    border-radius: 4px;
    font-size: 12px;
    white-space: nowrap;
    opacity: 0;
    transition: opacity 0.3s ease;
    pointer-events: none;
    font-family: 'ZCOOL KuaiLe', cursive;
    z-index: 1000;
}

.lottery-link:hover::after {
    opacity: 1;
}

/* 响应式设计 */
@media (max-width: 768px) {
    .lottery-link {
        padding: 6px 12px !important;
        font-size: 13px !important;
    }
    
    .lottery-link .dice-icon {
        font-size: 14px;
    }
    
    /* 移动端调整边距 */
    .dropdown .lottery-link,
    .right-menu .lottery-link,
    .user-menu .lottery-link {
        width: calc(100% - 10px);
        margin: 0 5px;
    }
}

/* 确保在所有菜单容器中都正确显示 */
.dropdown-item.lottery-link {
    display: block !important;
    width: 100% !important;
    box-sizing: border-box !important;
}

/* ========== 滑动验证码样式 ========== */
.slider-captcha {
    width: 100%;
    max-width: 300px;
    margin: 10px 0;
    position: relative;
    background: #f5f5f5;
    border-radius: 4px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    overflow: hidden;
}

.captcha-track {
    position: relative;
    height: 40px;
    background: linear-gradient(90deg, #4CAF50 0%, #45a049 100%);
    border-radius: 4px;
    cursor: pointer;
    user-select: none;
}

.captcha-thumb {
    position: absolute;
    left: 0;
    top: 0;
    width: 40px;
    height: 40px;
    background: #fff;
    border-radius: 4px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.2);
    display: flex;
    align-items: center;
    justify-content: center;
    transition: left 0.3s ease;
    cursor: grab;
}

.captcha-thumb:active {
    cursor: grabbing;
}

.captcha-thumb.dragging {
    transition: none;
}

.thumb-icon {
    font-size: 20px;
    color: #4CAF50;
    font-weight: bold;
}

.captcha-text {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    color: #fff;
    font-size: 14px;
    font-weight: bold;
    text-shadow: 1px 1px 2px rgba(0,0,0,0.3);
    pointer-events: none;
    transition: opacity 0.3s ease;
}

.captcha-track.success .captcha-text {
    opacity: 0;
}

.captcha-track.success {
    background: linear-gradient(90deg, #4CAF50 0%, #8BC34A 100%);
}

.captcha-track.success .captcha-thumb {
    background: #4CAF50;
}

.captcha-track.success .thumb-icon {
    color: #fff;
}

/* 数字点击验证码样式 */
.number-captcha { padding: 4px; }
.numcap-prompt { margin-bottom: 4px; color: #333; font-size: 13px; }
.numcap-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 4px; }
.num-button {
    padding: 6px 0;
    border: 1px solid #ddd;
    background: #fff;
    border-radius: 4px;
    cursor: pointer;
    font-size: 14px;
}
.num-button:active { transform: translateY(1px); }
.num-button.num-fail {
    background: #ffe6e6;
    border-color: #ffb3b3;
}
.num-button.num-success {
    background: #4CAF50;
    border-color: #4CAF50;
    color: #fff;
}

/* 响应式设计 */
@media (max-width: 480px) {
    .slider-captcha {
        max-width: 250px;
    }
    
    .captcha-track {
        height: 35px;
    }
    
    .captcha-thumb {
        width: 35px;
        height: 35px;
    }
    
    .thumb-icon {
        font-size: 18px;
    }
    
    .captcha-text {
        font-size: 12px;
    }
}

/* 注册页面滑动验证码样式调整 */
.register-form .slider-captcha {
    margin-top: 5px;
    margin-bottom: 5px;
}

.register-form .captcha-track {
    height: 36px;
}

.register-form .captcha-thumb {
    width: 36px;
    height: 36px;
}

.register-form .thumb-icon {
    font-size: 16px;
}

.register-form .captcha-text {
    font-size: 12px;
}


/* ========== 确保滑动验证码样式强制生效 ========== */
/* 登录弹窗样式补充 */
.login-modal {
    display: none;
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.8);
    z-index: 10000;
    justify-content: center;
    align-items: center;
}

.login-modal-content {
    background: linear-gradient(135deg, #1a1f2e, #0f1419);
    border-radius: 15px;
    width: 400px;
    max-width: 90%;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
    border: 2px solid #3498db;
    overflow: hidden;
}

.login-modal-header {
    background: linear-gradient(135deg, rgba(52, 152, 219, 0.2), rgba(155, 89, 182, 0.2));
    padding: 20px;
    text-align: center;
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.login-modal-header h3 {
    color: #fff;
    margin: 0;
    font-size: 20px;
}

.close-btn {
    position: absolute;
    top: 15px;
    right: 15px;
    color: #fff;
    font-size: 24px;
    cursor: pointer;
    transition: transform 0.3s;
}

.close-btn:hover {
    transform: rotate(90deg);
}

.login-modal-body {
    padding: 30px;
}

.login-form-group {
    margin-bottom: 20px;
}

.login-form-group label {
    display: block;
    color: #fff;
    margin-bottom: 8px;
    font-size: 14px;
}

.login-form-group input {
    width: 100%;
    padding: 12px;
    background: rgba(255, 255, 255, 0.1);
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: 5px;
    color: #fff;
    font-size: 14px;
    transition: all 0.3s;
}

.login-form-group input:focus {
    outline: none;
    border-color: #3498db;
    background: rgba(255, 255, 255, 0.15);
}

.login-btn {
    width: 100%;
    padding: 12px;
    background: linear-gradient(135deg, #3498db, #2980b9);
    color: #fff;
    border: none;
    border-radius: 5px;
    font-size: 16px;
    font-weight: bold;
    cursor: pointer;
    transition: all 0.3s;
}

.login-btn:hover {
    background: linear-gradient(135deg, #2980b9, #1f618d);
    transform: translateY(-2px);
}

.login-links {
    margin-top: 20px;
    text-align: center;
}

.login-links a {
    color: #3498db;
    text-decoration: none;
    margin: 0 10px;
    font-size: 13px;
    transition: color 0.3s;
}

.login-links a:hover {
    color: #5dade2;
}

.login-msg {
    margin-top: 15px;
    padding: 10px;
    border-radius: 5px;
    text-align: center;
    font-size: 13px;
}

/* 强制滑动验证码样式显示 */
.slider-captcha {
    width: 100% !important;
    max-width: 300px !important;
    margin: 10px 0 !important;
    position: relative !important;
    background: #f5f5f5 !important;
    border-radius: 4px !important;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1) !important;
    overflow: hidden !important;
    display: block !important;
}

.captcha-track {
    position: relative !important;
    height: 40px !important;
    background: linear-gradient(90deg, #4CAF50 0%, #45a049 100%) !important;
    border-radius: 4px !important;
    cursor: pointer !important;
    user-select: none !important;
    display: block !important;
}

.captcha-thumb {
    position: absolute !important;
    left: 0 !important;
    top: 0 !important;
    width: 40px !important;
    height: 40px !important;
    background: #fff !important;
    border-radius: 4px !important;
    box-shadow: 0 2px 4px rgba(0,0,0,0.2) !important;
    display: flex !important;
    align-items: center !important;
    justify-content: center !important;
    transition: left 0.3s ease !important;
    cursor: grab !important;
}

.captcha-thumb:active {
    cursor: grabbing !important;
}

.captcha-thumb.dragging {
    transition: none !important;
}

.thumb-icon {
    font-size: 20px !important;
    color: #4CAF50 !important;
    font-weight: bold !important;
}

.captcha-text {
    position: absolute !important;
    top: 50% !important;
    left: 50% !important;
    transform: translate(-50%, -50%) !important;
    color: #fff !important;
    font-size: 14px !important;
    font-weight: bold !important;
    text-shadow: 1px 1px 2px rgba(0,0,0,0.3) !important;
    pointer-events: none !important;
    transition: opacity 0.3s ease !important;
}

.captcha-track.success .captcha-text {
    opacity: 0 !important;
}

.captcha-track.success {
    background: linear-gradient(90deg, #4CAF50 0%, #8BC34A 100%) !important;
}

.captcha-track.success .captcha-thumb {
    background: #4CAF50 !important;
}

.captcha-track.success .thumb-icon {
    color: #fff !important;
}
</style>

<style>
.video-background {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    z-index: -1;
    overflow: hidden;
}

.video-background video {
    position: absolute;
    top: 50%;
    left: 50%;
    min-width: 100%;
    min-height: 100%;
    width: auto;
    height: auto;
    transform: translate(-50%, -50%);
    object-fit: cover;
}

.video-overlay {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.5);
}
</style>
</head>
<body>
<div class="video-background">
    <video autoplay muted loop playsinline>
        <source src="https://madebydesignesia.com/themes/aivent/video/2.mp4" type="video/mp4">
    </video>
    <div class="video-overlay"></div>
</div>

<!-- 游戏风格固定导航栏 -->
<nav class="game-navbar">
    <div class="nav-container">
        <!-- Logo和标题 -->

           
        <div class="nav-brand">
            <div class="game-logo">
                <i class="fas fa-dragon"></i>
            </div>
            <div class="game-title">CNCTZ挑战</div>
        </div>
        
        <!-- 导航菜单 -->
        <ul class="nav-menu">
            <li class="nav-item">
                <a href="index.asp" class="nav-link active">
                    <i class="fas fa-home"></i>
                    <span>首页</span>
                </a>
            </li>
        <li class="nav-item">
                <a href="javascript:void(0)" onclick="popup.cross({
    url: 'https://www.mediafire.com/file/5poo0asjqzve8dd/CNCTZ2022-DekaronA23-V4.exe/file',
    title: '游戏下载',
    width: 960,
    height: 640,
    keepShell: false
})" class="nav-link">
                    <i class="fas fa-download"></i>
                    <span>注册账号</span>
                </a>
            </li>
            <li class="nav-item">
                <a href="User.asp?Action=Down" class="nav-link">
                    <i class="fas fa-download"></i>
                    <span>游戏下载</span>
                </a>
            </li>
            <li class="nav-item">
                <a href="Shop.asp?Action=UserCenter" class="nav-link">
                    <i class="fas fa-user-cog"></i>
                    <span>账号中心</span>
                </a>
                <div class="dropdown">
                    <a href="User.asp?Action=Agree" class="dropdown-item">注册账号</a>
                    <a href="User.asp?Action=Down" class="dropdown-item">游戏下载</a>
                    <a href="User.asp?Action=Modify" class="dropdown-item">修改资料</a>
                    <a href="User.asp?Action=GetPwd" class="dropdown-item">取回密码</a>
                    <a href="User.asp?Action2=ChangeJob" class="dropdown-item">变更职业</a>
                    <a href="User.asp?Action2=Upgrade" class="dropdown-item">角色转生</a>
                    <a href="User.asp?Action2=Move" class="dropdown-item">卡号自救</a>
                </div>
            </li>
            <li class="nav-item">
                <a href="Shop.asp" class="nav-link">
                    <i class="fas fa-shopping-cart"></i>
                    <span>游戏商城</span>
                </a>
                <div class="dropdown">
                    <a href="Shop.asp?Action2=Add" class="dropdown-item">寄售道具</a>
                    <a href="Shop.asp?Action3=My" class="dropdown-item">我的寄售</a>
                    <a href="Shop.asp" class="dropdown-item">交易市场</a>
                    <a href="Shop.asp?Action2=Gift" class="dropdown-item">领取礼包</a>
                    <a href="Shop.asp?Action2=Exchange" class="dropdown-item">兑换商城币</a>
                    <a href="Shop.asp?Action2=ExchangeItem" class="dropdown-item">装备升级熔炼</a>
                    <a href="javascript:void(0);" class="dropdown-item lottery-link" onclick="popup.inline({
    title: '幸运大抽奖',
    url: 'lottery_modal.asp',
    width: 1300,
    height: 800
})">🎲 幸运大抽奖</a>
                    <a href="Shop.asp?Action=Pay" class="dropdown-item">在线充值</a>
                    <a href="Shop.asp?Action=OrderList" class="dropdown-item">订单管理</a>
                </div>
            </li>
            <li class="nav-item">
                <a href="#" class="nav-link">
                    <i class="fas fa-info-circle"></i>
                    <span>关于我们</span>
                </a>
            </li>
        </ul>
        
 
     <!-- 用户状态区域 -->
<div class="user-status">
    <% If Session("username") <> "" Then %>
        <!-- 已登录状态 -->
        <div id="userStatus">
            <div class="user-avatar">
                <i class="fas fa-user"></i>
            </div>
            <div class="user-info">
                <div class="user-name"><%=Session("username")%></div>
                <div class="user-level">
                    <%= GetCharacterDropdown() %>
                </div>
            </div>
        </div>
        <div id="authButtons">
            <a href="logout.asp" class="btn btn-login">退出</a>
        </div>
    <% Else %>
        <!-- 未登录状态 -->
        <div id="userStatus"></div>
        <div id="authButtons">
            <button class="btn btn-login" id="loginBtn">登录</button>
        </div>
    <% End If %>
</div>
                    <!-- 在线人数显示 -->
<div class="online-count">
    <i class="fas fa-users"></i>
    <span>在线人数: </span>
    <span id="onlineCount">158</span>
</div>
         
        </div>
    </div>
</nav>

<!-- 登录弹窗 -->
<div id="loginModal" class="login-modal">
    <div class="login-modal-content">
        <div class="login-modal-header">
            <h3>用户登录</h3>
            <span class="close-btn" id="closeLogin">&times;</span>
        </div>
        <div class="login-modal-body">
            <form class="loginform" id="loginForm" action="UserCore.asp?Action=Login" method="post" name="form">
                <div class="login-form-group">
                    <label for="username">用户名:</label>
                    <input type="text" id="username" name="username" placeholder="请输入用户名" required>
                </div>
                <div class="login-form-group">
                    <label for="password">密码:</label>
                    <input type="password" id="password" name="password" placeholder="请输入密码" required>
                </div>
                <div class="login-form-group">
                    <label for="Dkserver">选择大区:</label>
                    <% Call ServerList() %>
                </div>
                <!-- 滑动验证码容器 -->
                <div class="form-group">
                    <label>验证码</label>
                    <div id="loginCaptcha"></div>
                </div>
                <button type="submit" class="login-btn" id="loginSubmitBtn">立即登录</button>
                <input type="hidden" name="Url" value="<%=Server.URLEncode(Request.ServerVariables("REQUEST_URI"))%>">
                <div id="loginMsg" class="login-msg"></div>
            </form>
            <div class="login-links">
                <a href="User.asp?Action=Reg">立即注册</a>
                <a href="User.asp?Action=Modify">修改密码</a>
                <a href="User.asp?Action=GetPwd">找回密码</a>
            </div>
        </div>
    </div>
</div>
<script type="text/javascript">
$(document).ready(function() {
    // ========== 滑动验证码函数 ==========
    function createSliderCaptcha(containerId) {
        var captcha = {
            id: 'captcha_' + Date.now(),
            value: Math.floor(Math.random() * 90000) + 10000,
            sessionKey: 'slider_captcha_' + Date.now(),
            isDragging: false,
            startX: 0,
            currentX: 0,
            
            init: function() {
                // 确保容器存在
                var container = document.getElementById(containerId);
                if (!container) {
                    console.error('容器不存在: ' + containerId);
                    return;
                }
                
                this.saveToSession();
                
                var html = '<div class="slider-captcha" id="' + this.id + '">' +
                    '<div class="captcha-track" id="track_' + this.id + '">' +
                    '<div class="captcha-thumb" id="thumb_' + this.id + '">' +
                    '<span class="thumb-icon">→</span>' +
                    '</div>' +
                    '<div class="captcha-text">向右滑动验证</div>' +
                    '</div>' +
                    '<input type="hidden" id="input_' + this.id + '" value="">' +
                    '<input type="hidden" id="session_' + this.id + '" value="' + this.sessionKey + '">' +
                    '</div>';
                
                container.innerHTML = html;
                this.bindEvents();
            },
            
            saveToSession: function() {
                $.ajax({
                    url: 'inc/save_captcha_session.asp',
                    type: 'POST',
                    data: {
                        session_key: this.sessionKey,
                        captcha_value: this.value
                    },
                    async: false,
                    error: function() {
                        console.log('保存验证码到session失败');
                    }
                });
            },
            
            bindEvents: function() {
                var self = this;
                var track = document.getElementById('track_' + this.id);
                var thumb = document.getElementById('thumb_' + this.id);
                
                if (!track || !thumb) {
                    console.error('验证码元素创建失败');
                    return;
                }
                
                // 鼠标事件
                thumb.addEventListener('mousedown', function(e) {
                    self.isDragging = true;
                    self.startX = e.clientX - self.currentX;
                    thumb.classList.add('dragging');
                    e.preventDefault();
                });
                
                document.addEventListener('mousemove', function(e) {
                    if (self.isDragging) {
                        self.currentX = e.clientX - self.startX;
                        self.updatePosition();
                    }
                });
                
                document.addEventListener('mouseup', function() {
                    if (self.isDragging) {
                        self.isDragging = false;
                        thumb.classList.remove('dragging');
                        self.checkPosition();
                    }
                });
                
                // 触摸事件
                thumb.addEventListener('touchstart', function(e) {
                    self.isDragging = true;
                    self.startX = e.touches[0].clientX - self.currentX;
                    thumb.classList.add('dragging');
                    e.preventDefault();
                });
                
                document.addEventListener('touchmove', function(e) {
                    if (self.isDragging) {
                        self.currentX = e.touches[0].clientX - self.startX;
                        self.updatePosition();
                    }
                });
                
                document.addEventListener('touchend', function() {
                    if (self.isDragging) {
                        self.isDragging = false;
                        thumb.classList.remove('dragging');
                        self.checkPosition();
                    }
                });
            },
            
            updatePosition: function() {
                var track = document.getElementById('track_' + this.id);
                var thumb = document.getElementById('thumb_' + this.id);
                var maxPosition = track.offsetWidth - thumb.offsetWidth;
                
                this.currentX = Math.max(0, Math.min(this.currentX, maxPosition));
                thumb.style.left = this.currentX + 'px';
                
                var input = document.getElementById('input_' + this.id);
                if (input) {
                    input.value = Math.round((this.currentX / maxPosition) * 100);
                }
            },
            
            checkPosition: function() {
                var track = document.getElementById('track_' + this.id);
                var thumb = document.getElementById('thumb_' + this.id);
                var maxPosition = track.offsetWidth - thumb.offsetWidth;
                var successThreshold = maxPosition * 0.8;
                
                if (this.currentX >= successThreshold) {
                    track.classList.add('success');
                    thumb.style.left = maxPosition + 'px';
                    var input = document.getElementById('input_' + this.id);
                    if (input) {
                        input.value = this.value;
                    }
                    
                    setTimeout(function() {
                        track.classList.remove('success');
                        thumb.style.left = '0px';
                        var input = document.getElementById('input_' + this.id);
                        if (input) {
                            input.value = '';
                        }
                    }, 3000);
                } else {
                    thumb.style.left = '0px';
                    var input = document.getElementById('input_' + this.id);
                    if (input) {
                        input.value = '';
                    }
                }
            },
            
            validate: function() {
                var input = document.getElementById('input_' + this.id);
                return input && input.value == this.value;
            },
            
            reset: function() {
                var track = document.getElementById('track_' + this.id);
                var thumb = document.getElementById('thumb_' + this.id);
                if (track && thumb) {
                    track.classList.remove('success');
                    thumb.style.left = '0px';
                    var input = document.getElementById('input_' + this.id);
                    if (input) {
                        input.value = '';
                    }
                }
            }
        };
        
        captcha.init();
        return captcha;
    }
    
    function validateSliderCaptcha(captchaId) {
        var input = document.getElementById('input_' + captchaId);
        var sessionKey = document.getElementById('session_' + captchaId);
        
        if (!input || !sessionKey) return false;
        
        var isValid = false;
        $.ajax({
            url: 'inc/validate_captcha.asp',
            type: 'POST',
            data: {
                session_key: sessionKey.value,
                captcha_value: input.value
            },
            async: false,
            success: function(response) {
                isValid = response === 'true';
            },
            error: function() {
                console.log('验证验证码失败');
            }
        });
        
        return isValid;
    }

    // ========== 点击数字验证码（用于登录，简单易用，兼容移动设备） ==========
    function createNumberCaptcha(containerId) {
        var container = document.getElementById(containerId);
        if (!container) {
            console.error('容器不存在: ' + containerId);
            return null;
        }

        // 生成目标数字（1-9）
        var target = Math.floor(Math.random() * 9) + 1;

        // 生成按钮顺序（1..9 随机打乱）
        var nums = [1,2,3,4,5,6,7,8,9];
        for (var i = nums.length - 1; i > 0; i--) {
            var j = Math.floor(Math.random() * (i + 1));
            var tmp = nums[i]; nums[i] = nums[j]; nums[j] = tmp;
        }

        var html = '<div class="number-captcha" id="' + containerId + '_numcap">' +
            '<div class="numcap-prompt">请点击数字 <strong>' + target + '</strong></div>' +
            '<div class="numcap-grid">';
        for (var k = 0; k < nums.length; k++) {
            html += '<button type="button" class="num-button" data-num="' + nums[k] + '">' + nums[k] + '</button>';
        }
        html += '</div>' +
            '<input type="hidden" id="input_' + containerId + '" value="0">' +
            '</div>';

        container.innerHTML = html;

        var capEl = document.getElementById(containerId + '_numcap');
        var buttons = capEl.querySelectorAll('.num-button');
        var input = document.getElementById('input_' + containerId);

        function onSuccess(btn) {
            input.value = '1';
            btn.classList.add('num-success');
            capEl.querySelector('.numcap-prompt').innerHTML = '<span style="color:green">验证通过</span>';
            // 禁用其它按钮
            buttons.forEach(function(b){ b.disabled = true; });
        }

        buttons.forEach(function(btn){
            btn.addEventListener('click', function(e){
                var n = parseInt(btn.getAttribute('data-num'));
                if (n === target) {
                    onSuccess(btn);
                } else {
                    // 简单的错误提示效果
                    btn.classList.add('num-fail');
                    setTimeout(function(){ btn.classList.remove('num-fail'); }, 600);
                }
            });
        });

        return {
            id: containerId,
            target: target,
            validate: function() { return input && input.value === '1'; },
            reset: function() {
                input.value = '0';
                capEl.querySelector('.numcap-prompt').innerHTML = '请点击数字 <strong>' + target + '</strong>';
                buttons.forEach(function(b){ b.disabled = false; b.classList.remove('num-success'); });
            }
        };
    }

    function validateNumberCaptcha(captchaId) {
        var input = document.getElementById('input_' + captchaId);
        if (!input) return false;
        return input.value === '1';
    }
    
    function resetSliderCaptcha(captchaId) {
        var captcha = document.getElementById(captchaId);
        if (captcha) {
            var track = document.getElementById('track_' + captchaId);
            var thumb = document.getElementById('thumb_' + captchaId);
            if (track && thumb) {
                track.classList.remove('success');
                thumb.style.left = '0px';
                var input = document.getElementById('input_' + captchaId);
                if (input) {
                    input.value = '';
                }
            }
        }
    }
    
    // ========== 登录相关函数 ==========
    let baseOnlineCount = 158;
    let currentOnlineCount = 158;
    
    function fetchBaseOnlineCount() {
        return fetch('online_count.json?' + new Date().getTime())
            .then(response => {
                if (!response.ok) {
                    throw new Error('网络响应不正常，状态码: ' + response.status);
                }
                return response.json();
            })
            .then(data => {
                if (data && typeof data.online_count !== 'undefined') {
                    baseOnlineCount = data.online_count;
                } else if (data && typeof data.base_count !== 'undefined') {
                    baseOnlineCount = data.base_count;
                } else {
                    baseOnlineCount = 158;
                }
                return baseOnlineCount;
            })
            .catch(error => {
                baseOnlineCount = 158;
                return baseOnlineCount;
            });
    }

    function getTimeBasedMultiplier() {
        const now = new Date();
        const hour = now.getHours();
        
        let timeMultiplier = 1;
        if (hour >= 0 && hour < 6) {
            timeMultiplier = 0.7;
        } else if (hour >= 6 && hour < 12) {
            timeMultiplier = 0.9;
        } else if (hour >= 12 && hour < 18) {
            timeMultiplier = 1.1;
        } else {
            timeMultiplier = 1.3;
        }
        
        return timeMultiplier;
    }

    function updateOnlineCount() {
        const onlineCountElement = document.getElementById('onlineCount');
        if (!onlineCountElement) return;
        
        const timeMultiplier = getTimeBasedMultiplier();
        const timeAdjustedCount = Math.floor(baseOnlineCount * timeMultiplier);
        
        const randomChange = (Math.random() * 0.04 - 0.02) + 1;
        const newCount = Math.floor(currentOnlineCount * randomChange);
        
        const minCount = Math.floor(timeAdjustedCount * 0.7);
        const maxCount = Math.floor(timeAdjustedCount * 1.3);
        const finalCount = Math.max(minCount, Math.min(maxCount, newCount));
        
        onlineCountElement.textContent = finalCount;
        currentOnlineCount = finalCount;
    }

    function updateBaseCountPeriodically() {
        fetchBaseOnlineCount().then(() => {
            console.log('基准值已更新:', baseOnlineCount);
        });
    }

    // 打开登录弹窗
    function openLoginModal() {
        $('#loginModal').fadeIn(300);
        // 延迟初始化滑动验证码，确保DOM已渲染
        setTimeout(function() {
            // 优先使用数字点击验证码（更兼容），保留滑块实现作为回退
            if (!window.loginNumberCaptcha) {
                window.loginNumberCaptcha = createNumberCaptcha('loginCaptcha');
            }
            if (!window.loginCaptcha) {
                // 如果需要，也可以保留滑块作为回退
                window.loginCaptcha = createSliderCaptcha('loginCaptcha');
            }
        }, 100);
    }

    // 关闭登录弹窗
    $('#closeLogin').on('click', function() {
        $('#loginModal').fadeOut(300);
    });
    
    $('#loginModal').on('click', function(e) {
        if (e.target === this) {
            $('#loginModal').fadeOut(300);
        }
    });
    
    $(document).keydown(function(e) {
        if (e.keyCode === 27 && $('#loginModal').is(':visible')) {
            $('#loginModal').fadeOut(300);
        }
    });

    // 登录表单处理
    $("#loginForm").on('submit', function(e) {
        e.preventDefault();
        
        // 验证验证码：优先使用数字验证码，其次回退到滑块
        var numOk = false;
        try { numOk = validateNumberCaptcha('loginCaptcha'); } catch (e) { numOk = false; }
        if (!numOk) {
            // 尝试滑块验证
            try {
                if (!validateSliderCaptcha('loginCaptcha')) {
                    swal('错误', '请完成验证', 'error');
                    return false;
                }
            } catch (e) {
                swal('错误', '请完成验证', 'error');
                return false;
            }
        }
        
        var formData = $(this).serialize();
        var username = $('#username').val();
        var password = $('#password').val();
        var loginMsg = $('#loginMsg');
        
        loginMsg.html('<span style="color:blue;">正在登录，请稍候...</span>');
        
        // 基本验证
        if (!username || username.length < 4) {
            loginMsg.html('<span style="color:red;">用户名不能少于4个字符</span>');
            return false;
        }
        
        if (!password || password.length < 2) {
            loginMsg.html('<span style="color:red;">密码不能少于2个字符</span>');
            return false;
        }
        
        $.ajax({
            url: 'UserCore.asp?Action=Login',
            type: 'POST',
            data: formData,
            success: function(response, status, xhr) {
                if (response.indexOf('登录成功') !== -1 || response.indexOf('成功') !== -1 || response.indexOf('location') !== -1 || response.indexOf('重新刷新') !== -1) {
                    loginMsg.html('<span style="color:green;">登录成功，正在跳转...</span>');
                    setTimeout(function() {
                        window.location.href = window.location.href;
                    }, 1000);
                } else if (response.indexOf('验证码') !== -1) {
                    loginMsg.html('<span style="color:red;">验证码错误</span>');
                    resetSliderCaptcha('loginCaptcha');
                } else if (response.indexOf('用户名') !== -1) {
                    loginMsg.html('<span style="color:red;">用户名错误</span>');
                    resetSliderCaptcha('loginCaptcha');
                } else if (response.indexOf('密码') !== -1) {
                    loginMsg.html('<span style="color:red;">密码错误</span>');
                    resetSliderCaptcha('loginCaptcha');
                } else if (response.indexOf('在线') !== -1) {
                    loginMsg.html('<span style="color:red;">账号已在线</span>');
                    resetSliderCaptcha('loginCaptcha');
                } else {
                    loginMsg.html('<span style="color:red;">登录失败: ' + response + '</span>');
                    resetSliderCaptcha('loginCaptcha');
                }
            },
            error: function(xhr, status, error) {
                loginMsg.html('<span style="color:red;">网络错误，请稍后重试。状态: ' + xhr.status + '</span>');
                resetSliderCaptcha('loginCaptcha');
            }
        });
    });

    // 退出登录
    function logout() {
        $.ajax({
            url: 'UserCore.asp?Action=Quit',
            type: 'POST',
            success: function(response) {
                window.location.href = window.location.href;
            },
            error: function() {
                window.location.href = window.location.href;
            }
        });
    }

    // 使用事件委托绑定登录和退出按钮
    $(document).on('click', '#loginBtn', openLoginModal);
    $(document).on('click', '#logoutBtn', logout);

    // 初始化
    function init() {
        fetchBaseOnlineCount().then(() => {
            updateOnlineCount();
        });
        
        setInterval(updateOnlineCount, 5000);
        setInterval(updateBaseCountPeriodically, 300000);
    }
    
    init();
});

/**
 * 游戏风格弹窗框架
 */
class GameModal {
    constructor() {
        this.modal = null;
        this.overlay = null;
        this.isOpen = false;
        this.currentUrl = '';
        this.originalTitle = document.title;
        this.init();
    }

    init() {
        this.createModalElements();
        this.bindEvents();
    }

    createModalElements() {
        this.overlay = document.createElement('div');
        this.overlay.className = 'modal-overlay';
        document.body.appendChild(this.overlay);

        this.modal = document.createElement('div');
        this.modal.className = 'modal-container medium';
        this.modal.innerHTML = `
            <div class="modal-glow"></div>
            <div class="modal-header">
                <h3 class="modal-title">
                    <i class="fas fa-gamepad"></i>
                    <span>游戏弹窗</span>
                </h3>
                <div class="modal-close">
                    <i class="fas fa-times"></i>
                </div>
            </div>
            <div class="modal-body">
                <div class="modal-loading">
                    <div class="modal-loading-spinner"></div>
                    <div class="modal-loading-text">加载中...</div>
                </div>
            </div>
        `;
        document.body.appendChild(this.modal);
    }

    bindEvents() {
        const closeBtn = this.modal.querySelector('.modal-close');
        closeBtn.addEventListener('click', () => this.close());

        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && this.isOpen) {
                this.close();
            }
        });

        this.overlay.addEventListener('click', (e) => {
            e.preventDefault();
            e.stopPropagation();
        });
    }

    open(options = {}) {
        const defaults = {
            title: '游戏弹窗',
            size: 'medium',
            content: '',
            type: 'html',
            icon: 'fas fa-gamepad',
            showClose: true,
            callback: null
        };

        const config = Object.assign({}, defaults, options);

        this.modal.className = 'modal-container ' + config.size;
        
        const titleEl = this.modal.querySelector('.modal-title');
        titleEl.innerHTML = '<i class="' + config.icon + '"></i><span>' + config.title + '</span>';

        const closeBtn = this.modal.querySelector('.modal-close');
        closeBtn.style.display = config.showClose ? 'flex' : 'none';

        this.loadContent(config);

        this.overlay.style.display = 'block';
        this.modal.style.display = 'block';
        this.isOpen = true;

        this.hideUrlParams();

        if (config.callback) config.callback();
    }

    loadContent(config) {
        const body = this.modal.querySelector('.modal-body');
        
        body.innerHTML = `
            <div class="modal-loading">
                <div class="modal-loading-spinner"></div>
                <div class="modal-loading-text">加载中...</div>
            </div>
        `;

        switch (config.type) {
            case 'html':
                this.loadHtmlContent(body, config.content);
                break;
            case 'url':
                this.loadUrlContent(body, config.content);
                break;
            case 'iframe':
                this.loadIframeContent(body, config.content);
                break;
        }
    }

    loadHtmlContent(container, content) {
        container.innerHTML = content;
        this.executeScripts(container);
    }

    loadUrlContent(container, url) {
        this.currentUrl = url;
        
        const xhr = new XMLHttpRequest();
        xhr.open('GET', url, true);
        xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
        xhr.onreadystatechange = () => {
            if (xhr.readyState === 4) {
                if (xhr.status === 200) {
                    const parser = new DOMParser();
                    const doc = parser.parseFromString(xhr.responseText, 'text/html');
                    const bodyContent = doc.body ? doc.body.innerHTML : xhr.responseText;
                    
                    container.innerHTML = bodyContent;
                    this.executeScripts(container);
                } else {
                    container.innerHTML = `
                        <div class="modal-error">
                            <i class="fas fa-exclamation-triangle"></i>
                            <p>加载失败：HTTP ${xhr.status}</p>
                            <button onclick="gameModal.close()" class="modal-btn">关闭</button>
                        </div>
                    `;
                }
            }
        };
        xhr.onerror = () => {
            container.innerHTML = `
                <div class="modal-error">
                    <i class="fas fa-exclamation-triangle"></i>
                    <p>网络错误，请检查连接</p>
                    <button onclick="gameModal.close()" class="modal-btn">关闭</button>
                </div>
            `;
        };
        xhr.send();
    }

    loadIframeContent(container, url) {
        container.innerHTML = `
            <iframe src="${url}" style="width: 100%; height: 100%; border: none; border-radius: 10px;"></iframe>
        `;
    }

    executeScripts(container) {
        const scripts = container.querySelectorAll('script');
        scripts.forEach(oldScript => {
            const newScript = document.createElement('script');
            Array.from(oldScript.attributes).forEach(attr => {
                newScript.setAttribute(attr.name, attr.value);
            });
            newScript.appendChild(document.createTextNode(oldScript.innerHTML));
            oldScript.parentNode.replaceChild(newScript, oldScript);
        });
    }

    close() {
        this.overlay.style.display = 'none';
        this.modal.style.display = 'none';
        this.isOpen = false;
        
        this.restoreUrl();
        
        setTimeout(() => {
            const body = this.modal.querySelector('.modal-body');
            body.innerHTML = '';
        }, 300);
    }

    hideUrlParams() {
        if (window.history.pushState) {
            const cleanUrl = window.location.pathname;
            window.history.pushState({ modal: true }, '', cleanUrl);
        }
        document.title = this.originalTitle;
    }

    restoreUrl() {
        if (window.history.back) {
            window.history.back();
        }
    }

    showSuccess(message, callback) {
        const body = this.modal.querySelector('.modal-body');
        body.innerHTML = `
            <div class="modal-success">
                <i class="fas fa-check-circle" style="font-size: 48px; margin-bottom: 15px;"></i>
                <p style="font-size: 18px; margin: 0;">${message}</p>
            </div>
        `;
        
        if (callback) {
            setTimeout(callback, 2000);
        }
    }

    showError(message, callback) {
        const body = this.modal.querySelector('.modal-body');
        body.innerHTML = `
            <div class="modal-error">
                <i class="fas fa-exclamation-triangle" style="font-size: 48px; margin-bottom: 15px;"></i>
                <p style="font-size: 18px; margin: 0;">${message}</p>
            </div>
        `;
        
        if (callback) {
            setTimeout(callback, 3000);
        }
    }

    showLoading() {
        const body = this.modal.querySelector('.modal-body');
        body.innerHTML = `
            <div class="modal-loading">
                <div class="modal-loading-spinner"></div>
                <div class="modal-loading-text">处理中...</div>
            </div>
        `;
    }
}

// 创建全局实例
var gameModal = new GameModal();

// 打开注册弹窗
function openRegisterModal() {
    console.log('Opening register modal');
    gameModal.open({
        title: '注册账号',
        size: 'medium',
        type: 'url',
        content: 'register_modal.asp',
        icon: 'fas fa-user-plus'
    });
}

// 打开抽奖弹窗
function openLotteryModal() {
    console.log('Opening lottery modal');
    gameModal.open({
        title: '幸运抽奖',
        size: 'large',
        type: 'url',
        content: 'lottery_modal.asp',
        icon: 'fas fa-gift'
    });
    return false;
}

// 页面加载完成后初始化
document.addEventListener('DOMContentLoaded', function() {
    console.log('Modal framework initialized');
    
    document.querySelectorAll('[data-modal]').forEach(element => {
        element.addEventListener('click', function(e) {
            e.preventDefault();
            const options = JSON.parse(this.getAttribute('data-modal'));
            gameModal.open(options);
        });
    });
});

function switchCharacter(charId) {
    if (!charId) return;
    
    const selectEl = document.getElementById('charSelect');
    const wrapper = selectEl.parentElement;
    
    wrapper.style.transform = 'scale(0.95)';
    wrapper.style.opacity = '0.6';
    selectEl.style.borderColor = '#ff6b6b';
    
    setTimeout(() => {
        wrapper.style.transform = 'scale(1)';
        wrapper.style.opacity = '1';
        selectEl.style.borderColor = 'rgba(74, 158, 255, 0.5)';
    }, 200);
    
    var xhr = new XMLHttpRequest();
    xhr.open('GET', 'ShopCore.asp?Action=SetCurrentCharacter&Id=' + charId, true);
    xhr.onreadystatechange = function() {
        if (xhr.readyState == 4 && xhr.status == 200) {
            var currentUrl = window.location.pathname + window.location.search;
            currentUrl = currentUrl.replace(/([?&])Id=[^&]*/, '$1Id=' + charId);
            if (currentUrl.indexOf('Id=') === -1) {
                currentUrl += (currentUrl.indexOf('?') === -1 ? '?' : '&') + 'Id=' + charId;
            }
            window.location.href = currentUrl;
        }
    };
    xhr.send();
}

document.addEventListener('DOMContentLoaded', function() {
    const charSelect = document.getElementById('charSelect');
    if (charSelect) {
        charSelect.style.opacity = '0';
        charSelect.style.transform = 'translateY(-10px)';
        
        setTimeout(() => {
            charSelect.style.transition = 'all 0.5s ease';
            charSelect.style.opacity = '1';
            charSelect.style.transform = 'translateY(0)';
        }, 100);
    }
});
</script>


    <script src="tc/popup.js"></script>
    <script src="tc/config.js"></script>
    <!-- 在页面加载完成后初始化 -->
<script>
document.addEventListener('DOMContentLoaded', function() {
    // 加载游戏配置
    fetch('config.json')
        .then(response => response.json())
        .then(data => {
            // 将配置保存到全局变量
            window.gameConfig = data;
            console.log('游戏配置已加载');
        })
        .catch(error => {
            console.error('加载游戏配置失败:', error);
        });
});
</script>


<!-- 在body标签结束前添加 -->
<script src="static/js/modal.js"></script>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
</body>