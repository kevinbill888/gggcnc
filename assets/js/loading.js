// Loading管理器
const LoadingManager = {
    init: function() {
        this.createParticles();
        this.simulateProgress();
        // 页面加载完成后自动隐藏
        setTimeout(() => {
            this.hideLoading();
        }, 1500);
        console.log('LoadingManager initialized');
    },
    
    createParticles: function() {
        const particlesContainer = document.getElementById('particles');
        if (!particlesContainer) return;
        
        for (let i = 0; i < 20; i++) {
            const particle = document.createElement('div');
            particle.className = 'particle';
            particle.style.left = Math.random() * 100 + '%';
            particle.style.top = Math.random() * 100 + '%';
            particle.style.animationDelay = Math.random() * 3 + 's';
            particle.style.animationDuration = (3 + Math.random() * 2) + 's';
            particlesContainer.appendChild(particle);
        }
    },
    
    simulateProgress: function() {
        const progressBar = document.getElementById('progressBar');
        if (!progressBar) return;
        
        // 重置进度条
        progressBar.style.width = '0%';
        
        let progress = 0;
        const interval = setInterval(() => {
            progress += Math.random() * 15;
            if (progress >= 100) {
                progress = 100;
                clearInterval(interval);
            }
            progressBar.style.width = progress + '%';
        }, 200);
    },
    
    showLoading: function(text = '加载中...') {
        const overlay = document.getElementById('loadingOverlay');
        const loadingText = document.querySelector('.loading-text');
        if (overlay) {
            overlay.style.display = 'flex';
            if (loadingText) loadingText.textContent = text;
            // 调用进度条模拟
            LoadingManager.simulateProgress();
        }
    },
    
    hideLoading: function() {
        setTimeout(() => {
            const overlay = document.getElementById('loadingOverlay');
            if (overlay) {
                overlay.style.opacity = '0';
                overlay.style.transition = 'opacity 0.5s ease';
                setTimeout(() => {
                    overlay.style.display = 'none';
                    overlay.style.opacity = '1';
                }, 500);
            }
        }, 500);
    }
};

// 创建全局函数 - 直接调用LoadingManager的方法
window.showLoading = function(text = '加载中...') {
    LoadingManager.showLoading(text);
};

window.hideLoading = function() {
    LoadingManager.hideLoading();
};

// Toast提示函数
window.showToast = function(message, type = 'info') {
    // 确保页面已加载
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            showToast(message, type);
        });
        return;
    }
    
    // 创建toast元素
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.style.cssText = `
        position: fixed;
        top: 80px;
        right: 20px;
        background: ${type === 'success' ? '#28a745' : type === 'error' ? '#dc3545' : '#17a2b8'};
        color: white;
        padding: 12px 20px;
        border-radius: 8px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.3);
        z-index: 9999999;
        animation: slideIn 0.3s ease;
        max-width: 300px;
        font-weight: 500;
    `;
    toast.textContent = message;
    
    // 添加动画样式
    if (!document.getElementById('toastStyles')) {
        const style = document.createElement('style');
        style.id = 'toastStyles';
        style.textContent = `
            @keyframes slideIn {
                from { transform: translateX(100%); opacity: 0; }
                to { transform: translateX(0); opacity: 1; }
            }
            @keyframes slideOut {
                from { transform: translateX(0); opacity: 1; }
                to { transform: translateX(100%); opacity: 0; }
            }
        `;
        document.head.appendChild(style);
    }
    
    // 添加到页面
    document.body.appendChild(toast);
    
    // 添加控制台日志确认Toast已创建
    console.log('Toast created:', message, type);
    
    // 3秒后自动移除
    setTimeout(() => {
        toast.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        }, 300);
    }, 3000);
};
