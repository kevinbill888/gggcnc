<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

// 引入根目录下的认证模块
require_once '../config.php';
require_once '../auth.php';
require_once '../db.php';

// 检查登录状态
if (!is_logged_in()) {
    header('Location: ' . site_url('login.php'));
    exit;
}

$server_id = $_SESSION['server_id'];
$user_no = $_SESSION['user_no'];

// 获取当前角色
$current_character_no = $_SESSION['current_character_no'] ?? null;
$current_character_name = $_SESSION['current_character_name'] ?? '未选择角色';

// 获取用户角色列表
function getUserCharacters($server_id, $user_no) {
    $db_character = get_db($server_id, 'character');
    
    try {
        $characters = $db_character->fetchAll("
            SELECT character_no, character_name, wlevel, bypcClass 
            FROM user_character 
            WHERE user_no = ?
            ORDER BY wlevel DESC
        ", [$user_no]);
        
        return $characters;
    } catch (Exception $e) {
        error_log("getUserCharacters Error: " . $e->getMessage());
        return [];
    }
}

// 获取礼包列表
function getGiftList($server_id) {
    $db_account = get_db($server_id, 'account');
    
    try {
        $gifts = $db_account->fetchAll("
            SELECT id, min_level, min_upgrade, chr_date, 
                   item_id, item_name, item_count, Cash, Money
            FROM web_gift 
            ORDER BY min_level ASC
        ");
        
        return $gifts;
    } catch (Exception $e) {
        error_log("getGiftList Error: " . $e->getMessage());
        return [];
    }
}

// 获取装备兑换列表
function getExchangeItemList($server_id) {
    $db_account = get_db($server_id, 'account');
    
    try {
        $items = $db_account->fetchAll("
            SELECT oldid, oldname, newid, newname, needcash 
            FROM WEB_ExchangeItem 
            ORDER BY needcash ASC
        ");
        
        return $items;
    } catch (Exception $e) {
        error_log("getExchangeItemList Error: " . $e->getMessage());
        return [];
    }
}

// 获取用户背包物品
function getUserBagItems($server_id, $character_no) {
    $db_character = get_db($server_id, 'character');
    
    try {
        $items = $db_character->fetchAll("
            SELECT line_no, wIndex, info, byHeader 
            FROM user_bag 
            WHERE character_no = ?
            ORDER BY line_no ASC
        ", [$character_no]);
        
        return $items;
    } catch (Exception $e) {
        error_log("getUserBagItems Error: " . $e->getMessage());
        return [];
    }
}

// 获取用户余额
function getUserBalance($server_id, $user_no) {
    $db_cash = get_db($server_id, 'cash');
    
    try {
        $balance = $db_cash->fetch("
            SELECT amount, b_amount 
            FROM user_cash 
            WHERE user_no = ?
        ", [$user_no]);
        
        return [
            'c_coin' => $balance['amount'] ?? 0,
            'b_coin' => $balance['b_amount'] ?? 0
        ];
    } catch (Exception $e) {
        error_log("getUserBalance Error: " . $e->getMessage());
        return ['c_coin' => 0, 'b_coin' => 0];
    }
}

// 处理礼包领取
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['action'])) {
    header('Content-Type: application/json');
    
    if ($_POST['action'] === 'claim_gift') {
        $gift_id = $_POST['gift_id'];
        $character_no = $_POST['character_no'];
        
        try {
            $db_account = get_db($server_id, 'account');
            $db_character = get_db($server_id, 'character');
            
            // 开始事务
            $db_account->beginTransaction();
            $db_character->beginTransaction();
            
            // 检查礼包是否已领取
            $profile = $db_account->fetch("
                SELECT isGift FROM USER_PROFILE WHERE user_no = ?
            ", [$user_no]);
            
            $gift_bit = 1 << ($gift_id - 1);
            if (($profile['isGift'] ?? 0) & $gift_bit) {
                throw new Exception('该礼包已经领取过了');
            }
            
            // 获取礼包信息
            $gift = $db_account->fetch("
                SELECT * FROM web_gift WHERE id = ?
            ", [$gift_id]);
            
            if (!$gift) {
                throw new Exception('礼包不存在');
            }
            
            // 检查角色等级和转生
            $character = $db_character->fetch("
                SELECT wlevel, wMasterLevel, ipt_time 
                FROM user_character 
                WHERE character_no = ? AND user_no = ?
            ", [$character_no, $user_no]);
            
            if ($character['wlevel'] < $gift['min_level']) {
                throw new Exception('角色等级不足');
            }
            
            if ($character['wMasterLevel'] < $gift['min_upgrade']) {
                throw new Exception('角色转生次数不足');
            }
            
            // 更新礼包状态
            $new_gift_value = ($profile['isGift'] ?? 0) | $gift_bit;
            $db_account->exec("
                UPDATE USER_PROFILE SET isGift = ? WHERE user_no = ?
            ", [$new_gift_value, $user_no]);
            
            // 发送物品到邮箱
            if ($gift['item_id'] > 0) {
                $post_no = 'GIFT_' . date('YmdHis') . '_' . $user_no;
                $db_character->exec("
                    INSERT INTO user_postbox (
                        character_no, post_no, wIndex, dwSerialNumber,
                        byHeader, info, from_char_nm, post_title, body_text,
                        state_tag, item_tag, ipt_time, expire_time
                    ) VALUES (?, ?, ?, '00000000000000000000000000000000', 1, ?, 
                           '系统', ?, ?, ?, 0, 1, NOW(), DATEADD(day, 90, NOW()))
                ", [
                    $character_no, $post_no, $gift['item_id'], 
                    dechex($gift['item_count']), 
                    $gift['min_level'] . '级礼包', 
                    '恭喜您成功领取礼包，请在90天内取出！'
                ]);
            }
            
            // 发送商城币
            if ($gift['Cash'] > 0) {
                $db_account->exec("
                    UPDATE user_cash SET amount = amount + ? WHERE user_no = ?
                ", [$gift['Cash'], $user_no]);
            }
            
            // 提交事务
            $db_account->commit();
            $db_character->commit();
            
            echo json_encode(['success' => true, 'message' => '礼包领取成功！']);
            
        } catch (Exception $e) {
            $db_account->rollBack();
            $db_character->rollBack();
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
        exit;
    }
    
    // 处理装备兑换
    if ($_POST['action'] === 'exchange_item') {
        $line_no = $_POST['line_no'];
        $character_no = $_POST['character_no'];
        $exchange_id = $_POST['exchange_id'];
        
        try {
            $db_account = get_db($server_id, 'account');
            $db_character = get_db($server_id, 'character');
            
            // 开始事务
            $db_account->beginTransaction();
            $db_character->beginTransaction();
            
            // 获取兑换信息
            $exchange = $db_account->fetch("
                SELECT * FROM WEB_ExchangeItem WHERE id = ?
            ", [$exchange_id]);
            
            if (!$exchange) {
                throw new Exception('兑换信息不存在');
            }
            
            // 检查余额
            $balance = $db_account->fetch("
                SELECT amount FROM user_cash WHERE user_no = ?
            ", [$user_no]);
            
            if ($balance['amount'] < $exchange['needcash']) {
                throw new Exception('商城币不足');
            }
            
            // 扣除商城币
            $db_account->exec("
                UPDATE user_cash SET amount = amount - ? WHERE user_no = ?
            ", [$exchange['needcash'], $user_no]);
            
            // 更新装备
            $db_character->exec("
                UPDATE user_bag SET wIndex = ? WHERE line_no = ? AND character_no = ?
            ", [$exchange['newid'], $line_no, $character_no]);
            
            // 提交事务
            $db_account->commit();
            $db_character->commit();
            
            echo json_encode(['success' => true, 'message' => '装备兑换成功！']);
            
        } catch (Exception $e) {
            $db_account->rollBack();
            $db_character->rollBack();
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
        exit;
    }
}

// 获取功能类型
$function_type = $_GET['type'] ?? '';

// 设置页面信息
$page_title = '市场功能';
$breadcrumbs = [
    ['name' => '游戏市场', 'url' => site_url('market/')],
    ['name' => $function_type === 'gift' ? '领取礼包' : '装备兑换', 'url' => '#']
];

// 引入头部模板
include '../templates/header.php';
?>

<!-- 引入市场专用CSS -->
<link rel="stylesheet" href="../assets/css/market.css">

<!-- 功能页面样式 -->
<style>
.function-container {
    background: rgba(15, 15, 15, 0.85);
    backdrop-filter: blur(20px);
    color: #e0e0e0;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
    padding: 30px;
    border-radius: 12px;
    margin: 30px auto;
    max-width: 1200px;
    box-shadow: 0 15px 50px rgba(0, 0, 0, 0.5);
    border: 1px solid rgba(255, 255, 255, 0.15);
}

.function-header {
    background: rgba(30, 30, 30, 0.8);
    padding: 25px 30px;
    border-radius: 12px;
    margin-bottom: 30px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(5px);
}

.function-title {
    font-size: 28px;
    font-weight: 600;
    color: #f0f0f0;
    display: flex;
    align-items: center;
    gap: 15px;
    margin-bottom: 10px;
    text-shadow: 0 2px 4px rgba(0,0,0,0.5);
}

.function-title i {
    color: var(--accent);
}

.function-subtitle {
    color: #b0b0b0;
    font-size: 14px;
}

/* 角色选择器 */
.character-selector {
    background: rgba(20, 20, 20, 0.8);
    padding: 20px;
    border-radius: 12px;
    margin-bottom: 30px;
    border: 1px solid rgba(255, 255, 255, 0.1);
}

.character-selector h3 {
    color: #f0f0f0;
    margin-bottom: 15px;
    font-size: 18px;
}

.character-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: 15px;
}

.character-card {
    background: rgba(30, 30, 30, 0.7);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 8px;
    padding: 15px;
    cursor: pointer;
    transition: all 0.3s ease;
    text-align: center;
}

.character-card:hover {
    background: rgba(42, 42, 42, 0.8);
    border-color: var(--accent);
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(74, 158, 255, 0.3);
}

.character-card.active {
    background: rgba(42, 42, 42, 0.8);
    border-color: var(--accent);
    box-shadow: 0 0 10px rgba(74, 158, 255, 0.3);
}

.character-name {
    font-size: 16px;
    font-weight: 600;
    color: #f0f0f0;
    margin-bottom: 5px;
}

.character-info {
    font-size: 14px;
    color: #b0b0b0;
}

/* 礼包列表 */
.gift-list {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 20px;
}

.gift-card {
    background: rgba(30, 30, 30, 0.7);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 12px;
    padding: 20px;
    transition: all 0.3s ease;
}

.gift-card:hover {
    background: rgba(42, 42, 42, 0.8);
    border-color: var(--accent);
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(74, 158, 255, 0.3);
}

.gift-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 15px;
}

.gift-title {
    font-size: 18px;
    font-weight: 600;
    color: #f0f0f0;
}

.gift-status {
    padding: 4px 12px;
    border-radius: 20px;
    font-size: 12px;
    font-weight: 600;
}

.gift-status.available {
    background: rgba(40, 167, 69, 0.2);
    color: #28a745;
    border: 1px solid rgba(40, 167, 69, 0.4);
}

.gift-status.claimed {
    background: rgba(108, 117, 125, 0.2);
    color: #6c757d;
    border: 1px solid rgba(108, 117, 125, 0.4);
}

.gift-status.locked {
    background: rgba(220, 53, 69, 0.2);
    color: #dc3545;
    border: 1px solid rgba(220, 53, 69, 0.4);
}

.gift-requirements {
    margin-bottom: 15px;
}

.gift-requirement {
    display: flex;
    align-items: center;
    gap: 10px;
    margin-bottom: 5px;
    font-size: 14px;
    color: #b0b0b0;
}

.gift-requirement i {
    color: #4a9eff;
    width: 16px;
}

.gift-rewards {
    margin-bottom: 15px;
}

.gift-reward {
    display: flex;
    align-items: center;
    gap: 10px;
    margin-bottom: 5px;
    font-size: 14px;
}

.gift-reward i {
    color: #ffc107;
    width: 16px;
}

.gift-action {
    text-align: center;
}

.btn-claim {
    background: linear-gradient(135deg, #4a9eff, #3a7ecc);
    border: none;
    padding: 10px 20px;
    border-radius: 6px;
    color: white;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
    box-shadow: 0 2px 8px rgba(74, 158, 255, 0.3);
}

.btn-claim:hover:not(:disabled) {
    background: linear-gradient(135deg, #5aa8ff, #4a8edd);
    transform: translateY(-1px);
    box-shadow: 0 4px 10px rgba(74, 158, 255, 0.4);
}

.btn-claim:disabled {
    background: #666;
    cursor: not-allowed;
    box-shadow: none;
}

/* 装备兑换 */
.exchange-container {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 30px;
}

.exchange-list {
    background: rgba(20, 20, 20, 0.8);
    padding: 20px;
    border-radius: 12px;
    border: 1px solid rgba(255, 255, 255, 0.1);
}

.exchange-list h3 {
    color: #f0f0f0;
    margin-bottom: 15px;
    font-size: 18px;
}

.exchange-item {
    background: rgba(30, 30, 30, 0.7);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 8px;
    padding: 15px;
    margin-bottom: 10px;
    display: flex;
    align-items: center;
    justify-content: space-between;
}

.exchange-item-name {
    color: #f0f0f0;
    font-weight: 600;
}

.exchange-item-arrow {
    color: #4a9eff;
    margin: 0 10px;
}

.exchange-item-cost {
    color: #ffc107;
    font-weight: 600;
}

.bag-items {
    background: rgba(20, 20, 20, 0.8);
    padding: 20px;
    border-radius: 12px;
    border: 1px solid rgba(255, 255, 255, 0.1);
}

.bag-items h3 {
    color: #f0f0f0;
    margin-bottom: 15px;
    font-size: 18px;
}

.bag-item {
    background: rgba(30, 30, 30, 0.7);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 8px;
    padding: 15px;
    margin-bottom: 10px;
    display: flex;
    align-items: center;
    justify-content: space-between;
}

.bag-item-name {
    color: #f0f0f0;
    font-weight: 600;
}

.bag-item-action {
    display: flex;
    align-items: center;
    gap: 10px;
}

.btn-exchange {
    background: linear-gradient(135deg, #28a745, #218838);
    border: none;
    padding: 6px 12px;
    border-radius: 4px;
    color: white;
    font-size: 12px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.3s ease;
}

.btn-exchange:hover:not(:disabled) {
    background: linear-gradient(135deg, #34ce57, #2ea043);
    transform: translateY(-1px);
}

.btn-exchange:disabled {
    background: #666;
    cursor: not-allowed;
}

/* 响应式 */
@media (max-width: 768px) {
    .exchange-container {
        grid-template-columns: 1fr;
    }
    
    .character-grid {
        grid-template-columns: 1fr;
    }
    
    .gift-list {
        grid-template-columns: 1fr;
    }
}
</style>

<div class="function-container">
    <!-- 页面头部 -->
    <div class="function-header">
        <div class="function-title">
            <i class="fas fa-<?php echo $function_type === 'gift' ? 'gift' : 'sync'; ?>"></i>
            <?php echo $function_type === 'gift' ? '领取礼包' : '装备兑换'; ?>
        </div>
        <div class="function-subtitle">
            <?php echo $function_type === 'gift' ? '为您的角色领取专属礼包奖励' : '将您的装备升级为更强大的形态'; ?>
        </div>
    </div>
    
    <!-- 角色选择器 -->
    <div class="character-selector">
        <h3><i class="fas fa-users"></i> 选择角色</h3>
        <div class="character-grid">
            <?php 
            $characters = getUserCharacters($server_id, $user_no);
            if (!empty($characters)):
                foreach ($characters as $char): 
            ?>
                <div class="character-card" 
                     data-character-no="<?php echo $char['character_no']; ?>"
                     onclick="selectCharacter(this)">
                    <div class="character-name"><?php echo htmlspecialchars($char['character_name']); ?></div>
                    <div class="character-info">
                        Lv.<?php echo $char['wlevel']; ?> 
                        <?php echo getClass($char['bypcClass']); ?>
                    </div>
                </div>
            <?php 
                endforeach;
            else:
            ?>
                <div class="empty-state">
                    <i class="fas fa-user-slash"></i>
                    <p>暂无角色</p>
                </div>
            <?php endif; ?>
        </div>
    </div>
    
    <?php if ($function_type === 'gift'): ?>
        <!-- 礼包列表 -->
        <div class="gift-list" id="giftList">
            <?php 
            $gifts = getGiftList($server_id);
            if (!empty($gifts)):
                foreach ($gifts as $gift): 
            ?>
                <div class="gift-card">
                    <div class="gift-header">
                        <div class="gift-title"><?php echo $gift['min_level']; ?>级礼包</div>
                        <div class="gift-status" id="gift-status-<?php echo $gift['id']; ?>">
                            检查中...
                        </div>
                    </div>
                    
                    <div class="gift-requirements">
                        <div class="gift-requirement">
                            <i class="fas fa-layer-group"></i>
                            等级需求: Lv.<?php echo $gift['min_level']; ?>
                        </div>
                        <?php if ($gift['min_upgrade'] > 0): ?>
                        <div class="gift-requirement">
                            <i class="fas fa-arrow-up"></i>
                            转生需求: <?php echo $gift['min_upgrade']; ?>转
                        </div>
                        <?php endif; ?>
                        <?php if ($gift['chr_date']): ?>
                        <div class="gift-requirement">
                            <i class="fas fa-calendar"></i>
                            创建时间: <?php echo date('Y-m-d', strtotime($gift['chr_date'])); ?>
                        </div>
                        <?php endif; ?>
                    </div>
                    
                    <div class="gift-rewards">
                        <?php if ($gift['Cash'] > 0): ?>
                        <div class="gift-reward">
                            <i class="fas fa-coins"></i>
                            商城币: <?php echo $gift['Cash']; ?>
                        </div>
                        <?php endif; ?>
                        <?php if ($gift['Money'] > 0): ?>
                        <div class="gift-reward">
                            <i class="fas fa-money-bill"></i>
                            金币: <?php echo number_format($gift['Money']); ?>
                        </div>
                        <?php endif; ?>
                        <?php if ($gift['item_id'] > 0): ?>
                        <div class="gift-reward">
                            <i class="fas fa-box"></i>
                            <?php echo htmlspecialchars($gift['item_name']); ?> x<?php echo $gift['item_count']; ?>
                        </div>
                        <?php endif; ?>
                    </div>
                    
                    <div class="gift-action">
                        <button class="btn-claim" 
                                onclick="claimGift(<?php echo $gift['id']; ?>)"
                                id="gift-btn-<?php echo $gift['id']; ?>">
                            领取礼包
                        </button>
                    </div>
                </div>
            <?php 
                endforeach;
            else:
            ?>
                <div class="empty-state">
                    <i class="fas fa-gift"></i>
                    <p>暂无可领取的礼包</p>
                </div>
            <?php endif; ?>
        </div>
    <?php else: ?>
        <!-- 装备兑换 -->
        <div class="exchange-container">
            <!-- 兑换列表 -->
            <div class="exchange-list">
                <h3><i class="fas fa-exchange-alt"></i> 可兑换装备</h3>
                <?php 
                $exchange_items = getExchangeItemList($server_id);
                if (!empty($exchange_items)):
                    foreach ($exchange_items as $item): 
                ?>
                    <div class="exchange-item">
                        <div class="exchange-item-name"><?php echo htmlspecialchars($item['oldname']); ?></div>
                        <div class="exchange-item-arrow">→</div>
                        <div class="exchange-item-name"><?php echo htmlspecialchars($item['newname']); ?></div>
                        <div class="exchange-item-cost"><?php echo $item['needcash']; ?> 商城币</div>
                    </div>
                <?php 
                    endforeach;
                else:
                ?>
                    <div class="empty-state">
                        <i class="fas fa-exchange-alt"></i>
                        <p>暂无可兑换的装备</p>
                    </div>
                <?php endif; ?>
            </div>
            
            <!-- 背包物品 -->
            <div class="bag-items">
                <h3><i class="fas fa-backpack"></i> 我的背包</h3>
                <div id="bagItems">
                    <?php 
                    if ($current_character_no):
                        $bag_items = getUserBagItems($server_id, $current_character_no);
                        if (!empty($bag_items)):
                            foreach ($bag_items as $item): 
                                // 检查是否可兑换
                                $can_exchange = false;
                                foreach ($exchange_items as $ex_item) {
                                    if ($ex_item['oldid'] == $item['wIndex']) {
                                        $can_exchange = true;
                                        break;
                                    }
                                }
                            ?>
                                <div class="bag-item">
                                    <div class="bag-item-name">
                                        <?php 
                                        // 获取物品名称
                                        $db_account = get_db($server_id, 'account');
                                        $item_info = $db_account->fetch("
                                            SELECT item_name FROM web_items WHERE windex = ?
                                        ", [$item['wIndex']]);
                                        echo htmlspecialchars($item_info['item_name'] ?? '未知物品');
                                        ?>
                                    </div>
                                    <div class="bag-item-action">
                                        <?php if ($can_exchange): ?>
                                            <button class="btn-exchange" 
                                                    onclick="exchangeItem(<?php echo $item['line_no']; ?>, <?php echo $item['wIndex']; ?>)">
                                                兑换
                                            </button>
                                        <?php else: ?>
                                            <span style="color: #999;">不可兑换</span>
                                        <?php endif; ?>
                                    </div>
                                </div>
                            <?php 
                            endforeach;
                        else:
                        ?>
                            <div class="empty-state">
                                <i class="fas fa-box-open"></i>
                                <p>背包为空</p>
                            </div>
                        <?php endif; ?>
                    <?php else: ?>
                        <div class="empty-state">
                            <i class="fas fa-user-slash"></i>
                            <p>请先选择角色</p>
                        </div>
                    <?php endif; ?>
                </div>
            </div>
        </div>
    <?php endif; ?>
</div>

<script>
// 当前选中的角色
let selectedCharacterNo = null;

// 选择角色
function selectCharacter(element) {
    // 移除所有active类
    document.querySelectorAll('.character-card').forEach(card => {
        card.classList.remove('active');
    });
    
    // 添加active类到当前元素
    element.classList.add('active');
    
    // 保存角色编号
    selectedCharacterNo = element.dataset.characterNo;
    
    // 更新页面内容
    if (<?php echo $function_type === 'gift'; ?>) {
        checkGiftStatus();
    } else {
        updateBagItems();
    }
}

// 领取礼包
function claimGift(giftId) {
    if (!selectedCharacterNo) {
        alert('请先选择角色');
        return;
    }
    
    const btn = document.getElementById('gift-btn-' + giftId);
    const originalText = btn.innerHTML;
    btn.innerHTML = '领取中...';
    btn.disabled = true;
    
    fetch('', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'action=claim_gift&gift_id=' + giftId + '&character_no=' + selectedCharacterNo
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            alert('✅ ' + data.message);
            location.reload();
        } else {
            alert('❌ ' + data.message);
            btn.innerHTML = originalText;
            btn.disabled = false;
        }
    })
    .catch(error => {
        console.error('领取礼包错误:', error);
        alert('❌ 领取失败，请稍后重试');
        btn.innerHTML = originalText;
        btn.disabled = false;
    });
}

// 兑换装备
function exchangeItem(lineNo, wIndex) {
    if (!selectedCharacterNo) {
        alert('请先选择角色');
        return;
    }
    
    // 找到对应的兑换项
    const exchangeItems = <?php echo json_encode($exchange_items); ?>;
    let exchangeItem = null;
    
    for (let item of exchangeItems) {
        if (item.oldid == wIndex) {
            exchangeItem = item;
            break;
        }
    }
    
    if (!exchangeItem) {
        alert('该物品无法兑换');
        return;
    }
    
    if (!confirm(`确定要兑换 ${exchangeItem.oldname} 为 ${exchangeItem.newname} 吗？\n需要 ${exchangeItem.needcash} 商城币`)) {
        return;
    }
    
    fetch('', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'action=exchange_item&line_no=' + lineNo + '&character_no=' + selectedCharacterNo + '&exchange_id=' + exchangeItem.id
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            alert('✅ ' + data.message);
            location.reload();
        } else {
            alert('❌ ' + data.message);
        }
    })
    .catch(error => {
        console.error('兑换装备错误:', error);
        alert('❌ 兑换失败，请稍后重试');
    });
}

// 检查礼包状态
function checkGiftStatus() {
    if (!selectedCharacterNo) return;
    
    const giftIds = <?php echo json_encode(array_column($gifts, 'id')); ?>;
    const profileGifts = <?php echo json_encode($profile['isGift'] ?? 0); ?>;
    
    giftIds.forEach(giftId => {
        const statusEl = document.getElementById('gift-status-' + giftId);
        const btnEl = document.getElementById('gift-btn-' + giftId);
        
        const giftBit = 1 << (giftId - 1);
        const isClaimed = (profileGifts & giftBit) > 0;
        
        if (isClaimed) {
            statusEl.className = 'gift-status claimed';
            statusEl.textContent = '已领取';
            btnEl.disabled = true;
            btnEl.textContent = '已领取';
        } else {
            statusEl.className = 'gift-status available';
            statusEl.textContent = '可领取';
            btnEl.disabled = false;
            btnEl.textContent = '领取礼包';
        }
    });
}

// 更新背包物品
function updateBagItems() {
    if (!selectedCharacterNo) return;
    
    // 这里可以通过AJAX重新加载背包物品
    // 为了简化，直接刷新页面
    location.reload();
}

// 页面加载时自动选择第一个角色
document.addEventListener('DOMContentLoaded', function() {
    const firstCharacter = document.querySelector('.character-card');
    if (firstCharacter) {
        setTimeout(() => {
            firstCharacter.click();
        }, 500);
    }
});

// 获取职业名称
function getClass(classId) {
    const classes = [
        0 => '战士', 1 => '弓箭手', 2 => '法师', 3 => '驱魔师',
        4 => '巫师', 5 => '狂战士', 6 => '魔枪手',
        7 => '龙骑士', 9 => '暗咒师', 10 => '女武神',
        11 => '死神', 12 => '女战圣'
    ];
    return classes[classId] || '未知';
}
</script>

<?php include '../templates/footer.php'; ?>
