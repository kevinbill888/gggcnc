/**
 * 弹窗配置文件
 * 在这里配置所有弹窗参数，方便统一管理
 */
window.PopupConfig = {
    // 注册账号弹窗
    register: {
        type: 'cross', // cross 或 inline
        title: '账号注册',
        url: './register/index.php',
        width: 800,
        height: 600,
        contentWidth: 800,
        contentHeight: 600,
        autoJumpDelay: 0, // 不自动跳转
        keepShell: true
    },

    // 登录弹窗
    login: {
        type: 'inline',
        title: '用户登录',
        url: './login.html',
        width: 400,
        height: 500
    },

    // 游戏下载弹窗 - 根据配置动态生成
    getGameDownloadConfig: function(zoneId, clientIndex) {
        // 从全局配置中获取游戏区域数据
        if (!window.gameConfig || !window.gameConfig.gameZones) {
            console.error('游戏配置未加载');
            return null;
        }
        
        const zone = window.gameConfig.gameZones.find(z => z.id === zoneId);
        if (!zone || !zone.clients || !zone.clients[clientIndex]) {
            console.error('找不到指定的游戏区域或客户端');
            return null;
        }
        
        const client = zone.clients[clientIndex];
        const config = client.popupConfig || {};
        
        return {
            type: client.popupType === 'cross-domain' ? 'cross' : 'inline',
            title: `${zone.name} - ${client.name}`,
            url: client.url,
            width: config.width || 960,
            height: config.height || 640,
            contentWidth: config.contentWidth || 1200,
            contentHeight: config.contentHeight || 800,
            x: config.offsetX || 0,
            y: config.offsetY || 0,
            autoJumpDelay: config.autoJumpDelay || 800,
            keepShell: config.keepShell || false
        };
    },

    // 补丁下载弹窗 - 根据配置动态生成
    getPatchDownloadConfig: function(patchId) {
        // 从全局配置中获取补丁数据
        if (!window.gameConfig || !window.gameConfig.patches) {
            console.error('游戏配置未加载');
            return null;
        }
        
        const patch = window.gameConfig.patches.find(p => p.id === patchId);
        if (!patch) {
            console.error('找不到指定的补丁');
            return null;
        }
        
        const config = patch.popupConfig || {};
        
        return {
            type: patch.popupType === 'cross-domain' ? 'cross' : 'inline',
            title: patch.name,
            url: patch.url,
            width: config.width || 960,
            height: config.height || 640,
            contentWidth: config.contentWidth || 1200,
            contentHeight: config.contentHeight || 800,
            x: config.offsetX || 0,
            y: config.offsetY || 0,
            autoJumpDelay: config.autoJumpDelay || 800,
            keepShell: config.keepShell || false
        };
    },

    // 公告弹窗
    notice: {
        type: 'inline',
        title: '系统公告',
        html: `
            <div class="p-4">
                <h4 class="text-lg font-bold mb-3">最新公告</h4>
                <p class="text-gray-300 mb-4">这里是公告内容...</p>
                <button onclick="popup.closeModal()" class="popup-btn">我知道了</button>
            </div>
        `,
        width: 500,
        height: 300
    },

    // 帮助弹窗
    help: {
        type: 'inline',
        title: '帮助中心',
        url: './help.html',
        width: 800,
        height: 600
    },

    // 反馈弹窗
    feedback: {
        type: 'inline',
        title: '意见反馈',
        html: `
            <div class="p-4">
                <form onsubmit="alert('感谢您的反馈！'); popup.closeModal(); return false;">
                    <div class="mb-3">
                        <label class="block text-sm font-medium mb-2">您的邮箱</label>
                        <input type="email" class="w-full px-3 py-2 bg-gray-700 rounded" required>
                    </div>
                    <div class="mb-3">
                        <label class="block text-sm font-medium mb-2">反馈内容</label>
                        <textarea class="w-full px-3 py-2 bg-gray-700 rounded" rows="4" required></textarea>
                    </div>
                    <button type="submit" class="popup-btn">提交反馈</button>
                </form>
            </div>
        `,
        width: 500,
        height: 400
    }
};

/**
 * 便捷的调用函数
 * 使用方法：showConfigPopup('register')
 */
window.showConfigPopup = function(key) {
    const config = window.PopupConfig[key];
    if (!config) {
        console.error('未找到弹窗配置:', key);
        return;
    }

    if (config.type === 'cross') {
        popup.showCrossDomain(config);
    } else {
        popup.showModal(config);
    }
};

/**
 * 游戏下载弹窗调用函数
 * 使用方法：showGameDownloadPopup('zone1', 0)
 */
window.showGameDownloadPopup = function(zoneId, clientIndex) {
    const config = window.PopupConfig.getGameDownloadConfig(zoneId, clientIndex);
    if (!config) return;
    
    if (config.type === 'cross') {
        popup.showCrossDomain(config);
    } else {
        popup.showModal(config);
    }
};

/**
 * 补丁下载弹窗调用函数
 * 使用方法：showPatchDownloadPopup(1)
 */
window.showPatchDownloadPopup = function(patchId) {
    const config = window.PopupConfig.getPatchDownloadConfig(patchId);
    if (!config) return;
    
    if (config.type === 'cross') {
        popup.showCrossDomain(config);
    } else {
        popup.showModal(config);
    }
};
