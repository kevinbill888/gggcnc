<?php
class AlipayTradePagePayContent {
    private $alipaySdkVersion = "alipay-sdk-php-20180705";
    
    public function generateAlipayRequest($params) {
        $params['method'] = 'alipay.trade.page.pay';
        $params['version'] = '1.0';
        $params['format'] = ALIPAY_FORMAT;
        $params['timestamp'] = date('Y-m-d H:i:s');
        $params['alipay_sdk'] = $this->alipaySdkVersion;
        $params['charset'] = ALIPAY_CHARSET;
        $params['sign_type'] = ALIPAY_SIGN_TYPE;
        $params['app_id'] = ALIPAY_APPID;
        
        // 构建业务参数
        $bizContent = array(
            'out_trade_no' => $params['out_trade_no'],
            'product_code' => 'FAST_INSTANT_TRADE_PAY',
            'total_amount' => $params['total_amount'],
            'subject' => $params['subject'],
            'body' => $params['body'],
            'return_url' => $params['return_url'],
            'notify_url' => $params['notify_url']
        );
        
        $params['biz_content'] = json_encode($bizContent, JSON_UNESCAPED_UNICODE);
        
        // 生成签名
        $params['sign'] = $this->generateSign($params);
        
        // 构建请求URL
        $requestUrl = ALIPAY_GATEWAY . '?';
        foreach ($params as $key => $value) {
            if ($key != 'sign' && !empty($value)) {
                $requestUrl .= $key . '=' . urlencode($value) . '&';
            }
        }
        $requestUrl .= 'sign=' . urlencode($params['sign']);
        
        return $requestUrl;
    }
    
    private function generateSign($params) {
        // 过滤空值和签名
        $filteredParams = array();
        foreach ($params as $key => $value) {
            if ($key != 'sign' && !empty($value)) {
                $filteredParams[$key] = $value;
            }
        }
        
        // 排序
        ksort($filteredParams);
        
        // 构建签名字符串
        $signString = '';
        foreach ($filteredParams as $key => $value) {
            $signString .= $key . '=' . $value . '&';
        }
        $signString = rtrim($signString, '&');
        
        // 签名
        $privateKey = $this->formatPrivateKey(ALIPAY_PRIVATE_KEY);
        openssl_sign($signString, $sign, $privateKey, OPENSSL_ALGO_SHA256);
        return base64_encode($sign);
    }
    
    private function formatPrivateKey($key) {
        $key = str_replace("-----BEGIN RSA PRIVATE KEY-----", "", $key);
        $key = str_replace("-----END RSA PRIVATE KEY-----", "", $key);
        $key = str_replace("\n", "", $key);
        $key = "-----BEGIN RSA PRIVATE KEY-----\n" . wordwrap($key, 64, "\n", true) . "\n-----END RSA PRIVATE KEY-----";
        return openssl_get_privatekey($key);
    }
    
    public function verifySign($params, $sign) {
        $filteredParams = array();
        foreach ($params as $key => $value) {
            if ($key != 'sign' && $key != 'sign_type' && !empty($value)) {
                $filteredParams[$key] = $value;
            }
        }
        
        ksort($filteredParams);
        
        $signString = '';
        foreach ($filteredParams as $key => $value) {
            $signString .= $key . '=' . $value . '&';
        }
        $signString = rtrim($signString, '&');
        
        $publicKey = $this->formatPublicKey(ALIPAY_PUBLIC_KEY);
        return openssl_verify($signString, base64_decode($sign), $publicKey, OPENSSL_ALGO_SHA256) === 1;
    }
    
    private function formatPublicKey($key) {
        $key = str_replace("-----BEGIN PUBLIC KEY-----", "", $key);
        $key = str_replace("-----END PUBLIC KEY-----", "", $key);
        $key = str_replace("\n", "", $key);
        $key = "-----BEGIN PUBLIC KEY-----\n" . wordwrap($key, 64, "\n", true) . "\n-----END PUBLIC KEY-----";
        return openssl_get_publickey($key);
    }
}
?>
