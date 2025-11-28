<?php
// 创建 pay/test_asp_style.php
require_once '../config.php';

echo "<h2>ASP风格测试</h2>";

// 完全按照ASP的参数顺序
$order_no = 'ASP' . date('YmdHis');
$amount = 0.01;

// ASP中的参数顺序
$parameters = array();
$parameters['service'] = 'create_direct_pay_by_user';
$parameters['payment_type'] = '1';
$parameters['partner'] = ALIPAY_PARTNER;
$parameters['seller_email'] = ALIPAY_SELLER_EMAIL;
$parameters['return_url'] = 'https://reg.cnctz.com/i/pay/4.php';
$parameters['notify_url'] = 'https://reg.cnctz.com/i/pay/notify.php';
$parameters['_input_charset'] = ALIPAY_INPUT_CHARSET; // gbk
$parameters['out_trade_no'] = $order_no;
$parameters['subject'] = 'ASP测试';
$parameters['body'] = '测试';
$parameters['total_fee'] = $amount;

// 按照ASP的方式构建签名字符串
ksort($parameters);
reset($parameters);

$signString = '';
foreach ($parameters as $key => $value) {
    if ($value !== '' && !is_array($value)) {
        // ASP使用gb2312，我们用gbk
        $value = iconv('UTF-8', 'GBK//IGNORE', $value);
        $signString .= $key . '=' . $value . '&';
    }
}
$signString = rtrim($signString, '&');

// 添加key（不编码）
$signString .= ALIPAY_KEY;

// 生成MD5
$sign = md5($signString);

// 添加到参数
$parameters['sign'] = $sign;
$parameters['sign_type'] = 'MD5';

// 构建URL（参数需要URL编码）
$url = ALIPAY_GATEWAY . '?';
foreach ($parameters as $key => $value) {
    if ($key == 'sign') {
        $url .= $key . '=' . $value . '&';
    } else {
        $value = iconv('UTF-8', 'GBK//IGNORE', $value);
        $url .= $key . '=' . urlencode($value) . '&';
    }
}
$url = rtrim($url, '&');

echo "<h3>配置信息:</h3>";
echo "<p>Partner: " . ALIPAY_PARTNER . "</p>";
echo "<p>Seller: " . ALIPAY_SELLER_EMAIL . "</p>";
echo "<p>Key: " . ALIPAY_KEY . "</p>";
echo "<p>Charset: " . ALIPAY_INPUT_CHARSET . "</p>";

echo "<h3>签名字符串（未编码）:</h3>";
echo "<textarea style='width:100%;height:200px;'>" . htmlspecialchars($signString) . "</textarea>";

echo "<h3>生成的签名:</h3>";
echo "<p>$sign</p>";

echo "<h3>订单信息:</h3>";
echo "<p>订单号: $order_no</p>";
echo "<p>金额: ￥$amount</p>";

echo "<h3>支付链接:</h3>";
echo "<p><a href='$url' target='_blank'>点击支付</a></p>";
echo "<p>$url</p>";

// 显示所有参数
echo "<h3>所有参数:</h3>";
echo "<table border='1'>";
echo "<tr><th>参数</th><th>值</th></tr>";
foreach ($parameters as $key => $value) {
    echo "<tr><td>$key</td><td>" . htmlspecialchars($value) . "</td></tr>";
}
echo "</table>";
?>
