<!--#include file="inc/conn.asp"-->
<!--#include file="inc/char.asp"-->
<%
Response.ContentType = "text/html; charset=UTF-8"

' 检查用户是否登录
If Not ChkLogin Then
    Response.Write "<div style='text-align:center; padding:50px; color:#e74c3c;'>请先登录后再进行抽奖</div>"
    Response.End()
End If

' 获取当前角色ID（优先使用session中的）
Dim Id, currentUserNo, characterName, bBalance
Id = Trim(Request("Id"))
If Id = "" Then Id = Session("current_char_id")

' 获取用户的所有角色
Dim charList, charOptions
charList = ""
charOptions = ""
Set rsChars = conn_c.Execute("SELECT character_no, character_name, wlevel FROM User_Character WHERE user_no='" & session("user_no") & "' ORDER BY wlevel DESC")
If Not rsChars.EOF Then
    Do While Not rsChars.EOF
        Dim charNo, charName, charLevel
        charNo = Trim(rsChars("character_no"))
        charName = Trim(rsChars("character_name"))
        charLevel = rsChars("wlevel")
        
        ' 如果没有指定ID，使用第一个角色
        If Id = "" Then Id = charNo
        
        ' 构建选项列表
        charOptions = charOptions & "<option value='" & charNo & "'"
        If Id = charNo Then charOptions = charOptions & " selected"
        charOptions = charOptions & ">" & charName & " (Lv." & charLevel & ")</option>"
        
        ' 构建角色信息数组
        charList = charList & "{'id':'" & charNo & "','name':'" & charName & "','level':" & charLevel & "},"
        
        rsChars.MoveNext
    Loop
    ' 移除最后的逗号
    If Len(charList) > 0 Then charList = Left(charList, Len(charList) - 1)
End If
rsChars.Close

' 验证角色归属
Set rsChar = conn_c.Execute("SELECT user_no, character_name FROM User_Character WHERE character_no = '" & Id & "' AND user_no='" & session("user_no") & "'")
If rsChar.EOF Then
    Response.Write "<div style='text-align:center; padding:50px; color:#e74c3c;'>无法找到角色信息</div>"
    Response.End()
Else
    currentUserNo = Trim(rsChar("user_no") & "")
    characterName = Trim(rsChar("character_name") & "")
    ' 保存当前选择的角色到session
    Session("current_char_id") = Id
End If
rsChar.Close

' 获取B币余额
bBalance = 0
Set rsB = conn_b.Execute("select isnull(b_amount,0) as b_amount from user_cash with (nolock) where user_no='" & currentUserNo & "'")
If Not rsB.EOF Then 
    bBalance = CLng(rsB("b_amount"))
End If
rsB.Close
%>
<div class="lottery-container">
    <!-- 滚动公告栏 -->
    <div class="top-announcement-bar">
        <div class="announcement-content" id="scrollAnnouncement">
            <!-- 动态内容 -->
        </div>
    </div>
    
    <!-- 像素风格标题 -->
    <div class="pixel-header">🎮 像素幸运抽奖 🎮</div>
    
    <!-- 主要内容区：左侧九宫格，右侧信息 -->
    <div class="main-content">
        <!-- 左侧：九宫格抽奖区 -->
        <div class="lottery-section">
            <!-- 8格+1按钮的九宫格 -->
            <div class="pixel-grid" id="prizeGrid">
                <!-- 动态生成8个奖品 + 1个中心按钮 -->
            </div>
        </div>
        
        <!-- 右侧：信息区 -->
        <div class="info-section">
            <!-- 角色选择 -->
            <div class="pixel-char-select">
                <div class="select-title">👤 选择角色</div>
                <select id="characterSelect" class="character-select">
                    <%=charOptions%>
                </select>
                <div class="current-char">
                    当前: <span id="currentCharName"><%=characterName%></span>
                </div>
            </div>
            
            <!-- 货币信息 -->
            <div class="pixel-info">
                <div class="info-title">💰 货币信息</div>
                <div class="info-item">
                    <span class="info-label">当前B币:</span>
                    <span class="info-value" id="bBalance"><%=bBalance%></span>
                </div>
                <div class="info-item">
                    <span class="info-label">每次消耗:</span>
                    <span class="info-value" id="drawCost">10</span>
                </div>
            </div>
            
            <!-- 抽奖须知 -->
            <div class="pixel-notice">
                <div class="notice-title">📜 抽奖须知</div>
                <ul>
                    <li>每次抽奖消耗10 B币</li>
                    <li>所有奖品通过游戏邮件发送</li>
                    <li>中奖概率以游戏内设定为准</li>
                    <li>奖品将发送到选中角色的邮箱</li>
                    <li>祝您好运，抽到心仪大奖！</li>
                </ul>
            </div>
        </div>
    </div>
</div>

<style>
@import url('https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap');
@import url('https://fonts.googleapis.com/css2?family=ZCOOL+KuaiLe&display=swap');

/* 基础样式 */
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    /* 随机背景图片 */
    background: url('https://picsum.photos/seed/pixel<%=Timer()%>/1920/1080.jpg') center/cover no-repeat;
    font-family: 'Press Start 2P', monospace;
    color: #fff;
    overflow-x: hidden;
    padding: 10px 20px 20px;
}

.lottery-container {
    width: 95%;
    max-width: 1000px;
    margin: 0 auto;
    position: relative;
    min-height: 600px;
}

/* 滚动公告栏 */
.top-announcement-bar {
    position: sticky;
    top: 0;
    width: 100%;
    height: 40px;
    background: rgba(20, 20, 30, 0.9);
    border: 3px solid #f1c40f;
    border-radius: 4px;
    overflow: hidden;
    margin-bottom: 15px;
    padding: 5px;
    z-index: 100;
    box-shadow: 0 4px 0 #000, inset 0 0 10px rgba(0,0,0,0.5);
}

.announcement-content {
    white-space: nowrap;
    font-size: 12px;
    color: #fff;
    animation: scroll-left 20s linear infinite;
    text-shadow: 1px 1px 0 #000;
    line-height: 30px;
}

@keyframes scroll-left {
    0% { transform: translateX(100%); }
    100% { transform: translateX(-100%); }
}

/* 像素风格标题 */
.pixel-header {
    text-align: center;
    font-size: 24px;
    color: #f1c40f;
    margin-bottom: 15px;
    text-shadow: 2px 2px 0 #000;
    font-family: 'ZCOOL KuaiLe', cursive;
    letter-spacing: 2px;
    padding: 10px;
    background: rgba(40, 40, 50, 0.7);
    border: 3px solid #f1c40f;
    border-radius: 4px;
    box-shadow: 0 4px 0 #000, inset 0 0 10px rgba(0,0,0,0.5);
}

/* 主要内容区布局 */
.main-content {
    display: flex;
    gap: 20px;
    min-height: 500px;
}

/* 左侧：九宫格抽奖区 */
.lottery-section {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
}

/* 8格+1按钮的九宫格容器 */
.pixel-grid {
    width: 450px;
    height: 450px;
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    grid-template-rows: repeat(3, 1fr);
    gap: 10px;
    background: rgba(40, 40, 50, 0.7);
    border: 3px solid #f1c40f;
    border-radius: 4px;
    padding: 15px;
    box-shadow: 0 6px 0 #000, inset 0 0 10px rgba(0,0,0,0.5);
    margin-bottom: 0;
}

/* 奖品格子样式 */
.prize-tile {
    position: relative;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    font-size: 12px;
    color: #fff;
    text-align: center;
    padding: 10px;
    background: rgba(60, 60, 80, 0.9);
    border: 2px solid #f1c40f;
    border-radius: 4px;
    box-shadow: 
        0 4px 0 #000, 
        inset 0 0 10px rgba(0,0,0,0.5),
        inset 0 0 5px rgba(241, 196, 15, 0.3);
    overflow: hidden;
    transition: all 0.2s;
    font-family: 'ZCOOL KuaiLe', cursive;
    cursor: pointer;
}

.prize-tile:hover {
    transform: translateY(-2px);
    box-shadow: 
        0 6px 0 #000, 
        inset 0 0 15px rgba(241, 196, 15, 0.7);
    background: rgba(80, 80, 100, 0.9);
}

/* 中心抽奖按钮样式 */
.spin-tile {
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #e74c3c, #c0392b);
    border: 3px solid #fff;
    border-radius: 4px;
    box-shadow: 
        0 6px 0 #8e2424, 
        inset 0 0 15px rgba(0,0,0,0.7),
        inset 0 0 10px rgba(255,255,255,0.3);
    cursor: pointer;
    transition: all 0.2s;
    animation: pulseBtn 2s infinite;
}

@keyframes pulseBtn {
    0% { transform: scale(1); }
    50% { transform: scale(1.05); }
    100% { transform: scale(1); }
}

.spin-tile:hover {
    transform: translateY(-2px) scale(1.05);
    background: linear-gradient(135deg, #c0392b, #a93226);
    box-shadow: 
        0 8px 0 #8e2424, 
        inset 0 0 20px rgba(0,0,0,0.8),
        inset 0 0 15px rgba(255,255,255,0.5);
}

.spin-tile:active {
    transform: translateY(2px) scale(0.98);
    box-shadow: 
        0 2px 0 #8e2424, 
        inset 0 0 10px rgba(0,0,0,0.8);
}

.spin-tile:disabled {
    background: #7f8c8d;
    cursor: not-allowed;
    box-shadow: 0 2px 0 #555, inset 0 0 10px rgba(0,0,0,0.5);
    animation: none;
}

.spin-tile .btn-text {
    font-family: 'Press Start 2P';
    font-size: 16px;
    color: #fff;
    text-shadow: 2px 2px 0 #000;
    font-weight: bold;
}

/* 像素风格图标 */
.prize-icon {
    font-size: 24px;
    margin-bottom: 5px;
    text-shadow: 1px 1px 0 #000;
}

/* 抽奖动画效果 */
.prize-tile.active {
    animation: pixelGlow 0.3s ease;
    background: rgba(241, 196, 15, 0.3);
    border-color: #fff;
    transform: scale(1.05);
}

@keyframes pixelGlow {
    0% { 
        box-shadow: 0 4px 0 #000, inset 0 0 10px rgba(0,0,0,0.5);
    }
    50% { 
        box-shadow: 
            0 4px 0 #000, 
            0 0 15px rgba(241, 196, 15, 0.8),
            inset 0 0 15px rgba(241, 196, 15, 0.5);
    }
    100% { 
        box-shadow: 0 4px 0 #000, inset 0 0 10px rgba(0,0,0,0.5);
    }
}

/* 中奖效果 */
.prize-tile.winner {
    animation: pixelWinner 1s infinite;
    background: rgba(241, 196, 15, 0.5);
    border-color: #fff;
}

@keyframes pixelWinner {
    0% { 
        transform: scale(1);
        box-shadow: 0 4px 0 #000, inset 0 0 10px rgba(0,0,0,0.5);
    }
    50% { 
        transform: scale(1.1);
        box-shadow: 
            0 4px 0 #000, 
            0 0 20px rgba(241, 196, 15, 1),
            inset 0 0 20px rgba(241, 196, 15, 0.8);
    }
    100% { 
        transform: scale(1);
        box-shadow: 0 4px 0 #000, inset 0 0 10px rgba(0,0,0,0.5);
    }
}

/* 右侧：信息区 */
.info-section {
    width: 300px;
    display: flex;
    flex-direction: column;
    gap: 15px;
}

/* 角色选择框 */
.pixel-char-select {
    background: rgba(40, 40, 50, 0.7);
    border: 3px solid #f1c40f;
    border-radius: 4px;
    padding: 15px;
    box-shadow: 0 4px 0 #000, inset 0 0 10px rgba(0,0,0,0.5);
}

.select-title {
    font-size: 14px;
    color: #f1c40f;
    margin-bottom: 10px;
    text-shadow: 1px 1px 0 #000;
    font-family: 'ZCOOL KuaiLe', cursive;
    text-align: center;
    padding-bottom: 8px;
    border-bottom: 2px dashed #f1c40f;
}

.character-select {
    width: 100%;
    padding: 8px;
    background: rgba(20, 20, 30, 0.8);
    border: 2px solid #f1c40f;
    border-radius: 4px;
    color: #fff;
    font-family: 'Press Start 2P';
    font-size: 12px;
    cursor: pointer;
    margin-bottom: 8px;
    text-shadow: 1px 1px 0 #000;
}

.character-select:focus {
    outline: none;
    border-color: #fff;
    box-shadow: 0 0 10px rgba(241, 196, 15, 0.5);
}

.current-char {
    font-size: 11px;
    color: #ddd;
    text-align: center;
    text-shadow: 1px 1px 0 #000;
}

.current-char span {
    color: #f1c40f;
    font-weight: bold;
}

/* 像素风格信息框 */
.pixel-info, .pixel-notice {
    background: rgba(40, 40, 50, 0.7);
    border: 3px solid #f1c40f;
    border-radius: 4px;
    padding: 15px;
    box-shadow: 0 4px 0 #000, inset 0 0 10px rgba(0,0,0,0.5);
}

/* 信息标题 */
.info-title, .notice-title {
    font-size: 14px;
    color: #f1c40f;
    margin-bottom: 10px;
    text-shadow: 1px 1px 0 #000;
    font-family: 'ZCOOL KuaiLe', cursive;
    text-align: center;
    padding-bottom: 8px;
    border-bottom: 2px dashed #f1c40f;
}

/* 信息项 */
.info-item {
    display: flex;
    justify-content: space-between;
    margin-bottom: 8px;
    font-size: 12px;
    color: #ddd;
    text-shadow: 1px 1px 0 #000;
}

.info-label {
    color: #aaa;
}

.info-value {
    color: #f1c40f;
    font-weight: bold;
}

/* 抽奖须知列表 */
.pixel-notice ul {
    list-style-type: none;
    padding-left: 0;
    color: #ddd;
    font-size: 11px;
    line-height: 1.6;
    font-family: 'ZCOOL KuaiLe', cursive;
}

.pixel-notice li {
    margin-bottom: 8px;
    padding-left: 20px;
    position: relative;
}

.pixel-notice li::before {
    content: '▶';
    position: absolute;
    left: 0;
    color: #f1c40f;
    text-shadow: 1px 1px 0 #000;
}

/* 响应式设计 */
@media (max-width: 992px) {
    .main-content {
        flex-direction: column;
        align-items: center;
    }
    
    .info-section {
        width: 100%;
        max-width: 450px;
    }
    
    .pixel-grid {
        width: 400px;
        height: 400px;
    }
}

@media (max-width: 768px) {
    .pixel-grid {
        width: 350px;
        height: 350px;
        gap: 8px;
        padding: 10px;
    }
    
    .prize-tile {
        font-size: 10px;
        padding: 8px;
    }
    
    .prize-icon {
        font-size: 20px;
    }
    
    .spin-tile .btn-text {
        font-size: 14px;
    }
    
    .pixel-header {
        font-size: 20px;
    }
}

@media (max-width: 480px) {
    .pixel-grid {
        width: 300px;
        height: 300px;
        gap: 5px;
        padding: 8px;
    }
    
    .prize-tile {
        font-size: 9px;
        padding: 5px;
    }
    
    .prize-icon {
        font-size: 16px;
    }
    
    .spin-tile .btn-text {
        font-size: 12px;
    }
    
    .info-section {
        width: 100%;
    }
}
</style>

<script src="https://cdn.staticfile.org/jquery/1.8.3/jquery.min.js"></script>
<script>
(function() {
    var drawCost = 10;
    var prizes = [];
    var charId = "<%=Id%>";
    var drawUrl = "ShopCore.asp?Action=LotterySpin&Id=" + encodeURIComponent(charId);
    var announcementUrl = "ShopCore.asp?Action=GetLotteryAnnouncements";
    var prizePoolUrl = "ShopCore.asp?Action=GetPrizePool";

    var bBalanceEl = document.getElementById("bBalance");
    var spinBtn = null; // 将在renderGrid中设置
    var prizeGrid = document.getElementById("prizeGrid");
    var scrollAnnouncement = document.getElementById("scrollAnnouncement");
    var characterSelect = document.getElementById("characterSelect");
    var currentCharNameEl = document.getElementById("currentCharName");

    // 角色信息数组
    var characters = [<%=charList%>];

    // 像素图标映射
    var prizeIcons = {
        "金币": "💰",
        "钻石": "💎",
        "商城币": "🪙",
        "装备": "⚔️",
        "道具": "🎁",
        "材料": "🧱",
        "药水": "🧪",
        "卷轴": "📜",
        "宝石": "💠"
    };

    function getPrizeIcon(prizeName) {
        for (var key in prizeIcons) {
            if (prizeName.indexOf(key) !== -1) {
                return prizeIcons[key];
            }
        }
        return "🎁"; // 默认图标
    }

    function renderGrid() {
        prizeGrid.innerHTML = '';
        
        // 生成8个奖品格子 + 1个中心按钮
        for (var i = 0; i < 9; i++) {
            var tile = document.createElement('div');
            
            if (i === 4) {
                // 中心位置（第5个）是抽奖按钮
                tile.className = 'prize-tile spin-tile';
                tile.id = 'spinBtn';
                tile.innerHTML = '<span class="btn-text">开始抽奖</span>';
                spinBtn = tile;
            } else {
                // 其他位置是奖品
                tile.className = 'prize-tile';
                var prizeIndex = i < 4 ? i : i - 1; // 跳过中心位置
                tile.id = 'prize-' + prizeIndex;
                
                if (prizes[prizeIndex]) {
                    var icon = getPrizeIcon(prizes[prizeIndex].name);
                    tile.innerHTML = '<div class="prize-icon">' + icon + '</div>' + prizes[prizeIndex].name;
                } else {
                    tile.innerHTML = '<div class="prize-icon">🎁</div>...';
                }
            }
            
            prizeGrid.appendChild(tile);
        }
        
        // 绑定抽奖按钮事件
        if (spinBtn) {
            spinBtn.addEventListener("click", function() {
                startLottery();
            });
        }
    }

    // 角色选择事件
    characterSelect.addEventListener("change", function() {
        var selectedCharId = this.value;
        var selectedChar = characters.find(function(c) { return c.id === selectedCharId; });
        
        if (selectedChar) {
            charId = selectedCharId;
            currentCharNameEl.textContent = selectedChar.name;
            
            // 更新抽奖URL
            drawUrl = "ShopCore.asp?Action=LotterySpin&Id=" + encodeURIComponent(charId);
            
            // 重新加载奖池（因为不同角色可能有不同奖池）
            loadPrizePool();
        }
    });

    function loadAnnouncements() {
        $.ajax({
            url: announcementUrl,
            type: 'GET',
            dataType: 'json',
            success: function(res) {
                console.log('Announcement Response:', res);
                if (res.ok) {
                    if (res.announcements && res.announcements.length > 0) {
                        var announcementText = '';
                        res.announcements.forEach(function(item) {
                            announcementText += '<span class="player-name">' + item.name + '</span> 抽中了 <span class="prize-name">' + item.prize + '</span>    ';
                        });
                        scrollAnnouncement.innerHTML = announcementText;
                    } else {
                        scrollAnnouncement.innerHTML = '暂无中奖记录，快来成为第一个幸运儿吧！';
                    }
                } else {
                    scrollAnnouncement.innerHTML = '公告加载失败: ' + (res.msg || '未知错误');
                }
            },
            error: function(error) {
                console.error('Announcement Fetch Error:', error);
                scrollAnnouncement.innerHTML = '公告加载失败，网络错误。';
            }
        });
    }

    function updateBalance(v) { 
        bBalanceEl.textContent = v; 
    }

    function alertMsg(title, text, type) {
        if (window.parent && window.parent.swal) {
            window.parent.swal({ title: title, text: text, type: type });
        } else if (window.swal) {
            swal({ title: title, text: text, type: type });
        } else {
            alert(title + " - " + text);
        }
    }

    // 像素风格抽奖动画
    function startAnimation(winIndex) {
        var tiles = document.querySelectorAll('.prize-tile:not(.spin-tile)');
        var count = 0, speed = 100, finalIndex = winIndex, rounds = 3;
        var totalSteps = rounds * 8 + finalIndex; // 8个奖品格子
        spinBtn.disabled = true;
        spinBtn.querySelector('.btn-text').textContent = '抽奖中...';
        
        var interval = setInterval(function() {
            // 移除所有active类
            tiles.forEach(function(t) { t.classList.remove('active'); });
            
            // 添加active类到当前格子
            tiles[count % 8].classList.add('active');
            
            count++;
            if (count >= totalSteps) {
                clearInterval(interval);
                
                // 移除所有active类
                tiles.forEach(function(t) { t.classList.remove('active'); });
                
                // 添加winner类到中奖格子
                tiles[finalIndex].classList.add('winner');
                
                spinBtn.disabled = false;
                spinBtn.querySelector('.btn-text').textContent = '开始抽奖';
            }
        }, speed);
    }

    function startLottery() {
        var balance = parseInt(bBalanceEl.textContent || "0", 10);
        if (balance < drawCost) {
            alertMsg("提示", "B币不足，当前余额：" + balance + "，需要：" + drawCost, "warning");
            return;
        }
        
        spinBtn.disabled = true;
        spinBtn.querySelector('.btn-text').textContent = '抽奖中...';
        
        $.ajax({
            url: drawUrl,
            type: "POST",
            headers: { "X-Requested-With": "XMLHttpRequest" },
            dataType: 'json',
            success: function(res) {
                console.log('Lottery Response:', res);
                if (!res.ok) {
                    spinBtn.disabled = false;
                    spinBtn.querySelector('.btn-text').textContent = '开始抽奖';
                    alertMsg("错误", res.msg || "抽奖失败", "error");
                    if (typeof res.remainBB === "number") updateBalance(res.remainBB);
                    return;
                }
                prizes = res.prizes;
                renderGrid(); // 重新渲染以更新奖品
                updateBalance(res.remainBB);
                startAnimation(res.index);
                setTimeout(function() {
                    alertMsg("恭喜！", "获得：" + res.prizeLabel + "（已发送到 " + currentCharNameEl.textContent + " 的邮箱）", "success");
                    loadAnnouncements();
                }, (3 * 8 + res.index) * 100 + 500);
            },
            error: function(xhr, status, error) {
                console.error('Lottery Error:', error);
                spinBtn.disabled = false;
                spinBtn.querySelector('.btn-text').textContent = '开始抽奖';
                alertMsg("错误", "网络异常，请重试", "error");
            }
        });
    }

    function loadPrizePool() {
        $.ajax({
            url: prizePoolUrl,
            type: 'GET',
            dataType: 'json',
            success: function(res) {
                console.log('PrizePool Response:', res);
                if (res.ok) {
                    prizes = res.prizes;
                    renderGrid();
                } else {
                    alertMsg("错误", "无法加载奖池: " + (res.msg || '未知错误'), "error");
                }
            },
            error: function(error) {
                console.error('PrizePool Fetch Error:', error);
                alertMsg("错误", "奖池加载失败", "error");
            }
        });
    }

    function init() {
        loadPrizePool();
        loadAnnouncements();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
</script>
