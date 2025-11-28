<?php
// 获取职业名称
function getClass($classId) {
    $classes = [
        0 => '战士', 1 => '弓箭手', 2 => '法师', 3 => '驱魔师',
        4 => '巫师', 5 => '狂战士', 6 => '魔枪手',
        7 => '龙骑士', 9 => '暗咒师', 10 => '女武神',
        11 => '死神', 12 => '女战圣'
    ];
    return $classes[$classId] ?? '未知';
}

// 16进制转10进制
function hexdec($hexString) {
    return intval($hexString, 16);
}

// 10进制转16进制
function dechex($number) {
    return base_convert($number, 10, 16);
}
?>
