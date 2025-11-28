<?php
session_start();

// 生成验证码
$numbers = [];
$targetIndex = rand(0, 2); // 目标数字索引（3个中的第1个）
$targetNumber = rand(10, 99);

// 生成3个数字位置
for ($i = 0; $i < 3; $i++) {
    $numbers[] = [
        'number' => ($i == $targetIndex) ? $targetNumber : rand(10, 99),
        'x' => rand(50, 200),
        'y' => rand(40, 90)
    ];
}

// 保存到session
$_SESSION['click_captcha'] = [
    'target_index' => $targetIndex,
    'target_number' => $targetNumber,
    'numbers' => $numbers,
    'time' => time()
];

// 创建图片
$width = 300;
$height = 150;
$image = imagecreatetruecolor($width, $height);

// 白色背景
$bgColor = imagecolorallocate($image, 255, 255, 255);
imagefill($image, 0, 0, $bgColor);

// 添加网格背景
$gridColor = imagecolorallocate($image, 230, 230, 230);
for ($i = 0; $i < $width; $i += 20) {
    imageline($image, $i, 0, $i, $height, $gridColor);
}
for ($i = 0; $i < $height; $i += 20) {
    imageline($image, 0, $i, $width, $i, $gridColor);
}

// 添加干扰数字（灰色）
for ($i = 0; $i < 5; $i++) {
    $fakeNumber = rand(10, 99);
    $fakeX = rand(20, $width - 50);
    $fakeY = rand(20, $height - 30);
    $color = imagecolorallocate($image, 150, 150, 150);
    imagestring($image, 4, $fakeX, $fakeY, $fakeNumber, $color);
}

// 绘制3个红色数字（其中1个是目标）
foreach ($numbers as $index => $num) {
    if ($index == $targetIndex) {
        // 目标数字 - 鲜红色
        $color = imagecolorallocate($image, 220, 20, 60);
        $bgColor = imagecolorallocate($image, 255, 200, 200);
    } else {
        // 混淆数字 - 暗红色
        $color = imagecolorallocate($image, 180, 20, 20);
        $bgColor = imagecolorallocate($image, 240, 220, 220);
    }
    
    // 绘制背景框
    imagefilledrectangle($image, $num['x'] - 5, $num['y'] - 5, $num['x'] + 50, $num['y'] + 25, $bgColor);
    imagerectangle($image, $num['x'] - 5, $num['y'] - 5, $num['x'] + 50, $num['y'] + 25, $color);
    
    // 绘制数字
    imagestring($image, 5, $num['x'], $num['y'], $num['number'], $color);
}

// 添加提示
$tipColor = imagecolorallocate($image, 0, 0, 0);
imagestring($image, 3, 10, 5, "Click the bright red number: " . $targetNumber, $tipColor);

// 输出图片
header('Content-Type: image/png');
header('Cache-Control: no-cache');
imagepng($image);
imagedestroy($image);
?>
