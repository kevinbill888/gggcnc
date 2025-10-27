<?php
// 物品属性解析模块
class ItemParser {
    private $db_account;
    private $db_character;
    
    public function __construct($db_account, $db_character) {
        $this->db_account = $db_account;
        $this->db_character = $db_character;
    }
    
    // 显示16进制
    private function showHex($data) {
        if ($data === null) return '';
        $hex = '';
        $length = strlen($data);
        for ($i = 0; $i < $length; $i++) {
            $ch = $data[$i];
            $h = strtoupper(dechex(ord($ch)));
            if (strlen($h) == 1) $h = '0' . $h;
            $hex .= $h;
        }
        return $hex;
    }
    
    // 16进制转10进制
    private function hexNumber($nums) {
        $nums = strtoupper(trim($nums));
        $power = strlen($nums) - 1;
        $result = 0;
        
        for ($i = 0; $i < strlen($nums); $i++) {
            $tmp = $nums[$i];
            if (is_numeric($tmp)) {
                $result += $tmp * pow(16, $power);
            } else {
                $result += (ord($tmp) - 55) * pow(16, $power);
            }
            $power--;
        }
        
        return $result;
    }
    
    // 计算属性数量
    private function calcCounts($byHeader, &$attrCount, &$socketCount, &$isStack) {
        $attrCount = 0;
        $socketCount = 0;
        $isStack = false;
        
        if (!is_numeric($byHeader)) return;
        
        $b = intval($byHeader);
        if ($b == 0) return;
        if ($b == 1) {
            $isStack = true;
            return;
        }
        
        // 计算镶嵌数量
        $socketCount = intval($b / 16);
        
        // 计算属性数量
        $r = $b % 16;
        if ($r >= 5 && $r <= 8) {
            $attrCount = $r - 4;
        }
        
        // 限制范围
        if ($attrCount < 0) $attrCount = 0;
        if ($attrCount > 4) $attrCount = 4;
        if ($socketCount < 0) $socketCount = 0;
        if ($socketCount > 4) $socketCount = 4;
    }
    
    // 解析物品属性
    public function parseItemDetails($itemName, $hexStr, $byHeader) {
        $hexInfo = strtoupper($this->showHex($hexStr));
        $this->calcCounts($byHeader, $attrCount, $socketCount, $isStack);
        
        $qty = "1";
        if ($isStack) {
            // 带数量的物品，前4个字符是数量
            if (strlen($hexInfo) >= 4) {
                $qty = $this->hexNumber(substr($hexInfo, 0, 4));
            }
        }
        
        // 解析属性 - 从后往前，每个属性6字符
        $attrs = array();
        if ($attrCount > 0) {
            $length = strlen($hexInfo);
            // 属性从倒数第6个字符开始，每个属性6字符
            $startPos = $length - ($attrCount * 6);
            
            for ($i = 0; $i < $attrCount; $i++) {
                $pos = $startPos + ($i * 6);
                if ($pos + 6 <= $length) {
                    $optIdxHex = substr($hexInfo, $pos, 4);
                    $optValHex = substr($hexInfo, $pos + 4, 2);
                    $optIdx = $this->hexNumber($optIdxHex);
                    $optVal = $this->hexNumber($optValHex);
                    
                    if (is_numeric($optIdx)) {
                        try {
                            $stmt = $this->db_account->prepare("SELECT Description, minData, MaxData FROM web_itemoption WHERE OptionIndex = ?");
                            $stmt->execute(array($optIdx));
                            $option = $stmt->fetch(PDO::FETCH_ASSOC);
                            
                            if ($option) {
                                // ASP公式: value = minData + Fix((maxData - minData) * optVal / 100)
                                $value = $option['minData'] + intval(($option['MaxData'] - $option['minData']) * $optVal / 100);
                                
                                $attrs[] = array('desc' => $option['Description'], 'value' => $value);
                            }
                        } catch (Exception $e) {
                            $attrs[] = array('desc' => '属性' . ($i + 1), 'value' => $optVal);
                        }
                    }
                }
            }
        }
        
        // 解析镶嵌 - 从前往后，每个镶嵌4字符
        $sockets = array();
        if ($socketCount > 0) {
            $startPos = $isStack ? 4 : 0; // 如果是堆叠物品，跳过前4个字符的数量
            
            for ($i = 0; $i < $socketCount; $i++) {
                $pos = $startPos + ($i * 4);
                if ($pos + 4 <= strlen($hexInfo)) {
                    $socketHex = substr($hexInfo, $pos, 4);
                    $socketId = $this->hexNumber($socketHex);
                    
                    if (is_numeric($socketId) && $socketId != 0) {
                        try {
                            // 使用account数据库中的web_itemetc_socket表
                            $stmt = $this->db_account->prepare("SELECT name, value FROM web_itemetc_socket WHERE ID = ?");
                            $stmt->execute(array($socketId));
                            $socket = $stmt->fetch(PDO::FETCH_ASSOC);
                            
                            if ($socket) {
                                $sockets[] = array('name' => $socket['name'], 'value' => $socket['value']);
                            }
                        } catch (Exception $e) {
                            $sockets[] = array('name' => '宝石' . ($i + 1), 'value' => '属性+' . ($i + 1));
                        }
                    }
                }
            }
        }
        
        return array(
            'name' => $itemName,
            'qty' => $qty,
            'attrs' => $attrs,
            'sockets' => $sockets
        );
    }
    
    // 获取JSON格式的物品详情
    public function getItemDetailsJson($itemName, $hexStr, $byHeader) {
        $details = $this->parseItemDetails($itemName, $hexStr, $byHeader);
        return json_encode($details);
    }
}
?>
