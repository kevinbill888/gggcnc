/**
 * 弹窗系统 - 支持内联弹窗和跨域弹窗
 */
class PopupSystem {
    constructor() {
        this.init();
    }

    init() {
        // 创建弹窗容器
        this.createModalOverlay();
        this.createCrossDomainContainer();
        
        // 绑定全局事件
        this.bindEvents();
    }

    createModalOverlay() {
        if (!document.getElementById('modalOverlay')) {
            const overlay = document.createElement('div');
            overlay.id = 'modalOverlay';
            overlay.className = 'modal-overlay';
            overlay.innerHTML = `
                <div class="modal-content" id="modalContent">
                    <div class="modal-header">
                        <h3 class="modal-title" id="modalTitle">弹窗标题</h3>
                        <button class="modal-close" onclick="popup.closeModal()">
                            <i class="fas fa-times"></i>
                        </button>
                    </div>
                    <div class="modal-body" id="modalBody">
                        <!-- 内容区域 -->
                    </div>
                </div>
            `;
            document.body.appendChild(overlay);
        }
    }

    createCrossDomainContainer() {
        if (!document.getElementById('popupContainer')) {
            const container = document.createElement('div');
            container.id = 'popupContainer';
            container.className = 'popup-container';
            container.innerHTML = `
                <div class="popup-close" onclick="popup.closeCrossDomain()">
                    <i class="fas fa-times"></i>
                </div>
                <iframe class="popup-iframe" id="popupIframe"></iframe>
            `;
            document.body.appendChild(container);
        }
    }

    bindEvents() {
        // 点击遮罩关闭弹窗
        document.getElementById('modalOverlay').addEventListener('click', (e) => {
            if (e.target.id === 'modalOverlay') {
                this.closeModal();
            }
        });

        // ESC键关闭弹窗
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.closeModal();
                this.closeCrossDomain();
            }
        });
    }

    /**
     * 显示内联弹窗
     * @param {Object} options - 弹窗配置
     */
    showModal(options = {}) {
        const {
            title = '弹窗标题',
            content = '',
            width = 600,
            height = 400,
            url = null,
            html = null
        } = options;

        const modalTitle = document.getElementById('modalTitle');
        const modalBody = document.getElementById('modalBody');
        const modalContent = document.getElementById('modalContent');

        modalTitle.textContent = title;

        if (url) {
            // 显示iframe内容
            modalBody.innerHTML = `
                <div class="iframe-container" style="height: ${height - 100}px;">
                    <div class="iframe-loader">
                        <div class="loader mb-4"></div>
                        <p class="text-gray-400">正在加载内容...</p>
                    </div>
                    <iframe src="${url}" style="display: none; width: 100%; height: 100%;" 
                            onload="this.style.display='block'; this.previousElementSibling.style.display='none';"
                            sandbox="allow-same-origin allow-scripts allow-forms allow-popups"></iframe>
                </div>
            `;
        } else if (html) {
            // 直接显示HTML内容
            modalBody.innerHTML = html;
        } else {
            // 显示普通内容
            modalBody.innerHTML = `<div class="text-gray-300">${content}</div>`;
        }

        // 设置弹窗大小和位置
        modalContent.style.width = `${width}px`;
        modalContent.style.height = `${height}px`;
        modalContent.style.left = '50%';
        modalContent.style.top = '50%';
        modalContent.style.transform = 'translate(-50%, -50%)';

        // 显示弹窗
        document.getElementById('modalOverlay').style.display = 'block';
    }

    /**
     * 显示跨域弹窗
     * @param {Object} options - 弹窗配置
     */
    showCrossDomain(options = {}) {
        const {
            url,
            title = '弹窗标题',
            width = 960,
            height = 640,
            x = 0,
            y = 0,
            contentWidth = 1200,
            contentHeight = 800,
            keepShell = false,
            resizable = true,
            autoJumpDelay = 800
        } = options;

        const escapeHtml = s =>
            String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');

        const availW = window.screen.availWidth || window.screen.width;
        const availH = window.screen.availHeight || window.screen.height;
        const left = Math.max(0, Math.round((availW - width) / 2));
        const top = Math.max(0, Math.round((availH - height) / 3));

        let popup;
        try {
            popup = window.open(
                '',
                'PopupWindow_' + Date.now(),
                [
                    `width=${Math.max(200, width|0)}`,
                    `height=${Math.max(200, height|0)}`,
                    `left=${left}`,
                    `top=${top}`,
                    `resizable=${resizable ? 'yes' : 'no'}`,
                    'scrollbars=yes',
                    'location=no',
                    'menubar=no',
                    'toolbar=no',
                    'status=no'
                ].join(',')
            );

            if (!popup || popup.closed) {
                alert('弹窗被阻止，请允许本站弹出窗口');
                return;
            }

            const escUrl = escapeHtml(url);
            const seconds = Math.max(0, Math.round((autoJumpDelay || 0) / 1000));
            const metaRefresh = keepShell ? '' : `<meta http-equiv="refresh" content="${seconds}; url=${escUrl}">`;

            popup.document.write(`
              <!doctype html>
              <html lang="zh-CN">
              <head>
                <meta charset="utf-8">
                ${metaRefresh}
                <meta name="viewport" content="width=device-width,initial-scale=1">
                <title>${escapeHtml(title)}</title>
                <style>
                  :root{ --glass: rgba(15, 23, 42, .65); --primary: #7c5cff; --secondary: #00e0ff; --text: #e5e7eb; --muted: #9aa4b2; --border: rgba(255,255,255,.12) }
                  *{ box-sizing:border-box }
                  html,body{ height:100%; margin:0; font-family: ui-sans-serif,system-ui,Segoe UI,Roboto,Helvetica,Arial,'PingFang SC','Microsoft YaHei'; color:var(--text) }
                  body{
                    background:
                      radial-gradient(1200px 600px at 10% 10%, rgba(124,92,255,.25), transparent 60%),
                      radial-gradient(1200px 600px at 90% 90%, rgba(0,224,255,.25), transparent 50%),
                      #0b1022;
                    display:flex; flex-direction:column; overflow:hidden;
                  }
                  .topbar{
                    height: 48px; display:flex; align-items:center; justify-content:space-between; gap:10px; padding: 0 12px;
                    background: linear-gradient(90deg, rgba(20,26,46,.8), rgba(20,26,46,.4));
                    backdrop-filter: blur(10px) saturate(140%); border-bottom: 1px solid var(--border);
                  }
                  .title{
                    font-weight: 800; letter-spacing:.3px; background: linear-gradient(90deg, #fff, #99e7ff);
                    -webkit-background-clip: text; color: transparent; text-shadow: 0 0 14px rgba(0,224,255,.16); font-size: 15px;
                  }
                  .actions{ display:flex; gap:8px; align-items:center }
                  .btn{ height: 30px; padding: 0 10px; border-radius: 8px; border:1px solid var(--border); background: rgba(255,255,255,.06); color:#fff; cursor:pointer; font-weight:700 }
                  .btn.primary{ border:0; color:#0b1022; background: linear-gradient(90deg, var(--primary), var(--secondary)); box-shadow: 0 8px 18px rgba(0,224,255,.22) }
                  .shell{ position: relative; flex: 1 1 auto; margin: 10px; border-radius: 14px; overflow: hidden; background: var(--glass); border: 1px solid var(--border); box-shadow: 0 20px 40px rgba(0,0,0,.35) }
                  .hint{ position:absolute; z-index:2; left:12px; top:12px; padding: 8px 10px; border-radius: 10px; background: rgba(255,255,255,.08); border:1px solid var(--border); color: var(--muted); font-size: 12px }
                  .viewport{ position:absolute; inset:0; overflow:hidden; background:#0b1022 }
                  #GG_FRAME{ position:absolute; top:0; left:0; border:0; background:#0b1022; width:${Math.max(10, contentWidth|0)}px; height:${Math.max(10, contentHeight|0)}px; transform: translate(${x|0}px,${y|0}px) }
                  .loading{ position:absolute; right:12px; bottom:12px; z-index:2; padding: 8px 10px; border-radius: 10px; background: rgba(255,255,255,.08); border:1px solid var(--border); display:flex; align-items:center; gap:8px; color:var(--muted); font-size:12px }
                  .dot{ width:8px; height:8px; border-radius:50%; background: var(--secondary); box-shadow:0 0 10px var(--secondary); animation: pulse 1.2s infinite }
                  @keyframes pulse{ 0%{ transform:scale(.8) } 50%{ transform:scale(1) } 100%{ transform:scale(.8) } }
                </style>
              </head>
              <body oncontextmenu="return false">
                <div class="topbar">
                  <div class="title">${escapeHtml(title)}</div>
                  <div class="actions">
                    <button class="btn" onclick="try{window.open('${escUrl}','_blank')}catch(e){}">在新标签打开</button>
                    <button class="btn primary" onclick="try{window.close()}catch(e){}">关闭</button>
                  </div>
                </div>
                <div class="shell">
                  <div class="hint">正在为你打开页面… 若内嵌失败，将自动跳转。你也可点击"在新标签打开"。</div>
                  <div class="viewport"><iframe id="GG_FRAME" src="${escUrl}" referrerpolicy="no-referrer"></iframe></div>
                  <div class="loading"><span class="dot"></span> 正在连接</div>
                </div>
                <script>
                  (function(){
                    var delay = ${Math.max(0, autoJumpDelay|0)};
                    var target = '${escUrl}';
                    if (${keepShell ? 'false' : 'true'}) {
                      setTimeout(function(){
                        try { window.location.replace(target); }
                        catch(e){ try{ window.location.href = target; }catch(e2){} }
                      }, delay);
                    }
                  })();
                <\/script>
              </body>
              </html>
            `);
            popup.document.close();
            try { popup.focus(); } catch (e) {}
        } catch (e) {
            console.error(e);
            alert('无法打开弹窗，请在浏览器设置中允许弹窗权限');
        }
    }

    /**
     * 关闭内联弹窗
     */
    closeModal() {
        document.getElementById('modalOverlay').style.display = 'none';
    }

    /**
     * 关闭跨域弹窗
     */
    closeCrossDomain() {
        const container = document.getElementById('popupContainer');
        const iframe = document.getElementById('popupIframe');
        
        if (iframe) {
            iframe.src = 'about:blank';
        }
        container.style.display = 'none';
    }

    /**
     * 简化的调用方法 - 内联弹窗
     */
    inline(options) {
        this.showModal(options);
    }

    /**
     * 简化的调用方法 - 跨域弹窗
     */
    cross(options) {
        this.showCrossDomain(options);
    }
}

// 创建全局实例
const popup = new PopupSystem();

// 导出到全局
window.popup = popup;
window.TCPopup = popup;

// 便捷的全局函数
window.showPopup = (options) => popup.showModal(options);
window.showCrossPopup = (options) => popup.showCrossDomain(options);
window.closePopup = () => popup.closeModal();
window.closeCrossPopup = () => popup.closeCrossDomain();
