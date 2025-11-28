<?php
class AlipayMd5Pay {
    
    public function generateAlipayRequest($params) {
        // 构建请求参数
        $requestParams = array(
            'service' => 'create_direct_pay_by_user',
            'payment_type' => '1',
            'partner' => ALIPAY_PARTNER,
            'seller_email' => ALIPAY_SELLER_EMAIL,
            'return_url' => $params['return_url'],
            'notify_url' => 'https://reg.cnctz.com/i/pay/notify.php', // 使用固定URL
            '_input_charset' => ALIPAY_INPUT_CHARSET,
            'out_trade_no' => $params['out_trade_no'],
            'subject' => $params['subject'],
            'body' => $params['body'],
            'total_fee' => $params['total_amount']
        );
        
        // 排序
        ksort($requestParams);
        reset($requestParams);
        
        // 生成签名字符串（使用GBK编码）
        $signString = '';
        foreach ($requestParams as $key => $value) {
            if ($value !== '' && !is_array($value)) {
                // 转换为GBK编码
                $value_gbk = iconv('UTF-8', 'GBK//IGNORE', $value);
                $signString .= $key . '=' . $value_gbk . '&';
            }
        }
        $signString = rtrim($signString, '&');
        
        // 添加安全校验码（不编码）
        $signString .= ALIPAY_KEY;
        
        // 生成MD5签名
        $sign = md5($signString);
        
        // 添加签名
        $requestParams['sign'] = $sign;
        $requestParams['sign_type'] = 'MD5';
        
        // 构建URL（参数需要GBK编码后再URL编码）
        $url = ALIPAY_GATEWAY . '?';
        foreach ($requestParams as $key => $value) {
            if ($key == 'sign') {
                $url .= $key . '=' . $value . '&';
            } else {
                // 转换为GBK编码后再URL编码
                $value_gbk = iconv('UTF-8', 'GBK//IGNORE', $value);
                $url .= $key . '=' . urlencode($value_gbk) . '&';
            }
        }
        $url = rtrim($url, '&');
        
        return $url;
    }
    
    public function verifySign($params) {
        // 获取返回的签名
        $sign = $params['sign'] ?? '';
        unset($params['sign']);
        unset($params['sign_type']);
        
        // 排序
        ksort($params);
        reset($params);
        
        // 生成签名字符串（返回的参数已经是GBK编码）
        $signString = '';
        foreach ($params as $key => $value) {
            if ($value !== '' && !is_array($value)) {
                // 支付宝返回的参数是GBK编码，不需要再转换
                $signString .= $key . '=' . $value . '&';
            }
        }
        $signString = rtrim($signString, '&');
        
        // 添加安全校验码
        $signString .= ALIPAY_KEY;
        
        // 验证签名
        return md5($signString) === $sign;
    }
}
?>
