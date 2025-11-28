<?php
session_start();

// 生成验证码数据
$captcha = [
    'token' => md5(uniqid(mt_rand(), true)),
    'x' => rand(100, 250), // 拼图X位置
    'y' => rand(50, 150),  // 拼图Y位置
    'width' => 50,         // 拼图宽度
    'height' => 50         // 拼图高度
];

// 保存到session
$_SESSION['slider_captcha'] = $captcha;

// 创建背景图
$width = 350;
$height = 200;
$image = imagecreatetruecolor($width, $height);

// 生成渐变背景
for ($i = 0; $i < $height; $i++) {
    $color = imagecolorallocate($image, 
        200 + rand(-20, 20),
        220 + rand(-20, 20),
        240 + rand(-20, 20)
    );
    imageline($image, 0, $i, $width, $i, $color);
}

// 添加一些噪点
for ($i = 0; $i < 200; $i++) {
    $color = imagecolorallocate($image, rand(150, 255), rand(150, 255), rand(150, 255));
    imagesetpixel($image, rand(0, $width), rand(0, $height), $color);
}

// 创建拼图形状（缺口）
$gap = imagecreatetruecolor($captcha['width'], $captcha['height']);
$transparent = imagecolorallocatealpha($gap, 0, 0, 0, 127);
imagefill($gap, 0, 0, $transparent);
imagecolortransparent($gap, $transparent);

// 绘制拼图形状（简单的矩形带圆角）
imagefilledrectangle($gap, 5, 5, 45, 45, $transparent);
imagerectangle($gap, 5, 5, 45, 45, 0x000000);

// 将拼图缺口复制到主图
imagecopy($image, $gap, $captcha['x'], $captcha['y'], 0, 0, $captcha['width'], $captcha['height']);

// 输出图片
header('Content-Type: image/png');
header('Cache-Control: no-cache');
imagepng($image);
imagedestroy($image);
imagedestroy($gap);

// 同时输出JSON数据给前端
if (isset($_GET['get_data'])) {
    header('Content-Type: application/json');
    echo json_encode([
        'token' => $captcha['token'],
        'y' => $captcha['y']
    ]);
    exit;
}
?>
