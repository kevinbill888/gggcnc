<?php
// 创建 pay/compare_signature.php
require_once '../config.php';

echo "<h2>签名对比工具</h2>";

// 模拟ASP的参数
$test_params = array(
    'service' => 'create_direct_pay_by_user',
    'payment_type' => '1',
    'partner' => ALIPAY_PARTNER,
    'seller_email' => ALIPAY_SELLER_EMAIL,
    'return_url' => 'https://reg.cnctz.com/i/pay/4.php',
    'notify_url' => 'https://reg.cnctz.com/i/pay/notify.php',
    '_input_charset' => ALIPAY_INPUT_CHARSET,
    'out_trade_no' => 'COMPARE' . date('YmdHis'),
    'subject' => '对比测试',
    'body' => '测试',
    'total_fee' => '0.01'
);

echo "<h3>方法2：GBK编码（正确方法）</h3>";
ksort($test_params);
$signString2 = '';
$signString2_display = ''; // 用于显示
foreach ($test_params as $key => $value) {
    $value_gbk = iconv('UTF-8', 'GBK//IGNORE', $value);
    $signString2 .= $key . '=' . $value_gbk . '&';
    $signString2_display .= $key . '=' . $value . ' (GBK: ' . bin2hex($value_gbk) . ') & ';
}
$signString2 = rtrim($signString2, '&');
$signString2_display = rtrim($signString2_display, '&');
$signString2 .= ALIPAY_KEY;
$sign2 = md5($signString2);

echo "<p>签名字符串（显示UTF-8，实际用GBK）:</p>";
echo "<textarea style='width:100%;height:200px;'>" . htmlspecialchars($signString2_display) . "</textarea>";
echo "<p>实际签名字符串（GBK）:</p>";
echo "<textarea style='width:100%;height:100px;'>" . htmlspecialchars($signString2) . "</textarea>";
echo "<p>MD5: $sign2</p>";

// 生成测试URL
echo "<h3>测试URL:</h3>";
$url = ALIPAY_GATEWAY . '?';
foreach ($test_params as $key => $value) {
    $value_gbk = iconv('UTF-8', 'GBK//IGNORE', $value);
    $url .= $key . '=' . urlencode($value_gbk) . '&';
}
$url .= 'sign=' . $sign2 . '&sign_type=MD5';
echo "<p><a href='$url' target='_blank'>点击测试</a></p>";
echo "<p>$url</p>";
?>
