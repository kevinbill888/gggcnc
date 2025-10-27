<?php
// gift.php - 领取礼包页面
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once '../config.php';
require_once '../auth.php';
require_once '../db.php';
// 引入邮件发送函数
require_once '../functions/mail_sender.php';

// 检查登录状态
$is_logged_in = is_logged_in();

if (!$is_logged_in) {
    header('Location: ' . site_url('login.php'));
    exit;
}

$server_id = $_SESSION['server_id'];
$user_no = $_SESSION['user_no'];

// 获取当前角色ID
$current_character_no = $_SESSION['current_character_no'] ?? null;
$current_character_name = $_SESSION['current_character_name'] ?? '未选择角色';

// 获取当前角色完整信息
$current_character = null;
if ($current_character_no && $server_id) {
    $db_character = get_db($server_id, 'character');
    $current_character = $db_character->fetch("
        SELECT character_no, character_name, wlevel, wMasterLevel, ipt_time 
        FROM user_character 
        WHERE character_no = ? AND user_no = ?
    ", [$current_character_no, $user_no]);
}

// 获取礼包列表
function getGiftList($server_id) {
    $db_account = get_db($server_id, 'account');
    
    try {
        $stmt = $db_account->prepare("
            SELECT id, min_level, chr_date, item_id, Cash, Money, 
                   ISNULL(gift_name, '') as gift_name, item_name, item_count, min_upgrade
            FROM WEB_Gift2 
            ORDER BY id
        ");
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (Exception $e) {
        error_log("getGiftList Error: " . $e->getMessage());
        return [];
    }
}

// 获取礼包显示名称
function getGiftDisplayName($gift) {
    // 如果有自定义名称，使用自定义名称
    if (!empty($gift['gift_name'])) {
        return htmlspecialchars($gift['gift_name']);
    }
    // 否则使用默认名称
    return htmlspecialchars($gift['item_name']);
}

// 获取用户已领取的礼包（从account数据库的USER_PROFILE表）
function getUserClaimedGifts($server_id, $user_no) {
    $db_account = get_db($server_id, 'account');
    
    try {
        // 从USER_PROFILE表获取礼包状态
        $stmt = $db_account->prepare("
            SELECT TOP 1 isGift FROM USER_PROFILE 
            WHERE user_no = ?
        ");
        $stmt->execute([$user_no]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($row && $row['isGift'] !== null && $row['isGift'] !== '') {
            // 使用位运算解析已领取的礼包
            $claimed = [];
            $giftBits = $row['isGift'];
            
            // 检查每个礼包位
            for ($i = 1; $i <= 64; $i++) {
                $bitValue = 1 << ($i - 1);
                if (($giftBits & $bitValue) > 0) {
                    $claimed[] = $i;
                }
            }
            
            return $claimed;
        }
        
        return [];
    } catch (Exception $e) {
        error_log("getUserClaimedGifts Error: " . $e->getMessage());
        return [];
    }
}

// 获取用户角色列表（使用config.php中已定义的函数）
$characters = getUserCharacters($server_id, $user_no);

// 处理领取礼包请求
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    header('Content-Type: application/json');
    
    try {
        $action = $_POST['action'];
        
        if ($action === 'claim_gift') {
            $gift_id = intval($_POST['gift_id']);
            $character_no = $_POST['character_no'];
            
            // 获取数据库连接
            $db_account = get_db($server_id, 'account');
            $db_character = get_db($server_id, 'character');
            
            // 验证角色归属
            $char = $db_character->fetch("
                SELECT character_no, character_name, wlevel, wMasterLevel, ipt_time
                FROM user_character 
                WHERE character_no = ? AND user_no = ?
            ", [$character_no, $user_no]);
            
            if (!$char) {
                echo json_encode(['success' => false, 'message' => '角色信息错误']);
                exit;
            }
            
            // 获取礼包信息
            $gift = $db_account->fetch("
                SELECT * FROM WEB_Gift2 WHERE id = ?
            ", [$gift_id]);
            
            if (!$gift) {
                echo json_encode(['success' => false, 'message' => '礼包不存在']);
                exit;
            }
            
            // 检查是否已领取（账号级别）
            $claimed = getUserClaimedGifts($server_id, $user_no);
            if (in_array($gift_id, $claimed)) {
                echo json_encode(['success' => false, 'message' => '您已经领取过该礼包了']);
                exit;
            }
            
            // 检查等级要求
            if ($char['wlevel'] < $gift['min_level']) {
                echo json_encode(['success' => false, 'message' => '等级不足，需要等级 ' . $gift['min_level']]);
                exit;
            }
            
            // 检查转生要求
            if ($char['wMasterLevel'] < $gift['min_upgrade']) {
                echo json_encode(['success' => false, 'message' => '转生次数不足，需要 ' . $gift['min_upgrade'] . ' 转生']);
                exit;
            }
            
            // 检查创建时间要求
            if ($gift['chr_date']) {
                $char_time = strtotime($char['ipt_time']);
                $req_time = strtotime($gift['chr_date']);
                if ($char_time < $req_time) {
                    echo json_encode(['success' => false, 'message' => '角色创建时间不符合要求']);
                    exit;
                }
            }
            
            // 使用事务确保原子性
            $db_account->beginTransaction();
            $db_character->beginTransaction();
            
            try {
                // 1. 标记为已领取（账号级别）
                $current_claimed = getUserClaimedGifts($server_id, $user_no);
                $newGiftBits = 0;
                foreach ($current_claimed as $id) {
                    $newGiftBits |= (1 << ($id - 1));
                }
                $newGiftBits |= (1 << ($gift_id - 1));
                
                $stmt = $db_account->prepare("
                    UPDATE USER_PROFILE SET isGift = ? WHERE user_no = ?
                ");
                $result = $stmt->execute([$newGiftBits, $user_no]);
                
                if ($result === 0 || $stmt->rowCount() === 0) {
                    $stmt = $db_account->prepare("
                        INSERT INTO USER_PROFILE (user_no, isGift) VALUES (?, ?)
                    ");
                    $stmt->execute([$user_no, $newGiftBits]);
                }
                
                // 2. 使用邮件发送函数发送礼包（参考成功代码）
                $server_config = get_server_info($server_id);
                $send_results = sendGiftPackage($server_config, $user_no, $character_no, $gift);
                
                // 检查发送结果
                if (!empty($send_results['errors'])) {
                    throw new Exception('礼包发送失败: ' . implode(', ', $send_results['errors']));
                }
                
                // 提交事务
                $db_account->commit();
                $db_character->commit();
                
                echo json_encode([
                    'success' => true, 
                    'message' => '礼包领取成功！请前往游戏邮箱查收。'
                ]);
                
            } catch (Exception $e) {
                // 回滚事务
                $db_account->rollBack();
                $db_character->rollBack();
                
                error_log("Claim Error: " . $e->getMessage());
                echo json_encode(['success' => false, 'message' => '领取失败：' . $e->getMessage()]);
            }
        }
        
    } catch (Exception $e) {
        error_log("Main Error: " . $e->getMessage());
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
    exit;
}

// 获取页面数据
$gift_list = getGiftList($server_id);
$claimed_gifts = getUserClaimedGifts($server_id, $user_no);

// 设置页面信息
$page_title = '领取礼包 - 游戏市场';
$breadcrumbs = [
    ['name' => '游戏市场', 'url' => site_url('market/')],
    ['name' => '领取礼包', 'url' => site_url('market/gift.php')]
];

include '../templates/header.php';
?>

<style>
/* 礼包页面样式 */
.gift-container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
    position: relative;
}

.gift-header {
    text-align: center;
    margin-bottom: 30px;
}

.gift-title {
    font-size: 32px;
    font-weight: 800;
    color: #fff;
    text-shadow: 0 0 20px rgba(74, 158, 255, 0.5);
    margin-bottom: 10px;
}

.gift-subtitle {
    font-size: 16px;
    color: #b0b0b0;
}

/* 角色选择器 */
.character-selector {
    background: rgba(20, 20, 20, 0.9);
    backdrop-filter: blur(10px);
    border-radius: 12px;
    padding: 20px;
    margin-bottom: 30px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
}

.character-selector h3 {
    color: #f0f0f0;
    margin-bottom: 15px;
    font-size: 18px;
    display: flex;
    align-items: center;
    gap: 10px;
}

.character-selector h3 i {
    color: #4a9eff;
}

.character-options {
    display: flex;
    gap: 15px;
    flex-wrap: wrap;
}

.character-option {
    background: rgba(30, 30, 30, 0.8);
    border: 2px solid rgba(255, 255, 255, 0.1);
    border-radius: 8px;
    padding: 12px 20px;
    cursor: pointer;
    transition: all 0.3s ease;
    display: flex;
    align-items: center;
    gap: 10px;
    color: #e0e0e0;
}

.character-option:hover {
    background: rgba(74, 158, 255, 0.2);
    border-color: #4a9eff;
    transform: translateY(-2px);
}

.character-option.active {
    background: rgba(74, 158, 255, 0.3);
    border-color: #4a9eff;
    color: #4a9eff;
    font-weight: 600;
}

.character-option i {
    font-size: 20px;
}

.character-name {
    font-weight: 500;
}

.character-level {
    font-size: 12px;
    color: #888;
    margin-left: 5px;
}

/* 礼包卡片 */
.gift-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
    gap: 20px;
    margin-bottom: 30px;
}

.gift-card {
    background: rgba(20, 20, 20, 0.9);
    backdrop-filter: blur(10px);
    border-radius: 12px;
    padding: 20px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    transition: all 0.3s ease;
    position: relative;
    overflow: hidden;
}

.gift-card::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 4px;
    background: linear-gradient(90deg, #4a9eff, #9b59b6, #e74c3c, #f39c12);
    background-size: 400% 100%;
    animation: gradient-shift 3s ease infinite;
}

.gift-card.claimed::before {
    background: #6c757d;
}

@keyframes gradient-shift {
    0% { background-position: 0% 50%; }
    50% { background-position: 100% 50%; }
    100% { background-position: 0% 50%; }
}

.gift-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
}

/* 礼包头部布局 */
.gift-card-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    margin-bottom: 15px;
}

.gift-title-section {
    flex: 1;
}

.gift-number {
    font-size: 24px;
    font-weight: 800;
    color: #4a9eff;
    margin-bottom: 5px;
}

.gift-name {
    font-size: 18px;
    font-weight: 600;
    color: #f0f0f0;
}

/* 状态指示器 - 移到右上角 */
.gift-status {
    position: absolute;
    top: 15px;
    right: 15px;
    padding: 6px 12px;
    border-radius: 20px;
    font-weight: 600;
    font-size: 12px;
    z-index: 2;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
}

.status-available {
    background: linear-gradient(135deg, #28a745, #20c997);
    color: white;
}

.status-claimed {
    background: #6c757d;
    color: white;
}

.status-locked {
    background: #dc3545;
    color: white;
}

.gift-requirements {
    background: rgba(255, 255, 255, 0.05);
    border-radius: 8px;
    padding: 15px;
    margin-bottom: 15px;
}

.requirement-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 8px;
    font-size: 14px;
}

.requirement-item:last-child {
    margin-bottom: 0;
}

.requirement-label {
    color: #888;
}

.requirement-value {
    font-weight: 600;
}

.requirement-met {
    color: #28a745;
}

.requirement-not-met {
    color: #dc3545;
}

.gift-rewards {
    background: rgba(40, 167, 69, 0.1);
    border-radius: 8px;
    padding: 15px;
    margin-bottom: 15px;
}

.reward-item {
    display: flex;
    align-items: center;
    gap: 10px;
    margin-bottom: 8px;
    font-size: 14px;
}

.reward-item:last-child {
    margin-bottom: 0;
}

.reward-icon {
    font-size: 20px;
}

.reward-name {
    color: #e0e0e0;
}

.reward-amount {
    font-weight: 600;
    color: #ffc107;
}

.claim-btn {
    background: linear-gradient(135deg, #4a9eff, #3a7ecc);
    color: white;
    border: none;
    padding: 10px 20px;
    border-radius: 6px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
    width: 100%;
    position: relative;
}

.claim-btn:hover:not(:disabled) {
    background: linear-gradient(135deg, #5aa8ff, #4a8edd);
    transform: translateY(-2px);
}

.claim-btn:disabled {
    background: #6c757d;
    cursor: not-allowed;
    transform: none;
}

.claim-btn.loading {
    background: #6c757d;
    color: transparent;
    cursor: not-allowed;
}

.claim-btn.loading::after {
    content: '';
    position: absolute;
    top: 50%;
    left: 50%;
    width: 20px;
    height: 20px;
    margin: -10px 0 0 -10px;
    border: 2px solid transparent;
    border-top: 2px solid #ffffff;
    border-radius: 50%;
    animation: spin 1s linear infinite;
}

/* 账号级提示 */
.account-notice {
    background: rgba(74, 158, 255, 0.1);
    border: 1px solid rgba(74, 158, 255, 0.3);
    border-radius: 8px;
    padding: 15px;
    margin-bottom: 20px;
    color: #e0e0e0;
    font-size: 14px;
    text-align: center;
}

.account-notice i {
    color: #4a9eff;
    margin-right: 8px;
}

/* 防重复提交提示 */
.anti-duplicate-notice {
    background: rgba(255, 193, 7, 0.1);
    border: 1px solid rgba(255, 193, 7, 0.3);
    border-radius: 8px;
    padding: 10px 15px;
    margin-bottom: 15px;
    color: #ffc107;
    font-size: 12px;
    text-align: center;
}

.anti-duplicate-notice i {
    color: #ffc107;
    margin-right: 5px;
}

/* 加载动画 */
.loading-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.8);
    display: none;
    justify-content: center;
    align-items: center;
    z-index: 9999999;
}

.loading-content {
    text-align: center;
    color: white;
}

.loading-spinner {
    width: 50px;
    height: 50px;
    border: 4px solid rgba(255, 255, 255, 0.1);
    border-top: 4px solid #4a9eff;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin: 0 auto 20px;
}

@keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
}

/* Toast提示 */
.toast {
    position: fixed;
    top: 80px;
    right: 20px;
    padding: 15px 20px;
    border-radius: 8px;
    color: white;
    font-weight: 500;
    z-index: 9999999;
    animation: slideIn 0.3s ease;
    max-width: 300px;
}

.toast.success {
    background: #28a745;
    box-shadow: 0 4px 12px rgba(40, 167, 69, 0.3);
}

.toast.error {
    background: #dc3545;
    box-shadow: 0 4px 12px rgba(220, 53, 69, 0.3);
}

@keyframes slideIn {
    from { transform: translateX(100%); opacity: 0; }
    to { transform: translateX(0); opacity: 1; }
}
</style>

<!-- 加载动画遮罩 -->
<div id="loadingOverlay" class="loading-overlay" style="display: none;">
    <div class="loading-content">
        <div class="loading-spinner"></div>
        <div class="loading-text" id="loadingText">处理中...</div>
    </div>
</div>

<div class="gift-container">
    <!-- 页面头部 -->
    <div class="gift-header">
        <div class="gift-title">
            <i class="fas fa-gift"></i>
            礼包中心
        </div>
        <div class="gift-subtitle">
            精心准备的礼包，助力您的冒险之旅
        </div>
    </div>
    
    <!-- 账号级提示 -->
    <div class="account-notice">
        <i class="fas fa-info-circle"></i>
        <span>每个礼包只能由账号领取一次，领取后该账号下所有角色都无法再次领取</span>
    </div>
    
    <!-- 防重复提交提示 -->
    <div class="anti-duplicate-notice">
        <i class="fas fa-exclamation-triangle"></i>
        <span>领取过程中请勿重复点击按钮，以免造成异常</span>
    </div>
    
    <!-- 角色选择器 -->
    <?php if ($is_logged_in && $server_id): ?>
        <div class="character-selector">
            <h3><i class="fas fa-user"></i> 选择角色</h3>
            <div class="character-options">
                <?php foreach ($characters as $char): ?>
                    <div class="character-option <?php echo ($current_character['character_no'] ?? '') == $char['character_no'] ? 'active' : ''; ?>" 
                         data-character-no="<?php echo $char['character_no']; ?>"
                         data-character-name="<?php echo htmlspecialchars($char['character_name']); ?>"
                         onclick="selectCharacter(this)">
                        <i class="fas fa-user-circle"></i>
                        <div>
                            <span class="character-name"><?php echo htmlspecialchars($char['character_name']); ?></span>
                            <span class="character-level">Lv.<?php echo $char['wlevel']; ?></span>
                        </div>
                    </div>
                <?php endforeach; ?>
            </div>
        </div>
    <?php endif; ?>
    
    <!-- 礼包列表 -->
    <div class="gift-grid">
        <?php foreach ($gift_list as $gift): ?>
            <?php 
            $is_claimed = in_array($gift['id'], $claimed_gifts);
            $can_claim = false;
            $status_class = 'status-locked';
            $status_text = '未满足条件';
            $btn_disabled = 'disabled';
            
            // 获取礼包显示名称
            $gift_display_name = getGiftDisplayName($gift);
            
            // 检查是否可以领取
            if ($current_character) {
                $level_ok = $current_character['wlevel'] >= $gift['min_level'];
                $upgrade_ok = $current_character['wMasterLevel'] >= $gift['min_upgrade'];
                $time_ok = true;
                
                if ($gift['chr_date']) {
                    $char_time = strtotime($current_character['ipt_time']);
                    $req_time = strtotime($gift['chr_date']);
                    $time_ok = $char_time >= $req_time;
                }
                
                if ($level_ok && $upgrade_ok && $time_ok && !$is_claimed) {
                    $can_claim = true;
                    $status_class = 'status-available';
                    $status_text = '可领取';
                    $btn_disabled = '';
                } elseif ($is_claimed) {
                    $status_class = 'status-claimed';
                    $status_text = '账号已领取';
                }
            }
            ?>
            <div class="gift-card <?php echo $is_claimed ? 'claimed' : ''; ?>">
                <!-- 礼包头部 -->
                <div class="gift-card-header">
                    <div class="gift-title-section">
                        <div class="gift-number">礼包 <?php echo $gift['id']; ?></div>
                        <div class="gift-name"><?php echo $gift_display_name; ?></div>
                    </div>
                </div>
                
                <!-- 状态指示器 - 移到右上角 -->
                <div class="gift-status <?php echo $status_class; ?>">
                    <?php echo $status_text; ?>
                </div>
                
                <div class="gift-requirements">
                    <div class="requirement-item">
                        <span class="requirement-label">等级要求:</span>
                        <span class="requirement-value <?php echo $current_character && $current_character['wlevel'] >= $gift['min_level'] ? 'requirement-met' : 'requirement-not-met'; ?>">
                            Lv.<?php echo $gift['min_level']; ?>
                        </span>
                    </div>
                    <?php if ($gift['min_upgrade'] > 0): ?>
                    <div class="requirement-item">
                        <span class="requirement-label">转生要求:</span>
                        <span class="requirement-value <?php echo $current_character && $current_character['wMasterLevel'] >= $gift['min_upgrade'] ? 'requirement-met' : 'requirement-not-met'; ?>">
                            <?php echo $gift['min_upgrade']; ?>转
                        </span>
                    </div>
                    <?php endif; ?>
                    <?php if ($gift['chr_date']): ?>
                    <div class="requirement-item">
                        <span class="requirement-label">创建时间:</span>
                        <span class="requirement-value <?php echo $time_ok ? 'requirement-met' : 'requirement-not-met'; ?>">
                            <?php echo date('Y-m-d', strtotime($gift['chr_date'])); ?>后
                        </span>
                    </div>
                    <?php endif; ?>
                </div>
                
                <div class="gift-rewards">
                    <?php if ($gift['Cash'] > 0): ?>
                        <div class="reward-item">
                            <span class="reward-icon">💎</span>
                            <span class="reward-name">商城币</span>
                            <span class="reward-amount">+<?php echo number_format($gift['Cash']); ?></span>
                        </div>
                    <?php endif; ?>
                    <?php if ($gift['Money'] > 0): ?>
                        <div class="reward-item">
                            <span class="reward-icon">💰</span>
                            <span class="reward-name">游戏币</span>
                            <span class="reward-amount">+<?php echo number_format($gift['Money']); ?></span>
                        </div>
                    <?php endif; ?>
                    <?php if ($gift['item_id'] > 0): ?>
                        <div class="reward-item">
                            <span class="reward-icon">🎁</span>
                            <span class="reward-name"><?php echo htmlspecialchars($gift['item_name']); ?></span>
                            <span class="reward-amount">x<?php echo $gift['item_count']; ?></span>
                        </div>
                    <?php endif; ?>
                </div>
                
                <?php if ($can_claim): ?>
                    <button class="claim-btn" 
                            onclick="claimGift(<?php echo $gift['id']; ?>, this)"
                            data-gift-id="<?php echo $gift['id']; ?>">
                        <i class="fas fa-gift"></i> 立即领取
                    </button>
                <?php else: ?>
                    <button class="claim-btn" <?php echo $btn_disabled; ?>>
                        <i class="fas fa-lock"></i> <?php echo $status_text; ?>
                    </button>
                <?php endif; ?>
            </div>
        <?php endforeach; ?>
    </div>
</div>

<script>
// 防止重复提交的标记
let isSubmitting = false;

// 当前选中的角色
let selectedCharacterNo = '<?php echo $current_character['character_no'] ?? ''; ?>';
let selectedCharacterName = '<?php echo $current_character['character_name'] ?? ''; ?>';

// 选择角色
function selectCharacter(element) {
    // 移除所有active类
    document.querySelectorAll('.character-option').forEach(el => {
        el.classList.remove('active');
    });
    
    // 添加active类到当前元素
    element.classList.add('active');
    
    // 更新选中的角色
    selectedCharacterNo = element.dataset.characterNo;
    selectedCharacterName = element.dataset.characterName;
    
    console.log('Selected character:', selectedCharacterName, 'ID:', selectedCharacterNo);
    
    // 更新Session（通过AJAX）
    fetch('<?php echo site_url('assets/ajax/set_character.php'); ?>', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'character_no=' + selectedCharacterNo + '&character_name=' + encodeURIComponent(selectedCharacterName)
    }).then(response => response.json()).then(data => {
        if (data.success) {
            console.log('Character updated in session');
            // 刷新页面以更新礼包状态
            location.reload();
        }
    });
}

// 领取礼包 - 添加防重复提交
function claimGift(giftId, buttonElement) {
    // 防止重复提交
    if (isSubmitting) {
        showToast('请勿重复提交，正在处理中...', 'error');
        return;
    }
    
    if (!selectedCharacterNo) {
        showToast('请先选择角色', 'error');
        return;
    }
    
    if (confirm(`确定要用角色【${selectedCharacterName}】领取这个礼包吗？\n\n注意：每个礼包只能由账号领取一次！`)) {
        // 设置提交状态
        isSubmitting = true;
        
        // 禁用所有领取按钮
        document.querySelectorAll('.claim-btn:not(:disabled)').forEach(btn => {
            btn.disabled = true;
            btn.classList.add('loading');
        });
        
        showLoading('正在领取礼包...');
        
        fetch('', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: 'action=claim_gift&gift_id=' + giftId + '&character_no=' + selectedCharacterNo
        })
        .then(response => response.json())
        .then(data => {
            hideLoading();
            
            // 重置提交状态
            isSubmitting = false;
            
            if (data.success) {
                showToast(data.message, 'success');
                // 延迟刷新页面以更新状态
                setTimeout(() => {
                    location.reload();
                }, 2000);
            } else {
                showToast(data.message, 'error');
                // 重新启用按钮
                enableAllButtons();
            }
        })
        .catch(error => {
            hideLoading();
            // 重置提交状态
            isSubmitting = false;
            showToast('领取失败：' + error.message, 'error');
            // 重新启用按钮
            enableAllButtons();
        });
    }
}

// 启用所有按钮
function enableAllButtons() {
    document.querySelectorAll('.claim-btn').forEach(btn => {
        // 只启用原本可点击的按钮（没有disabled属性的）
        if (!btn.hasAttribute('disabled') || btn.getAttribute('disabled') === 'false') {
            btn.disabled = false;
            btn.classList.remove('loading');
        }
    });
}

// 显示Loading
function showLoading(text = '处理中...') {
    const overlay = document.getElementById('loadingOverlay');
    const loadingText = document.getElementById('loadingText');
    if (overlay) {
        overlay.style.display = 'flex';
        if (loadingText) loadingText.textContent = text;
    }
}

// 隐藏Loading
function hideLoading() {
    const overlay = document.getElementById('loadingOverlay');
    if (overlay) {
        overlay.style.display = 'none';
    }
}

// 显示Toast提示
function showToast(message, type = 'info') {
    const toast = document.createElement('div');
    toast.className = 'toast ' + type;
    toast.textContent = message;
    document.body.appendChild(toast);
    
    // 3秒后移除
    setTimeout(() => {
        toast.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        }, 300);
    }, 3000);
}

// 添加动画样式
if (!document.getElementById('toastAnimations')) {
    const style = document.createElement('style');
    style.id = 'toastAnimations';
    style.textContent = `
        @keyframes slideOut {
            from { transform: translateX(0); opacity: 1; }
            to { transform: translateX(100%); opacity: 0; }
        }
    `;
    document.head.appendChild(style);
}
</script>

<?php include '../templates/footer.php'; ?>
