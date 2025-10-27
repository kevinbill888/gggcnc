<?php
// item_icon_helper.php - 物品图标识别模块

/**
 * 获取物品图标类型
 * @param string $item_name 物品名称
 * @return string 图标类型 (weapon|armor|accessory|gem|other)
 */
function getItemIconType($item_name) {
    $item_name = strtolower($item_name);
    
    // 武器类关键词
    $weapon_keywords = [
        '刀', '剑', '枪', '弓', '斧', '杖', '棍', '锤', '刃', '刺', '戟', '鞭', '爪', '拳',
        'weapon', 'sword', 'blade', 'gun', 'bow', 'axe', 'staff', 'hammer', 'dagger', 'spear'
    ];
    
    // 防具类关键词
    $armor_keywords = [
        '甲', '衣', '袍', '鞋', '盔', '盾', '护', '装', '腿', '头', '手', '靴', '铠', '胄',
        'armor', 'cloth', 'helmet', 'shield', 'boots', 'gloves', 'chest', 'pants', 'shoulder'
    ];
    
    // 首饰类关键词
    $accessory_keywords = [
        '项链', '指环', '戒指', '手镯', '耳环', '护符', '珠', '佩', '环', '坠', '饰', '佩饰',
        'necklace', 'ring', 'bracelet', 'earring', 'amulet', 'charm', 'jewelry', 'pendant'
    ];
    
    // 宝石类关键词
    $gem_keywords = [
        '石', '宝石', '晶', '玉', '钻', '珠', '矿石', '水晶', '翡翠', '玛瑙', '琥珀',
        'stone', 'gem', 'crystal', 'diamond', 'jewel', 'ruby', 'emerald', 'sapphire', 'amber'
    ];
    
    // 检查武器类
    foreach ($weapon_keywords as $keyword) {
        if (strpos($item_name, $keyword) !== false) {
            return 'weapon';
        }
    }
    
    // 检查防具类
    foreach ($armor_keywords as $keyword) {
        if (strpos($item_name, $keyword) !== false) {
            return 'armor';
        }
    }
    
    // 检查首饰类
    foreach ($accessory_keywords as $keyword) {
        if (strpos($item_name, $keyword) !== false) {
            return 'accessory';
        }
    }
    
    // 检查宝石类
    foreach ($gem_keywords as $keyword) {
        if (strpos($item_name, $keyword) !== false) {
            return 'gem';
        }
    }
    
    // 其他类
    return 'other';
}

/**
 * 获取物品图标URL
 * @param string $item_name 物品名称
 * @return string 图标URL
 */
function getItemIconUrl($item_name) {
    $icon_type = getItemIconType($item_name);
    
    // 本地图标路径
    $icons = [
        'weapon' => '../assets/images/wq.png',
        'armor' => '../assets/images/fj.png',
        'accessory' => '../assets/images/ss.png',
        'gem' => '../assets/images/st.png',
        'other' => '../assets/images/qt.png'
    ];
    
    return $icons[$icon_type] ?? $icons['other'];
}
