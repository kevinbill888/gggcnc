<!--#include file="inc/conn.asp" -->
<%
' ============================================
' 防刷新机制 - 保护数据库资源
' ============================================
Dim refreshLimit, lastRefresh
refreshLimit = 10 ' 5秒内禁止重复刷新
lastRefresh = Session("LastRefresh")

If lastRefresh <> "" Then
    If DateDiff("s", lastRefresh, Now()) < refreshLimit Then
        ' 如果刷新间隔小于限制，显示缓存内容或错误信息
        Response.Write "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>操作频繁</title></head><body style='font-family: Arial, sans-serif; text-align: center; padding: 50px; background: #1a1a2e; color: white;'>"
        Response.Write "<div style='background: #2d3748; padding: 30px; border-radius: 10px; display: inline-block;'>"
        Response.Write "<h2 style='color: #f59e0b;'>⚠️ 操作过于频繁</h2>"
        Response.Write "<p>请等待 " & refreshLimit & " 秒后再刷新页面</p>"
        Response.Write "<p style='color: #94a3b8; font-size: 14px;'>系统保护机制已激活，防止过度消耗资源</p>"
        Response.Write "<button onclick='window.location.reload()' style='background: #3b82f6; color: white; border: none; padding: 10px 20px; border-radius: 5px; margin-top: 15px; cursor: pointer;'>重新加载</button>"
        Response.Write "</div></body></html>"
        Response.End
    End If
End If

Session("LastRefresh") = Now()

' ============================================
' 数据缓存机制 - 减少数据库查询
' ============================================
Dim cacheKey, cachedData, cacheExpiry
cacheKey = "ExchangeData_" & session("DkServer")
cacheExpiry = 30 ' 缓存30秒

' 尝试从缓存读取数据
If Application(cacheKey & "_Time") <> "" Then
    If DateDiff("s", Application(cacheKey & "_Time"), Now()) < cacheExpiry Then
        cachedData = Application(cacheKey)
    End If
End If

' 强制设置分区
Dim forceDkServer
forceDkServer = Request.QueryString("DkServer")
If forceDkServer = "" Then
    forceDkServer = "1"
End If
session("DkServer") = forceDkServer

' 重新连接数据库
On Error Resume Next

' 关闭原有连接
If IsObject(conn) Then
    conn.Close
    Set conn = Nothing
End If

' 重新包含分区配置
Select Case session("DkServer")
    Case "2" 
        %><!--#include file="inc/server_2.asp" --><%
    Case Else
        %><!--#include file="inc/server_1.asp" --><%
End Select

' 重新建立连接
connstr = "driver={SQL Server};Server=" & SQL_Server & ";UID=" & SQL_UserName & ";PWD=" & SQL_PassWord & ";database=" & DBName
Set conn = Server.CreateObject("ADODB.Connection")
conn.Open connstr

' 读取数据
Dim rsExchange, itemCount, sqlQuery
itemCount = 0

If IsArray(cachedData) Then
    ' 使用缓存数据
    exchangeData = cachedData
    itemCount = UBound(exchangeData, 1) + 1
Else
    ' 从数据库读取
    sqlQuery = "SELECT oldname, newname, needcash FROM WEB_ExchangeItem ORDER BY ID"

    Set rsExchange = Server.CreateObject("ADODB.Recordset")
    rsExchange.CursorLocation = 3
    rsExchange.Open sqlQuery, conn, 1, 1

    If Not rsExchange.EOF Then
        itemCount = rsExchange.RecordCount
        
        ' 读取数据到数组
        Dim exchangeData()
        ReDim exchangeData(itemCount-1, 3)
        
        Dim i
        i = 0
        Do While Not rsExchange.EOF
            exchangeData(i, 0) = Server.HTMLEncode(rsExchange("oldname"))
            exchangeData(i, 1) = Server.HTMLEncode(rsExchange("newname"))
            exchangeData(i, 2) = rsExchange("needcash")
            exchangeData(i, 3) = Int((5-3+1)*Rnd + 3)
            i = i + 1
            rsExchange.MoveNext
        Loop
        
        ' 存储到缓存
        Application.Lock
        Application(cacheKey) = exchangeData
        Application(cacheKey & "_Time") = Now()
        Application.UnLock
    End If

    If Not rsExchange Is Nothing Then
        rsExchange.Close
        Set rsExchange = Nothing
    End If
End If

' 关闭数据库连接
If IsObject(conn) Then
    conn.Close
    Set conn = Nothing
End If
%>
<!DOCTYPE html>
<html>
<head>
    <title>挑战装备熔炉系统 - CNCTZ-DEKARON-挑战装备熔炼</title>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <link rel="stylesheet" type="text/css" href="static/css/sweetalert.css" />
    <script type="text/javascript" src="http://apps.bdimg.com/libs/jquery/1.8.3/jquery.min.js"></script>
    <script type="text/javascript" src="static/js/sweetalert.min.js"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">

    <!-- 代码保护：禁止查看源代码 -->
    <script type="text/javascript">
    // 禁止右键菜单
    document.addEventListener('contextmenu', function(e) {
        e.preventDefault();
        showProtectionAlert('右键菜单已禁用');
        return false;
    });
    
    // 禁止选择文本
    document.addEventListener('selectstart', function(e) {
        e.preventDefault();
        return false;
    });
    
    // 禁止拖拽
    document.addEventListener('dragstart', function(e) {
        e.preventDefault();
        return false;
    });
    
    // 禁止F12、Ctrl+Shift+I、Ctrl+Shift+J、Ctrl+U
    document.addEventListener('keydown', function(e) {
        if (e.keyCode === 123 || 
            (e.ctrlKey && e.shiftKey && e.keyCode === 73) || 
            (e.ctrlKey && e.shiftKey && e.keyCode === 74) ||
            (e.ctrlKey && e.keyCode === 85)) {
            e.preventDefault();
            showProtectionAlert('开发者工具已禁用');
            return false;
        }
    });
    
    // 防止iframe嵌入
    if (window.top !== window.self) {
        window.top.location = window.self.location;
    }
    
    // 显示保护提示
    function showProtectionAlert(message) {
        if (typeof swal !== 'undefined') {
            swal({
                title: "保护提示",
                text: message,
                icon: "warning",
                button: "确定"
            });
        } else {
            alert(message);
        }
    }
    </script>
    
    <style>
        /* ============================================
           基础样式设置
           ============================================ */
        * {
            -webkit-user-select: none;
            -moz-user-select: none;
            -ms-user-select: none;
            user-select: none;
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        /* 允许部分元素选择 */
        .item-name, .price-tag, .stats-item span {
            -webkit-user-select: text;
            -moz-user-select: text;
            -ms-user-select: text;
            user-select: text;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #0c0c0c 0%, #1a1a2e 50%, #16213e 100%);
            min-height: 100vh;
            padding: 20px;
            color: #e0e0e0;
            overflow-x: hidden;
        }
        
        /* ============================================
           容器样式 - 可以调整整体大小
           ============================================ */
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: rgba(13, 17, 23, 0.95);
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.7);
            overflow: hidden;
            border: 1px solid #2d3748;
            position: relative;
        }
        
        /* 防拷贝覆盖层 */
        .protection-overlay {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            z-index: 9999;
            pointer-events: none;
        }
        
        /* ============================================
           头部样式 - 可以调整高度
           ============================================ */
        .header {
            background: linear-gradient(135deg, #1e3a8a 0%, #3730a3 50%, #5b21b6 100%);
            color: white;
            padding: 25px 30px; /* 减小了上下内边距，从35px改为25px */
            text-align: center;
            position: relative;
            overflow: hidden;
            border-bottom: 2px solid #6366f1;
        }
        
        .header h1 {
            font-size: 2.8em;
            margin-bottom: 10px; /* 减小了下边距，从12px改为10px */
            font-weight: 700;
            text-shadow: 0 2px 10px rgba(0, 0, 0, 0.5);
            background: linear-gradient(135deg, #fbbf24 0%, #f59e0b 50%, #d97706 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        
        .header .subtitle {
            font-size: 1.2em;
            opacity: 0.9;
            font-weight: 300;
            color: #cbd5e1;
        }
        
        /* ============================================
           统计栏样式 - 可以调整高度
           ============================================ */
        .stats-bar {
            background: linear-gradient(135deg, #1e293b 0%, #334155 100%);
            color: #e2e8f0;
            padding: 12px 30px; /* 减小了上下内边距，从18px改为12px */
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 0.95em;
            border-bottom: 1px solid #374151;
        }
        
        .stats-item {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .stats-item i {
            color: #f59e0b;
        }
        
        /* ============================================
           调试面板样式 - 可以调整高度
           ============================================ */
        .debug-panel {
            background: #1e3a8a;
            color: #bfdbfe;
            padding: 10px 15px; /* 减小了内边距 */
            margin: 8px 30px; /* 减小了外边距 */
            border-radius: 8px;
            font-size: 0.85em;
            border-left: 4px solid #3b82f6;
        }
        
        /* ============================================
           CSS Grid 布局 - 关键：调整列宽比例
           ============================================ */
        .grid-container {
            display: grid;
            /* 列宽比例调整：序号列宽度减小，为其他列腾出空间 */
            grid-template-columns: 5% 25% 10% 25% 15% 20%; /* 调整了各列比例 */
            background: #111827;
        }
        
        .grid-header {
            display: contents;
        }
        
        .grid-header-item {
            background: linear-gradient(135deg, #1e40af 0%, #1e3a8a 100%);
            color: #fbbf24;
            padding: 15px 18px; /* 减小了内边距，从20px 15px改为15px 12px */
            font-weight: 600;
            font-size: 1.05em;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            border-bottom: 2px solid #f59e0b;
            position: sticky;
            top: 0;
            z-index: 10;
        }
        
        .grid-body {
            display: contents;
        }
        
        .grid-row {
            display: contents;
        }
        
        /* ============================================
           表格单元格样式 - 关键：调整行高和间距
           ============================================ */
        .grid-cell {
            padding: 6px 8px; /* 减小了内边距，从20px 15px改为14px 12px */
            color: #e5e7eb;
            border-bottom: 1px solid #2d3748;
            background: #1f2937;
            display: flex;
            align-items: center;
            transition: all 0.3s ease;
        }
        
        .grid-row:nth-child(even) .grid-cell {
            background: #18212f;
        }
        
        .grid-row:hover .grid-cell {
            background: linear-gradient(135deg, #2d3748 0%, #374151 100%);
            box-shadow: 0 5px 20px rgba(0, 0, 0, 0.4);
        }
        
        /* 单独控制箭头列不参与hover效果 */
        .grid-row:hover .grid-cell.arrow-cell {
            transform: none;
            background: inherit;
            box-shadow: none;
        }
        
        /* ============================================
           滚动容器 - 关键：调整可视区域高度
           ============================================ */
        .scrolling-container {
            max-height: 900px; /* 增加了最大高度，从600px改为800px，显示更多行 */
            overflow-y: auto;
            position: relative;
        }
        
        .scrolling-container::-webkit-scrollbar {
            width: 10px;
        }
        
        .scrolling-container::-webkit-scrollbar-track {
            background: #1f2937;
            border-radius: 5px;
        }
        
        .scrolling-container::-webkit-scrollbar-thumb {
            background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
            border-radius: 5px;
            border: 2px solid #1f2937;
        }
        
        /* ============================================
           物品名称和图标样式 - 可以调整大小
           ============================================ */
        .item-name {
            font-weight: 600;
            color: #f3f4f6;
            display: flex;
            align-items: center;
            gap: 8px; /* 减小了间距，从12px改为10px */
        }
        
        .item-icon {
            width: 28px; /* 减小了尺寸，从32px改为28px */
            height: 28px; /* 减小了尺寸，从32px改为28px */
            background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
            border-radius: 6px; /* 减小了圆角，从8px改为6px */
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 13px; /* 减小了字体大小，从14px改为13px */
            font-weight: bold;
            box-shadow: 0 4px 8px rgba(99, 102, 241, 0.3);
            flex-shrink: 0;
        }
        
        .price-tag {
            background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%);
            color: white;
            padding: 5px 10px; /* 减小了内边距，从10px 18px改为8px 15px */
            border-radius: 10px; /* 减小了圆角，从25px改为20px */
            font-weight: 700;
            font-size: 0.8em; /* 减小了字体大小，从1em改为0.9em */
            display: inline-block;
            box-shadow: 0 4px 12px rgba(220, 38, 38, 0.4);
        }
        
        .popularity-stars {
            display: flex;
            gap: 3px; /* 减小了间距，从4px改为3px */
            align-items: center;
        }
        
        .star {
            color: #fbbf24;
            font-size: 12px; /* 减小了字体大小，从18px改为16px */
            text-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);
        }
        
        .hot-badge {
            background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%);
            color: white;
            padding: 5px 10px; /* 减小了内边距，从6px 12px改为5px 10px */
            border-radius: 12px; /* 减小了圆角，从15px改为12px */
            font-size: 0.7em; /* 减小了字体大小，从0.75em改为0.7em */
            margin-left: 8px; /* 减小了左边距，从10px改为8px */
            animation: glow 2s infinite;
            font-weight: 600;
        }
        
        /* ============================================
           底部样式 - 可以调整高度
           ============================================ */
        .footer {
            background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
            padding: 20px; /* 减小了内边距，从25px改为20px */
            text-align: center;
            color: #94a3b8;
            border-top: 1px solid #374151;
        }
        
        .close-btn {
            background: linear-gradient(135deg, #dc2626 0%, #991b1b 100%);
            color: white;
            border: none;
            padding: 12px 30px; /* 减小了内边距，从14px 35px改为12px 30px */
            border-radius: 25px; /* 减小了圆角，从30px改为25px */
            font-size: 1.05em; /* 减小了字体大小，从1.1em改为1.05em */
            cursor: pointer;
            transition: all 0.3s ease;
            box-shadow: 0 6px 20px rgba(220, 38, 38, 0.4);
            font-weight: 600;
        }
        
        .close-btn:hover {
            transform: translateY(-3px);
            box-shadow: 0 8px 25px rgba(220, 38, 38, 0.6);
        }
        
        @keyframes glow {
            0%, 100% { box-shadow: 0 0 5px #dc2626; }
            50% { box-shadow: 0 0 15px #dc2626; }
        }
        
        .empty-state {
            text-align: center;
            padding: 50px 30px; /* 减小了内边距，从60px 30px改为50px 30px */
            color: #9ca3af;
            grid-column: 1 / -1;
        }
        
        .empty-state i {
            font-size: 3.5em; /* 减小了字体大小，从4em改为3.5em */
            margin-bottom: 15px; /* 减小了下边距，从20px改为15px */
            color: #4b5563;
        }
        
        .empty-state h3 {
            font-size: 1.4em; /* 减小了字体大小，从1.5em改为1.4em */
            margin-bottom: 8px; /* 减小了下边距，从10px改为8px */
            color: #d1d5db;
        }
        
        /* ============================================
           升级箭头特效
           ============================================ */
        .upgrade-arrow {
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 18px; /* 减小了字体大小，从24px改为22px */
            color: #f59e0b;
            position: relative;
            width: 100%;
            height: 100%;
        }
        
        .upgrade-arrow::before {
            content: "➜";
            font-size: 22px; /* 减小了字体大小，从28px改为26px */
            text-shadow: 0 0 10px rgba(245, 158, 11, 0.7);
            animation: arrowPulse 2s infinite;
        }
        
        @keyframes arrowPulse {
            0%, 100% { 
                transform: scale(1);
                opacity: 1;
            }
            50% { 
                transform: scale(1.2);
                opacity: 0.8;
            }
        }
        
        /* ============================================
           表格行上移动画
           ============================================ */
        @keyframes slideUp {
            0% { 
                transform: translateY(0);
                opacity: 1;
            }
            100% { 
                transform: translateY(-100%);
                opacity: 0;
            }
        }
        
        .slide-up {
            animation: slideUp 0.5s ease-out forwards;
        }
        
        /* ============================================
           在线人数样式
           ============================================ */
        .online-count {
            background: linear-gradient(135deg, #059669 0%, #047857 100%);
            color: white;
            padding: 3px 10px; /* 减小了内边距，从4px 12px改为3px 10px */
            border-radius: 12px; /* 减小了圆角，从15px改为12px */
            font-size: 0.8em; /* 减小了字体大小，从0.85em改为0.8em */
            margin-left: 6px; /* 减小了左边距，从8px改为6px */
            animation: onlinePulse 3s infinite;
        }
        
        @keyframes onlinePulse {
            0%, 100% { 
                box-shadow: 0 0 5px #059669;
            }
            50% { 
                box-shadow: 0 0 15px #059669;
            }
        }
        
        /* ============================================
           热门装备边框发光效果 - 只对5星装备生效
           ============================================ */
        .hot-item .grid-cell:not(.arrow-cell) {
            position: relative;
        }
        
        .hot-item .grid-cell:not(.arrow-cell)::before {
            content: "";
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            border: 1px solid transparent;
            border-radius: 4px;
            background: linear-gradient(90deg, #f59e0b, #fbbf24, #f59e0b) border-box;
            -webkit-mask: linear-gradient(#fff 0 0) padding-box, linear-gradient(#fff 0 0);
            -webkit-mask-composite: destination-out;
            mask-composite: exclude;
            animation: borderFlow 3s linear infinite;
            opacity: 0;
            transition: opacity 0.3s ease;
        }
        
        .hot-item:hover .grid-cell:not(.arrow-cell)::before {
            opacity: 1;
        }
        
        @keyframes borderFlow {
            0% {
                background-position: -200% 0;
            }
            100% {
                background-position: 200% 0;
            }
        }
        
        /* ============================================
           更轻量的边框效果，用于4星装备
           ============================================ */
        .popular-item .grid-cell:not(.arrow-cell) {
            position: relative;
        }
        
        .popular-item .grid-cell:not(.arrow-cell)::before {
            content: "";
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            border: 1px solid transparent;
            border-radius: 4px;
            background: linear-gradient(90deg, #10b981, #34d399, #10b981) border-box;
            -webkit-mask: linear-gradient(#fff 0 0) padding-box, linear-gradient(#fff 0 0);
            -webkit-mask-composite: destination-out;
            mask-composite: exclude;
            animation: borderFlow 4s linear infinite;
            opacity: 0;
            transition: opacity 0.3s ease;
        }
        
        .popular-item:hover .grid-cell:not(.arrow-cell)::before {
            opacity: 0.7;
        }
        
        /* ============================================
           序号样式 - 可以调整大小
           ============================================ */
        .index-icon {
            width: 28px; /* 减小了尺寸，从32px改为28px */
            height: 28px; /* 减小了尺寸，从32px改为28px */
            background: linear-gradient(135deg, #6b7280 0%, #4b5563 100%);
            border-radius: 6px; /* 减小了圆角，从8px改为6px */
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 13px; /* 减小了字体大小，从14px改为13px */
            font-weight: bold;
            box-shadow: 0 4px 8px rgba(107, 114, 128, 0.3);
            flex-shrink: 0;
        }
        
        /* ============================================
           趋势箭头样式 - 可以调整大小
           ============================================ */
        .trend-arrow {
            margin-left: 6px; /* 减小了左边距，从8px改为6px */
            font-size: 14px; /* 减小了字体大小，从16px改为14px */
            font-weight: bold;
            animation: trendPulse 1.5s infinite;
        }
        
        .trend-up {
            color: #10b981;
        }
        
        .trend-down {
            color: #ef4444;
        }
        
        @keyframes trendPulse {
            0%, 100% { 
                transform: scale(1);
                opacity: 1;
            }
            50% { 
                transform: scale(1.2);
                opacity: 0.8;
            }
        }
        
        /* ============================================
           装备名称容器
           ============================================ */
        .item-name-container {
            display: flex;
            align-items: center;
            gap: 6px; /* 减小了间距，从8px改为6px */
        }
        
        .item-text {
            flex: 1;
        }
        
        /* ============================================
           缓存状态指示器
           ============================================ */
        .cache-indicator {
            position: absolute;
            top: 8px; /* 调整了位置，从10px改为8px */
            right: 8px; /* 调整了位置，从10px改为8px */
            background: rgba(59, 130, 246, 0.8);
            color: white;
            padding: 3px 6px; /* 减小了内边距，从4px 8px改为3px 6px */
            border-radius: 4px;
            font-size: 0.65em; /* 减小了字体大小，从0.7em改为0.65em */
            z-index: 100;
        }
        
        /* ============================================
           刷新保护页面样式
           ============================================ */
        .refresh-protection {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.9);
            display: flex;
            justify-content: center;
            align-items: center;
            z-index: 10000;
            color: white;
        }
        
        .refresh-protection-content {
            background: #1f2937;
            padding: 25px; /* 减小了内边距，从30px改为25px */
            border-radius: 10px;
            text-align: center;
            max-width: 380px; /* 减小了最大宽度，从400px改为380px */
            border: 2px solid #f59e0b;
        }
        
        .refresh-protection h2 {
            color: #f59e0b;
            margin-bottom: 12px; /* 减小了下边距，从15px改为12px */
        }
        
        .refresh-protection button {
            background: #3b82f6;
            color: white;
            border: none;
            padding: 8px 16px; /* 减小了内边距，从10px 20px改为8px 16px */
            border-radius: 5px;
            cursor: pointer;
            margin-top: 12px; /* 减小了上边距，从15px改为12px */
        }
        
        .refresh-protection button:hover {
            background: #2563eb;
        }
        
        /* ============================================
           前排高亮效果
           ============================================ */
        .front-row {
            position: relative;
        }
        
        .front-row::after {
            content: "";
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 2px;
            background: linear-gradient(90deg, transparent, #f59e0b, transparent);
            animation: frontRowGlow 3s infinite;
        }
        
        @keyframes frontRowGlow {
            0%, 100% { opacity: 0.3; }
            50% { opacity: 1; }
        }
        
        /* ============================================
           更新动画效果
           ============================================ */
        .row-update {
            animation: rowUpdateHighlight 1.5s ease-out;
        }
        
        @keyframes rowUpdateHighlight {
            0% { 
                background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
                transform: scale(1.02);
            }
            100% { 
                background: inherit;
                transform: scale(1);
            }
        }
        

/* 标题改成8-bit像素风，并加轻微故障动画 */
.header h1 {
    letter-spacing: 1px;
    position: relative;
    animation: hdrGlitch 3s infinite ease-in-out;
}

@keyframes hdrGlitch {

    0%,
    100% {
        text-shadow: 0 0 0 rgba(255, 0, 85, .0), 0 0 0 rgba(0, 255, 170, .0)
    }

    20% {
        text-shadow: 2px 0 rgba(255, 0, 85, .25), -2px 0 rgba(0, 255, 170, .25)
    }

    40% {
        text-shadow: -2px 0 rgba(255, 0, 85, .25), 2px 0 rgba(0, 255, 170, .25)
    }

    60% {
        text-shadow: 1px 0 rgba(255, 0, 85, .25), -1px 0 rgba(0, 255, 170, .25)
    }

    80% {
        text-shadow: -1px 0 rgba(255, 0, 85, .25), 1px 0 rgba(0, 255, 170, .25)
    }
}

/* 容器加 CRT 扫描线与轻微噪点（像素风味） */
.container::before {
    content: "";
    position: absolute;
    inset: 0;
    pointer-events: none;
    background: repeating-linear-gradient(transparent 0 2px, rgba(0, 0, 0, .1) 2px 3px), radial-gradient(ellipse at center, rgba(255, 255, 255, .05), rgba(0, 0, 0, 0) 60%);
    mix-blend-mode: lighten;
    opacity: .35;
    z-index: 1;
}



/* 价格徽章加金币图标 + 闪光 */
.price-tag {
    position: relative;
    padding-left: 28px;
    background: linear-gradient(135deg, #eab308 0%, #f59e0b 100%);
    color: #1f2937;
    text-shadow: 0 1px 0 rgba(255, 255, 255, .25);
    border: 2px solid #78350f;
    box-shadow: 0 3px 0 #78350f, inset 0 0 8px rgba(255, 255, 255, .3);
}

.price-tag::before {
    content: "🪙";
    position: absolute;
    left: 8px;
    top: 50%;
    transform: translateY(-50%);
    filter: saturate(1.3) brightness(1.1);
}

/* 像素风按钮（对你现有的按钮类进行皮肤覆盖） */
.detail-btn,
.action-btn,
.close-btn,
button {
    font-family: 'Press Start 2P', monospace;
    letter-spacing: .5px;
    background: #10b981;
    color: #0b1020;
    border: 0;
    padding: 12px 18px;
    border-radius: 0;
    position: relative;
    cursor: pointer;
    transition: transform .08s ease;
    box-shadow: 0 4px 0 #0f5132, 0 0 0 3px #0b1020 inset, 0 0 0 6px rgba(255, 255, 255, .05) inset;
}

.detail-btn:hover,
.action-btn:hover,
.close-btn:hover,
button:hover {
    transform: translateY(-2px);
}

.detail-btn:active,
.action-btn:active,
.close-btn:active,
button:active {
    transform: translateY(2px);
    box-shadow: 0 2px 0 #0f5132, 0 0 0 3px #0b1020 inset, 0 0 0 6px rgba(255, 255, 255, .08) inset;
}

.action-btn.buy-btn {
    background: #22c55e;
}

.action-btn.sell-btn {
    background: #f97316;
}

.action-btn.gift-btn {
    background: #e11d48;
}

.close-btn {
    background: #ef4444;
}

/* 热门项加8-bit发光边框（你已有 .hot-item/.popular-item 类，这里增强下） */
.hot-item .grid-cell:not(.arrow-cell)::before,
.popular-item .grid-cell:not(.arrow-cell)::before {
    border-radius: 0 !important;
    box-shadow: 0 0 0 2px rgba(255, 255, 255, .06) inset;
}

/* 升级箭头换成更亮的像素风 */
.upgrade-arrow::before {
    content: "▶";
    font-family: 'Press Start 2P', monospace;
    color: #f59e0b;
    text-shadow: 0 0 8px rgba(245, 158, 11, .8);
    animation: arrowPulse 1.6s infinite;
}

/* 顶部状态栏数字轻微跳动 */
.stats-item strong {
    animation: statPulse 2.2s infinite;
}

@keyframes statPulse {

    0%,
    100% {
        transform: translateY(0)
    }

    50% {
        transform: translateY(-1px)
    }
}

/* 粒子容器（JS会创建） */
#pixelParticles {
    position: fixed;
    inset: 0;
    pointer-events: none;
    z-index: 9999;
}

.pixel-p {
    position: absolute;
    width: 6px;
    height: 6px;
    image-rendering: pixelated;
}

/* 小星星闪烁（用于热度） */
.star {
    filter: drop-shadow(0 0 3px rgba(251, 191, 36, .6));
}

/* ============================================
       在线人数脉冲效果 - 新增
       ============================================ */
    .online-pulse {
        animation: onlinePulseEffect 1s ease-in-out;
    }
    
    @keyframes onlinePulseEffect {
        0% { transform: scale(1); }
        50% { transform: scale(1.05); }
        100% { transform: scale(1); }
    }
    
    </style>
</head>
<body>
    <!-- 刷新保护弹层 - 默认隐藏 -->
    <div id="refreshProtection" class="refresh-protection" style="display: none;">
        <div class="refresh-protection-content">
            <h2>⚠️ 操作过于频繁</h2>
            <p>请等待 <span id="countdown">5</span> 秒后再刷新页面</p>
            <p style="color: #94a3b8; font-size: 14px; margin-top: 10px;">请勿频繁操作</p>
            <button onclick="hideRefreshProtection()">确定</button>
        </div>
    </div>

    <div class="container">
        <!-- 防拷贝覆盖层 -->
        <div class="protection-overlay"></div>
        
        <!-- 缓存状态指示器 -->
        <% If IsArray(cachedData) Then %>
        <div class="cache-indicator" title="数据来自缓存，下次更新: <% = DateAdd("s", cacheExpiry - DateDiff("s", Application(cacheKey & "_Time"), Now()), Now()) %>">
            🔄 缓存中 (<% = cacheExpiry - DateDiff("s", Application(cacheKey & "_Time"), Now()) %>s)
        </div>
        <% End If %>
        
        <div class="header">
            <h1>⚔️ CNCTZ装备升级熔炉</h1>
            <div class="subtitle">装备升级库 - 共 <span id="headerCount"><%=itemCount%></span> 项神秘装备</div>
        </div>
        
        <div class="stats-bar">
            <div class="stats-item">
                <i class="fas fa-server"></i>
                <span>分区: <strong><%=session("DkServer")%></strong></span>
            </div>
            <div class="stats-item">
                <i class="fas fa-chess-knight"></i>
                <span>装备总数: <strong id="totalItems"><%=itemCount%></strong></span>
            </div>
            <div class="stats-item">
                <i class="fas fa-fire"></i>
                <span>熔炉热度: <strong id="livePopularity">🔥 计算中...</strong></span>
            </div>
            <div class="stats-item">
                <i class="fas fa-users"></i>
                <span>在线勇士: <strong id="onlineCount">加载中...</strong></span>
            </div>
        </div>

   
        
        <!-- ============================================
             数据表格容器 - 现在可以显示15-20行数据
             ============================================ -->
        <div class="scrolling-container">
            <div class="grid-container" id="exchangeGrid">
                <!-- 表头 -->
                <div class="grid-header">
                    <div class="grid-header-item">#</div>
                    <div class="grid-header-item">🗡️ 当前物品</div>
                    <div class="grid-header-item">✨ 进化</div>
                    <div class="grid-header-item">⚡ 进化物品</div>
                    <div class="grid-header-item">💰 所需C币</div>
                    <div class="grid-header-item">🔥 熔炉热度</div>
                </div>
                
                <!-- 表体 -->
                <div class="grid-body" id="tableBody">
                    <%
                    If itemCount > 0 Then
                        For i = 0 To itemCount - 1
                            Dim starCount, starsHtml, showHotBadge, itemClass, trendArrow, trendClass
                            starCount = exchangeData(i, 3)
                            starsHtml = ""
                            
                            ' 根据星级决定特效类
                            itemClass = ""
                            If starCount = 5 Then
                                itemClass = "hot-item"
                            ElseIf starCount = 4 Then
                                itemClass = "popular-item"
                            End If
                            
                            ' 随机生成趋势箭头（60%几率上升，40%几率下降）
                            Dim randomTrend
                            randomTrend = Rnd()
                            If randomTrend > 0.4 Then
                                trendArrow = "↑"
                                trendClass = "trend-up"
                            Else
                                trendArrow = "↓"
                                trendClass = "trend-down"
                            End If
                            
                            For j = 1 To 5
                                If j <= starCount Then
                                    starsHtml = starsHtml & "<i class='fas fa-star star'></i>"
                                Else
                                    starsHtml = starsHtml & "<i class='far fa-star star' style='color: #4b5563;'></i>"
                                End If
                            Next
                            
                            ' 30%几率显示火爆徽章
                            showHotBadge = (Rnd > 0.7)
                            If showHotBadge Then
                                starsHtml = starsHtml & " <span class='hot-badge'><i class='fas fa-fire'></i>熔炼中</span>"
                            End If
                            
                            ' 为前10行添加前排高亮效果
                            Dim frontRowClass
                            frontRowClass = ""
                            If i < 10 Then
                                frontRowClass = "front-row"
                            End If
                    %>
                    <div class="grid-row <%=itemClass%> <%=frontRowClass%>" data-index="<%=i%>">
                        <div class="grid-cell">
                            <div class="index-icon"><%=i+1%></div>
                        </div>
                        <div class="grid-cell">
                            <div class="item-name">
                                <div class="item-icon">⚔</div>
                                <div class="item-name-container">
                                    <div class="item-text">
                                        <span style="color: #fbbf24;"><%=exchangeData(i, 0)%></span>
                                    </div>
                                    <div class="trend-arrow <%=trendClass%>"><%=trendArrow%></div>
                                </div>
                            </div>
                        </div>
                        <div class="grid-cell arrow-cell">
                            <div class="upgrade-arrow"></div>
                        </div>
                        <div class="grid-cell">
                            <div class="item-name">
                                <div class="item-icon" style="background: linear-gradient(135deg, #10b981 0%, #059669 100%);">⚡</div>
                                <span style="color: #10b981;"><%=exchangeData(i, 1)%></span>
                            </div>
                        </div>
                        <div class="grid-cell">
                            <span class="price-tag"><%=exchangeData(i, 2)%> C币</span>
                        </div>
                        <div class="grid-cell">
                            <div class="popularity-stars">
                                <%=starsHtml%>
                            </div>
                        </div>
                    </div>
                    <%
                        Next
                    Else
                    %>
                    <div class="empty-state">
                        <i class="fas fa-dragon"></i>
                        <h3>熔炉暂时沉寂</h3>
                        <p>暂无装备升级信息，巨龙正在沉睡中...</p>
                    </div>
                    <%
                    End If
                    %>
                </div>
            </div>
        </div>
        
        <div class="footer">
            <p>💎 提示: 熔炉热度根据勇士们的升级频率实时波动，星级越高代表当前升级越热门</p>
            <p>📈 动态调控: <span style="color: #10b981;">↑ 随时上架和下架物品,价格动态调控</span></p>


            <button class="close-btn" onclick="safeCloseWindow()">
                <i class="fas fa-times"></i> 关闭熔炉
            </button>
        </div>
    </div>

    <script>
    // ============================================
    // 前端防刷新机制
    // ============================================
    var lastClickTime = 0;
    var clickDelay = 2000; // 2秒内禁止重复点击
    
    document.addEventListener('click', function(e) {
        var currentTime = new Date().getTime();
        if (currentTime - lastClickTime < clickDelay) {
            e.preventDefault();
            e.stopPropagation();
            showRefreshProtection();
            return false;
        }
        lastClickTime = currentTime;
    }, true);
    
    // ============================================
    // 刷新保护弹层功能
    // ============================================
    function showRefreshProtection() {
        var protection = document.getElementById('refreshProtection');
        var countdown = document.getElementById('countdown');
        var seconds = 5;
        
        protection.style.display = 'flex';
        countdown.textContent = seconds;
        
        var countdownInterval = setInterval(function() {
            seconds--;
            countdown.textContent = seconds;
            
            if (seconds <= 0) {
                clearInterval(countdownInterval);
                hideRefreshProtection();
            }
        }, 1000);
    }
    
    function hideRefreshProtection() {
        document.getElementById('refreshProtection').style.display = 'none';
    }
    
    // ============================================
    // 安全关闭窗口
    // ============================================
    function safeCloseWindow() {
        if (confirm('确定要关闭装备升级熔炉吗？')) {
            window.close();
        }
    }
    
    // ============================================
    // 增强代码保护
    // ============================================
    // 防止控制台打开
    setInterval(function() {
        checkConsole();
    }, 1000);
    
    function checkConsole() {
        var start = new Date().getTime();
        debugger;
        var end = new Date().getTime();
        if (end - start > 100) {
            document.body.innerHTML = '<div style="text-align:center;padding:50px;color:red;"><h1>⚠️ 安全警告</h1><p>检测到非法调试行为</p></div>';
            window.location.reload();
        }
    }
    
    // 防止复制
    document.addEventListener('copy', function(e) {
        e.preventDefault();
        showProtectionAlert('内容受保护，禁止复制！');
        return false;
    });
    
    // 防止剪切
    document.addEventListener('cut', function(e) {
        e.preventDefault();
        return false;
    });
    
    // 防止粘贴
    document.addEventListener('paste', function(e) {
        e.preventDefault();
        return false;
    });
    
    // 更新实时热度
    function updateLivePopularity() {
        var totalStars = 0;
        var starElements = $('.fa-star:not(.far)');
        
        if (starElements.length > 0) {
            totalStars = starElements.length;
            var totalPossibleStars = $('.popularity-stars').length * 5;
            var avgStars = (totalStars / totalPossibleStars * 100).toFixed(0);
            var popularityText;
            
            if (avgStars >= 80) {
                popularityText = '<span style="color: #ef4444;">🔥 熔岩沸腾</span>';
            } else if (avgStars >= 60) {
                popularityText = '<span style="color: #f59e0b;">🔥 烈焰燃烧</span>';
            } else if (avgStars >= 40) {
                popularityText = '<span style="color: #eab308;">🔥 炉火正旺</span>';
            } else {
                popularityText = '<span style="color: #84cc16;">🔥 温暖炉火</span>';
            }
            
            $('#livePopularity').html(popularityText);
        }
    }
    
    // 为单行生成星级
    function generateRowStars($starsElement) {
        var starCount = Math.floor(Math.random() * 3) + 3; // 3-5颗星
        var starsHtml = '';
        
        for (var i = 0; i < 5; i++) {
            if (i < starCount) {
                starsHtml += '<i class="fas fa-star star"></i>';
            } else {
                starsHtml += '<i class="far fa-star star" style="color: #4b5563;"></i>';
            }
        }
        
        // 随机决定是否显示火爆徽章
        if (Math.random() > 0.7) {
            starsHtml += ' <span class="hot-badge"><i class="fas fa-fire"></i>熔炼中</span>';
        }
        
        $starsElement.html(starsHtml);
        
        // 更新行的特效类
        var $row = $starsElement.closest('.grid-row');
        $row.removeClass('hot-item popular-item');
        
        if (starCount === 5) {
            $row.addClass('hot-item');
        } else if (starCount === 4) {
            $row.addClass('popular-item');
        }
        
        updateLivePopularity();
    }
    
    // 更新趋势箭头
    function updateTrendArrow($row) {
        var $trendArrow = $row.find('.trend-arrow');
        var randomValue = Math.random();
        
        if (randomValue > 0.4) {
            // 60%几率显示上升箭头
            $trendArrow.html('↑').removeClass('trend-down').addClass('trend-up');
        } else {
            // 40%几率显示下降箭头
            $trendArrow.html('↓').removeClass('trend-up').addClass('trend-down');
        }
    }
    
    // 获取在线人数 
    function getOnlineCount() {
        $.ajax({
            url: 'online_count.json',
            type: 'GET',
            dataType: 'json',
            cache: false, // 防止缓存
            success: function(data) {
                if (data && data.base_count) {
                    updateOnlineCount(data.base_count);
                } else {
                    // 如果JSON格式不正确，使用默认值
                    updateOnlineCount(258);
                }
            },
            error: function(xhr, status, error) {
                console.log('无法读取online_count.json，使用默认值: ' + error);
                // 如果JSON文件不存在，使用默认值
                updateOnlineCount(258);
            }
        });
    }
    
    // 更新在线人数显示 - 修复版本
    function updateOnlineCount(baseCount) {
        var now = new Date();
        var hour = now.getHours();
        var minute = now.getMinutes();
        var second = now.getSeconds();
        
        // 根据时间段计算动态系数
        var dynamicFactor = 1.0;
        
        // 高峰期（晚上7-11点）增加15-20%
        if (hour >= 19 && hour < 23) {
            dynamicFactor = 1.15 + (Math.random() * 0.05); // 15-20%
        }
        // 次高峰期（下午2-6点）增加10-15%
        else if (hour >= 14 && hour < 18) {
            dynamicFactor = 1.10 + (Math.random() * 0.05); // 10-15%
        }
        // 中午高峰期（11-14点）增加5-10%
        else if (hour >= 11 && hour < 14) {
            dynamicFactor = 1.05 + (Math.random() * 0.05); // 5-10%
        }
        // 上午（8-11点）增加0-5%
        else if (hour >= 8 && hour < 11) {
            dynamicFactor = 1.00 + (Math.random() * 0.05); // 0-5%
        }
        // 凌晨（0-6点）减少5-10%
        else if (hour >= 0 && hour < 6) {
            dynamicFactor = 0.90 + (Math.random() * 0.05); // -5% to -10%
        }
        // 其他时间段（6-8点，23-24点）保持基准或小幅波动
        else {
            dynamicFactor = 0.98 + (Math.random() * 0.04); // -2% to +2%
        }
        
        // 每10秒的小幅度波动（1-5%）
        var timeFactor = 1.0;
        var secondsMod = Math.floor(second / 10); // 每10秒一个周期
        
        // 基于当前10秒周期计算小幅波动
        var cyclePosition = secondsMod % 6; // 6个10秒周期为一分钟
        var smallFluctuation = 0.0;
        
        // 渐进式波动：在1-5%之间缓慢变化
        switch(cyclePosition) {
            case 0: smallFluctuation = 0.01; break; // +1%
            case 1: smallFluctuation = 0.02; break; // +2%
            case 2: smallFluctuation = 0.03; break; // +3%
            case 3: smallFluctuation = 0.04; break; // +4%
            case 4: smallFluctuation = 0.05; break; // +5%
            case 5: smallFluctuation = 0.03; break; // 回到+3%
        }
        
        // 随机决定是正波动还是负波动（60%正，40%负）
        if (Math.random() > 0.6) {
            timeFactor = 1.0 + smallFluctuation;
        } else {
            timeFactor = 1.0 - smallFluctuation;
        }
        
        // 计算最终在线人数
        var finalCount = Math.round(baseCount * dynamicFactor * timeFactor);
        finalCount = Math.max(finalCount, Math.round(baseCount * 0.8));
        var totalChangePercent = Math.round(((finalCount - baseCount) / baseCount) * 100);
        
        // 更新显示
        var displayText = finalCount + ' <span class="online-count">';
        if (totalChangePercent > 0) {
            displayText += '+' + totalChangePercent + '%';
        } else if (totalChangePercent < 0) {
            displayText += totalChangePercent + '%';
        } else {
            displayText += '±0%';
        }
        displayText += '</span>';
        
        $('#onlineCount').html(displayText);
        
        // 添加脉冲效果
        $('#onlineCount').addClass('online-pulse');
        setTimeout(function() {
            $('#onlineCount').removeClass('online-pulse');
        }, 1000);
        
        // 记录调试信息
        console.log('在线人数已更新: ' + finalCount + 
                    ' (基准: ' + baseCount + 
                    ', 时段系数: ' + dynamicFactor.toFixed(3) + 
                    ', 波动系数: ' + timeFactor.toFixed(3) + 
                    ', 总变化: ' + totalChangePercent + '%)');
    }
    
    // 渐进式更新函数 - 每10秒执行一次
    function gradualOnlineUpdate() {
        getOnlineCount();
    }
    
    // ============================================
    // 改进的表格动态更新逻辑
    // ============================================
    
    // 智能更新表格 - 优先更新前10行
    function smartUpdateTable() {
        var $allRows = $('#tableBody .grid-row');
        var totalRows = $allRows.length;
        
        if (totalRows === 0) return;
        
        // 决定更新的行数（1-3行）
        var updateCount = Math.floor(Math.random() * 3) + 1;
        
        for (var i = 0; i < updateCount; i++) {
            // 80%的几率更新前10行，20%的几率更新其他行
            var updateFront = Math.random() < 0.8;
            var targetIndex;
            
            if (updateFront && totalRows > 10) {
                // 更新前10行
                targetIndex = Math.floor(Math.random() * Math.min(10, totalRows));
            } else {
                // 更新其他行
                targetIndex = Math.floor(Math.random() * totalRows);
            }
            
            var $targetRow = $allRows.eq(targetIndex);
            
            // 更新星级和趋势
            var $stars = $targetRow.find('.popularity-stars');
            generateRowStars($stars);
            updateTrendArrow($targetRow);
            
            // 添加更新动画效果
            $targetRow.addClass('row-update');
            setTimeout(function() {
                $targetRow.removeClass('row-update');
            }, 1500);
            
            // 如果更新的行不在前10行，有50%几率将其移到前10行
            if (targetIndex >= 10 && Math.random() < 0.5) {
                var newPosition = Math.floor(Math.random() * Math.min(10, totalRows));
                if (newPosition === 0) {
                    $targetRow.prependTo('#tableBody');
                } else {
                    $targetRow.insertBefore($allRows.eq(newPosition));
                }
                
                // 重新获取所有行
                $allRows = $('#tableBody .grid-row');
            }
        }
    }
    
    // 前排特殊效果 - 更频繁地更新前10行
    function updateFrontRows() {
        var $frontRows = $('#tableBody .grid-row:lt(10)'); // 前10行
        var frontRowCount = $frontRows.length;
        
        if (frontRowCount === 0) return;
        
        // 更新1-2个前排装备
        var updateCount = Math.floor(Math.random() * 2) + 1;
        
        for (var i = 0; i < updateCount; i++) {
            var targetIndex = Math.floor(Math.random() * frontRowCount);
            var $targetRow = $frontRows.eq(targetIndex);
            
            // 更新星级和趋势
            var $stars = $targetRow.find('.popularity-stars');
            generateRowStars($stars);
            updateTrendArrow($targetRow);
            
            // 添加更明显的更新效果
            $targetRow.addClass('row-update');
            setTimeout(function() {
                $targetRow.removeClass('row-update');
            }, 1500);
        }
    }
    
    // ============================================
    // 页面加载完成后的初始化
    // ============================================
    $(document).ready(function() {
        updateLivePopularity();
        
        // 立即获取在线人数
        getOnlineCount();
        
        // 每10秒更新一次在线人数（小幅度波动）
        setInterval(gradualOnlineUpdate, 10000);
        
        // 每分钟重新获取基准人数（防止长时间运行的累积误差）
        setInterval(getOnlineCount, 60000);
        
        // 自动调整窗口大小 - 根据新的行高调整
        var rowCount = <%=itemCount%>;
        // 计算新的窗口高度：基础高度 + 行数 * 新的行高(约45px)
        var windowHeight = Math.min(1000, 400 + Math.min(rowCount, 20) * 45);
        window.resizeTo(1250, windowHeight);
        
        // 添加鼠标悬停效果 - 排除箭头列
        $('.grid-row').hover(
            function() {
                $(this).find('.grid-cell:not(.arrow-cell)').css('transform', 'translateX(8px)');
            },
            function() {
                $(this).find('.grid-cell:not(.arrow-cell)').css('transform', 'translateX(0)');
            }
        );
        
        // 智能表格更新 - 每3秒一次
        setInterval(smartUpdateTable, 13000);
        
        // 前排特殊更新 - 每2秒一次，更频繁
        setInterval(updateFrontRows, 5000);
    });

    </script>
</body>
</html>