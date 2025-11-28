<?php
error_reporting(E_ALL);
ini_set('display_errors', 0); // 关闭错误显示，避免影响JSON

// 引入配置文件
require_once '../config.php';

// 使用默认服务器ID
define('SERVER_ID', DEFAULT_SERVER_ID);

// 数据库连接函数
function get_db($server_id, $db_type) {
    global $servers;
    $server = $servers[$server_id];
    
    $host = $server['host'];
    $user = $server['user'];
    $pass = $server['pass'];
    $dbname = $server['db_' . $db_type];
    
    try {
        $pdo = new PDO("sqlsrv:Server={$host};Database={$dbname}", $user, $pass);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
        return $pdo;
    } catch (PDOException $e) {
        throw new Exception("数据库连接失败: " . $e->getMessage());
    }
}

// 执行查询的辅助函数
function db_query($db, $sql, $params = []) {
    try {
        $stmt = $db->prepare($sql);
        if ($params) {
            foreach ($params as $i => $param) {
                $stmt->bindValue($i + 1, $param);
            }
        }
        $stmt->execute();
        return $stmt;
    } catch (PDOException $e) {
        throw new Exception("查询失败: " . $e->getMessage());
    }
}

// 权限检查 - 简化版
session_start();
if (!isset($_SESSION['is_admin']) && !isset($_SESSION['admin_user'])) {
    // 临时调试模式
    if (!isset($_GET['debug'])) {
        header('Content-Type: application/json');
        echo json_encode(['success' => false, 'message' => '无权限访问，请添加 ?debug=admin 进行调试']);
        exit;
    }
    $_SESSION['is_admin'] = true;
    $_SESSION['admin_user'] = 'admin';
}

// 处理AJAX请求
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    header('Content-Type: application/json');
    
    if ($_POST['action'] === 'search_account') {
    $account = trim($_POST['account']);
    
    try {
        // 获取两个数据库连接
        $db_character = get_db(SERVER_ID, 'character');
        $db_account = get_db(SERVER_ID, 'account');
        
        // 跨库查询 - 使用完整的数据库名
        $sql = "SELECT TOP 20
                c.character_no, 
                c.character_name, 
                c.wlevel,
                c.bypcClass,
                u.user_id
            FROM character.dbo.user_character c
            INNER JOIN account.dbo.user_profile u ON c.user_no = u.user_no
            WHERE u.user_id = ?
            ORDER BY c.wlevel DESC";
        
        // 使用character数据库连接执行跨库查询
        $stmt = db_query($db_character, $sql, [$account]);
        $characters = [];
        
        while ($row = $stmt->fetch()) {
            $characters[] = $row;
        }
        
        if ($characters) {
            echo json_encode(['success' => true, 'characters' => $characters]);
        } else {
            echo json_encode(['success' => false, 'message' => '该账号没有角色或账号不存在']);
        }
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
    exit;
}

    
    if ($_POST['action'] === 'get_items') {
        $category = $_POST['category'] ?? '';
        $db_account = get_db(SERVER_ID, 'account');
        
        $where = '';
        switch($category) {
            case '武器': $where = 'windex BETWEEN 0 AND 999'; break;
            case '防具': $where = 'windex BETWEEN 1000 AND 1999'; break;
            case '首饰': $where = 'windex BETWEEN 2000 AND 2999'; break;
            case '消耗品': $where = 'windex BETWEEN 3000 AND 3999'; break;
            case '材料': $where = 'windex BETWEEN 4000 AND 4999'; break;
            case '任务物品': $where = 'windex BETWEEN 5000 AND 5999'; break;
            default: $where = 'windex >= 6000';
        }
        
        $sql = "SELECT TOP 100 
                windex, 
                ISNULL(item_name, '未知物品') as item_name,
                ISNULL(level, '') as level,
                ISNULL(min_attack, 0) as min_attack,
                ISNULL(max_attack, 0) as max_attack
            FROM web_items 
            WHERE {$where}
            ORDER BY windex";
        
        try {
            $stmt = db_query($db_account, $sql);
            $items = [];
            
            while ($row = $stmt->fetch()) {
                $items[] = $row;
            }
            
            echo json_encode(['success' => true, 'items' => $items]);
        } catch (Exception $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
        exit;
    }
    
   if ($_POST['action'] === 'send_item') {
    try {
        $character_no = $_POST['character_no'];
        $wIndex = intval($_POST['wIndex']);
        $number = intval($_POST['number'] ?? 0);
        $note = $_POST['note'] ?? '';
        
        $db_character = get_db(SERVER_ID, 'character');
        $db_account = get_db(SERVER_ID, 'account');
        
        // 验证角色
        $sql = "SELECT character_name, user_no 
            FROM user_character 
            WHERE character_no = ?";
        $stmt = db_query($db_character, $sql, [$character_no]);
        $character = $stmt->fetch();
        
        if (!$character) {
            throw new Exception('角色不存在');
        }
        
        // 获取物品名称
        $sql = "SELECT ISNULL(item_name, '未知物品') as item_name
            FROM web_items 
            WHERE windex = ?";
        $stmt = db_query($db_account, $sql, [$wIndex]);
        $item = $stmt->fetch();
        
        if (!$item) {
            throw new Exception('物品ID不存在');
        }
        
        $item_name = $item['item_name'];
        
        // 获取属性
        $attributes = [
            $_POST['attribute1'] ?? '000000',
            $_POST['attribute2'] ?? '000000',
            $_POST['attribute3'] ?? '000000',
            $_POST['attribute4'] ?? '000000'
        ];
        
        $holes = [
            $_POST['hole1'] ?? '0000',
            $_POST['hole2'] ?? '0000',
            $_POST['hole3'] ?? '0000',
            $_POST['hole4'] ?? '0000'
        ];
        
        // 计算byHeader和info
        if ($number > 0) {
            // 带数量的物品 - 数量占4字节
            $number = dechex($number);
            $number = str_pad($number, 4, '0', STR_PAD_LEFT);
            $infoHex = $number;
            $byHeader = 1;
        } else {
            // 装备类物品
            $attrCount = 0;
            foreach ($attributes as $attr) {
                if ($attr !== '000000') $attrCount++;
            }
            
            $holeCount = 0;
            foreach ($holes as $hole) {
                if ($hole !== '0000') $holeCount++;
            }
            
            $byHeader = ($attrCount > 0 ? ($attrCount + 4) : 0) + ($holeCount * 16);
            $infoHex = implode('', $holes) . implode('', $attributes);
        }
        
        // 确保info不超过25字节（50个十六进制字符）
        if (strlen($infoHex) > 50) {
            $infoHex = substr($infoHex, 0, 50);
        }
        
        // 查找空位
        $sql = "SELECT line_no FROM user_storage 
            WHERE character_no = ?";
        $stmt = db_query($db_character, $sql, [$character_no]);
        $occupied = $stmt->fetchAll();
        
        $occupied_slots = [];
        foreach ($occupied as $slot) {
            $occupied_slots[] = $slot['line_no'];
        }
        
        $line_no = -1;
        for ($i = 0; $i < 120; $i++) {
            if (!in_array($i, $occupied_slots)) {
                $line_no = $i;
                break;
            }
        }
        
        if ($line_no == -1) {
            throw new Exception('仓库已满');
        }
        
        // 生成16字节的序列号（32个十六进制字符）
        $serialHex = '';
        for ($i = 0; $i < 16; $i++) {
            $serialHex .= str_pad(dechex(mt_rand(0, 255)), 2, '0', STR_PAD_LEFT);
        }
        
        // 插入物品到character数据库
        $sql = "INSERT INTO user_storage (
            character_no, line_no, wIndex, byHeader, info,
            dwSerialNumber, upt_time
        ) VALUES (
            '{$character_no}', 
            {$line_no}, 
            {$wIndex}, 
            {$byHeader}, 
            0x{$infoHex}, 
            0x{$serialHex}, 
            GETDATE()
        )";
        
        $db_character->exec($sql);
        
        // 记录日志到account数据库
        $admin_user = $_SESSION['admin_user'] ?? 'Unknown';
        $ip = $_SERVER['REMOTE_ADDR'];
        
        // 使用account数据库连接记录日志
        $sql = "INSERT INTO account.dbo.adminlog (admin, datetime, ip, user_id, adminlog, logtype)
            VALUES (?, GETDATE(), ?, ?, ?, 3)";
        
        $stmt = $db_account->prepare($sql);
        $stmt->bindValue(1, $admin_user);
        $stmt->bindValue(2, $ip);
        $stmt->bindValue(3, $character['character_name']);
        $stmt->bindValue(4, "发送装备到仓库: {$item_name} (ID:{$wIndex}) 位置:{$line_no}");
        $stmt->execute();
        
        echo json_encode([
            'success' => true,
            'message' => "装备 {$item_name} 已发送到仓库位置 {$line_no}",
            'item_name' => $item_name,
            'line_no' => $line_no
        ]);
        
    } catch (Exception $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
    exit;
}


}

// 设置页面
$page_title = '仓库物品发送工具';
$breadcrumbs = [
    ['name' => '管理工具', 'url' => '/admin/'],
    ['name' => '仓库物品发送', 'url' => '/admin/send_storage_item.php']
];

// 简单的头部
?>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo $page_title; ?></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        body {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            font-family: 'Microsoft YaHei', sans-serif;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
            padding: 20px;
        }
        .step-container {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 25px;
            margin-bottom: 20px;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        .step-header {
            display: flex;
            align-items: center;
            margin-bottom: 20px;
        }
        .step-number {
            width: 40px;
            height: 40px;
            background: linear-gradient(135deg, #667eea, #764ba2);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
            margin-right: 15px;
        }
        .step-title {
            color: #ffc107;
            font-size: 1.2em;
            font-weight: 500;
        }
        .form-group {
            margin-bottom: 15px;
        }
        .form-group label {
            display: block;
            color: white;
            margin-bottom: 5px;
        }
        .form-control {
            width: 100%;
            padding: 10px;
            border-radius: 8px;
            border: 1px solid rgba(255, 255, 255, 0.3);
            background: rgba(255, 255, 255, 0.9);
        }
        .btn {
            padding: 10px 25px;
            border: none;
            border-radius: 25px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.3s ease;
        }
        .btn-primary {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
        }
        .btn-success {
            background: linear-gradient(135deg, #28a745, #20c997);
            color: white;
        }
        .btn-warning {
            background: linear-gradient(135deg, #ffc107, #ff9800);
            color: white;
        }
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.3);
        }
        .character-list {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
            gap: 15px;
            margin-top: 15px;
        }
        .character-card {
            background: rgba(255, 255, 255, 0.1);
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-radius: 10px;
            padding: 15px;
            cursor: pointer;
            transition: all 0.3s ease;
            color: white;
        }
        .character-card:hover {
            background: rgba(255, 255, 255, 0.2);
            transform: translateY(-2px);
        }
        .character-card.selected {
            background: rgba(102, 126, 234, 0.5);
            border-color: #667eea;
        }
        .character-name {
            font-size: 1.1em;
            font-weight: bold;
            color: #ffc107;
            margin-bottom: 5px;
        }
        .character-info {
            font-size: 0.9em;
            color: rgba(255, 255, 255, 0.8);
        }
        .item-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 10px;
            max-height: 300px;
            overflow-y: auto;
            padding: 10px;
            background: rgba(0, 0, 0, 0.3);
            border-radius: 8px;
        }
        .item-option {
            padding: 10px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 5px;
            cursor: pointer;
            color: white;
            transition: all 0.3s ease;
            border: 1px solid transparent;
        }
        .item-option:hover {
            background: rgba(255, 255, 255, 0.2);
        }
        .item-option.selected {
            background: rgba(102, 126, 234, 0.5);
            border-color: #667eea;
        }
        .custom-item {
            background: rgba(255, 193, 7, 0.2);
            border: 1px solid rgba(255, 193, 7, 0.5);
        }
        .alert {
            padding: 15px;
            border-radius: 8px;
            margin: 10px 0;
        }
        .alert-success {
            background: rgba(40, 167, 69, 0.2);
            border: 1px solid rgba(40, 167, 69, 0.5);
            color: #28a745;
        }
        .alert-danger {
            background: rgba(220, 53, 69, 0.2);
            border: 1px solid rgba(220, 53, 69, 0.5);
            color: #dc3545;
        }
        .alert-warning {
            background: rgba(255, 193, 7, 0.2);
            border: 1px solid rgba(255, 193, 7, 0.5);
            color: #ffc107;
        }
        .row {
            display: flex;
            gap: 20px;
        }
        .col-md-6 {
            flex: 1;
        }
        .disabled {
            opacity: 0.5;
            pointer-events: none;
        }
    </style>
</head>
<body>
<div class="container">
    <h2 style="color: white; text-align: center; margin-bottom: 30px;">
        <i class="fas fa-box"></i> 仓库物品发送工具
    </h2>
    
    <form id="sendForm">
        <!-- 第一步：输入账号 -->
        <div class="step-container">
            <div class="step-header">
                <div class="step-number">1</div>
                <div class="step-title">输入玩家账号</div>
            </div>
            <div class="row">
                <div class="col-md-8">
                    <div class="form-group">
                        <input type="text" class="form-control" id="accountInput" placeholder="请输入玩家账号">
                    </div>
                </div>
                <div class="col-md-4">
                    <button type="button" class="btn btn-primary" onclick="searchAccount()" style="width: 100%;">
                        <i class="fas fa-search"></i> 搜索角色
                    </button>
                </div>
            </div>
            <div id="characterList" class="character-list" style="display: none;"></div>
        </div>
        
        <!-- 第二步：选择物品 -->
        <div class="step-container disabled" id="step2">
            <div class="step-header">
                <div class="step-number">2</div>
                <div class="step-title">选择物品</div>
            </div>
            
            <div class="alert alert-warning">
                <i class="fas fa-info-circle"></i> 
                <strong>提示：</strong>自定义物品ID优先级高于左侧物品列表，填写自定义ID后将忽略左侧选择
            </div>
            
            <div class="row">
                <div class="col-md-6">
                    <div class="form-group">
                        <label>物品类别：</label>
                        <select class="form-control" id="itemCategory">
                            <option value="">请选择类别</option>
                            <option value="武器">武器</option>
                            <option value="防具">防具</option>
                            <option value="首饰">首饰</option>
                            <option value="消耗品">消耗品</option>
                            <option value="材料">材料</option>
                            <option value="任务物品">任务物品</option>
                        </select>
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="form-group">
                        <label>自定义物品ID（优先）：</label>
                        <input type="text" class="form-control" id="customItemId" placeholder="直接输入物品ID">
                    </div>
                </div>
            </div>
            
            <div class="form-group">
                <label>物品列表：</label>
                <div id="itemList" class="item-grid" style="display: none;"></div>
            </div>
            
            <div class="form-group">
                <label>已选择物品：</label>
                <input type="text" class="form-control" id="selectedItem" readonly>
                <input type="hidden" name="wIndex" id="wIndex" required>
            </div>
            
            <div class="form-group">
                <label>数量（消耗品填写，装备留空）：</label>
                <input type="number" class="form-control" name="number" min="0" max="9999" placeholder="装备留空，消耗品填写数量">
            </div>
        </div>
        
        <!-- 第三步：属性设置 -->
        <div class="step-container disabled" id="step3">
            <div class="step-header">
                <div class="step-number">3</div>
                <div class="step-title">属性设置（装备类）</div>
            </div>
            
            <div style="display: flex; gap: 10px; flex-wrap: wrap;">
                <select name="attribute1" style="flex: 1; min-width: 150px;">
                    <option value="000000">属性1（无）</option>
                    <option value="CD3CFF">致命+158</option>
                    <option value="DB03FF">魔法抗性+</option>
                </select>
                <select name="attribute2" style="flex: 1; min-width: 150px;">
                    <option value="000000">属性2（无）</option>
                    <option value="CD3CFF">致命+158</option>
                    <option value="DB03FF">魔法抗性+</option>
                </select>
                <select name="attribute3" style="flex: 1; min-width: 150px;">
                    <option value="000000">属性3（无）</option>
                    <option value="CD3CFF">致命+158</option>
                    <option value="DB03FF">魔法抗性+</option>
                </select>
                <select name="attribute4" style="flex: 1; min-width: 150px;">
                    <option value="000000">属性4（无）</option>
                    <option value="CD3CFF">致命+158</option>
                    <option value="DB03FF">魔法抗性+</option>
                </select>
            </div>
        </div>
        
        <!-- 第四步：镶嵌设置 -->
        <div class="step-container disabled" id="step4">
            <div class="step-header">
                <div class="step-number">4</div>
                <div class="step-title">镶嵌设置</div>
            </div>
            
            <div style="display: flex; gap: 10px; flex-wrap: wrap;">
                <select name="hole1" style="flex: 1; min-width: 150px;">
                    <option value="0000">孔1（无）</option>
                    <option value="197F">挡格晶石142(头盔)</option>
                    <option value="19A7">所有防84(护甲)</option>
                    <option value="19EF">不灭腰带4%(腰带)</option>
                    <option value="1966">击退晶石3%(手环)</option>
                    <option value="1989">阻拦晶石123(盾)</option>
                    <option value="19AF">火7%</option>
                    <option value="19B0">冰7%</option>
                    <option value="19B1">电7%</option>
                    <option value="19B2">毒7%</option>
                    <option value="19B3">诅7%</option>
                </select>
                <select name="hole2" style="flex: 1; min-width: 150px;">
                    <option value="0000">孔2（无）</option>
                    <option value="197F">挡格晶石142(头盔)</option>
                    <option value="19A7">所有防84(护甲)</option>
                    <option value="19EF">不灭腰带4%(腰带)</option>
                    <option value="1966">击退晶石3%(手环)</option>
                    <option value="1989">阻拦晶石123(盾)</option>
                    <option value="19AF">火7%</option>
                    <option value="19B0">冰7%</option>
                    <option value="19B1">电7%</option>
                    <option value="19B2">毒7%</option>
                    <option value="19B3">诅7%</option>
                </select>
                <select name="hole3" style="flex: 1; min-width: 150px;">
                    <option value="0000">孔3（无）</option>
                    <option value="197F">挡格晶石142(头盔)</option>
                    <option value="19A7">所有防84(护甲)</option>
                    <option value="19EF">不灭腰带4%(腰带)</option>
                    <option value="1966">击退晶石3%(手环)</option>
                    <option value="1989">阻拦晶石123(盾)</option>
                    <option value="19AF">火7%</option>
                    <option value="19B0">冰7%</option>
                    <option value="19B1">电7%</option>
                    <option value="19B2">毒7%</option>
                    <option value="19B3">诅7%</option>
                </select>
                <select name="hole4" style="flex: 1; min-width: 150px;">
                    <option value="0000">孔4（无）</option>
                    <option value="197F">挡格晶石142(头盔)</option>
                    <option value="19A7">所有防84(护甲)</option>
                    <option value="19EF">不灭腰带4%(腰带)</option>
                    <option value="1966">击退晶石3%(手环)</option>
                    <option value="1989">阻拦晶石123(盾)</option>
                    <option value="19AF">火7%</option>
                    <option value="19B0">冰7%</option>
                    <option value="19B1">电7%</option>
                    <option value="19B2">毒7%</option>
                    <option value="19B3">诅7%</option>
                </select>
            </div>
        </div>
        
        <!-- 第五步：备注和发送 -->
        <div class="step-container disabled" id="step5">
            <div class="step-header">
                <div class="step-number">5</div>
                <div class="step-title">备注信息</div>
            </div>
            
            <div class="form-group">
                <label>操作备注：</label>
                <textarea class="form-control" name="note" rows="3" placeholder="请填写操作原因或备注信息"></textarea>
            </div>
            
            <div style="text-align: center;">
                <input type="hidden" name="action" value="send_item">
                <input type="hidden" name="character_no" id="character_no">
                <button type="submit" class="btn btn-success btn-lg">
                    <i class="fas fa-paper-plane"></i> 发送到仓库
                </button>
            </div>
        </div>
    </form>
    
    <!-- 结果提示 -->
    <div id="resultMessage" style="display: none;"></div>
</div>

<script>
let selectedCharacter = null;

// 搜索账号
function searchAccount() {
    const account = document.getElementById('accountInput').value.trim();
    if (!account) {
        alert('请输入玩家账号');
        return;
    }
    
    const formData = new FormData();
    formData.append('action', 'search_account');
    formData.append('account', account);
    
    // 显示加载状态
    const listDiv = document.getElementById('characterList');
    listDiv.innerHTML = '<div style="color: white; padding: 20px; text-align: center;">搜索中...</div>';
    listDiv.style.display = 'block';
    
    fetch('', {
        method: 'POST',
        body: formData
    })
    .then(response => {
        // 检查响应是否为JSON
        const contentType = response.headers.get('content-type');
        if (!contentType || !contentType.includes('application/json')) {
            throw new Error('服务器返回的不是JSON格式');
        }
        return response.json();
    })
    .then(data => {
        if (data.success) {
            if (data.characters && data.characters.length > 0) {
                let html = '';
                data.characters.forEach(char => {
                    const className = getClassName(char.bypcClass);
                    html += `
                        <div class="character-card" onclick="selectCharacter('${char.character_no}', '${char.character_name}', '${className}', '${char.wlevel}')">
                            <div class="character-name">${char.character_name}</div>
                            <div class="character-info">
                                职业：${className} | 等级：${char.wlevel}<br>
                                账号：${char.user_id}
                            </div>
                        </div>
                    `;
                });
                listDiv.innerHTML = html;
                listDiv.style.display = 'grid';
            } else {
                listDiv.innerHTML = '<div style="color: white; padding: 20px; text-align: center;">该账号没有角色</div>';
                listDiv.style.display = 'block';
            }
        } else {
            listDiv.innerHTML = `<div style="color: #ffc107; padding: 20px; text-align: center;">错误：${data.message}</div>`;
            listDiv.style.display = 'block';
        }
    })
    .catch(error => {
        console.error('搜索失败:', error);
        listDiv.innerHTML = `<div style="color: #dc3545; padding: 20px; text-align: center;">搜索失败：${error.message}</div>`;
        listDiv.style.display = 'block';
    });
}

// 获取职业名称
function getClassName(classId) {
    const classes = {
        0: '骑士', 1: '弓箭手', 2: '法师', 3: '驱魔师',
        4: '巫师', 5: '狂战士', 6: '魔枪手', 7: '龙骑士',
        9: '暗咒师', 10: '女武神', 11: '死神', 12: '女战圣'
    };
    return classes[classId] || '未知';
}

// 选择角色
function selectCharacter(no, name, className, level) {
    selectedCharacter = { no, name, className, level };
    
    // 更新UI
    document.getElementById('character_no').value = no;
    document.querySelectorAll('.character-card').forEach(card => {
        card.classList.remove('selected');
    });
    event.target.closest('.character-card').classList.add('selected');
    
    // 启用后续步骤
    enableSteps(2);
    
    // 显示选中信息
    const resultDiv = document.getElementById('resultMessage');
    resultDiv.className = 'alert alert-success';
    resultDiv.innerHTML = `<i class="fas fa-check-circle"></i> 已选择角色：${name} (${className} Lv.${level})`;
    resultDiv.style.display = 'block';
    setTimeout(() => {
        resultDiv.style.display = 'none';
    }, 3000);
}

// 启用步骤
function enableSteps(fromStep) {
    for (let i = fromStep; i <= 5; i++) {
        document.getElementById('step' + i).classList.remove('disabled');
    }
}

// 物品类别选择
document.getElementById('itemCategory').addEventListener('change', function() {
    const category = this.value;
    if (!category) {
        document.getElementById('itemList').style.display = 'none';
        return;
    }
    
    const formData = new FormData();
    formData.append('action', 'get_items');
    formData.append('category', category);
    
    fetch('', {
        method: 'POST',
        body: formData
    })
    .then(response => {
        const contentType = response.headers.get('content-type');
        if (!contentType || !contentType.includes('application/json')) {
            throw new Error('服务器返回的不是JSON格式');
        }
        return response.json();
    })
    .then(data => {
        const listDiv = document.getElementById('itemList');
        if (data.success && data.items.length > 0) {
            let html = '';
            data.items.forEach(item => {
                html += `
                    <div class="item-option" onclick="selectItem('${item.windex}', '${item.item_name}')">
                        <div>${item.item_name}</div>
                        <small style="color: rgba(255,255,255,0.7)">ID: ${item.windex}</small>
                    </div>
                `;
            });
            listDiv.innerHTML = html;
            listDiv.style.display = 'grid';
        } else {
            listDiv.innerHTML = '<div class="item-option">该类别暂无物品</div>';
            listDiv.style.display = 'grid';
        }
    })
    .catch(error => {
        console.error('获取物品失败:', error);
    });
});

// 自定义物品ID
document.getElementById('customItemId').addEventListener('input', function() {
    const itemId = this.value.trim();
    if (itemId && /^\d+$/.test(itemId)) {
        selectItem(itemId, '自定义物品 (ID: ' + itemId + ')');
        // 高亮自定义输入框
        this.style.background = 'rgba(255, 193, 7, 0.2)';
        // 清除列表选择
        document.querySelectorAll('.item-option').forEach(el => {
            el.classList.remove('selected');
        });
    } else {
        this.style.background = 'rgba(255, 255, 255, 0.9)';
    }
});

// 选择物品
function selectItem(id, name) {
    document.getElementById('wIndex').value = id;
    document.getElementById('selectedItem').value = name;
    
    // 如果不是自定义ID，才更新自定义输入框
    if (!document.getElementById('customItemId').value) {
        document.getElementById('customItemId').value = id;
    }
    
    // 高亮选中的物品
    document.querySelectorAll('.item-option').forEach(el => {
        el.classList.remove('selected');
    });
    if (event.target) {
        event.target.closest('.item-option').classList.add('selected');
    }
}

// 表单提交
document.getElementById('sendForm').addEventListener('submit', function(e) {
    e.preventDefault();
    
    if (!selectedCharacter) {
        alert('请先选择角色');
        return;
    }
    
    const formData = new FormData(this);
    const resultDiv = document.getElementById('resultMessage');
    
    // 发送请求
    fetch('', {
        method: 'POST',
        body: formData
    })
    .then(response => {
        const contentType = response.headers.get('content-type');
        if (!contentType || !contentType.includes('application/json')) {
            throw new Error('服务器返回的不是JSON格式');
        }
        return response.json();
    })
    .then(data => {
        if (data.success) {
            resultDiv.className = 'alert alert-success';
            resultDiv.innerHTML = `
                <i class="fas fa-check-circle"></i> ${data.message}
                <br>物品：${data.item_name}
                <br>位置：仓库第 ${data.line_no} 格
            `;
            
            // 重置表单
            this.reset();
            selectedCharacter = null;
            document.getElementById('characterList').style.display = 'none';
            document.getElementById('itemList').style.display = 'none';
            for (let i = 2; i <= 5; i++) {
                document.getElementById('step' + i).classList.add('disabled');
            }
        } else {
            resultDiv.className = 'alert alert-danger';
            resultDiv.innerHTML = `<i class="fas fa-exclamation-circle"></i> 发送失败：${data.message}`;
        }
        resultDiv.style.display = 'block';
        
        setTimeout(() => {
            resultDiv.style.display = 'none';
        }, 5000);
    })
    .catch(error => {
        console.error('发送失败:', error);
        resultDiv.className = 'alert alert-danger';
        resultDiv.innerHTML = '<i class="fas fa-exclamation-circle"></i> 发送失败，请稍后重试';
        resultDiv.style.display = 'block';
    });
});

// 回车搜索
document.getElementById('accountInput').addEventListener('keypress', function(e) {
    if (e.key === 'Enter') {
        searchAccount();
    }
});
</script>
</body>
</html>
