<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once '../auth.php';
require_once '../config.php';
require_once '../db.php';
require_once 'item_parser.php';

// 处理POST请求
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    if ($_POST['action'] === 'buy') {
        if (!is_logged_in()) {
            echo json_encode(['success' => false, 'message' => '请先登录']);
            exit;
        }
        
        $post_no = $_POST['post_no'];
        $character_no = $_POST['character_no'] ?? '';
        
        // 调试信息
        error_log("Debug: post_no = $post_no, character_no = $character_no");
        error_log("Debug: session user_no = " . $_SESSION['user_no']);
        error_log("Debug: session server_id = " . $_SESSION['server_id']);
        
        $result = handlePurchase($post_no, $character_no);
        echo json_encode($result);
        exit;
    }
}

$admin_character = "E24080630000000032";

// 处理购买/取回请求
function handlePurchase($post_no, $character_no) {
    global $admin_character;
    
    try {
        $server_id = $_SESSION['server_id'];
        $user_no = $_SESSION['user_no'];
        
        error_log("Debug: Inside handlePurchase - server_id = $server_id, user_no = $user_no");
        
        $db_character = get_db($server_id, 'character');
        $db_account = get_db($server_id, 'account');
        $db_cash = get_db($server_id, 'cash');
        
        // 获取物品信息
        $sql = "SELECT * FROM USER_POSTBOX WHERE post_no = ? AND character_no = ?";
        error_log("Debug: SQL = $sql, params = [$post_no, $admin_character]");
        
        $item = $db_character->fetch($sql, [$post_no, $admin_character]);
        
        if (!$item) {
            error_log("Debug: Item not found!");
            throw new Exception("物品不存在或已售出");
        }
        
        error_log("Debug: Found item: " . print_r($item, true));
        
        // 验证角色归属
        $character = $db_character->fetch(
            "SELECT user_no, character_name FROM user_character WHERE character_no = ? AND user_no = ?",
            [$character_no, $user_no]
        );
        
        if (!$character) {
            error_log("Debug: Character not found or not owned by user!");
            throw new Exception('角色不属于您');
        }
        
        $character_name = $character['character_name'];
        error_log("Debug: Character name = $character_name");
        
        // 判断是否本人取回
        $is_self_recall = ($item['sell_character_no'] === $character_no);
        error_log("Debug: is_self_recall = " . ($is_self_recall ? 'true' : 'false'));
        error_log("Debug: sell_character_no = {$item['sell_character_no']}, selected_character_no = $character_no");
        
        if ($is_self_recall) {
            // 本人取回操作
            $db_character->exec("
                UPDATE USER_POSTBOX 
                SET character_no = ?,
                    from_char_nm = '系统管理员',
                    post_title = '装备取回成功',
                    body_text = '您已成功取回自己寄售的装备，请在90天内取出',
                    state_tag = 0,
                    ipt_time = GETDATE(),
                    expire_time = DATEADD(day, 90, GETDATE())
                WHERE post_no = ?
            ", [$character_no, $post_no]);
            
            $message = '装备取回成功！';
            error_log("Debug: Recall successful!");
            
        } else {
            // 非本人购买操作
            $message = '购买成功！';
            error_log("Debug: Purchase successful!");
        }
        
        return ['success' => true, 'message' => $message];
        
    } catch (Exception $e) {
        error_log("Error in handlePurchase: " . $e->getMessage());
        return ['success' => false, 'message' => $e->getMessage()];
    }
}

// 简单的测试页面
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>调试购买</title>
</head>
<body>
    <h1>调试购买功能</h1>
    <?php if (is_logged_in()): ?>
        <p>已登录：<?php echo $_SESSION['user_id']; ?></p>
        <p>服务器：<?php echo $_SESSION['server_id']; ?></p>
        
        <h2>测试购买</h2>
        <form id="testForm">
            <label>物品ID：<input type="text" id="post_no" value=""></label><br><br>
            <label>角色ID：<input type="text" id="character_no" value=""></label><br><br>
            <button type="button" onclick="testPurchase()">测试购买/取回</button>
        </form>
        
        <div id="result" style="margin-top: 20px;"></div>
    <?php else: ?>
        <p>请先登录</p>
    <?php endif; ?>
    
    <script>
        function testPurchase() {
            const postNo = document.getElementById('post_no').value;
            const characterNo = document.getElementById('character_no').value;
            const resultDiv = document.getElementById('result');
            
            if (!postNo || !characterNo) {
                alert('请填写物品ID和角色ID');
                return;
            }
            
            fetch('', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: 'action=buy&post_no=' + postNo + '&character_no=' + characterNo
            })
            .then(response => response.json())
            .then(data => {
                resultDiv.innerHTML = '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
            })
            .catch(error => {
                resultDiv.innerHTML = 'Error: ' + error.message;
            });
        }
    </script>
</body>
</html>
